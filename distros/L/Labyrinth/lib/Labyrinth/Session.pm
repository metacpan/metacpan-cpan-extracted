package Labyrinth::Session;

use warnings;
use strict;

use vars qw($VERSION @ISA %EXPORT_TAGS @EXPORT @EXPORT_OK);
$VERSION = '5.32';

=head1 NAME

Labyrinth::Session - Session Management for Labyrinth.

=head1 SYNOPSIS

  use Labyrinth::Session;
  Login($username,$password);
  my $logged_in = 1 if(my $user = ValidSession());

=head1 DESCRIPTION

Provides the session management functionality, including Login & Logout 
functions, to maintain a user's access to the system. 

=cut

# -------------------------------------
# Export Details

require Exporter;
@ISA       = qw(Exporter);
%EXPORT_TAGS = (
    'all' => [ qw(
        ValidSession VerifyUser Authorised UserAccess FolderAccess
        ResetLanguage UpdateSession
    ) ]
);

@EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
@EXPORT    = ( @{ $EXPORT_TAGS{'all'} } );

# -------------------------------------
# Library Modules

use Labyrinth::Audit;
use Labyrinth::Globals;
use Labyrinth::DTUtils;
use Labyrinth::CookieLib;
use Labyrinth::Mailer;
use Labyrinth::Users;
use Labyrinth::Variables;

use Session::Token;

# -------------------------------------
# Variables

my (%USERS,%FOLDERS);

# -------------------------------------
# The Functional Interface

=head1 FUNCTIONS

=over 4

=item Login

Handles login capabilities, including bad logins.

=item InternalLogin

Saves the internal session of a successful login. Also used for automatic
authenticated logins.

=item Logout

Handles logout capabilities.

=cut

sub Login {
    # forgotten password?
    return _forgotten()             if($cgiparams{cause} && $cgiparams{forgot});

    # values complete?
    return SetError('ERROR',1)      unless($cgiparams{cause} && $cgiparams{effect});

    # verify username/password
    my @rows = CheckUser($cgiparams{cause},$cgiparams{effect});
    return SetError('BADUSER',1)    unless(@rows);

    InternalLogin($rows[0]);
}

sub InternalLogin {
    my $user = shift;

    $tvars{user} = $user;

    # add entry to session table
    my $session;
    (   $session,
        $tvars{user}{name},
        $tvars{'loginid'},
        $tvars{realm},
        $tvars{langcode}
    ) = _save_session($user->{realname},$user->{userid},$user->{realm},$user->{langcode});

    # set template variables
    $tvars{'loggedin'}   = 1;
    $tvars{user}{folder} = 1;
    $tvars{user}{option} = 0;
    $tvars{user}{userid} = $tvars{'loginid'};
    $tvars{user}{access} = VerifyUser($tvars{'loginid'});

    $tvars{realm} = $user->{realm} || 'public';

    if($tvars{realm} ne 'public') {
        SetCommand('home-' . $tvars{realm});
    }
}

sub Logout {
    my @rows = CheckUser('GUEST','GUEST');
    unless(@rows) {
        push @rows, {realname => 'Guest', userid => 0, realm => 'public', langcode => 'en'};
    }

    my $session;
    (   $session,
        $tvars{user}{name},
        $tvars{'loginid'},
        $tvars{realm},
        $tvars{langcode}
    ) = _save_session($rows[0]->{realname},$rows[0]->{userid},$rows[0]->{realm},$rows[0]->{langcode});
    $tvars{loggedin}     = 0;
    $tvars{user}{folder} = 1;
    $tvars{user}{option} = 0;
    $tvars{user}{userid} = $tvars{'loginid'};
    $tvars{user}{access} = VerifyUser($tvars{'loginid'});

    $tvars{redirect} = $settings{'logout-redirect'}   
        if($settings{'logout-redirect'} && $settings{'logout-redirect'} ne $cgiparams{act});
    return($session,$tvars{user}{name},$tvars{'loginid'},$tvars{realm});
}

=item ValidSession

Reloads an existing session, or creates a new one.

=item Store

Stores the current request, while the user logs in. (A simple form of continuations)

=item Retrieve

Retrieves the last request, if the user has logged in. (A simple form of continuations)
If the user is already login will set according to their realm.

=cut

sub ValidSession {
    # read cookie
    my ($userid,$name,$realm,$folder,$langcode,$option) = _get_session();
    $tvars{'loggedin'}   = ($name && lc $name ne 'guest') ? 1 : 0;
    $tvars{'loginid'}    = $userid;
    $tvars{'langcode'}   = $langcode;

    $tvars{user}{name}   = $name;
    $tvars{user}{userid} = $userid;
    $tvars{user}{folder} = $folder;
    $tvars{user}{option} = $option;
    $tvars{user}{access} = VerifyUser($userid);

    my $user = Labyrinth::Session->new($userid,$name,$realm);
    return $user;
}

sub Store {
    # we don't want to continually logout!
    return  if($cgiparams{act} eq 'user-logout');

    # store ready for continuation after login
    if (&GetCookies('sessionid')){
        my $session = $main::Cookies{'sessionid'};
        if($session && $session ne 'expired') {
            if(my @rows = $dbi->GetQuery('array','CheckSession',$session)) {
                my $query;
                if($cgiparams{lastpage} && $settings{lastpagereturn}) {
                    $query = $cgiparams{lastpage};
                    $query =~ y/~/=/;
                    $query =~ y/ /&/;
                } elsif($settings{lastpagereturn}) {
                    $query = join("&",map {"$_=$cgiparams{$_}"} keys %cgiparams);
                }
                $dbi->DoQuery('StoreSession',$query,$session);
            }
        }
    }
}

sub Retrieve {
    my $act = 'home-' . $tvars{realm};
LogDebug("Retrieve: 1.=$act");

    if(my @rows = $dbi->GetQuery('hash','GetRealmByName',$tvars{realm})) {
        $act = $rows[0]->{command};
    }
LogDebug("Retrieve: 2.=$act");

    if (&GetCookies('sessionid')){
        my $session = $main::Cookies{'sessionid'};
        if($session && $session ne 'expired') {
            if(my @rows = $dbi->GetQuery('array','RetrieveSession',$session)) {
LogDebug("Retrieve: 3.=[".($rows[0]->[0]||'')."]");
                my @parts = $rows[0]->[0] ? split("&",$rows[0]->[0]) : ();
                for my $part (@parts) {
                    $cgiparams{$1} = $2     if($part =~ /(.*?)=(.*)/);
                }
                $act = $cgiparams{act}  if(@parts);
                $dbi->DoQuery('StoreSession','',$session);
LogDebug("Retrieve: 4.=$act");
            }
        }
    }

LogDebug("Retrieve: NEXT=$act");
    SetCommand($act);
}

=item Authorised($level[,$userid])

Verifies the user has authorisation to the requested level. If userid is
omitted, the current user is assumed.

=item UserAccess

Returns the folders the user (and associated groups) has access to.

=item VerifyUser

Looks up the user's authorisation level, based on their user id and any groups
they belong to.

=item CheckUser

Given a username and password checks the database to ensure that the user
exists. Note that this uses both SHA1 (new encryption) and OLD_PASSWORD (old
encyription) to find the user. The latter is preserved for older
implementations.

=cut

sub Authorised  {
    my $needed = shift;
    return 0    if($needed && !$tvars{loggedin});

    my $userid = shift || $tvars{'loginid'};
    my $actual = VerifyUser($userid);

#   LogDebug("Authorised - needed=[$needed], actual=[$actual], result=[".($actual >= $needed ? 1 : 0)."]");

    return $actual >= $needed ? 1 : 0;
}

sub UserAccess {
    my $folderid = shift;
    my $groups = shift;

    my @rows = $dbi->GetQuery('array','FolderAccess',$tvars{loginid},$groups);
    return 0    unless(@rows);
    return $rows[0]->[0];
}

my %folderaccess;

sub VerifyUser {
    my $userid = shift || 0;
    my $folder = shift || 'public';
    my $access = 0;
LogDebug("VerifyUser($userid,'$folder')");

    return $access  unless($userid);

    # return if known
    return $folderaccess{$userid}{$folder}
        if($folderaccess{$userid}{$folder});

    # check base access
    my $user = GetUser($userid);
    $access = $user->{accessid};
    $tvars{user}{$_} = $user->{$_}   for(qw(realname nickname email));

    my @folders = ($folder ? GetFolderIDs( ref => $folder ) : (1));
    my $folders = join(',',grep {$_} @folders);
    my $groups = GetGroupIDs($userid);

    # check folder permissions
    my @rows = $dbi->GetQuery('hash','GetPermission',{folders=>$folders,groups=>$groups,user=>$userid});
    foreach my $rec (@rows) {
        $access = $rec->{accessid}  if($access < $rec->{accessid});
    }

LogDebug("-access=$access");

    $folderaccess{$userid}{$folder} = $access;
    return $access;
}

sub CheckUser {
    my ($user,$pass) = @_;

    return @{$USERS{$user}} if($USERS{$user});

    # SHA1 encryption
    my @rows = $dbi->GetQuery('hash','CheckUser',$user,$pass);
    if(@rows) {
        $USERS{$user} = \@rows;
        return @rows;
    }

    # OLD PASSWORD encryption
    @rows = $dbi->GetQuery('hash','CheckUserOld',$user,$pass);
    if(@rows) {
        $USERS{$user} = \@rows;
        return @rows;
    }

    # user not found
    return;
}

=item LoadFolders

Convienence function to load all folders when required.

=item GetFolderIDs

Returns the list of folders for the given leaf folder.

=item FolderAccess

Returns true or false as to whether the given user has access to the specified
folder. If no folder is given the default 'public' folder is used. If no user
is given the currently logged in user is used.

=cut

sub LoadFolders {
    return  if(%FOLDERS);

    my @rows = $dbi->GetQuery('hash','AllFolders');
    for my $row (@rows) {
        $FOLDERS{$row->{folderid}} = $row;
    }
}

sub GetFolderIDs {
    my %hash = @_;
    my ($id,%ids,@ids);

    LoadFolders();

    if($hash{id}) {
        $id = $hash{id};

    } elsif($hash{ref}) {
        for my $folderid (keys %FOLDERS) {
            if($FOLDERS{$folderid}->{path} eq $hash{ref}) {
                $id = $folderid;
                last;
            }
        }
    }

    return '0'  unless($id);

    while($FOLDERS{$id} && $FOLDERS{$id}->{parent} > 0) {
        $ids{$id} = 1;
        $id = $FOLDERS{$hash{id}}->{parent};
    }
    $ids{$id} = 1;
    @ids = keys %ids;

    return @ids if(wantarray);
    return join(",",@ids);
}

sub FolderAccess {
    my $folder = shift || 'public';
    my $userid = shift || $tvars{loginid};

LogDebug("FolderAccess('$folder',$userid)");

    my @rows = $dbi->GetQuery('hash','GetFolderByPath',$folder);
    return 0    unless(@rows);

    my $access = VerifyUser($userid,$folder);
    return 1    if($access >= $rows[0]->{accessid});
    return 0;
}

=item GetGroupIDs

Returns the list of groups the given user has access to.

=cut

sub GetGroupIDs {
    my $userid = shift;
    my %groups;

    $groups{1} = 1; # everyone is public

    # find primary groups for user
    my @rows = $dbi->GetQuery('array','GetGroupUserMap',$userid);

    while(@rows) {
        my (@parents);
        foreach (@rows) {
            next    if($_->[0] == 0);       # a bad entry
            next    if($groups{$_->[0]});   # already seen group
            $groups{$_->[0]} = 1;
            push @parents, $_->[0];
        }

        last    unless(@parents);

        # find associated groups for user
        @rows = $dbi->GetQuery('array','GetGroupParents',{groups=>join(",",@parents)});
    }

    return keys %groups if(wantarray);
    return join(",",keys %groups);
}

=item ResetLanguage

Within the current session, this function allows the user to change the
language associated within the system.

Currently this language element is under used, and could be used for error and
message strings pulled from a phrasebook.

=cut

sub ResetLanguage {
    my $lang = shift;
    return  unless($lang);

    my @rows = $dbi->GetQuery('array','GetLang',$lang);
    return  unless(@rows);

    $dbi->DoQuery('SetLangUser',$lang,$tvars{loginid});
    $dbi->DoQuery('SetLangSession',$lang,$settings{session});
    $tvars{langcode} = $lang;
}

=item UpdateSession

Updates specific fields for the current session.

=back

=cut

sub UpdateSession {
    my %hash = @_;
    my $session = delete $hash{session};
    $session ||= $main::Cookies{'sessionid'};
    for(keys %hash) {
        next    unless($hash{$_});
        $dbi->DoQuery('UpdateSession',{field=>$_},$hash{$_},$session);
    }

    if($hash{optionid}) {
        $tvars{user}{option} = $hash{optionid};
    }
}

# -------------------------------------
# The Object Interface

=head1 OBJECT METHODS

In addition to the above functions, the Session Management also allows for an
object interface.

=over 4

=item new

Create a new session object.

=item realm

Returns the current realm.

=cut

sub new {
    my $self = shift;

    my $atts = {
        'userid'    => $_[0],
        'name'      => $_[1],
        'realm'     => $_[2],
    };

    # create the object
    bless $atts, $self;
    return $atts;
}

sub realm {
    my $self = shift;
    return $self->{realm};
}

sub DESTROY {}

# -------------------------------------
# Internal Functions

sub _create_session_key {
    my $gen = Session::Token->new(length => 24);
    return $gen->get();
}

sub _get_session {
    my $tsnow = formatDate(0);

    if($settings{delete_sessions}) {
        # delete timed out sessions, including this one if necessary (self cleaning)
        my $timeout = $settings{timeout} || 0;
        my $tsthen = $tsnow - $timeout;
        $dbi->DoQuery('DeleteSessions',$tsthen);
    }

    # default settings
    my ($userid,$name,$realm,$folder,$langcode,$option) = (0,'guest','public',1,'en',0);
    my $session;

    # retrieve the cookie
    if($settings{testing}) {
        $userid     = $cgiparams{cluserid}      if($cgiparams{cluserid});
        $name       = $cgiparams{clname}        if($cgiparams{clname});
        $realm      = $cgiparams{clrealm}       if($cgiparams{clrealm});
        $folder     = $cgiparams{clfolder}      if($cgiparams{clfolder});
        $langcode   = $cgiparams{cllangcode}    if($cgiparams{cllangcode});
#LogDebug("get_session: testing: ($userid,$name,$realm,$folder)");
    } elsif (&GetCookies('sessionid')){
        $session = $main::Cookies{'sessionid'};
        LogDebug("session=$session");
    } else {
        LogDebug("session=<no session>");
    }

    if(!$userid) {
        my @rows = CheckUser('GUEST','GUEST');
        $userid = $rows[0]->{userid};
    }

    $session = undef    if($session && $session eq 'expired');

    # try and time stamp the session
    if($session) {
        my @rows = $dbi->GetQuery('array','CheckSession',$session);
        LogDebug("CheckSession: 1.".(@rows ? 'found' : 'no')." session");
        if(@rows) {
            ($userid,$name,$realm,$folder,$langcode,$option) = @{$rows[0]};
            $option = $cgiparams{option}    if($cgiparams{option});
            UpdateSession(timeout => $tsnow, optionid => $option, session => $session);
        } else {
            $session = undef;
        }
    }

    # check we actually updated in time
    if($session) {
        my @rows = $dbi->GetQuery('array','CheckSession',$session);
        LogDebug("CheckSession: 2.".(@rows ? 'found' : 'no')." session");
        $session = undef    unless(@rows);
    }

    # create a new session if necessary
    unless($session) {
        if($settings{testing}) {
            ($session) = Logout();
        } else {
            ($session,$name,$userid,$realm,$langcode) = Logout();
        }
    }
    $settings{session} = $session;

    LogDebug('GetSession:name=['.($name||'').'], realm=['.($realm||'').']');

    return $userid,$name,$realm,$folder,$langcode,$option;
}

sub _save_session {
    my @fields = @_;
    my $session;

    LogDebug('SaveSession:1 fields=['.join('][',map {$_ || ''} @fields).']');

    $fields[0] ||= 'guest';
    $fields[1] ||= 0;
    $fields[2] ||= 'public';
    $fields[3] ||= 'en';
    $fields[4] ||= 0;

    if($fields[1] == 0) {
        my @rows = CheckUser('GUEST','GUEST');
        $fields[1] = $rows[0]->{userid};
    }

    LogDebug('SaveSession:2 fields=['.join('][',map {$_ || ''} @fields).']');

    $session = $main::Cookies{'sessionid'}  if(GetCookies('sessionid'));
    if($session && $session ne 'expired') {
        # check the session has been recorded in case it's been reaped, a user
        # can relogin with the same session key
        my @rows = $dbi->GetQuery('array','CheckSession',$session);
        LogDebug("CheckSession: 3.".(@rows ? 'found' : 'no')." session");
        if(@rows) {
            $dbi->DoQuery('UpdateSessionX',formatDate(0),@fields,$session);
        } else {
            $dbi->DoQuery('CreateSession',formatDate(0),@fields,$session);
        }
    } else {
        # add entry to session table
        $session = _create_session_key($cgiparams{cause});
        $dbi->DoQuery('CreateSession',formatDate(0),@fields,$session);
    }

    SetCookiePath('/');
    $tvars{cookie} = SetCookie('sessionid',$session);
    LogDebug('SaveSession:4 fields=['.join('][',map {$_ || ''} @fields).']');
    return ($session,@fields);
}

sub _forgotten {
    my @rows = $dbi->GetQuery('hash','FindUser',$cgiparams{cause});
    return SetError('BADUSER')    unless(@rows);
    return SetError('BANUSER')    if($rows[0]->{password} eq '-banned-');

    my $password = FreshPassword();
    my $name = $rows[0]->{'realname'} || 'User';

    $dbi->DoQuery('ChangePassword',$password,$rows[0]->{userid});
    MailSend(   template    => 'mailer/forgot.eml',
                name        => $name,
                password    => $password,
                email       => $cgiparams{cause}
    );

    if(MailSent()) {
        SetCommand('user-forgot');
    } else {
        SetError('BADMAIL');
    }
}

1;

__END__

=back

=head1 SEE ALSO

  Digest::MD5
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
