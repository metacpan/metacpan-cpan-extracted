package Labyrinth::Plugin::Links;

use warnings;
use strict;

our $VERSION = '1.08';

=head1 NAME

Labyrinth::Plugin::Links - Links plugin handler for Labyrinth

=head1 DESCRIPTION

Contains all the link handling functionality for the Labyrinth
framework.

=cut

# -------------------------------------
# Library Modules

use base qw(Labyrinth::Plugin::Base);

use Labyrinth::DBUtils;
use Labyrinth::MLUtils;
use Labyrinth::Support;
use Labyrinth::Variables;

# -------------------------------------
# Variables

# type: 0 = optional, 1 = mandatory
# html: 0 = none, 1 = text, 2 = textarea

my %cat_fields = (
    catid       => { type => 0, html => 0 },
    orderno     => { type => 0, html => 1 },
    category    => { type => 1, html => 1 },
);

my (@cat_mandatory,@cat_allfields);
for(keys %cat_fields) {
    push @cat_mandatory, $_     if($cat_fields{$_}->{type});
    push @cat_allfields, $_;
}

my %fields = (
    linkid      => { type => 0, html => 0 },
    catid       => { type => 0, html => 0 },
    href        => { type => 1, html => 1 },
    title       => { type => 1, html => 3 },
    body        => { type => 0, html => 2 },
);

my (@mandatory,@allfields);
for(keys %fields) {
    push @mandatory, $_     if($fields{$_}->{type});
    push @allfields, $_;
}

my @savefields  = qw(title href body catid);
my $INDEXKEY    = 'linkid';
my $ALLSQL      = 'GetLinks';
my $SAVESQL     = 'SaveLink';
my $ADDSQL      = 'AddLink';
my $GETSQL      = 'GetLinkByID';
my $DELETESQL   = 'DeleteLink';

my %adddata = (
    linkid      => 0,
    href        => '',
    title       => '',
    body        => '',
);

my $protocol = qr{(?:http|https|ftp|afs|news|nntp|mid|cid|mailto|wais|prospero|telnet|gopher|git)://};

# -------------------------------------
# The Subs

=head1 PUBLIC INTERFACE METHODS

=head2 Default Methods

=over 4

=item List

Provides a list of all the current links.

=back

=cut

sub List {
    # get link list for current realm
    my @rows = $dbi->GetQuery('hash','GetLinks');
    $tvars{links} = \@rows  if(@rows);
}

=head1 ADMIN INTERFACE METHODS

=head2 Link Methods

=over 4

=item Admin

Provides a list of all the current links, with additional administrator
functions.

=item Add

Add a link.

=item Edit

Edit an existing link.

=item Save

Validates the given fields and saves to the database.

=item Delete

Delete a link

=item CheckLink

Checks whether a link begins with an accepted protocol (http, https, ftp), and
if missing adds 'http://'.

=back

=cut

sub Admin {
    return  unless(AccessUser(EDITOR));
    if($cgiparams{doaction}) {
           if($cgiparams{doaction} eq 'Delete' ) { Delete();  }
    }
    my @rows = $dbi->GetQuery('hash',$ALLSQL);
    $tvars{data} = \@rows   if(@rows);
}

sub Add {
    return  unless AccessUser(EDITOR);
    $tvars{data}{ddcats} = CatSelect();
}

sub Edit {
    return  unless AccessUser(EDITOR);
    return  unless AuthorCheck($GETSQL,$INDEXKEY,EDITOR);
    $tvars{data}{ddcats} = CatSelect($tvars{data}{catid});
    $tvars{data}{ddpublish} = PublishSelect($tvars{data}{publish},1);
}

sub Save {
    return  unless AccessUser(EDITOR);
    return  unless AuthorCheck($GETSQL,$INDEXKEY,EDITOR);
    for(keys %fields) {
           if($fields{$_}->{html} == 1) { $cgiparams{$_} = CleanHTML($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 2) { $cgiparams{$_} = CleanTags($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 3) { $cgiparams{$_} = CleanLink($cgiparams{$_}) }
    }
    return  if FieldCheck(\@allfields,\@mandatory);
    my @fields = map {$tvars{data}->{$_}} @savefields;
    if($cgiparams{$INDEXKEY}) {
        $dbi->DoQuery($SAVESQL,@fields,$cgiparams{$INDEXKEY});
    } else {
        $cgiparams{$INDEXKEY} = $dbi->IDQuery($ADDSQL,@fields);
    }
    $tvars{thanks} = 1;
}

sub Delete {
    return  unless AccessUser(ADMIN);
    my @ids = CGIArray('LISTED');
    return  unless @ids;

    $dbi->DoQuery($DELETESQL,{ids=>join(",",@ids)});
}

sub CheckLink {
    if($cgiparams{href} && $cgiparams{href} !~ m!^(/|$protocol)!) {
        $cgiparams{href} = 'http://' . $cgiparams{href};
    }
}

=head2 Category Admin

=over 4

=item CatAdmin

Provides a list of the link categories.

=item CatEdit

Edit a link category.

=item CatSave

Validates the fields returned from the edit page, and either saves or inserts
the record into the database.

=item CatDelete

Delete a link category.

=item CatSelect

Returns a HTML drop-down list of link categories.

=cut

sub CatAdmin {
    return  unless(AccessUser(EDITOR));
    if($cgiparams{doaction}) {
           if($cgiparams{doaction} eq 'Delete' ) { CatDelete();  }
    }
    my @rows = $dbi->GetQuery('hash','GetCategories');
    $tvars{data} = \@rows   if(@rows);
}

sub CatEdit {
    return  unless AccessUser(EDITOR);
    return  unless AuthorCheck('GetCategoryByID','catid',EDITOR);
}

sub CatSave {
    return  unless AccessUser(EDITOR);
    return  unless AuthorCheck('GetCategoryByID','catid',EDITOR);

    for(keys %cat_fields) {
           if($cat_fields{$_}->{html} == 1) { $cgiparams{$_} = CleanHTML($cgiparams{$_}) }
        elsif($cat_fields{$_}->{html} == 2) { $cgiparams{$_} = CleanTags($cgiparams{$_}) }
        elsif($cat_fields{$_}->{html} == 3) { $cgiparams{$_} = CleanLink($cgiparams{$_}) }
    }
    return  if FieldCheck(\@cat_allfields,\@cat_mandatory);

    $tvars{data}->{orderno} ||= 1;
    my @fields = ($tvars{data}->{orderno},$tvars{data}->{category});
    if($cgiparams{catid}) {    $dbi->DoQuery('SaveCategory',@fields,$cgiparams{catid}); }
    else { $cgiparams{catid} = $dbi->IDQuery('NewCategory',@fields); }
    $tvars{thanks} = 1;
}

sub CatDelete {
    return  unless AccessUser(ADMIN);
    my @ids = CGIArray('LISTED');
    return  unless @ids;
    $dbi->DoQuery('DeleteCategory',{ids=>join(",",@ids)});
    $dbi->DoQuery('DeleteCatLinks',{ids=>join(",",@ids)});
}

sub CatSelect {
    my $opt = shift;
    my @rows = $dbi->GetQuery('hash','GetCategories');
    DropDownRows($opt,'catid','catid','category',@rows);
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

  Copyright (C) 2002-2014 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
