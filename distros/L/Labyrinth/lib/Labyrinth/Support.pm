package Labyrinth::Support;

use warnings;
use strict;

use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT @EXPORT_OK);
$VERSION = '5.32';

=head1 NAME

Labyrinth::Support - Common Function Library for Labyrinth.

=head1 SYNOPSIS

  use Labyrinth::Support;

=head1 DESCRIPTION

The functions contain herein are commonly used throughout Labyrinth and 
plugins.

=head1 EXPORT

  AlignName
  AlignClass
  AlignSelect

  PublishState
  PublishSelect
  PublishAction

  FieldCheck
  ParamCheck
  AuthorCheck
  MasterCheck

  AccessName
  AccessID
  AccessUser
  AccessGroup
  AccessSelect
  AccessAllFolders 
  AccessAllAreas

  RealmCheck
  RealmSelect
  RealmName
  RealmID

  ProfileSelect
  FolderName
  FolderID
  FolderSelect
  AreaSelect

=cut

# -------------------------------------
# Export Details

require Exporter;
@ISA = qw(Exporter);

%EXPORT_TAGS = (
    'all' => [ qw(
        AlignName AlignClass AlignSelect
        PublishState PublishSelect PublishAction
        FieldCheck ParamCheck AuthorCheck MasterCheck
        AccessName AccessID AccessUser AccessGroup AccessSelect
        AccessAllFolders AccessAllAreas
        RealmCheck RealmSelect RealmName RealmID
        ProfileSelect FolderName FolderID FolderSelect AreaSelect
    ) ]
);

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT    = ( @{ $EXPORT_TAGS{'all'} } );

# -------------------------------------
# Library Modules

use Time::Local;

use Labyrinth::Audit;
use Labyrinth::Globals;
use Labyrinth::Groups;
use Labyrinth::MLUtils;
use Labyrinth::Session;
use Labyrinth::Writer;
use Labyrinth::Variables;

# -------------------------------------
# The Subs

=head1 FUNCTIONS

=over 4

=item PublishState

Returns the name of the current publish state, given the numeric state.

=item PublishSelect

Provides a dropdown selection box, as a XHTML code snippet, of the currently 
available publishing states.

=item PublishAction

Provides a dropdown selection box, as a XHTML code snippet, of the currently 
accessible publishing states.

=cut

my %publishstates = (
    1 => {Action => 'Draft',    State => 'Draft' },
    2 => {Action => 'Submit',   State => 'Submitted' },
    3 => {Action => 'Publish',  State => 'Published' },
    4 => {Action => 'Archive',  State => 'Archived' },
);
my @states = map {{'id'=>$_,'value'=> $publishstates{$_}->{State}}} sort keys %publishstates;

sub PublishState {
    my $state = shift;
    return ''   unless($state);
    return $publishstates{$state}->{State};
}


sub PublishSelect {
    my ($opt,$blank) = @_;
    my @list = @states;
    unshift @list, {id=>0,value=>'Select Status'}   if(defined $blank && $blank == 1);
    DropDownRows($opt,'publish','id','value',@list);
}

sub PublishAction {
    my $opt = shift ||  1;
    my $ack = shift || -1;

    my $html = qq{<select id="publish" name="publish">};
    foreach (sort keys %publishstates) {
        unless($ack == -1) {
            next    if(!$ack && $_ != $opt);
            next    if($_ < $opt || $_ > $opt+1);
        }
        $html .= "<option value='$_'";
        $html .= ' selected="selected"' if($opt == $_);
        $html .= ">$publishstates{$_}->{Action}</option>";
    }

    $html .= "</select>";
    return $html;
}

my %alignments = (
    0 => { name => 'none',              class => 'nail'     },
    1 => { name => 'left',              class => 'left'     },
    2 => { name => 'centre',            class => 'centre'   },
    3 => { name => 'right',             class => 'right'    },
    4 => { name => 'left (no wrap)',    class => 'lnowrap'  },
    5 => { name => 'right (no wrap)',   class => 'rnowrap'  },
);
my @alignments = map {{'id'=>$_,'value'=> $alignments{$_}->{name}}} sort keys %alignments;

=item AlignName

Returns the name of the given alignment type, defaults to 'none'.

=item AlignClass

Returns the class of the given alignment type, defaults to 'nail'.

=item AlignSelect

Provides a dropdown selection box, as a XHTML code snippet, of the currently 
available alignment states.

=cut

sub AlignName {
    my $opt = shift || 1;
    return $alignments{$opt}->{name};
}

sub AlignClass {
    my $opt = shift || 1;
    return $alignments{$opt}->{class};
}

sub AlignSelect {
    my $opt = shift || 0;
    my $num = shift || 0;
    DropDownRows($opt,"ALIGN$num",'id','value',@alignments);
}

=item AuthorCheck

Checks whether the current user is the author of the data requested, or has
permissions to allow them to access the data. If not sets the BADACCESS error
code, otherwise retrieves the data.

=cut

sub AuthorCheck {
    my ($key,$id,$permission) = @_;
    return 1    unless($cgiparams{$id});    # if the id key doesn't exist, this is likely to be a new entry

    $permission = ADMIN unless(defined $permission);

    my @rows = $dbi->GetQuery('hash',$key,$cgiparams{$id});
    return 0    unless(@rows);

    $tvars{data}{$_} = $rows[0]->{$_} for(keys %{$rows[0]});

    return 1    if(Authorised($permission));
    return 1    if($rows[0]->{userid} && $rows[0]->{userid} == $tvars{'loginid'});

    $tvars{errcode} = 'BADACCESS';
    return 0;
}

=item MasterCheck

Ensure only a Master user can access a Master user details.

=cut

sub MasterCheck {
    return 1    if( !$cgiparams{userid} || ! Authorised(MASTER,$cgiparams{userid}) );
    return 1    if( Authorised(MASTER,$cgiparams{userid}) && Authorised(MASTER,$tvars{'loginid'}) );
    $tvars{errcode} = 'BADACCESS';
    return 0;
}

=item FieldCheck(\@allfields,\@mandatory)

Stores all the input data listed in @allfields, then checks that all the fields
listed in @mandatory are provided. Any errors found during parameter parsing
both for missing mandatory fields and via Data::FormValidator are then flagged
and the error code set.

=item ParamCheck(\%fields)

Cleans data inputs, then stores all the input data fields in $tvars{data}. All
mandatory fields are validated to ensure each has a value. Any errors found 
during parameter parsing both for missing mandatory fields and via 
Data::FormValidator are then flagged and the error code set.

The fields hash contains a list of fields, with the keys 'type' and 'html'. 
'type' indicates whether the field is mandatory (1) or optional (0). 'html'
indicates the level of cleaning required:

    my %fields = (
        linkid      => { type => 0, html => 0 },
        catid       => { type => 0, html => 0 },
        href        => { type => 1, html => 1 },
        title       => { type => 1, html => 3 },
        body        => { type => 0, html => 2 },
    );

    # type: 0 = optional, 1 = mandatory
    # html: 0 = none, 1 = text, 2 = textarea, 3 = no links

'0' should only be used if previous parameter validation via 
Data::FormValidator has already ensured that only legal characters are used.

'1' removes all HTML tags.

'2' removes disallowed HTML tags and cleans up many tags and whitespace.

'3' removes anything that looks like a link or script tag, with the aim of 
preventing a XSS attack. 


=cut

sub FieldCheck {
    my ($allfields,$mandatory) = @_;

    # store base list for re-edit page
    foreach (@$allfields) {
        # automatically turn arrays into strings, in case someone is trying
        # to subvert the data input process. known arrays are correctly stored
        # appropriately elsewhere.
        $tvars{data}->{$_} = join("|",CGIArray($_));
    }

    # check for mandatory fields
    my $errors = 0;
    foreach (@$mandatory) {
        if(defined $cgiparams{$_} && exists $cgiparams{$_} && $cgiparams{$_}) {
            # nothing
        } else {
            LogDebug("FieldCheck: mandatory missing - [$_]");
            $tvars{data}->{$_.'_err'} = ErrorSymbol();
            $errors++;
            $tvars{errcode} = 'ERROR';
        }
    }

    # check for invalid fields
    for my $z (keys %cgiparams) {
        next    unless($z =~ /err_(.*)/);
        my $x = $1;
        $tvars{data}->{$x . '_err'} = ErrorSymbol();
        $errors++;
        $tvars{errcode} = 'ERROR';
    }

    return $errors;
}

sub ParamCheck {
    my ($fields) = @_;
    my $errors = 0;

    for my $key (keys %$fields) {

        # clean up cgi parameters
           if($fields->{$key}{html} == 1) { $cgiparams{$key} = CleanHTML($cgiparams{$key}) }
        elsif($fields->{$key}{html} == 2) { $cgiparams{$key} = CleanTags($cgiparams{$key}) }
        elsif($fields->{$key}{html} == 3) { $cgiparams{$key} = CleanLink($cgiparams{$key}) }

        # store field
    
        # automatically turn arrays into strings, in case someone is trying
        # to subvert the data input process. known arrays are correctly stored
        # appropriately elsewhere.
        $tvars{data}->{$key} = join("|",CGIArray($key));

        # skip checks if optional field
        next    unless($fields->{$key}{type});

        # mandatory fields must contain values
        next    if(defined $cgiparams{$key} && exists $cgiparams{$key} && $cgiparams{$key});

        # if we get here, record missing field
        LogDebug("FieldCheck: mandatory missing - [$key]");
        $tvars{data}->{$key.'_err'} = ErrorSymbol();
        $errors++;
        $tvars{errcode} = 'ERROR';
    }

    # check for invalid fields
    for my $z (keys %cgiparams) {
        next    unless($z =~ /err_(.*)/);
        my $x = $1;
        $tvars{data}->{$x . '_err'} = ErrorSymbol();
        $errors++;
        $tvars{errcode} = 'ERROR';
    }

    return $errors;
}

=item AccessName

Returns the access permission name, given the access id.

=item AccessID

Returns the access id, given the access permission name.

=item AccessUser

Returns whether the current user has access at the given level of permissions.
Default permission level is ADMIN. Returns 1 if permission is granted, 0 
otherwise.

=item AccessGroup

Returns whether the current user has access to the given group. Returns 1 if 
yes, 0 otherwise.

=item AccessSelect

Provides a dropdown selection box, as a XHTML code snippet, of the currently 
available access states.

=item AccessAllFolders

Return list of folders current user has access to.

=item AccessAllAreas

Return list of areas current user has access to.

=cut

sub AccessName  {
    my $value = shift;
    LoadAccess();
    return $settings{access}{ids}{$value};
}

sub AccessID  {
    my $value = shift;
    LoadAccess();
    return $settings{access}{names}{$value};
}

sub AccessUser  {
    my $permission = shift;
    $permission = ADMIN unless(defined $permission);

    return 1    if(Authorised($permission));

    $tvars{errcode} = 'BADACCESS';
    return 0;
}

sub AccessGroup {
    my %hash = @_;
    my $groupid = $hash{ID} || GetGroupID($hash{NAME});
    return 0    unless($groupid);   # this is not bad access, the group may have been deleted

    return 1    if UserInGroup($groupid);

    $tvars{errcode} = 'BADACCESS';
    return 0;
}

sub AccessSelect {
    my $opt  = shift || 0;
    my $name = shift || 'accessid';
    my $max  = Authorised(MASTER) ? MASTER : ADMIN;
    my @rows = $dbi->GetQuery('hash','AllAccess',$max);
    DropDownRows($opt,$name,'accessid','accessname',@rows);
}

sub AccessAllFolders {
    my $userid = shift || $tvars{loginid};
    my $access = shift || PUBLISHER;
    my $groups = getusergroups($userid);
    my @rows = $dbi->GetQuery('array','GetFolderAccess',
                        {groups=>$groups,userid=>$userid,access=>$access});
    my @folders = map {$_->[0]} @rows;
    return join(',',@folders);
}

sub AccessAllAreas {
    my @rows = $dbi->GetQuery('array','AllAreas');
    my @areas = map {"'$_->[0]'"} @rows;
    return join(',',@areas);
}

=item RealmCheck

Checks whether the given realm is known within the system.

=item RealmSelect

Provides a dropdown selection box, as a XHTML code snippet, of the currently 
available realms.

=item RealmName

Returns the name of a realm, given a realm id.

=item RealmID

Returns the id of a realm, given a realm name.

=cut

sub RealmCheck {
    while(@_) {
        my $realm = shift;
        return 1    if($realm eq $tvars{realm});
    }

    $tvars{errcode} = 'BADACCESS';
    return 0;   # failed
}

sub RealmSelect {
    my $opt = shift;
    my @rows = $dbi->GetQuery('hash','AllRealms');
    DropDownRows($opt,'realmid','realmid','name',@rows);
}

sub RealmName {
    my $id = shift;
    my @rows = $dbi->GetQuery('hash','GetRealmByID',$id);
    return $rows[0]->{realm};
}

sub RealmID {
    my $name = shift;
    my @rows = $dbi->GetQuery('hash','GetRealmByName',$name);
    return $rows[0]->{realmid};
}

=item ProfileSelect

Returns a dropdown list for the current list of profiles.

=item FolderID

Returns the folder id, given the folder name.

=item FolderName

Returns the name of a folder, given a folder id.

=item FolderSelect

Provides a dropdown selection box, as a XHTML code snippet, of the currently 
available folders.

=cut

sub ProfileSelect {
    my $opt  = shift || 0;
    my $name = shift || 'profile';
    LoadProfiles();
    my @rows = map { { profile => $_ } } sort grep {$_ ne $settings{profiles}{default} } keys %{$settings{profiles}{profiles}};
    unshift @rows, { profile => $settings{profiles}{default} }  if($settings{profiles}{default});
    unshift @rows, { profile => 'Select Profile' };
    DropDownRows($opt,$name,'profile','profile',@rows);
}

sub FolderID {
    my $opt  = shift || return;
    my @rows = $dbi->GetQuery('hash','GetFolderByPath',$opt);
    return @rows ? $rows[0]->{folderid} : undef;
}

sub FolderName {
    my $opt  = shift || return;
    my @rows = $dbi->GetQuery('hash','GetFolder',$opt);
    return @rows ? $rows[0]->{foldername} : undef;
}

sub FolderSelect {
    my $opt  = shift || 0;
    my $name = shift || 'folderid';
    my @rows = $dbi->GetQuery('hash','AllFolders');
    DropDownRows($opt,$name,'folderid','foldername',@rows);
}

=item AreaSelect

Provides a dropdown selection box, as a XHTML code snippet, of the currently 
available areas.

=cut

sub AreaSelect {
    my $opt = shift;
    my @rows = $dbi->GetQuery('hash','AllAreas');
    DropDownRows($opt,'area','areaid','title',@rows);
}

1;

__END__

=back

=head1 SEE ALSO

  Time::Local
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
