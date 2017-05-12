package Fuse::DAAP;

# vi: ts=4 sw=4

use strict;
use warnings;

# FIXME Why doesn't this work?
#use base Fuse;
use Fuse;
use Net::DAAP::Client;

# For error constants
use POSIX;

our $VERSION = 0.01;

# The 'st_dev' and 'st_blksize' fields are ignored
my $BLOCKSIZE = 65536;

my $daap;

sub new {
	my $class = shift;
	my %args = @_;

	$daap = Net::DAAP::Client->new(SERVER_HOST => $args{hostname},
		SERVER_PORT => $args{serverport});

	$daap->connect || die 'connect: ', $daap->error;

	#$class->SUPER::main(debug => $args{debug},
	Fuse::main(debug => $args{debug},
		mountpoint => $args{mountpoint},
		getattr => \&getattr,
		getdir => \&getdir,
		open => \&open,
		read => \&read,
		release => \&release,
		getxattr => \&getxattr,
		listxattr => \&listxattr);
}

sub _filename {
	my ($song, $hash) = @_;

	return $hash->{'dmap.itemname'} . '.' . $hash->{'daap.songformat'};
}

sub getattr {
	my ($path) = @_;
	$path =~ s/^\/+//;

	my @components = split /\/+/, $path;
	my $component = shift @components;
	if (!defined $component) {
		return _getattr(undef, undef, 0);
	} elsif ($component eq 'Library') {
		$component = shift @components;
		if (!defined $component) {
			return _getattr(undef, undef, 0);
		}

		my $songs = $daap->songs;
		for my $song (keys %$songs) {
			if (_filename($song, $songs->{$song}) eq $component) {
				return _getattr($song, $songs->{$song}, 1);
			}
		}
	} elsif ($component eq 'Playlists') {
		$component = shift @components;
		if (!defined $component) {
			return _getattr(undef, undef, 0);
		}

		my $playlists = $daap->playlists;
		for my $playlist (keys %$playlists) {
			if ($playlists->{$playlist}->{'dmap.itemname'} eq $component) {
				return _getattr($playlist, $playlists->{$playlist}, 0);
			}
		}
	}

	return -ENOENT();
}

sub _getattr {
	my ($song, $hash, $type) = @_;

	# FIXME
	my $BLOCKSIZE = 65536;

	if ($type) {

		# Read only file.  Use as much info from the DAAP hash
		return (0,	# dev
			0,	# ino
			0100444,	# mode
			1,	# nlink
			0,	# uid
			0,	# gid
			0,	# rdev
			$hash->{'daap.songsize'},	# size
			$hash->{'daap.songdatemodified'},	# atime
			$hash->{'daap.songdatemodified'},	# mtime
			$hash->{'daap.songdateadded'},	# ctime
			$BLOCKSIZE,	# blksize
			$hash->{'daap.songsize'} / $BLOCKSIZE + 1);	# blocks
	}

	# Read only directory
	return (0,	# dev
		0,	# ino
		0040555,	# mode
		1,	# nlink
		0,	# uid
		0,	# gid
		0,	# rdev
		0,	# size
		0,	# atime
		0,	# mtime
		0,	# ctime
		$BLOCKSIZE,	# blksize
		0);	# blocks
}

sub getdir {
	my ($path) = @_;
	$path =~ s/^\/+//;

	my @components = split /\/+/, $path;
	my $component = shift @components;
	if (!defined $component) {
		return '.', '..', 'Library', 'Playlists', 0;
	} elsif ($component eq 'Library') {
		$component = shift @components;
		if (!defined $component) {
			my $songs = $daap->songs;
			my @names = ('.', '..');
			for my $song (keys %$songs) {
				push @names, _filename($song, $songs->{$song});
			}

			return @names, 0;
		}
	} elsif ($component eq 'Playlists') {
		$component = shift @components;
		if (!defined $component) {
			my $playlists = $daap->playlists;
			my @names = ('.', '..');
			for my $playlist (keys %$playlists) {
				push @names, $playlists->{$playlist}->{'dmap.itemname'};
			}

			return @names, 0;
		}
	}

	return -ENOENT();
}

sub open {
	my ($path, $flags) = @_;
	$path =~ s/^\/+//;

	if ($flags & O_RDWR || $flags & O_WRONLY) {
		return -EOPNOTSUPP();
	}

	my @components = split /\/+/, $path;
	my $component = shift @components;
	if (!defined $component) {
		return -EISDIR();
	} elsif ($component eq 'Library') {
		$component = shift @components;
		if (!defined $component) {
			return -EISDIR();
		}

		my $songs = $daap->songs;
		for my $song (keys %$songs) {
			if (_filename($song, $songs->{$song}) eq $component) {
				return 0;
			}
		}
	} elsif ($component eq 'Playlists') {
		$component = shift @components;
		if (!defined $component) {
			return -EISDIR();
		}

		my $playlists = $daap->playlists;
		for my $playlist (keys %$playlists) {
			if ($playlists->{$playlist}->{'dmap.itemname'} eq $component) {
				return -EISDIR();
			}
		}
	}

	return -ENOENT();
}

sub read {
	my ($path, $size, $offset) = @_;
	$path =~ s/^\/+//;

	my @components = split /\/+/, $path;
	my $component = shift @components;
	if (!defined $component) {
		return -EISDIR();
	} elsif ($component eq 'Library') {
		$component = shift @components;
		if (!defined $component) {
			return -EISDIR();
		}

		my $songs = $daap->songs;
		for my $song (keys %$songs) {
			if (_filename($song, $songs->{$song}) eq $component) {
				return _read($song, $songs->{$song}, $size, $offset);
			}
		}
	} elsif ($component eq 'Playlists') {
		$component = shift @components;
		if (!defined $component) {
			return -EISDIR();
		}

		my $playlists = $daap->playlists;
		for my $playlist (keys %$playlists) {
			if ($playlists->{$playlist}->{'dmap.itemname'} eq $component) {
				return -EISDIR();
			}
		}
	}

	return -ENOENT();
}

sub _read {
	my ($song, $hash, $size, $offset) = @_;

	if ($size + $offset > $hash->{'daap.songsize'}) {
		return -EINVAL();
	}

	return substr $daap->get($song), $offset, $size;
}

sub release {
	my ($path, $flags) = @_;
	$path =~ s/^\/+//;

	if ($flags & O_RDWR || $flags & O_WRONLY) {
		return -EOPNOTSUPP();
	}

	my @components = split /\/+/, $path;
	my $component = shift @components;
	if (!defined $component) {
		return -EISDIR();
	} elsif ($component eq 'Library') {
		$component = shift @components;
		if (!defined $component) {
			return -EISDIR();
		}

		my $songs = $daap->songs;
		for my $song (keys %$songs) {
			if (_filename($song, $songs->{$song}) eq $component) {
				return 0;
			}
		}
	} elsif ($component eq 'Playlists') {
		$component = shift @components;
		if (!defined $component) {
			return -EISDIR();
		}

		my $playlists = $daap->playlists;
		for my $playlist (keys %$playlists) {
			if ($playlists->{$playlist}->{'dmap.itemname'} eq $component) {
				return -EISDIR();
			}
		}
	}

	return -ENOENT();
}

sub getxattr {
	my ($path, $name) = @_;
	$path =~ s/^\/+//;

	my @components = split /\/+/, $path;
	my $component = shift @components;
	if (!defined $component) {
		return -EOPNOTSUPP();
	} elsif ($component eq 'Library') {
		$component = shift @components;
		if (!defined $component) {
			return -EOPNOTSUPP();
		}

		my $songs = $daap->songs;
		for my $song (keys %$songs) {
			if (_filename($song, $songs->{$song}) eq $component) {
				if (!defined $songs->{$song}->{$name}) {
					return -EOPNOTSUPP();
				}

				return $songs->{$song}->{$name} . '';
			}
		}
	} elsif ($component eq 'Playlists') {
		$component = shift @components;
		if (!defined $component) {
			return -EOPNOTSUPP();
		}

		my $playlists = $daap->playlists;
		for my $playlist (keys %$playlists) {
			if ($playlists->{$playlist}->{'dmap.itemname'} eq $component) {
				if (!defined $playlists->{$playlist}->{$name}) {
					return -EOPNOTSUPP();
				}

				return $playlists->{$playlist}->{$name} . '';
			}
		}
	}

	return -ENOENT();
}

sub listxattr {
	my ($path) = @_;
	$path =~ s/^\/+//;

	my @components = split /\/+/, $path;
	my $component = shift @components;
	if (!defined $component) {
		return 0;
	} elsif ($component eq 'Library') {
		$component = shift @components;
		if (!defined $component) {
			return 0;
		}

		my $songs = $daap->songs;
		for my $song (keys %$songs) {
			if (_filename($song, $songs->{$song}) eq $component) {
				return keys %{$songs->{$song}}, 0;
			}
		}
	} elsif ($component eq 'Playlists') {
		$component = shift @components;
		if (!defined $component) {
			return 0;
		}

		my $playlists = $daap->playlists;
		for my $playlist (keys %$playlists) {
			if ($playlists->{$playlist}->{'dmap.itemname'} eq $component) {
				return keys %{$playlists->{$playlist}}, 0;
			}
		}
	}

	return -ENOENT();
}

1;

__END__

=head1 NAME

Fuse::DAAP -- mount DAAP music shares using the FUSE kernel module

=head1 PREREQUISITES

Fuse

Net::DAAP::Client

=head1 TODO

Caching

=head1 AUTHOR

Jack Bates <ms419@freezone.co.uk>

=head1 COPYRIGHT

Copyright 2006, Jack Bates.  All rights reserved

This program is free software.  You can redistribute it and/or modify it under
the same terms as Perl itself

=head1 SEE ALSO

Fuse

Net::DAAP::Client

=cut
