package Filesys::Virtual::DPAP;

use strict;
use warnings;

use Net::DPAP::Client;

use base (
	'Filesys::Virtual',
	'Class::Accessor::Fast'
);

__PACKAGE__->mk_accessors(
	'_client',
	'cwd',
	'host',
	'port',
	'_tree'
);

our $VERSION = '0.01';

=head1 NAME

Filesys::Virtual::DPAP - Filesys::Virtual interface to DPAP (iPhoto) shares

=head1 SYNOPSIS

	use Filesys::Virtual::DPAP;

	my $fs = Filesys::Virtual::DPAP->new({
		host => 'localhost'
	});

	my @albums = $fs->list('/');
	my @photos = $fs->list(@albums);

=head1 DESCRIPTION

This module is based on Richard Clamp's awesome Filesys::Virtual::DAAP module -
many thanks to Richard for all his rad Perl contributions!

Most of this module's functionality is provided by Leon Brocard's way cool
Net::DPAP::Client - thanks also to Leon, for many likewise terrific Perl
modules!

This module currently implements only a limited subset of Filesys::Virtual
methods, but like Filesys::Virtual::DAAP, it can republish DPAP shares, via
either Net::DAV::Server or POE::Component::Server::FTP

=cut

my $BLOCKSIZE = 1024;

sub new {
	my $self = shift;
	$self = $self->SUPER::new(@_);

	my $client = Net::DPAP::Client->new;

	if (defined $self->host) {
		$client->hostname($self->host);
	}

	if (defined $self->port) {
		$client->port($self->port);
	}

	my @albums = $client->connect;

	my %tree;
	for my $album (@albums) {
		my $images = $album->images;

		my %album;
		for my $image (@$images) {
			$album{$self->_safe_name($image->imagefilename)} = $image;
		}

		$tree{$self->_safe_name($album->name)} = \%album;
	}

	$self->_client($client);
	$self->_tree(\%tree);

	return $self;
}

sub size {
	my $self = shift;
	my ($path) = @_;
print "size $path\n";

	my $node = $self->_fetch_node($path);
	if (!defined $node) {
		return;
	}

	#if (blessed $node eq 'Net::DPAP::Client::Image') {
	#if (defined blessed $node) {
	if (ref $node eq 'Net::DPAP::Client::Image') {
		return $node->imagefilesize;
	} else {
		return 0;
	}
}

sub chdir {
	my $self = shift;
	my ($path) = @_;
print "chdir $path\n";

	my $node = $self->_fetch_node($path);
	if (!defined $node) {
		return;
	}

	$self->cwd($path);
}

sub list {
	my $self = shift;
	my ($path) = @_;
print "list $path\n";

	my $node = $self->_fetch_node($path);
	if (!defined $node) {
		return;
	}

	#if (blessed $node eq 'Net::DPAP::Client::Image') {
	#if (defined blessed $node) {
	if (ref $node eq 'Net::DPAP::Client::Image') {
		return $self->_safe_name($node->imagefilename);
	} else {
		return ('.', '..', keys %$node);
	}
}

sub stat {
	my $self = shift;
	my ($path) = @_;
print "stat $path\n";

	my $node = $self->_fetch_node($path);
	if (!defined $node) {
		return;
	}

	#if (blessed $node eq 'Net::DPAP::Client::Image') {
	#if (defined blessed $node) {
	if (ref $node eq 'Net::DPAP::Client::Image') {
		return (
			0 + $self,	# dev
			0 + $node,	# ino
			0100444,	# mode
			1,	# nlink
			0,	# uid
			0,	# gid
			0,	# rdev
			$node->imagefilesize,	# size
			0,	# atime
			0,	# mtime
			$node->creationdate,	# ctime
			$BLOCKSIZE,	# blksize
			$node->imagefilesize / $BLOCKSIZE + 1	# blocks
		);
	} else {
		return (
			0 + $self,	# dev
			0 + $node,	# ino
			042555,	# mode
			1,	# nlink
			0,	# uid
			0,	# gid
			0,	# rdev
			0,	# size
			0,	# atime
			0,	# mtime
			0,	# ctime
			$BLOCKSIZE,	# blksize
			1	# blocks
		);
	}
}

sub test {
	my $self = shift;
	my ($test, $path) = @_;
print "test $test $path\n";

	my $node = $self->_fetch_node($path);
	if (!defined $node) {
		return;
	}

	# -r File is readable by effective uid/gid.
	# -w File is writable by effective uid/gid.
	# -x File is executable by effective uid/gid.
	# -o File is owned by effective uid.

	# -R File is readable by real uid/gid.
	# -W File is writable by real uid/gid.
	# -X File is executable by real uid/gid.
	# -O File is owned by real uid.

	# -e File exists.
	# -z File has zero size.
	# -s File has nonzero size (returns size).

	# -f File is a plain file.
	# -d File is a directory.
	# -l File is a symbolic link.
	# -p File is a named pipe (FIFO), or Filehandle is a pipe.
	# -S File is a socket.
	# -b File is a block special file.
	# -c File is a character special file.
	# -t Filehandle is opened to a tty.

	# -u File has setuid bit set.
	# -g File has setgid bit set.
	# -k File has sticky bit set.

	# -T File is a text file.
	# -B File is a binary file (opposite of -T).

	# -M Age of file in days when script started.
	# -A Same for access time.
	# -C Same for inode change time.
	if ($test =~ /r/i) {
		return 1;
	} elsif ($test =~ /w/i) {
		return 0;
	} elsif ($test =~ /x/i) {
		#if (blessed $node eq 'Net::DPAP::Client::Image') {
		#if (defined blessed $node) {
		if (ref $node eq 'Net::DPAP::Client::Image') {
			return 0;
		} else {
			return 1;
		}
	} elsif ($test =~ /o/i) {
		return 1;
	} elsif ($test =~ /e/) {
		return 1;
	} elsif ($test =~ /z/) {
		#if (blessed $node eq 'Net::DPAP::Client::Image') {
		#if (defined blessed $node) {
		if (ref $node eq 'Net::DPAP::Client::Image') {
			return 0;
		} else {
			return 1;
		}
	} elsif ($test =~ /s/) {
		#if (blessed $node eq 'Net::DPAP::Client::Image') {
		#if (defined blessed $node) {
		if (ref $node eq 'Net::DPAP::Client::Image') {
			return $node->imagefilesize;
		} else {
			return 0;
		}
	} elsif ($test =~ /f/) {
		#if (blessed $node eq 'Net::DPAP::Client::Image') {
		#if (defined blessed $node) {
		if (ref $node eq 'Net::DPAP::Client::Image') {
			return 1;
		} else {
			return 0;
		}
	} elsif ($test =~ /d/) {
		#if (blessed $node eq 'Net::DPAP::Client::Image') {
		#if (defined blessed $node) {
		if (ref $node eq 'Net::DPAP::Client::Image') {
			return 0;
		} else {
			return 1;
		}
	} elsif ($test =~ /[lpSbctugkT]/) {
		return 0;
	} elsif ($test =~ /[B]/) {
		return 1;
	} elsif ($test =~ /[MAC]/) {
		return 0;
	}
}

sub open_read {
	my $self = shift;
	my ($path) = @_;
print "open_read $path\n";

	my $node = $self->_fetch_node($path);
	if (!defined $node) {
		return;
	}

	#if (blessed $node eq 'Net::DPAP::Client::Image') {
	#if (defined blessed $node) {
	if (ref $node eq 'Net::DPAP::Client::Image') {
		open(my $fh, '<', \$node->hires);
		return $fh;
	}
}

sub close_read {
	my $self = shift;
	my ($fh) = @_;
print "close_read $fh\n";

	return close $fh;
}

sub _fetch_node {
	my $self = shift;
	my ($path) = @_;

	my @names;
	if ($path =~ /^\//) {
		(undef, @names) = split /\//, $path;
	} else {
		(undef, @names) = split /\//, $self->cwd;
		push @names, split /\//, $path;
	}

	push my @nodes, $self->_tree;
	for my $name (@names) {
		if ($name eq '.') {
			next;
		} elsif ($name eq '..') {
			pop @nodes;
		} else {
			push @nodes, ${$nodes[$#nodes]}{$name};
		}
	}

	return $nodes[$#nodes];
}

sub _safe_name {
	my $self = shift;
	my ($name) = @_;

	$name =~ s/\//:/g;

	return $name;
}

1;

__END__

=head1 AUTHOR

Jack Bates <ms419@freezone.co.uk>

=head1 COPYRIGHT

Copyright (c) 2005 Jack Bates. All rights reserved.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=head1 BUGS

So far so good - except for some strangeness actually reading photos using
OS X's WebDAVFS; in my experience, doing so causes script sharing
Filesys::Virtual::DPAP to silently terminate.

I experience this problem publishing Filesys::Virtual::DPAP using both
HTTP::Daemon & POE::Component::Server::HTTP - I tracked it down to
'print $response->content' lines in both modules.

Strangely, reading photos using Firefox, etc. or even Cadaver works fine - even
adjusting the file extension so OS X thinks photos are actually QuickTime files
enables photos to be read.

At this point, I can only speculate that OS X does something funky to the HTTP
connection when reading photos - like maybe it's closed when Perl tries
writing the response content & Perl commits suicide.

I could sure use some help with this one!

Report bugs using the CPAN RT system -
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Filesys::Virtual::DPAP>

=head1 TODO

 * Explore exporting extra DPAP properties as WebDAV properties - in a 'DPAP'
   namespace.

 * Explore writing DPAP structures back to sufficiently capable DPAP servers.

=head1 SEE ALSO

L<Net::DPAP::Client>, L<Net::DAV::Server>, L<POE::Component::Server::FTP>
