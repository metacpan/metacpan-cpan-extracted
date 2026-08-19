# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2026 Dick Olsson <hi@senzilla.io>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

use v5.36;

package Fugu::StateFile;
our $VERSION = '0.1.2';

use Fugu::File;

# Fugu::StateFile - a small JSON state file with typed accessors.
#
# A daemon and its tools keep a handful of facts between runs: a
# counter, a flag, a timestamp. This module is that file, and nothing
# more. It holds no PID logic and starts no subprocess:
# Fugu::Pidfile owns the first, and the caller owns the second.
#
# load tolerates a missing file and a corrupt one, because a state
# file that a crash truncated must not stop the program that would
# rewrite it. save is atomic, so the file is never the corrupt one
# that the next load has to tolerate.

# Fugu::StateFile->new(%args):
#	path => $file	the state file (required)
#	mode => $octal	file mode (default 0600)
#	The constructor does not touch the file. Call load.
sub new ( $class, %args )
{
	my $path = $args{path};
	die 'path parameter required'
	    unless defined $path && length $path;

	return bless {
		path  => $path,
		mode  => $args{mode} // 0600,
		data  => {},
		error => undef,
	}, $class;
}

# $self->path:
#	Return the state file.
sub path ($self)
{
	return $self->{path};
}

# $self->error: the most recent failure.
sub error ($self)
{
	return $self->{error};
}

# $self->load:
#	Read the state. An absent file gives empty state. A corrupt
#	file gives empty state and records the reason in ->error, so
#	the caller can report it and carry on. The method returns the
#	object either way.
sub load ($self)
{
	$self->{error} = undef;
	$self->{data}  = {};

	return $self unless -f $self->{path};

	my $data = Fugu::File->read_json( $self->{path} );
	unless ( defined $data && ref $data eq 'HASH' ) {
		$self->{error} = "Cannot read state from $self->{path}";
		return $self;
	}

	$self->{data} = $data;

	return $self;
}

# $self->save:
#	Write the state atomically, with the mode applied before the
#	content. The method returns the object on success, and undef
#	with ->error set on failure.
sub save ($self)
{
	$self->{error} = undef;

	unless (
		Fugu::File->write_json(
			$self->{path}, $self->{data}, mode => $self->{mode} ) )
	{
		$self->{error} = "Cannot write state to $self->{path}";
		return;
	}

	return $self;
}

# $self->get($key):
#	Return one value, or undef.
sub get ( $self, $key )
{
	return $self->{data}{$key};
}

# $self->set($key, $value):
#	Store one value and save. The method returns the object on
#	success, and undef when the save failed. A caller that changes
#	several keys uses data and save instead of one call for each.
sub set ( $self, $key, $value )
{
	$self->{data}{$key} = $value;

	return $self->save;
}

# $self->delete($key):
#	Remove one value and save.
sub delete ( $self, $key )
{
	delete $self->{data}{$key};

	return $self->save;
}

# $self->data:
#	Return the state hashref itself. A caller that changes several
#	keys at once changes it and then calls save.
sub data ($self)
{
	return $self->{data};
}

1;
