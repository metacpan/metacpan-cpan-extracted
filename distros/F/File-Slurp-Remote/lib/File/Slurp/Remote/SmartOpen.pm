
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
our $VERSION = 0.2;

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

	if ($file =~ s/(.+):// && $fqdnify{$1} ne $myfqdn) {
		my $host = $1;
		$unzip = "|$unzip" if $unzip;
		$zip = "$zip|" if $zip;
		if ($mode && $mode eq 'w') {
			my $cat = $q_shell{"cat > $q_shell{$file}"};
			$pid = open $fd, "|$zip $ssh $q_shell{$host} $cat"
				or confess "open |$zip $ssh $q_shell{$host} $cat: $!";
		} else {
			$pid = open $fd, "$ssh -n $q_shell{$host} cat $q_shell{$file} $unzip|"
				or confess "open $ssh $q_shell{$host} cat $q_shell{$file} $unzip|: $!";
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

1;

__END__

=head1 NAME

File::Slurp::Remote::SmartOpen - open files locally or remotely automatially

=head1 SYNOPSIS

 use File::Slurp::Remote::SmartOpen;

 smartopen($file, $fd, $mode);

=head1 DESCRIPTION

This module provides one function: C<smartopen($file, $fd, $mode)>.
The function looks at the filename.  If it has a colon in it, then
it assumes that what comes before the colon is a hostname.  If that
hostname is not the hostname of the local system, it uses ssh 
to get to the remote system to open the file.

If the filename ends with C<.gz> or C<.bz2>, then it will pipe the
input (or output) though C<zcat> or C<bzcat> (C<gzip> or C<bzip2>) as
it opens the file.

The mode can be C<r> or C<w>.  It defaults to read.

By default, remote files are accessed with

 ssh -o StrictHostKeyChecking=no

You can override that by redefining C<$File::Slurp::Remote::SmartOpen::ssh>.

=head1 EXAMPLES

 smartopen("host1:/etc/passwd", my $fd, "r");

=head1 LICENSE

This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

