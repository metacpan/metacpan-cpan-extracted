
package File::Slurp::Remote::SmartOpen;

use strict;
use warnings;
require Exporter;
use File::Slurp::Remote::BrokenDNS qw($myfqdn %fqdnify);
use Tie::Function::Examples qw(%q_shell);
use Carp qw(confess);

our @EXPORT = qw(smartopen);
our @ISA = qw(Exporter);
our $ssh = "ssh -o StrictHostKeyChecking=no -o BatchMode=yes -o PasswordAuthentication=no";
our $VERSION = '0.48';

sub smartopen($\$$)
{
	my ($file, $fdref, $mode) = @_;

	my $unzip = '';
	my $zip = '';
	if ($file =~ /\.gz$/) {
		$unzip = "zcat";
		$zip = "gzip";
	} elsif ($file =~ /\.bz2$/) {
		$unzip = "bzcat";
		$zip = "bzip2";
	}

	my $pid;

	my $fd = $$fdref;

	my ($user, $host);
	# As with scp, a colon before any slash separates the host from the path
	if ($file =~ s/^([^\/]+?)://) {
		$host = $1;
		# Allow user@host; like ssh, split at the last @
		if ($host =~ /^(.*)@([^@]*)$/) {
			($user, $host) = ($1, $2);
			confess "smartopen: invalid user '$user'" if $user eq '' || $user =~ /^-/;
		}
		confess "smartopen: invalid host '$host'" if $host eq '' || $host =~ /^-/;
	}

	if (defined($host) && ($fqdnify{$host} ne $myfqdn || (defined($user) && $user ne _local_user()))) {
		my $dest = defined($user) ? "-l $q_shell{$user} $q_shell{$host}" : $q_shell{$host};
		$unzip = "|$unzip" if $unzip;
		$zip = "$zip|" if $zip;
		if ($mode && $mode eq 'w') {
			my $cat = $q_shell{"cat > $q_shell{$file}"};
			$pid = open $fd, "|$zip $ssh $dest $cat"
				or confess "open |$zip $ssh $dest $cat: $!";
		} else {
			$pid = open $fd, "$ssh -n $dest cat $q_shell{$file} $unzip|"
				or confess "open $ssh $dest cat $q_shell{$file} $unzip|: $!";
		}
	} else {
		if ($mode && $mode eq 'w') {
			if ($zip) {
				$pid = open $fd, "|$zip > $q_shell{$file}"
					or die "open |$zip > $q_shell{$file}: $!";
			} else {
				open $fd, ">", $file
					or die "open >$file: $!";
				$pid = "0butTrue";
			}
		} else {
			if ($unzip) {
				$pid = open $fd, "$unzip < $q_shell{$file}|"
					or die "open $unzip < $q_shell{$file}|: $!";
			} else {
				open $fd, "<", $file
					or die "open <$file: $!";
				$pid = "0buttrue";
			}
		}
	}
	$$fdref = $fd;
	return $pid;
}

# The login name of the user running this process
sub _local_user
{
	my $name = eval { scalar getpwuid($<) };
	return $name if defined $name;
	return $ENV{USER} if defined $ENV{USER};
	return $ENV{USERNAME} if defined $ENV{USERNAME};
	return '';
}

1;

__END__

=head1 NAME

File::Slurp::Remote::SmartOpen - open files locally or remotely automatially

=head1 SYNOPSIS

 use File::Slurp::Remote::SmartOpen;

 smartopen($file, $fd, $mode);

=head1 DESCRIPTION

This module provides one function, which is exported by default.

=head1 FUNCTIONS

=head2 smartopen($file, $fd, $mode)

Opens C<$file> and puts the filehandle in C<$fd>.

The function looks at the filename.  As with C<scp>, if it has a colon
before any slash, then what comes before that colon is taken to be a
hostname, and the rest (which may itself contain colons) is the path.
If that hostname is not the hostname of the local system, it uses ssh
to get to the remote system to open the file.

As with C<scp>, the hostname may be given as C<user@host> to log in
to the remote system as a different user.  Like C<ssh>, the user name
ends at the last C<@>, so C<user@domain@host> logs in to C<host> as
C<user@domain>.  The user name is passed to ssh with C<-l>.  If a user
is given and it differs from the user running the program, ssh is used
even if the host is the local system.

If the filename ends with C<.gz> or C<.bz2>, then it will pipe the
input (or output) though C<zcat> or C<bzcat> (C<gzip> or C<bzip2>) as
it opens the file.

The mode can be C<r> or C<w>.  It defaults to read.

By default, remote files are accessed with

 ssh -o StrictHostKeyChecking=no

You can override that by redefining C<$File::Slurp::Remote::SmartOpen::ssh>.

=head1 RETURN VALUE

The process ID of the pipe when the file is opened through ssh or a
compression program, otherwise a true value.

=head1 ERRORS

C<smartopen> dies if the file cannot be opened.  It also dies if the
user or host is empty, or begins with C<->, so that it can't be taken
as an ssh option.

=head1 EXAMPLES

 smartopen("host1:/etc/passwd", my $fd, "r");

 smartopen("fred\@host1:/home/fred/notes.txt", my $fd, "w");

=head1 LICENSE

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

