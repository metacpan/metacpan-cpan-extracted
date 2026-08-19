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

package Fugu::Config;
our $VERSION = '0.1.2';

use File::Basename qw(dirname);
use File::Spec;

# Fugu::Config - the OpenBSD-style configuration grammar.
#
# A file holds top-level settings and blocks:
#
#	log_level debug
#	hap_port = 51827
#
#	device light dimmable bedroom {
#		name = "Bedroom Lamp"
#		topic = tasmota/bedroom
#	}
#
# Both "key value" and "key = value" parse. A double-quoted value
# loses its quotes. A comment starts with # and runs to the end of the
# line. Blocks nest one level; a block inside a block is an error.
#
# A block header is a type, then one or more arguments, then an
# opening brace. The parser keeps the arguments in order and also
# indexes each block by its last argument, its name. Thus a caller
# that wants an ordered list of devices and a caller that wants the VM
# called "default" read the same parse.
#
# Each block also carries its position in the file. A caller that
# reads two types and wants them interleaved as the file wrote them
# sorts on it; blocks() alone can only answer for one type.
#
# A malformed line is an error with a file and a line number. The
# module never skips a line it did not understand: a typo that a
# parser ignores is a setting that silently does not apply.

sub new ( $class, %args )
{
	my $file = $args{file};
	die 'file parameter required'
	    unless defined $file && length $file;

	return bless {
		file     => $file,
		settings => {},
		blocks   => {},
		error    => undef,
		loaded   => 0,
	}, $class;
}

# $self->file:
#	Return the path that this object parses.
sub file ($self)
{
	return $self->{file};
}

# $self->error:
#	Return the most recent failure, with its file and line.
sub error ($self)
{
	return $self->{error};
}

# $self->load:
#	Read and parse the file. The method returns the object on
#	success. It returns undef when the file does not open or holds
#	a line that the grammar does not accept, with the reason in
#	->error.
#
#	A caller for whom an absent file is normal tests for the file
#	first. The method itself treats an unreadable file as an error:
#	a daemon that silently runs on defaults after a typo in a path
#	is worse than one that refuses to start.
sub load ($self)
{
	$self->{settings} = {};
	$self->{blocks}   = {};
	$self->{error}    = undef;
	$self->{loaded}   = 0;

	open my $fh, '<', $self->{file} or do {
		$self->{error} = "Cannot open $self->{file}: $!";
		return;
	};
	my @lines = <$fh>;
	close $fh;

	my $block;
	my $lineno = 0;
	my $order  = 0;

	for my $line (@lines) {
		$lineno++;
		chomp $line;

		# A # starts a comment. The grammar has no escape for
		# it, so a value cannot hold one.
		$line =~ s/#.*//;
		$line =~ s/^\s+|\s+$//g;
		next if $line eq '';

		# Block end
		if ( $line eq '}' ) {
			unless ($block) {
				return $self->_fail( $lineno,
					'closing brace outside a block' );
			}
			$block->{order} = $order++;
			push @{ $self->{blocks}{ $block->{type} } }, $block;
			$block = undef;
			next;
		}

		# Block start: <type> <arg> ... {
		if ( $line =~ /\{$/ ) {
			if ($block) {
				return $self->_fail( $lineno,
					'a block cannot hold a block' );
			}
			$block = _parse_header( $line, $self, $lineno )
			    or return;
			next;
		}

		my ( $key, $value ) = _parse_setting($line);
		unless ( defined $key ) {
			return $self->_fail( $lineno, "cannot parse: $line" );
		}

		if ($block) {
			$block->{settings}{$key} = $value;
		}
		else {
			$self->{settings}{$key} = $value;
		}
	}

	if ($block) {
		return $self->_fail( $lineno,
			"unterminated $block->{type} block" );
	}

	$self->{loaded} = 1;

	return $self;
}

# $self->get($key, $default):
#	Return a top-level setting, or the default.
sub get ( $self, $key, $default = undef )
{
	return $self->{settings}{$key} // $default;
}

# $self->setting_names:
#	Return the names of the top-level settings, sorted.
sub setting_names ($self)
{
	return sort keys %{ $self->{settings} };
}

# $self->parse_bool($value, $default):
#	The same switch grammar, for a value that a caller already
#	holds. A block setting comes through here.
sub parse_bool ( $self, $value, $default = 0 )
{
	# The accessor reports the most recent failure, so a value that
	# parses must not leave an older one behind
	$self->{error} = undef;

	return $default unless defined $value;

	my $normal = lc $value;
	$normal =~ s/^\s+|\s+$//g;

	return 1
	    if $normal eq 'yes'
	    || $normal eq 'true'
	    || $normal eq 'on'
	    || $normal eq '1';
	return 0
	    if $normal eq 'no'
	    || $normal eq 'false'
	    || $normal eq 'off'
	    || $normal eq '0';

	$self->{error} = "$self->{file}: not a yes/no value: $value";

	return $default;
}

# $self->blocks($type):
#	Return every block of the type, in file order. Each entry is a
#	hashref with type, args, name, settings and order. This is the
#	view for a list where the order matters and two entries can
#	share a name.
sub blocks ( $self, $type )
{
	return @{ $self->{blocks}{$type} // [] };
}

# $self->block($type, $name):
#	Return the block of the type whose name matches, or undef. The
#	name is the last argument of the block header. When two blocks
#	share a name, the last one in the file wins, as an
#	assignment does.
sub block ( $self, $type, $name )
{
	my $found;
	for my $entry ( @{ $self->{blocks}{$type} // [] } ) {
		$found = $entry if $entry->{name} eq $name;
	}

	return $found;
}

# $class->find_project_root($marker):
#	Walk up from the working directory to the first directory that
#	holds $marker. The method returns that directory, or undef when
#	the walk reaches the root without a match.
sub find_project_root ( $class, $marker )
{
	die 'marker parameter required'
	    unless defined $marker && length $marker;

	my $dir = File::Spec->rel2abs('.');

	while (1) {
		return $dir if -f "$dir/$marker";

		my $parent = dirname($dir);
		last if $parent eq $dir;    # The walk reached the root
		$dir = $parent;
	}

	return;
}

# _parse_header($line, $self, $lineno):
#	Parse "<type> <arg> ... {" into a block. A quoted argument
#	loses its quotes, so a name with a space is possible.
sub _parse_header ( $line, $self, $lineno )
{
	my $header = $line;
	$header =~ s/\s*\{$//;

	my @tokens = _tokenize($header);
	unless ( @tokens >= 2 ) {
		return $self->_fail( $lineno,
			'a block needs a type and a name' );
	}

	my $type = shift @tokens;
	unless ( $type =~ /^\w+$/ ) {
		return $self->_fail( $lineno, "not a block type: $type" );
	}

	return {
		type     => $type,
		args     => [@tokens],
		name     => $tokens[-1],
		settings => {},
	};
}

# _tokenize($string):
#	Split on whitespace, but keep a double-quoted run together.
sub _tokenize ($string)
{
	my @tokens;
	while ( $string =~ /\G\s*(?:"([^"]*)"|(\S+))/gc ) {
		push @tokens, defined $1 ? $1 : $2;
	}

	return @tokens;
}

# _parse_setting($line):
#	Parse "key value" or "key = value". The function returns
#	($key, $value), or an empty list when the line is not a
#	setting.
sub _parse_setting ($line)
{
	return unless $line =~ /^(\w+)\s*(?:=\s*)?(.*)$/;

	my ( $key, $value ) = ( $1, $2 );
	$value =~ s/^\s+|\s+$//g;

	# A key with no value is not a setting. The grammar has no flag
	# form, and a caller that reads an empty string would not know
	# the difference.
	return unless length $value;

	$value =~ s/^"(.*)"$/$1/;

	return ( $key, $value );
}

# $self->_fail($lineno, $message):
#	Record a parse error with its position and return undef.
sub _fail ( $self, $lineno, $message )
{
	$self->{error} = "$self->{file}:$lineno: $message";
	return;
}

1;
