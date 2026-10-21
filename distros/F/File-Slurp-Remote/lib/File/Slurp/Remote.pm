package File::Slurp::Remote;

use strict;
use warnings;
use File::Slurp;
require Exporter;
use File::Slurp::Remote::SmartOpen;

our @ISA = qw(Exporter);
our @EXPORT = (@File::Slurp::EXPORT, qw(write_remote_file read_remote_file));

our $VERSION = '0.48';

# Unused: retained so that code which sets it doesn't break
our $scp = "scp -q -o StrictHostKeyChecking=no -o BatchMode=yes -o PasswordAuthentication=no";

sub write_remote_file
{
	my $host = shift;
	my $file = shift;

	my $fd;
	smartopen("$host:$file", $fd, "w");
	(print $fd @_) or die "write to $host:$file: $!";
	close($fd) or die "close $host:$file: $!";
}

sub read_remote_file
{
	my $host = shift;
	my $file = shift;

	my $fd;
	smartopen("$host:$file", $fd, "r");
	if (wantarray) {
		return <$fd>;
	} else {
		return join('', <$fd>);
	}
}

1;

__END__

=head1 NAME

 File::Slurp::Remote - read/write files on remote systems using ssh.

=head1 SYNOPSIS

 use File::Slurp::Remote;

 write_remote_file($host, $file, @contents);

 @lines = read_remote_file($host, $file);

 $whole_thing = read_remote_file($host, $file);

 # Log in as a different user on the remote system
 $whole_thing = read_remote_file("$user\@$host", $file);

=head1 DESCRIPTION

This is similar to L<File::Slurp>, but it reads and writes files on
remote systems using C<ssh> to get there.

If the remote user name is not the same as the local one, pass the
host as C<user@host>, just as you would to C<scp>.

It uses ssh to get to the remote systems, through
L<File::Slurp::Remote::SmartOpen>.  You can override the remote shell
command by redefining C<$File::Slurp::Remote::SmartOpen::ssh>.

C<$File::Slurp::Remote::scp> is still defined for backwards
compatibility, but it has never been used and setting it has no effect.

If the host is the local system (and no other user is given), the file
is read or written directly, without ssh.

Files whose names end in C<.gz> or C<.bz2> are decompressed as they are
read and compressed as they are written.

As well as the functions below, everything that L<File::Slurp> exports
by default (C<read_file>, C<write_file> and so on) is exported.

=head1 FUNCTIONS

=head2 write_remote_file($host, $file, @contents)

Writes C<@contents> to C<$file> on C<$host>, replacing anything already
there.  Returns nothing useful; it dies on failure.

=head2 read_remote_file($host, $file)

In list context, returns the lines of C<$file> on C<$host>, each with
its line ending.  In scalar context, returns the whole file as one
string.

=head3 API SPECIFICATION

=head4 Input

Both functions take positional arguments:

 $host     string, required.  A hostname, or user@host to log in as a
           different user.  The user name ends at the last '@'.
           Neither the user nor the host may be empty or begin with '-'.
 $file     string, required.  The path on the remote system.
 @contents list of strings (write_remote_file only).  Written in order,
           with no separator added.

=head4 Output

 read_remote_file, list context:   list of strings, one per line
 read_remote_file, scalar context: string
 write_remote_file:                nothing useful

=head1 ERRORS

Both functions die if the host or user is invalid (see above), or if
the file cannot be opened, written or closed.  When ssh is used, a
failure on the remote side is reported when the file is closed, so
C<write_remote_file> dies but C<read_remote_file> may just return
nothing.

=head1 LICENSE

Copyright (C) 2008-2007,2008-2010 David Sharnoff.
Copyright (C) 2007-2008 SearchMe Inc.
Copyright (C) 2011 Google Inc.
This package may be used and redistributed under the terms of either
the Artistic 2.0 or LGPL 2.1 license.

=head1 AUTHOR

David Muir Sharnoff

=head1 SUPPORT

Module now maintained by
Nigel Horne, C<< <nhorne at nigelhorne.com> >>
