package Labyrinth::Plugin::Users;

use warnings;
use strict;

our $VERSION = '5.19';

=head1 NAME

Labyrinth::Plugin::Users - Plugin Users handler for Labyrinth

=head1 DESCRIPTION

Contains all the default user handling functionality for the Labyrinth
framework.

=cut

# -------------------------------------
# Library Modules

use base qw(Labyrinth::Plugin::Base);

use Labyrinth::Audit;
use Labyrinth::DBUtils;
use Labyrinth::Media;
use Labyrinth::MLUtils;
use Labyrinth::Session;
use Labyrinth::Writer;
use Labyrinth::Support;
use Labyrinth::Users;
use Labyrinth::Variables;

use Clone   qw/clone/;
use Digest::MD5 qw(md5_hex);
use URI::Escape qw(uri_escape);

# -------------------------------------
# Constants

use constant    MaxUserWidth    => 300;
use constant    MaxUserHeight   => 400;

# -------------------------------------
# Variables

# type: 0 = optional, 1 = mandatory
# html: 0 = none, 1 = text, 2 = textarea

my %fields = (
    email       => { type => 1, html => 1 },
    effect      => { type => 0, html => 1 },
    userid      => { type => 0, html => 0 },
    nickname    => { type => 0, html => 1 },
    realname    => { type => 1, html => 1 },
    aboutme     => { type => 0, html => 2 },
    search      => { type => 0, html => 0 },
    image       => { type => 0, html => 0 },
    accessid    => { type => 0, html => 0 },
    realmid     => { type => 0, html => 0 },
);

my (@mandatory,@allfields);
for(keys %fields) {
    push @mandatory, $_     if($fields{$_}->{type});
    push @allfields, $_;
}

my $LEVEL = ADMIN;

# -------------------------------------
# The Subs

=head1 PUBLIC INTERFACE METHODS

=over 4

=item UserLists

Provide the current user list, taking into account of any search strings and
filters.

=item Gravatar

Provide the gravatar for a specified user.

=item Item

Provide the content attributed to the specified user.

=item Name

Provide the name of the specified user.

=item Password

Check and store a change of password.

=item Register

Provide the template variable hash for a new user to register.

=item Registered

Set the email address for the newly registered user, to auto log them in.

=back

=cut

sub UserLists {
    my (%search,$search,$key);
    my @fields = ();
    $search{where} = '';
    $search{order} = 'realname,nickname';
    $search{search} = 1;
    $search{access} = MASTER + 1;

    if(Authorised(ADMIN)) {
        $search{order} = 'u.realname'   if($cgiparams{ordered});
        $search{search} = 0;
        $search{access} = PUBLISHER     if($tvars{loginid} > 1);
    }

    if($cgiparams{'all'}) {
        $key = 'SearchUsers';
        @fields = ('%','%');

    } elsif($cgiparams{'letter'}) {
        $search = ($cgiparams{'letter'} || '') . '%';
        @fields = ($search,$search);
        $key = 'SearchUserNames';

    } elsif($cgiparams{'searchname'}) {
        $search = '%' . $cgiparams{'searchname'} . '%';
        @fields = ($search,$search);
        $key = 'SearchUserNames';

    } elsif($cgiparams{'searched'}) {
        @fields = ($cgiparams{'searched'},$cgiparams{'searched'});
        $key = 'SearchUsers';

    } else {
        $key = 'SearchUsers';
        @fields = ('%','%');
    }

    my @rows = $dbi->GetQuery('hash',$key,\%search,@fields);
    LogDebug("UserList: key=[$key], rows found=[".scalar(@rows)."]");

    for(@rows) {
        ($_->{width},$_->{height}) = GetImageSize($_->{link},$_->{dimensions},$_->{width},$_->{height},MaxUserWidth,MaxUserHeight);
        $_->{gravatar} = GetGravatar($_->{userid},$_->{email});

        if($_->{url} && $_->{url} !~ /^https?:/) {
            $_->{url} = 'http://' . $_->{url};
        }
        if($_->{aboutme}) {
            $_->{aboutme} = '<p>' . $_->{aboutme}   unless($_->{aboutme} =~ /^\s*<p>/si);
            $_->{aboutme} .= '</p>'                 unless($_->{aboutme} =~ m!</p>\s*$!si);
        }
        my @grps = $dbi->GetQuery('hash','LinkedUsers',$_->{userid});
        if(@grps) {
            $_->{member} = $grps[0]->{member};
        }
        if(Authorised(ADMIN)) {
            $_->{name}  = $_->{realname};
            $_->{name} .= " ($_->{nickname})" if($_->{nickname});
        } else {
            $_->{name} = $_->{nickname} || $_->{realname};
        }
    }

    $tvars{users}    = \@rows       if(@rows);
    $tvars{searched} = $fields[0]   if(@fields);
}

sub Gravatar {
    my $nophoto = uri_escape($settings{nophoto});
    $tvars{data}{gravatar} = $nophoto;

    return  unless $cgiparams{'userid'};
    my @rows = $dbi->GetQuery('hash','GetUserByID',$cgiparams{'userid'});
    return  unless @rows;

    $tvars{data}{gravatar} =
        'http://www.gravatar.com/avatar.php?'
        .'gravatar_id='.md5_hex($rows[0]->{email})
        .'&amp;default='.$nophoto
        .'&amp;size=80';
}

sub Item {
    return  unless $cgiparams{'userid'};

    my @rows = $dbi->GetQuery('hash','GetUserByID',$cgiparams{'userid'});
    return  unless(@rows);

    $rows[0]->{tag}  = ''   if($rows[0]->{link} =~ /blank.png/);
    $rows[0]->{link} = ''   if($rows[0]->{link} =~ /blank.png/);

    ($rows[0]->{width},$rows[0]->{height}) = GetImageSize($rows[0]->{link},$rows[0]->{dimensions},$rows[0]->{width},$rows[0]->{height},MaxUserWidth,MaxUserHeight);
    $rows[0]->{gravatar} = GetGravatar($rows[0]->{userid},$rows[0]->{email});

    $tvars{data} = $rows[0];
}

sub Name {
    return unless($cgiparams{'userid'});
    return UserName($cgiparams{'userid'})
}

sub Password {
    return  unless $tvars{'loggedin'};

    $cgiparams{'userid'} = $tvars{'loginid'}    unless(Authorised(ADMIN) && $cgiparams{'userid'});
    $tvars{data}->{name} = UserName($cgiparams{userid});

    my @manfields = qw(userid effect2 effect3);
    push @manfields, 'effect1'  if($cgiparams{'userid'} == $tvars{'loginid'} || $tvars{user}{access} < ADMIN);

    if(FieldCheck(\@manfields,\@manfields)) {
        $tvars{errmess} = 'All fields must be complete, please try again.';
        $tvars{errcode} = 'ERROR';
        return;
    }

    my $who = $cgiparams{'userid'};
    $who = $tvars{'loginid'} if(Authorised(ADMIN));

    if($cgiparams{'userid'} == $tvars{'loginid'} || $tvars{user}{access} < ADMIN) {
        my @rows = $dbi->GetQuery('hash','ValidUser',$who,$cgiparams{'effect1'});
        unless(@rows) {
            $tvars{errmess} = 'Current password is invalid, please try again.';
            $tvars{errcode} = 'ERROR';
            return;
        }
    }

    if($cgiparams{effect2} ne $cgiparams{effect3}) {
        $tvars{errmess} = 'New &amp; verify passwords don\'t match, please try again.';
        $tvars{errcode} = 'ERROR';
        return;
    }

    my %passerrors = (
        1 => "Password too short, length should be $settings{minpasslen}-$settings{maxpasslen} characters.",
        2 => "Password too long, length should be $settings{minpasslen}-$settings{maxpasslen} characters.",
        3 => 'Password not cyptic enough, please enter as per password rules.',
        4 => 'Password contains spaces or tabs.',
        5 => 'Password should contain 3 or more unique characters.',
    );

    my $invalid = PasswordCheck($cgiparams{effect2});
    if($invalid) {
        $tvars{errmess} = $passerrors{$invalid};
        $tvars{errcode} = 'ERROR';
        return;
    }

    $dbi->DoQuery('ChangePassword',$cgiparams{effect2},$cgiparams{'userid'});
    $tvars{thanks}  = 2;

    if($cgiparams{mailuser}) {
        my @rows = $dbi->GetQuery('hash','GetUserByID',$cgiparams{'userid'});
        MailSend(   template        => 'mailer/reset.eml',
                    name            => $rows[0]->{realname},
                    password        => $cgiparams{effect2},
                    recipient_email => $rows[0]->{email}
        );
    }

    SetCommand('user-adminedit')    if(Authorised(ADMIN) && $cgiparams{'userid'} != $tvars{'loginid'});
}

sub Register {
    my %data = (
        'link'          => 'images/blank.png',
        'tag'           => '[No Image]',
        'admin'         => Authorised(ADMIN),
    );

    $tvars{data}{$_} = $data{$_}  for(keys %data);
    $tvars{userid} = 0;
    $tvars{newuser} = 1;
    $tvars{htmltags} = LegalTags();
}

sub Registered {
    $cgiparams{cause} = $cgiparams{email};
}

=head1 ADMIN INTERFACE METHODS

=over 4

=item Login

Action the login functionality to the site.

=item Logout

Action the logout functionality to the site.

=item Store

=item Retrieve

=item LoggedIn

Check with the current user is logged in.

=item ImageCheck

Check whether images uploaded for the user profile are still being used. Used
to allow the images plugin to delete unused images.

=item Admin

List current users.

=item Add

Provide the template variable hash to create a new user.

=item Edit

Edit the given user.

=item Save

Save the given user. For use by the currently logged in user.

=item AdminSave

Save the given user. For use by admin user to update any non-system user.

=item Delete

Delete the specified user account

=item Ban

Ban the specified user account. Account can be reactivated or deleted. 

Banned users should receive a message at login, explain who they need to 
contact to be reinstated.

=item Disable

Disable the specified user account. This different from a banned user, in that
disabled accounts cannot be reactivated or deleted. This is to prevent reuse of
an old account.

=item AdminPass

Allow the admin user to create a new password of a given user.

Note passwords are store in an encrypted format, so cannot be viewed.

=item AdminChng

Allow the admin user to change the password of a given user.

=cut

sub Login    { Labyrinth::Session::Login()    }
sub Logout   { Labyrinth::Session::Logout()   }
sub Store    { Labyrinth::Session::Store()    }
sub Retrieve { Labyrinth::Session::Retrieve() }

sub LoggedIn {
    $tvars{errcode} = 'ERROR'   if(!$tvars{loggedin});
}

sub ImageCheck  {
    my @rows = $dbi->GetQuery('array','UsersImageCheck',$_[0]);
    @rows ? 1 : 0;
}

sub Admin {
    return  unless AccessUser($LEVEL);

    # note: cannot alter the guest & master users
    if(my $ids = join(",",grep {$_ > 2} CGIArray('LISTED'))) {
        $dbi->DoQuery('SetUserSearch',{ids=>$ids},1)    if($cgiparams{doaction} eq 'Show');
        $dbi->DoQuery('SetUserSearch',{ids=>$ids},0)    if($cgiparams{doaction} eq 'Hide');
        Ban($ids)                                       if($cgiparams{doaction} eq 'Ban');
        Disable($ids)                                   if($cgiparams{doaction} eq 'Disable');
        Delete($ids)                                    if($cgiparams{doaction} eq 'Delete');
    }

    UserLists();
}

sub Add {
    return  unless AccessUser($LEVEL);

    my %data = (
        'link'      => 'images/blank.png',
        'tag'       => '[No Image]',
        ddrealms    => RealmSelect(0),
        ddaccess    => AccessSelect(0),
        ddgroups    => 'no groups assigned',
        member      => 'no group assigned',
    );

    $tvars{users}{data} = \%data;
    $tvars{userid} = 0;
}

sub Edit {
    $cgiparams{userid} ||= $tvars{'loginid'};
    return  unless MasterCheck();
    return  unless AuthorCheck('GetUserByID','userid',$LEVEL);

    $tvars{data}{tag}      = '[No Image]' if(!$tvars{data}{link} || $tvars{data}{link} =~ /blank.png/);
    $tvars{data}{name}     = UserName($tvars{data}{userid});
    $tvars{data}{admin}    = Authorised(ADMIN);
    $tvars{data}{ddrealms} = RealmSelect(RealmID($tvars{data}{realm}));
    $tvars{data}{ddaccess} = AccessSelect($tvars{data}{accessid});

    my @grps = $dbi->GetQuery('hash','LinkedUsers',$cgiparams{'userid'});
    if(@grps) {
        $tvars{data}{ddgroups} = join(', ',map {$_->{groupname}} @grps);
        $tvars{data}{member} = $grps[0]->{member};
    } else {
        $tvars{data}{ddgroups} = 'no groups assigned';
        $tvars{data}{member} = 'no group assigned';
    }

    $tvars{htmltags} = LegalTags();
    $tvars{users}{data}    = clone($tvars{data});  # data fields need to be editable
    $tvars{users}{preview} = clone($tvars{data});  # data fields need to be editable

    for(keys %fields) {
           if($fields{$_}->{html} == 1) { $tvars{users}{data}{$_}    = CleanHTML($tvars{users}{data}{$_});
                                          $tvars{users}{preview}{$_} = CleanHTML($tvars{users}{preview}{$_}); }
        elsif($fields{$_}->{html} == 2) { $tvars{users}{data}{$_}    = SafeHTML($tvars{users}{data}{$_});     }
    }

    $tvars{users}{preview}{gravatar} = GetGravatar($tvars{users}{preview}{userid},$tvars{users}{preview}{email});

    $tvars{users}{preview}{link} = undef
        if($tvars{users}{data}{link} && $tvars{users}{data}{link} =~ /blank.png/);
}

sub Save {
    my $newuser = $cgiparams{'userid'} ? 0 : 1;
    unless($newuser) {
        return  unless MasterCheck();
        if($cgiparams{userid} != $tvars{'loginid'} && !Authorised($LEVEL)) {
            $tvars{errcode} = 'BADACCESS';
            return;
        }
    }

    return  unless AuthorCheck('GetUserByID','userid',$LEVEL);

    $tvars{newuser} = $newuser;
    for(keys %fields) {
           if($fields{$_}->{html} == 1) { $cgiparams{$_} = CleanHTML($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 2) { $cgiparams{$_} = CleanTags($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 3) { $cgiparams{$_} = CleanLink($cgiparams{$_}) }
    }

    my @manfields = @mandatory;
    push @manfields, 'effect'   if($tvars{command} eq 'regsave');

    return  if FieldCheck(\@allfields,\@manfields);

    # determine realm
    $tvars{data}{'realm'}   = RealmName($tvars{data}{'realmid'});
    $tvars{data}{'realm'} ||= 'public';

    ## before continuing we should ensure the IP address has not
    ## submitted repeated registrations. Though we should be aware
    ## of Proxy Servers too.
    my $imageid = $cgiparams{imageid} || 1;
    ($imageid) = SaveImageFile(
            param => 'image',
            stock => 'Users'
        )   if($cgiparams{image});

    my @fields = (  $tvars{data}{'nickname'}, $tvars{data}{'realname'},
                    $tvars{data}{'email'},    $imageid,
                    $tvars{data}{'realm'}
    );

    if($newuser) {
        $tvars{data}{'accessid'} = $tvars{data}{'accessid'} || 1;
        $tvars{data}{'search'}   = $tvars{data}{'search'}   ? 1 : 0;
        $tvars{data}{'realm'}    = 'public';
        $cgiparams{'userid'} = $dbi->IDQuery('NewUser', $tvars{data}{'effect'},
                                                        $tvars{data}{'accessid'},
                                                        $tvars{data}{'search'},
                                                        @fields);
    } else {
        $dbi->DoQuery('SaveUser',@fields,$cgiparams{'userid'});
    }

    $tvars{data}{userid} = $cgiparams{'userid'};
    $tvars{newuser} = 0;
    $tvars{thanks}  = 1;
}

sub AdminSave {
    return  unless AccessUser($LEVEL);
    return  unless MasterCheck();

    my $newuser = $cgiparams{'userid'} ? 0 : 1;
    return  unless AuthorCheck('GetUserByID','userid',$LEVEL);

    $tvars{newuser} = $newuser;

    for(keys %fields) {
           if($fields{$_}->{html} == 1) { $cgiparams{$_} = CleanHTML($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 2) { $cgiparams{$_} = CleanTags($cgiparams{$_}) }
        elsif($fields{$_}->{html} == 3) { $cgiparams{$_} = CleanLink($cgiparams{$_}) }
    }

    my $realm = $tvars{data}->{realm} || 'public';
    return  if FieldCheck(\@allfields,\@mandatory);

    ## before continuing we should ensure the IP address has not
    ## submitted repeated registrations. Though we should be aware
    ## of Proxy Servers too.
    my $imageid = $cgiparams{imageid} || 1;
    ($imageid) = SaveImageFile(
            param => 'image',
            stock => 'Users'
        )   if($cgiparams{image});

    # in case of a new user
    $tvars{data}->{'accessid'} = $tvars{data}->{'accessid'} || 1;
    $tvars{data}->{'search'}   = $tvars{data}->{'search'}   ? 1 : 0;
    $tvars{data}->{'realm'}    = Authorised(ADMIN) && $tvars{data}->{'realmid'} ? RealmName($tvars{data}->{realmid}) : $realm;

    my @fields = (  $tvars{data}{'accessid'}, $tvars{data}{'search'},
                    $tvars{data}{'realm'},    
                    $tvars{data}{'nickname'}, $tvars{data}{'realname'},
                    $tvars{data}{'email'},    $imageid
    );

    if($newuser) {
        $cgiparams{'userid'} = $dbi->IDQuery('NewUser',$tvars{data}->{'effect'},@fields);
    } else {
        $dbi->DoQuery('AdminSaveUser',@fields,$cgiparams{'userid'});
    }

    $tvars{data}->{userid} = $cgiparams{'userid'};
    $tvars{newuser} = 0;
    $tvars{thanks}  = 1;
}

sub Delete {
    my $ids = shift;
    return  unless AccessUser($LEVEL);
    $dbi->DoQuery('DeleteUsers',{ids => $ids});
    $tvars{thanks} = 'Users Deleted.';
}

sub Disable {
    my $ids = shift;
    return  unless AccessUser($LEVEL);
    $dbi->DoQuery('BanUsers',{ids => $ids},'-deleted-');
    $tvars{thanks} = 'Users Disabled.';
}

sub Ban {
    my $ids = shift;
    return  unless AccessUser($LEVEL);
    $dbi->DoQuery('BanUsers',{ids => $ids},'-banned-');
    $tvars{thanks} = 'Users Banned.';
}

sub AdminPass {
    return  unless($cgiparams{'userid'});
    return  unless MasterCheck();
    return  unless AccessUser($LEVEL);
    return  unless AuthorCheck('GetUserByID','userid',$LEVEL);
    $tvars{data}{name}     = UserName($cgiparams{'userid'});
}

sub AdminChng {
    return  unless($cgiparams{'userid'});
    return  unless MasterCheck();
    return  unless AccessUser($LEVEL);

    my @mandatory = qw(userid effect2 effect3);
    if(FieldCheck(\@mandatory,\@mandatory)) {
        $tvars{errmess} = 'All fields must be complete, please try again.';
        $tvars{errcode} = 'ERROR';
        return;
    }

    $tvars{data}{name}     = UserName($cgiparams{'userid'});

    if($cgiparams{effect2} ne $cgiparams{effect3}) {
        $tvars{errmess} = 'New &amp; verify passwords don\'t match, please try again.';
        $tvars{errcode} = 'ERROR';
        return;
    }

    my %passerrors = (
        1 => "Password too short, length should be $settings{minpasslen}-$settings{maxpasslen} characters.",
        2 => "Password too long, length should be $settings{minpasslen}-$settings{maxpasslen} characters.",
        3 => 'Password not cyptic enough, please enter as per password rules.',
        4 => 'Password contains spaces or tabs.',
        5 => 'Password should contain 3 or more unique characters.',
    );

    my $invalid = PasswordCheck($cgiparams{effect2});
    if($invalid) {
        $tvars{errmess} = $passerrors{$invalid};
        $tvars{errcode} = 'ERROR';
        return;
    }

    $dbi->DoQuery('ChangePassword',$cgiparams{effect2},$cgiparams{'userid'});
    $tvars{thanks} = 'Password Changed.';

    if($cgiparams{mailuser}) {
        my @rows = $dbi->GetQuery('hash','GetUserByID',$cgiparams{'userid'});
        MailSend(   template        => 'mailer/reset.eml',
                    name            => $rows[0]->{realname},
                    password        => $cgiparams{effect2},
                    recipient_email => $rows[0]->{email}
        );
    }
}

=item ACL

List the current access control levels for the given user.

=item ACLAdd1

Apply the given profile to the current user's folders.

=item ACLAdd2

Add permissions for the current user to the given folder.

=item ACLSave

Save changes to the current access control levels for the given user.

=item ACLDelete

Delete the specified access control level for the given user.

=cut

sub ACL {
    return  unless AccessUser($LEVEL);
    return  unless $cgiparams{'userid'};

    my @rows = $dbi->GetQuery('hash','GetUserByID',$cgiparams{'userid'});
    $tvars{data}->{$_} = $rows[0]->{$_}  for(qw(userid realname accessname accessid));

    push @{$tvars{data}->{access}}, { folderid => 0, path => 'DEFAULT', accessname => $tvars{data}->{accessname}, ddaccess => AccessSelect($tvars{data}->{accessid},'ACCESS0') };

    @rows = $dbi->GetQuery('hash','UserACLs',$cgiparams{'userid'});
    for my $row (@rows) {
        $row->{ddaccess} = AccessSelect($row->{accessid},'ACCESS' . $row->{aclid});
        push @{$tvars{data}->{access}}, $row;
    }

    $tvars{ddprofile} = ProfileSelect();
    $tvars{ddfolder}  = FolderSelect();
    $tvars{ddaccess}  = AccessSelect();
}

sub ACLAdd1 {
    LoadProfiles();
    if($settings{profiles}{profiles}{$cgiparams{profile}}) {
        for(keys %{ $settings{profiles}{profiles}{$cgiparams{profile}} }) {
            my $folderid = FolderID($_);
            my $accessid = AccessID($settings{profiles}{profiles}{$cgiparams{profile}}{$_});

            my @rows = $dbi->GetQuery('hash','UserACLCheck1', $cgiparams{'userid'}, $folderid);
            if(@rows) {
                $dbi->DoQuery('UserACLUpdate1',$accessid,$cgiparams{'userid'},$folderid)
                    if($rows[0]->{accessid} < $accessid);
            } else {
                $dbi->DoQuery('UserACLInsert',$accessid,$cgiparams{'userid'},$folderid);
            }
        }
    }
}

sub ACLAdd2 {
    my ($userid,$aclid,$accessid,$folderid) = @_;
    if($aclid) {
        my @rows = $dbi->GetQuery('hash','UserACLCheck2', $userid, $aclid);
        if(@rows) {
            $dbi->DoQuery('UserACLUpdate2',$accessid,$userid,$aclid)
                if($rows[0]->{accessid} < $accessid);
        } else {
            $dbi->DoQuery('UserACLInsert',$accessid,$userid,$folderid);
        }
    } else {
        $dbi->DoQuery('UserACLDefault',$accessid,$userid);
    }
}

sub ACLSave {
    return  unless AccessUser($LEVEL);

    if($cgiparams{submit} eq 'Apply') {
        ACLAdd1();
    } elsif($cgiparams{submit} eq 'Add') {
        ACLAdd2($cgiparams{userid},0,$cgiparams{accessid},$cgiparams{folderid});
    } else {
        my @acls = grep {/ACCESS/} keys %cgiparams;
        for my $acl ( @acls ) {
            my ($aclid) = $acl =~ /ACCESS(\d+)/;
            ACLAdd2($cgiparams{userid},$aclid,$cgiparams{'ACCESS'.$aclid});
        }
    }

    $tvars{thanks} = 'User permissions saved successfully.';
}

sub ACLDelete {
    return  unless AccessUser($LEVEL);

    my @manfields = qw(userid accessid folderid);;
    return  if FieldCheck(\@manfields,\@manfields);

    $dbi->DoQuery('UserACLDelete',
            $cgiparams{'userid'},
            $cgiparams{'accessid'},
            $cgiparams{'folderid'});

    $tvars{thanks} = 'User access removed successfully.';
}

1;

__END__

=back

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
