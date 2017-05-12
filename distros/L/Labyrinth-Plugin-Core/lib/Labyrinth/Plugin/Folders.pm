package Labyrinth::Plugin::Folders;

use warnings;
use strict;

our $VERSION = '5.19';

=head1 NAME

Labyrinth::Plugin::Folders - handler for Labyrinth folders

=head1 DESCRIPTION

Contains all the folder handling functionality for the Labyrinth
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

my %fields = (
    folderid    => { type => 0, html => 1 },
    path        => { type => 1, html => 1 },
    parent      => { type => 0, html => 1 },
    accessid    => { type => 1, html => 1 }
);

my (@mandatory,@allfields);
for(keys %fields) {
    push @mandatory, $_     if($fields{$_}->{type});
    push @allfields, $_;
}

my @savefields  = qw(path accessid parent);

my $LEVEL       = ADMIN;
my $INDEXKEY    = 'folderid';
my $ALLSQL      = 'AllFolders';
my $GETSQL      = 'GetFolder';
my $SAVESQL     = 'UpdateFolder';
my $ADDSQL      = 'InsertFolder';
my $DELETESQL   = 'DeleteFolder';

# -------------------------------------
# The Subs

=head1 ADMIN INTERFACE METHODS

All action methods are only accessible by users with admin permission.

=over 4

=item Admin

Lists the current set of folders.

=item Add

Add a new folder.

=item Edit

Edit specified folder.

=item Save

Save specified folder.

=item Delete

Delete specified folder.

=item DeleteLinkRealm

Delete a link between the specified folder and realm.

=back

=cut

sub Admin {
    return  unless AccessUser(ADMIN);

    if($cgiparams{doaction}) {
           if($cgiparams{doaction} eq 'Delete' ) { Delete();  }
    }

    my @rows = $dbi->GetQuery('hash','AllFolders');
    $tvars{data} = \@rows   if(@rows);
}

sub Add {
    return  unless AccessUser(ADMIN);
    $tvars{data} = {
        path        => '',
        ddaccess    => AccessSelect(1),
        ddparent    => FolderSelect(1,'parent')
    };
}

sub Edit {
    return  unless AccessUser($LEVEL);
    return  unless( $cgiparams{'folderid'} && $cgiparams{'folderid'} > 1 );

    my @rows = $dbi->GetQuery('hash','GetFolder',$cgiparams{'folderid'});
    return  unless(@rows);

    $tvars{data} = $rows[0];
    $tvars{data}{ddaccess} = AccessSelect($rows[0]->{accessid});
    $tvars{data}{ddparent} = FolderSelect($rows[0]->{parent},'parent');
}

sub Save {
    return  unless AccessUser($LEVEL);
    return  unless AuthorCheck('GetFolder',$INDEXKEY);

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

  This module is free software; you can redistribute it and/or
  modify it under the Artistic License 2.0.

=cut
