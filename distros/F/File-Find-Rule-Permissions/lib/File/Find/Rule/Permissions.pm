package File::Find::Rule::Permissions;
use strict;

use Devel::AssertOS::Unix;

use File::Find::Rule;
use base qw(File::Find::Rule);
use vars qw(
    $VERSION @EXPORT
    %UIDsByUsername %UsernamesByUID %GIDsByGroupname
    %GroupnamesByGID %UIDinGID
);
@EXPORT  = @File::Find::Rule::EXPORT;
$VERSION = '2.03';

use Fcntl qw(:mode);

=head1 NAME

File::Find::Rule::Permissions - rule to match on file permissions and user
access

=head1 SYNOPSIS

  use File::Find::Rule::Permissions;

  # Which files can the 'nobody' user read in the current directory?
  @readable = File::Find::Rule::Permissions->file()
      ->permissions(isReadable => 1, user => 'nobody')
      ->in('.');
                  
  # Which files can UID 42 *not* read in the current directory?
  @notreadable = File::Find::Rule::Permissions->file()
      ->permissions(isReadable => 0, user => 42)
      ->in('.');
                  
  # Find big insecurity badness!
  @eek = File::Find::Rule::Permissions->permissions(
      isWriteable => 1,
      isExecutable => 1,
      user => 'nobody'
  )->in('/web');

=head1 DESCRIPTION

An extension for File::Find::Rule to work with file permission bits and
determine whether a given user can read, write or execute files.

=head1 METHODS

=head2 B<permissions>

Takes at least one parameter and up to four.  The mandatory parameter
must be one of isReadable, isWriteable or isExecutable, which take
values of 1 or 0 (actually true or false).  Any of those three that
are missing are ignored - ie, we match regardless of their truth or
falsehood.  A value of 1 means that we must only match files where
the user can read/write/execute (as appropriate) the file, and a
value of 0 means we must only match if the user can NOT
read/write/execute the file.  To supply none of these three is clearly
an error, as it is equivalent to not caring what the permissions are,
which is equivalent to seeing if the file exists, which
File::Find::Rule already does quite nicely thankyouverymuch.

The 'user' parameter is optional.  By default, we check access for the
current effective userid, which is normally the user running the
program.  This can be changed using this parameter, which takes a
numeric uid or a username.  Note, however, that if the user running
the program can't get at parts of the filesystem that the desired user
can, the results will be incomplete.

The astute reader will have noticed that File::Find::Rule already
handles some of these rules (checking permissions for the effective
uid), but not for an arbitrary user.  That this module can also check
for the effective uid is more of a lucky accident that just falls out
of the code when checking for any arbitrary user :-)

=head1 BUGS

I assume a Unix-a-like system, both when looking at file permissions,
and when divining users' membership of groups.  Patches for other
systems are welcome.

We divine which groups a user belongs to when the module is loaded.  If
group membership changes underneath the program, incorrect results may
be returned.  I consider this to be Just Fine, given that most shells
also have the same limitation.

=cut

# figure out who has what UID and which UIDs are in which group
(%UIDsByUsername, %UsernamesByUID, %GIDsByGroupname,
    %GroupnamesByGID, %UIDinGID) = ();
getusergroupdetails();

# we override these in the test suite to avoid having to be root.
# or we will do when that bit is written, anyway.

sub stat { return CORE::stat(shift); }
sub geteuid { return $>; }
sub getusergroupdetails {
    while(my($name, undef, $uid, $gid) = getpwent()) {
        $UIDsByUsername{$name} = $uid;
        $UsernamesByUID{$uid} = $name;
        $UIDinGID{$gid}{$uid} = 1;
    }
    while(my($grname, $grpass, $gid, $members) = getgrent()) {
        $GIDsByGroupname{$grname} = $gid;
        $GroupnamesByGID{$gid} = $grname;
    
        foreach my $member (split(/\s+/, $members)) {
            next unless(exists($UIDsByUsername{$member}));
            $UIDinGID{$gid}{$UIDsByUsername{$member}} = 1;
        }
    }
}

sub File::Find::Rule::permissions {
    my $self = shift()->_force_object;
    my %criteria = ref($_[0]) eq "HASH" ? %{$_[0]} : @_;

    $self->exec(sub {
        my $file = shift;
        my $userid;
        
        # first check that we've got the mandatory parameters
        if(
            !exists($criteria{isReadable}) &&
            !exists($criteria{isWriteable}) &&
            !exists($criteria{isExecutable})
        ) { die("File::Find::Rule::Permissions::permissions: no criteria\n"); }
        
        # if a user has been specified, first get their UID (from their
	# username if necessary).  If a user *hasn't* been specified,
	# then we pretend one has anyway
        $criteria{user} = geteuid() unless(exists($criteria{user}));
        if($criteria{user} =~ /^\d+$/) { $userid = $criteria{user}; }
         else { $userid = $UIDsByUsername{$criteria{user}}; }
            
        # now divine the user's permissions.  first get the file's mode
	# bits and ownership
        my($mode, $file_uid, $file_gid) = (&stat($file))[2,4,5];
        
        # now check user/group perms.  Set isReadable etc if the mode has
	# the owner bit set and the user is the owner, or has the group bit
	# set and the user is in the right group
        my $isReadable = $mode & (
            (($userid == $file_uid) ? S_IRUSR : 0) |
            ($UIDinGID{$file_gid}{$userid} ? S_IRGRP : 0)
        );
        my $isWriteable = $mode & (
            (($userid == $file_uid) ? S_IWUSR : 0) |
            ($UIDinGID{$file_gid}{$userid} ? S_IWGRP : 0)
        );
        my $isExecutable = $mode & (
            (($userid == $file_uid) ? S_IXUSR : 0) |
            ($UIDinGID{$file_gid}{$userid} ? S_IXGRP : 0)
        );
	# now check "other" perms.  Set isReadable etc if "other" bit is
	# set and user is *not* owner and *not* in right group
	if($userid != $file_uid && !$UIDinGID{$file_gid}{$userid}) {
	    $isReadable = $mode & S_IROTH;
	    $isWriteable = $mode & S_IWOTH;
    	    $isExecutable = $mode & S_IXOTH;
	}

        # root can read and write anything, can execute anything
        # with any x bit set
        $isReadable = $isWriteable = 1 if($userid == 0);
        $isExecutable = 1 if($userid == 0 && $mode & 0111);
        
        # Why do all those constants look like incantations to the elder gods?
        #
        # S'IXOTH, S'IXOTH IRGRP!
        
        if(exists($criteria{isReadable}) && $criteria{isReadable}) {    # must be readable
            return 0 unless($isReadable);
        } elsif(exists($criteria{isReadable}) && !$criteria{isReadable}) { # must not be ...
            return 0 if($isReadable);
        }
        if(exists($criteria{isWriteable}) && $criteria{isWriteable}) {  # must be writeable
            return 0 unless($isWriteable);
        } elsif(exists($criteria{isWriteable}) && !$criteria{isWriteable}) {
            return 0 if($isWriteable);
        }
        if(exists($criteria{isExecutable}) && $criteria{isExecutable}) {# must be executable
            return 0 unless($isExecutable);
        } elsif(exists($criteria{isExecutable}) && !$criteria{isExecutable}) {
            return 0 if($isExecutable);
        }
        
        return 1;
    } );
}


=head1 FEEDBACK

I welcome constructive criticism.  If you need to report a bug, it would
be most helpful - and it'll get fixed quicker - if you include sufficient
information for me to be able to replicate it consistently.  Especially
useful are test scripts which fail with the current implementation but
should pass.

Please report bugs either by email or using L<http://rt.cpan.org/>.

=head1 SOURCE CODE REPOSITORY

L<git://github.com/DrHyde/perl-modules-File-Find-Rule-Permissions.git>

=head1 SEE ALSO

  File::Find::Rule

=head1 AUTHOR, COPYRIGHT and LICENCE

Copyright 2003-2009 David Cantrell E<lt>david@cantrell.org.ukE<gt>

Based on code by Kate Pugh (File::Find::Rule::MP3Info) and Richard Clamp.

This software is free-as-in-speech software, and may be used,
distributed, and modified under the terms of either the GNU
General Public Licence version 2 or the Artistic Licence. It's
up to you which one you use. The full text of the licences can
be found in the files GPL2.txt and ARTISTIC.txt, respectively.

=head1 CONSPIRACY

This module is also free-as-in-mason software.

=cut

1;
