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

package Fugu::File;
our $VERSION = '0.1.2';

use Fcntl          qw(O_CREAT O_EXCL O_TRUNC O_WRONLY);
use File::Basename qw(dirname);
use File::Path     qw(make_path remove_tree);
use File::Spec;
use Fugu::Log;
use JSON::PP;

# Fugu::File - the file operations that a daemon and its tools
# repeat.
#
# Every method is a class method over a path. The module keeps no
# state. A recoverable failure returns undef and reports through the
# log, because a class-method module has no error accessor to hold the
# reason.
#
# The write methods set the mode at the open, before the first byte.
# A chmod after the write leaves a window in which a secret is
# world-readable, and that window is the whole point of the mode.

# The longest name that a single path component may have. The value is
# the traditional NAME_MAX. A longer name is a caller error, not a
# filesystem question.
use constant MAX_NAME_LENGTH => 255;

# Directories that atomic_dir built and has not published yet. The END
# guard removes them, so an interrupt in the middle of a long build
# leaves no orphan tree behind.
my %pending;

END {
	_sweep_pending();
}

# $class->read($path):
#	Read a whole file and return its bytes. The method returns
#	undef when the file does not open, and logs the reason.
sub read ( $class, $path )
{
	open my $fh, '<', $path or do {
		Fugu::Log->default->debug( 'Cannot read %s: %s', $path, $! );
		return;
	};
	binmode $fh;
	my $content = do { local $/; <$fh> };
	close $fh;

	return $content // '';
}

# $class->write($path, $data, %args):
#	Write the bytes to the file. The file gets its mode at the
#	open, so it never holds content under a wider mode than the
#	caller asked for.
#
#	%args:
#		mode => $octal	file mode (default 0644)
sub write ( $class, $path, $data, %args )
{
	my $mode = $args{mode} // 0644;

	# An existing file keeps its own mode through the open. Remove
	# it first, so the mode argument means what it says.
	unlink $path if -e $path;

	sysopen my $fh, $path, O_CREAT | O_WRONLY | O_TRUNC, $mode or do {
		Fugu::Log->default->error( 'Cannot write %s: %s', $path, $! );
		return;
	};
	binmode $fh;

	my $ok = $class->_write_all( $fh, $data, $path );
	close $fh or $ok = undef;

	return $ok;
}

# $class->write_atomic($path, $data, %args):
#	Write through a temporary file in the same directory, then
#	rename over the target. A reader sees the old content or the
#	new content, never a half-written file.
#
#	%args:
#		mode => $octal	file mode (default 0644)
sub write_atomic ( $class, $path, $data, %args )
{
	my $mode = $args{mode} // 0644;
	my $temp = _temp_name($path);

	sysopen my $fh, $temp, O_CREAT | O_EXCL | O_WRONLY, $mode or do {
		Fugu::Log->default->error( 'Cannot write %s: %s', $temp, $! );
		return;
	};
	binmode $fh;

	unless ( $class->_write_all( $fh, $data, $temp ) && close $fh ) {
		close $fh;
		unlink $temp;
		return;
	}

	unless ( rename $temp, $path ) {
		Fugu::Log->default->error( 'Cannot rename %s to %s: %s',
			$temp, $path, $! );
		unlink $temp;
		return;
	}

	return 1;
}

# $class->read_json($path):
#	Read and decode a JSON file. The method returns undef when the
#	file is absent, empty, or not valid JSON. A corrupt state file
#	is a recoverable condition: the caller starts over.
sub read_json ( $class, $path )
{
	return unless -f $path;

	my $content = $class->read($path);
	return if !defined $content || $content eq '';

	my $data = eval { JSON::PP->new->utf8->decode($content) };
	unless ( defined $data ) {
		Fugu::Log->default->warning( 'Cannot decode %s: %s',
			$path, _reason($@) );
		return;
	}

	return $data;
}

# $class->write_json($path, $ref, %args):
#	Encode and write a JSON file atomically, with the mode applied
#	before the content. The encoding is canonical, so the same data
#	always gives the same bytes and a diff of two state files is
#	readable.
#
#	%args:
#		mode => $octal	file mode (default 0644)
sub write_json ( $class, $path, $ref, %args )
{
	my $json = eval { JSON::PP->new->utf8->canonical->encode($ref) };
	unless ( defined $json ) {
		Fugu::Log->default->error( 'Cannot encode %s: %s',
			$path, _reason($@) );
		return;
	}

	return $class->write_atomic( $path, $json, %args );
}

# $class->ensure_dir($path, %args):
#	Make sure the directory exists. The method refuses a symlink
#	and refuses a path that exists as something else. Both are
#	conditions that a daemon must not write through.
#
#	%args:
#		mode => $octal	mode for directories it creates (default 0755)
sub ensure_dir ( $class, $path, %args )
{
	my $mode = $args{mode} // 0755;

	if ( -l $path ) {
		Fugu::Log->default->error( 'Directory is a symlink: %s',
			$path );
		return;
	}
	if ( -e $path && !-d $path ) {
		Fugu::Log->default->error( 'Path is not a directory: %s',
			$path );
		return;
	}
	return 1 if -d $path;

	eval { make_path( $path, { mode => $mode } ); 1 };
	unless ( -d $path ) {

		# make_path dies with a message that names the module
		# and the line. A daemon log wants the reason only.
		Fugu::Log->default->error( 'Cannot create %s: %s',
			$path, _reason($@) );
		return;
	}

	return 1;
}

# $class->expand_tilde($path):
#	Replace a leading ~ with the home directory. The method leaves
#	every other path unchanged, and leaves ~user alone: this module
#	does not resolve other users.
sub expand_tilde ( $class, $path )
{
	return $path unless defined $path;
	return $path unless $path =~ m{^~(?:/|$)};

	my $home = $ENV{HOME};
	return $path unless defined $home && length $home;

	substr( $path, 0, 1 ) = $home;

	return $path;
}

# $class->share_path($relative, %args):
#	Resolve a file that ships with a distribution. The search
#	tries, in order: an explicit root, the checkout that holds the
#	caller's module file, the working directory, and the installed
#	share tree of the named distribution under @INC.
#
#	%args:
#		root => $dir	extra directory to search first
#		from => $file	the caller's module file (__FILE__);
#				names the checkout that ships the data
#		dist => $name	the distribution name; an installed
#				distribution keeps its share files under
#				auto/share/dist/<name>, the
#				File::ShareDir layout
#
#	The method returns the first path that exists, or undef.
sub share_path ( $class, $relative, %args )
{
	my @roots;
	push @roots, $args{root} if defined $args{root};

	# The caller's module file lives at <root>/lib/<Module>.pm in a
	# checkout. The directory above the deepest lib component is the
	# root of the tree that ships the data. An installed module has
	# no such component, so the root search moves on.
	if ( defined $args{from} ) {
		my $dir   = dirname( File::Spec->rel2abs( $args{from} ) );
		my @parts = File::Spec->splitdir($dir);
		for my $i ( reverse 1 .. $#parts ) {
			next unless $parts[$i] eq 'lib';
			push @roots,
			    File::Spec->catdir( @parts[ 0 .. $i - 1 ] );
			last;
		}
	}

	push @roots, File::Spec->rel2abs('.');

	for my $root (@roots) {
		my $path = "$root/$relative";
		return $path if -e $path;
	}

	# The installed layout. The dist tarball maps share/<path> to
	# auto/share/dist/<name>/<path>, so the leading share/ component
	# never appears in an installed tree.
	if ( defined $args{dist} ) {
		my $mapped = $relative =~ s{^share/}{}r;
		for my $inc (@INC) {
			next if ref $inc;
			my $path =
			    File::Spec->catfile( $inc, 'auto', 'share',
				'dist', $args{dist}, $mapped );
			return $path if -e $path;
		}
	}

	return;
}

# $class->atomic_dir($target, $code):
#	Build a directory tree beside $target and publish it with one
#	rename. $code receives the temporary directory and returns true
#	when the tree is complete. A false return, a die, or a signal
#	discards the tree.
#
#	The method refuses to overwrite an existing target: a rename
#	over a populated directory is not atomic, and the caller that
#	wanted a replacement must remove the old tree itself.
#
#	The method returns $target on success, and undef otherwise.
sub atomic_dir ( $class, $target, $code )
{
	if ( -e $target ) {
		Fugu::Log->default->warning( 'Already exists: %s', $target );
		return;
	}

	my $parent = dirname($target);
	$class->ensure_dir($parent) or return;

	my $temp = _make_temp_dir($parent) or return;

	# A long build must not orphan the tree when the operator
	# interrupts it. The handlers are local, so they last only for
	# this call.
	local $SIG{INT}  = sub { _sweep_pending(); exit 130 };
	local $SIG{TERM} = sub { _sweep_pending(); exit 143 };

	my $ok = eval { $code->($temp) };
	unless ($ok) {
		my $why = $@;
		_discard($temp);
		Fugu::Log->default->warning( 'Cannot build %s: %s',
			$target, _reason($why) )
		    if $why;
		return;
	}

	unless ( rename $temp, $target ) {
		Fugu::Log->default->error( 'Cannot publish %s: %s',
			$target, $! );
		_discard($temp);
		return;
	}
	delete $pending{$temp};

	return $target;
}

# $class->sweep_temp($parent):
#	Remove the leftover build directories under $parent. An
#	interrupt that the guards did not catch, or a kill, leaves
#	them. The method returns the count it removed.
sub sweep_temp ( $class, $parent )
{
	return 0 unless -d $parent;

	opendir my $dh, $parent or return 0;
	my @names = grep { /^\.tmp\./ } readdir $dh;
	closedir $dh;

	my $removed = 0;
	for my $name (@names) {
		my $path = "$parent/$name";
		next unless -d $path;
		remove_tree( $path, { safe => 0 } );
		delete $pending{$path};
		$removed++ unless -e $path;
	}

	return $removed;
}

# $class->valid_name($name):
#	Report if the string is safe as one path component. The check
#	refuses an empty name, a name that is too long, a name that
#	holds a path separator or a NUL, and the two directory entries.
#	Every one of them turns a name from a caller into a path that
#	reaches outside the directory it was meant for.
sub valid_name ( $class, $name )
{
	return 0 unless defined $name && length $name;
	return 0 if length($name) > MAX_NAME_LENGTH;
	return 0 if $name =~ m{[/\x00]};
	return 0 if $name eq '.' || $name eq '..';

	return 1;
}

# $class->_write_all($fh, $data, $name):
#	Write every byte to a handle or a socket. A short syswrite is
#	not an error by itself, so the loop continues until the data is
#	gone. $name labels the destination in the error log. The method
#	is a class method so the daemon host and the proxy share this
#	one loop. It returns 1, or undef on a write error.
sub _write_all ( $class, $fh, $data, $name )
{
	$data //= '';
	my $offset = 0;
	while ( $offset < length $data ) {
		my $n = syswrite $fh, $data, length($data) - $offset, $offset;
		unless ( defined $n ) {
			next if $!{EINTR};
			Fugu::Log->default->error( 'Cannot write %s: %s',
				$name, $! );
			return;
		}
		$offset += $n;
	}

	return 1;
}

# _candidates($prefix):
#	The candidate names of one temporary sibling: ten numbered
#	attempts. Both temporary forms draw from this one loop.
sub _candidates ($prefix)
{
	return map { "$prefix.$$.$_" } 1 .. 10;
}

# _temp_name($path):
#	A sibling name for the temporary half of an atomic write. The
#	rename that publishes it must stay inside one filesystem, so
#	the name lives in the target's own directory.
sub _temp_name ($path)
{
	my $dir  = dirname($path);
	my $base = ( File::Spec->splitpath($path) )[2];

	for my $temp ( _candidates("$dir/.$base") ) {
		return $temp unless -e $temp;
	}

	return sprintf '%s/.%s.%d', $dir, $base, $$;
}

# _make_temp_dir($parent):
#	A private directory beside the target, for a tree under
#	construction. The mode is 0700: a half-built tree is nobody
#	else's business.
sub _make_temp_dir ($parent)
{
	for my $dir ( _candidates("$parent/.tmp") ) {
		next if -e $dir;
		if ( mkdir $dir, 0700 ) {
			$pending{$dir} = 1;
			return $dir;
		}
	}

	Fugu::Log->default->error( 'Cannot create a build directory in %s',
		$parent );
	return;
}

sub _discard ($dir)
{
	remove_tree( $dir, { safe => 0 } );
	delete $pending{$dir};
	return;
}

sub _sweep_pending ()
{
	_discard($_) for keys %pending;
	return;
}

# _reason($error):
#	Reduce a die message to one line with no file and line number.
#	A daemon log is not the place for a Perl backtrace.
sub _reason ($error)
{
	my $why = $error // 'unknown error';
	$why =~ s/ at \S+ line \d+.*//s;
	$why =~ s/\s+$//;

	return length($why) ? $why : 'unknown error';
}

1;
