package Labyrinth::Plugin::Base;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '5.32';

=head1 NAME

Labyrinth::Plugin::Base - Base Plugin Handler for Labyrinth

=head1 DESCRIPTION

Contains all the admin handling functionality for a simple plugin.

=cut

# -------------------------------------
# Library Modules

use Labyrinth::Globals;
use Labyrinth::DBUtils;
use Labyrinth::Session;
use Labyrinth::Support;
use Labyrinth::Variables;

# -------------------------------------
# Variables

my @mandatory;
my @allfields;
my @savefields;
my @addfields;
my $INDEXKEY    = 'id';
my $ALLSQL      = 'AllRecords';
my $SAVESQL     = 'SaveRecord';
my $ADDSQL      = 'AddRecord';
my $GETSQL      = 'GetRecordByID';
my $DELETESQL   = 'DeleteRecords';
my $PROMOTESQL  = 'PromoteRecord';
my $IMAGEKEY    = 'NoImageCheck';
my $LEVEL       = EDITOR;
my $NEXTCOMMAND = 'home-main';

my %adddata;
my %fields;

# -------------------------------------
# The Subs

=head1 FUNCTIONS

=head2 Constructor

=over 4

=item new()

Creates the Plugin object.

=back

=cut

sub new {
    my $self    = shift;

    # create an attributes hash
    my $atts = {
        'mandatory'     => \@mandatory,
        'allfields'     => \@allfields,
        'savefields'    => \@savefields,
        'addfields'     => \@addfields,
        'INDEXKEY'      => $INDEXKEY,
        'ALLSQL'        => $ALLSQL,
        'SAVESQL'       => $SAVESQL,
        'ADDSQL'        => $ADDSQL,
        'GETSQL'        => $GETSQL,
        'DELETESQL'     => $DELETESQL,
        'PROMOTESQL'    => $PROMOTESQL,
        'IMAGEKEY'      => $IMAGEKEY,
        'LEVEL'         => $LEVEL,
        'NEXTCOMMAND'   => $NEXTCOMMAND,
        'adddata'       => \%adddata,
        'fields'        => \%fields,
    };

    # create the object
    bless $atts, $self;
    return $atts;
}

=head1 PUBLIC INTERFACE METHODS

None by default.

=head1 ADMIN INTERFACE METHODS

=over 4

=item Access

Determines the minimum level of access required. Primarily used to build the
administration navigation panel.

=cut

sub Access  { my $self = shift; Authorised($self->{LEVEL}) }

=item ImageCheck

Used when deleting images, to sure the plugin doesn't still reference them.
Otherwise missing images could result.

=cut

sub ImageCheck  { return 0 }

=item Admin

Full Admin list for the current plugin. Enables the 'Delete' and 'Copy'
features if they have been selected. Calls the SearchSQL function to generate
the 'WHERE' clause, and stores the result output.

=item SearchSQL

Generates the 'WHERE' clause to refine a list.

=item AdminAmendments

Some plugins need to add or amend field values, or perform additonal
functionality before displaying the list of records.

=cut

sub Admin {
    my $self = shift;
    return  unless(AccessUser($self->{LEVEL}));

    if($cgiparams{doaction}) {
           if($cgiparams{doaction} eq 'Delete')  { Delete()  }
        elsif($cgiparams{doaction} eq 'Copy')    { Copy()    }
        elsif($cgiparams{doaction} eq 'Promote') { Promote() }
    }

    my $where = SearchSQL();

    my @rows = $dbi->GetQuery('hash',$self->{ALLSQL},{where=>$where});
    $tvars{data} = \@rows   if(@rows);

    AdminAmendments();
}

sub SearchSQL { return '' }

sub AdminAmendments {}

=item Add

Primes the edit page for adding a record.

=item AddAmendments

Some plugins need to add or amend field values, or perform additonal
functionality before displaying the new record for edit.

=cut

sub Add {
    my $self = shift;
    return  unless AccessUser($self->{LEVEL});

    AddAmendments();

    $tvars{data} = $self->{adddata};
}

sub AddAmendments {}

=item Promote

Promotes the reference item through to the next stage of the workflow.

=cut

sub Promote {
    my $self = shift;
    return  unless AccessUser($self->{LEVEL});
    my @ids = CGIArray('LISTED');
    return  unless @ids;

    for my $id (@ids) {
        $cgiparams{$self->{INDEXKEY}} = $id;
        next    unless AuthorCheck($self->{GETSQL},$self->{INDEXKEY},$self->{LEVEL});

        my $publish = $tvars{data}->{publish} + 1;
        next    unless($publish < 5);
        $dbi->DoQuery($self->{PROMOTESQL},$publish,$cgiparams{$self->{INDEXKEY}});
    }
}

=item Copy

Performs any copy functionality required.

=item CopyAmendments

Some plugins need to add or amend field values, or perform additonal
functionality before saving and displaying the copied record for edit.

=cut

sub Copy {
    my $self = shift;
    return  unless(AccessUser($self->{LEVEL}));
    $cgiparams{$self->{INDEXKEY}} = $cgiparams{'LISTED'};
    return  unless AuthorCheck($self->{GETSQL},$self->{INDEXKEY},$self->{LEVEL});

    CopyAmendments();

    my @fields;
    push @fields, $tvars{data}->{$_}    for(@{$self->{addfields}});

    $cgiparams{$self->{INDEXKEY}} = $dbi->IDQuery($self->{ADDSQL},@fields);

    SetCommand($self->{NEXTCOMMAND});
}

sub CopyAmendments {}

=item Edit

Primes the edit page for editing a record.

=cut

sub Edit {
    my $self = shift;
    return  unless $cgiparams{$self->{INDEXKEY}};
    return  unless AccessUser($self->{LEVEL});
    return  unless AuthorCheck($self->{GETSQL},$self->{INDEXKEY});
    EditAmendments();
}

=item EditAmendments

Some plugins need to add or amend field values, or perform additonal
functionality before displaying the record for edit.

=cut

sub EditAmendments {}

=item Save

Validates the fields returned from the edit page, and either saves or inserts
the record into the database.

=cut

sub Save {
    my $self = shift;
    return  unless(AccessUser($self->{LEVEL}));
    return  unless AuthorCheck($self->{GETSQL},$self->{INDEXKEY},$self->{LEVEL});
    EditAmendments();

    for(keys %{$self->{fields}}) {
           if($fields{$_}->{html} == 1) { $cgiparams{$_} = CleanHTML($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 2) { $cgiparams{$_} = CleanTags($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 3) { $cgiparams{$_} = CleanLink($cgiparams{$_}) }
    }

    return  if FieldCheck($self->{allfields},$self->{mandatory});
    SaveAmendments();

    my @fields;
    if($cgiparams{$self->{INDEXKEY}}) {
        push @fields, $tvars{data}->{$_}    for(@{$self->{savefields}});
        $dbi->DoQuery($self->{SAVESQL},@fields,$cgiparams{$self->{INDEXKEY}});
    } else {
        push @fields, $tvars{data}->{$_}    for(@{$self->{addfields}});
        $cgiparams{$self->{INDEXKEY}} = $dbi->IDQuery($self->{ADDSQL},@fields);
    }

    $tvars{thanks} = 1;
}

=item SaveAmendments

Some plugins need to amend fields, or perform additonal functionality before
saving the record.

=cut

sub SaveAmendments {}

=item Delete

Deletes the requested records from the database.

=item DeleteItem

=item DeleteVerify

=cut

sub Delete {
    my $self = shift;
    return  unless AccessUser($self->{LEVEL});
    my @ids = CGIArray('LISTED');
    return  unless @ids;
    my $ids = join(",",@ids);

    $dbi->DoQuery($self->{DELETESQL},{ids=>$ids});
}

sub DeleteVerify {
    my $self = shift;
    return  unless AccessUser($self->{LEVEL});
    my @ids = CGIArray('LISTED');
    return  unless @ids;

    for my $id (@ids) {
        $cgiparams{$self->{INDEXKEY}} = $id;
        next    unless AuthorCheck($self->{GETSQL},$self->{INDEXKEY},$self->{LEVEL});
        $dbi->DoQuery($self->{DELETESQL},$cgiparams{$self->{INDEXKEY}});
    }
}

sub DeleteItem {
    my $self = shift;
    return  unless(AccessUser($self->{LEVEL}));
    $dbi->DoQuery($self->{DELETESQL},{ids=>$cgiparams{$self->{INDEXKEY}}});
}

1;

__END__

=back

=head1 SEE ALSO

  Labyrinth

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
