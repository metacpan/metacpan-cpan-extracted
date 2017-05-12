package Labyrinth::Plugin::Requests;

use warnings;
use strict;

use vars qw($VERSION);
$VERSION = '1.08';

=head1 NAME

Labyrinth::Plugin::Requests - Requests handler for the Labyrinth framework.

=head1 DESCRIPTION

Contains all the request administration functionality for Labyrinth.

=cut

# -------------------------------------
# Library Modules

use base qw(Labyrinth::Plugin::Base);

use Labyrinth::Audit;
use Labyrinth::Globals;
use Labyrinth::DBUtils;
use Labyrinth::MLUtils;
use Labyrinth::Support;
use Labyrinth::Variables;

# -------------------------------------
# Variables

# type: 0 = optional, 1 = mandatory
# html: 0 = none, 1 = text, 2 = textarea

my %fields = (
    requestid   => { type => 0, html => 1 },
    section     => { type => 1, html => 1 },
    command     => { type => 1, html => 1 },
    actions     => { type => 0, html => 1 },
    layout      => { type => 0, html => 1 },
    content     => { type => 0, html => 1 },
    onsuccess   => { type => 0, html => 1 },
    onerror     => { type => 0, html => 1 },
    onfailure   => { type => 0, html => 1 },
    secure      => { type => 0, html => 1 },
    rewrite     => { type => 0, html => 1 },
);

my @savefields  = qw(section command actions layout content onsuccess onerror onfailure secure rewrite);
my $INDEXKEY    = 'requestid';
my $ALLSQL      = 'AllRequests';
my $SAVESQL     = 'SaveRequest';
my $ADDSQL      = 'AddRequest';
my $GETSQL      = 'GetRequestByID';
my $DELETESQL   = 'DeleteRequests';
my $LEVEL       = ADMIN;

my %adddata = (
    section     => '',
    command     => '',
    actions     => '',
    layout      => '',
    content     => '',
    onsuccess   => '',
    onerror     => '',
    onfailure   => '',
    secure      => 1,
    rewrite     => '',
);

# security types

my %types = (
    1 => 'off',
    2 => 'on',
    3 => 'either',
    4 => 'both',
);
my @types = map {{'id'=>$_,'value'=> $types{$_}}} sort keys %types;


# -------------------------------------
# Admin Methods

=head1 ADMIN INTERFACE METHODS

=over 4

=item Admin

Handle main administrive duties, and display requests admin page.

=item Add

Add a request.

=item Edit

Edit a request.

=item Save

Save a request.

=item Delete

Delete one or more requests.

=item SecureSelect

Security selection box. This denotes whether request requires SSL.

=item SecureName

Give an id, returns the security status.

=back

=cut

sub Admin {
    return  unless(AccessUser($LEVEL));

    if($cgiparams{doaction}) {
        if($cgiparams{doaction} eq 'Delete' ) { Delete();  }
    }

    my @rows = $dbi->GetQuery('hash','AllRequests');
    for(@rows) {
        $_->{secured} = SecureName($_->{secure});
    }
    $tvars{data} = \@rows   if(@rows);
}

sub Add {
    return  unless AccessUser($LEVEL);
    $tvars{data} = \%adddata;
    $tvars{data}->{ddsecure} = SecureSelect($adddata{secure});
}

sub Edit {
    return  unless AccessUser($LEVEL);
    return  unless AuthorCheck($GETSQL,$INDEXKEY,$LEVEL);
    $tvars{data}->{ddsecure} = SecureSelect($tvars{data}->{secure});
}

sub Save {
    return  unless AccessUser($LEVEL);
    return  unless AuthorCheck($GETSQL,$INDEXKEY,$LEVEL);

    return  if ParamCheck(\%fields);

    my @fields;
    push @fields, $tvars{data}->{$_}    for(@savefields);
    if($cgiparams{$INDEXKEY}) {
        $dbi->DoQuery($SAVESQL,@fields,$cgiparams{$INDEXKEY});
    } else {
        $cgiparams{$INDEXKEY} = $dbi->IDQuery($ADDSQL,@fields);
    }

    $tvars{thanks} = 1;
}

sub Delete {
    return  unless AccessUser($LEVEL);
    my @ids = CGIArray('LISTED');
    return  unless @ids;

    # remove requests
    my $ids = join(",",@ids);
    $dbi->DoQuery($DELETESQL,{ids=>$ids});
}

sub SecureSelect {
    my $opt = shift || 0;
    DropDownRows($opt,"typeid",'id','value',@types);
}

sub SecureName {
    my $id = shift || 1;
    return $types{$id};
}

1;

__END__

=head1 SEE ALSO

L<Labyrinth>

=head1 AUTHOR

Barbie, <barbie@missbarbell.co.uk> for
Miss Barbell Productions, L<http://www.missbarbell.co.uk/>

=head1 COPYRIGHT & LICENSE

  Copyright (C) 2002-2015 Barbie for Miss Barbell Productions
  All Rights Reserved.

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
