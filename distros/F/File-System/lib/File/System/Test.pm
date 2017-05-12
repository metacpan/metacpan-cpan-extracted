package File::System::Test;

use strict;
use warnings;

our $VERSION = '1.16';

require Exporter;
use File::Basename ();
use Test::Builder;

my $test = Test::Builder->new;

our @ISA    = qw( Exporter );
our @EXPORT = qw(
	prepare
	is_root_sane
	is_object_sane
	is_container_sane
	is_content_sane
	is_content_writable
	is_container_mobile
	is_content_mobile
	is_glob_and_find_consistent
);

sub _check {
	my $true = shift;
	my $name = shift;

	unless ($true) {
		$test->ok(0, $name);
		$test->diag(join('', @_));
		return 0;
	} else {
		return 1;
	}
}

=head1 NAME

File::System::Test - Module for testing file system drivers

=head1 DESCRIPTION

This suite of test subroutines will test if a file system object is internally consistent and can be used to test other features of the object.

The following tests are available:

=over

=item is_root_sane($obj, $name)

Checks to make sure the root file object is generally sane. It tests the
following:

=over

=item *

Is the root object defined?

=item *

Does the root subroutine of the root object represent the same path?

=item *

Is the path '/'?

=item *

Does stringify work correctly?

=item *

Does basename return ''?

=item *

Does dirname return '/'?

=item *

Does a lookup of '' exist? Does it represent the same path?

=item *

Does a lookup of '.' exist? Does it represent the same path?

=item *

Does a lookup of '..' exist? Does it represent the same path?

=item *

Does a lookup of '/' exist? Does it represent the same path?

=item *

Does is_root return true?

=item *

Is parent path the same as root path?

=item *

Does properties return at least basename, dirname, and path?

=item *

Does is_container return true?

=back

=cut

sub is_root_sane {
	my $obj  = shift;
	my $name = shift;

	_check(defined $obj, $name, 'root object does not exist') || return;

	my $root = $obj->root;
	_check($obj->path eq $root->path, $name,
		"root object path [$obj] does not match ->root path [$root]") || return;

	_check($obj->path eq '/', $name, 
		"root object path is [$obj] instead of the desired [/]") || return;

	_check($obj->path eq "$obj", $name,
		"root object stringify was [$obj] instead of [",$obj->path,"]") || return;

	_check($obj->basename eq '/', $name,
		"root object basename was [",$obj->basename,"] instead of [/]") || return;

	_check($obj->dirname eq '/', $name,
		"root object dirname was [",$obj->dirname,"] instead of [/]") || return;

	_check($obj->is_root, $name, "root object [$obj] is not reporting is_root") || return;

	my $parent = $obj->parent;
	_check($obj->path eq $parent->path, $name,
		"root object path is [$obj] but parent is [$parent]") || return;

	_check(grep(/^basename$/, $obj->properties), $name,
		"root object [$obj] properties missing basename") || return;

	_check(grep(/^dirname$/, $obj->properties), $name,
		"root object [$obj] properties missing dirname") || return;

	_check(grep(/^path$/, $obj->properties), $name,
		"root object [$obj] properties missing path") || return;

	_check($obj->is_container, $name, "root object [$obj] is not a container") || return;

	for my $path ('', '.', '..', '/') {
		_check($obj->exists($path), $name, "root [$obj] cannot access file path [$path]") || return;

		my $lookup = $root->lookup($path);
		_check($obj->path eq $lookup->path, $name,
			"root object path [$obj] does not match ->lookup($path) path [$lookup]") || return;
	}

	$test->ok(1, $name);
}

=item is_object_sane($obj, $name)

This test performs the following:

=over

=item *

Is the object defined?

=item *

Does stringify work?

=item *

Does lookup of path result in object for same path?

=item *

Does basename return the basename of path?

=item *

Does dirname return the dirname of path?

=item *

Does is_root return false?

=item *

Does parent path match dirname?

=item *

Does properties return at least basename, dirname, and path?

=back

=cut

sub is_object_sane {
	my $obj = shift;
	my $name = shift;

	_check(defined $obj, 'object does not exist') || return;

	_check($obj->path eq "$obj", $name,
		"object stringify was [$obj] instead of [",$obj->path,"]") || return;

	my $lookup = $obj->lookup($obj->path);
	_check($obj->path eq $lookup->path, $name,
		"object lookup($obj) results in [$lookup] instead of expected [$obj]") || return;

	_check($obj->basename eq $obj->basename_of_path($obj->path), $name,
		"object [$obj] basename was [",$obj->basename,"] instead of [",
		$obj->basename_of_path($obj->path),"]") || return;

	_check($obj->dirname eq $obj->dirname_of_path($obj->path), $name,
		"object [$obj] dirname was [",$obj->dirname,"] instead of [",
		$obj->dirname_of_path($obj->path),"]") || return;

	_check(!$obj->is_root, $name, "object [$obj] is incorrectly reporting is_root") || return;

	my $parent = $obj->parent;
	_check($obj->dirname eq $parent->path, $name,
		"object [$obj] dirname is [",$obj->dirname,"] but parent path is [$parent]") || return;

	_check(grep(/^basename$/, $obj->properties), $name,
		"object [$obj] properties missing basename") || return;

	_check(grep(/^dirname$/, $obj->properties), $name,
		"object [$obj] properties missing dirname") || return;

	_check(grep(/^path$/, $obj->properties), $name,
		"object [$obj] properties missing path") || return;
	
	$test->ok(1, $name);
}

=item is_container_sane($obj, $name)

Runs additional container specific tests. It tests the following:

=over

=item *

Does is_container return true?

=item *

Can the container C<has_children>?

=item *

Can the container C<children_paths>?

=item *

Can the container C<children>?

=item *

Can the container C<child>?

=item *

If not C<has_children>, does C<children_paths> return '.' and '..' only? Does C<children> return an empty list?

=item *

If the container C<has_children>, does C<children_paths> return '.' and '..' and more? Does C<children> return a non-empty list?

=item *

If the container C<has_children>, does each C<child> return an object for the same path as C<lookup>.

=back

=cut

sub is_container_sane {
	my $obj  = shift;
	my $name = shift;

	_check($obj->is_container, $name, "is_container [$obj] does not return true") || return;

	_check($obj->can("has_children"), $name, 
		"container [$obj] does not have a 'has_children' method.") || return;

	_check($obj->can("children_paths"), $name,
		"container [$obj] does not have a 'children_paths' method.") || return;

	_check($obj->can('children'), $name,
		"container [$obj] does not have a 'children' method.") || return;

	_check($obj->can('child'), $name,
		"container [$obj] does not have a 'child' method.") || return;

	my @children_paths = $obj->children_paths;
	my @children       = $obj->children;
	
	_check(grep(/^\.$/, @children_paths), $name,
		"container [$obj] does not contain a '.' child.") || return;

	_check(grep(/^\.\.$/, @children_paths), $name,
		"container [$obj] does not contain a '..' child.") || return;

	if ($obj->has_children) {
		_check(grep(!/^\.\.?$/, @children_paths), $name,
			"container [$obj] says it has children but children_paths returns none") || return;

		_check(scalar(@children) > 0, $name,
			"container [$obj] says it has children but children returns none") || return;

		for my $path (@children_paths) {
			my $lookup = $obj->lookup($path);
			my $child  = $obj->child($path);

            my $lookup_path = eval { $lookup->path } || '<undef>';
            my $child_path  = eval { $child->path }  || '<undef>';

			_check($lookup_path eq $child_path, $name,
				"container [$obj] doesn't find the same object via child() [$child_path] as it does for lookup() [$lookup_path] of $path") || return;
		}
	} else {
		_check(!grep(!/^\.\.?$/, @children_paths), $name,
			"container says it has no children but children_paths returns some") || return;

		_check(scalar(@children) == 0, $name,
			"container says it has no children but children returns some") || return;
	}

	$test->ok(1, $name);
}

=item is_content_sane($obj, $name)

Runs additional content specific tests. It tests the following:

=over

=item *

Does is_content return true?

=back

=cut

sub is_content_sane {
	my $obj  = shift;
	my $name = shift;

	_check($obj->has_content, $name, "has_content [$obj] does not return true") || return;

	$test->ok(1, $name);
}

=item is_content_writable($obj, $name)

Checks to see if the given file object is writable and confirms that writing works as expected.

=over

=item *

Check to see if is_readable and is_writable.

=item *

Does open("w") work?

=item *

Can we write to the file handle returned by open("w")?

=item *

Does the file handle close properly?

=item *

Is the content of the file the same as written?

=item *

Check to see if is_appendable. If so, write one more line to the end, close and reopen to check that the file is as expected.

=item *

Check to see if is_seekable. If so, seek into the middle, overwrite part of the file, close andreopen to check that the file is as expected.

=back

=cut

sub is_content_writable {
	my $obj  = shift;
	my $name = shift;

	_check($obj->is_readable, $name, "is_readable [$obj] returns false") || return;

	_check($obj->is_writable, $name, "is_writable [$obj] returns false") || return;

	my $fh = $obj->open("w");
	_check(defined $fh, $name, "open('w') [$obj] returns undef") || return;

	my @expected = (
		"Hello World\n",
		"foo\n",
		"bar\n",
		"baz\n",
		"qux\n",
	);

	for my $line (@expected) {
		_check(print($fh $line), $name, "print [$obj] failed on file handle") || return;
	}

	_check(close($fh), $name, "[$obj] failed to close file handle") || return;

	my $content = $obj->content;
	_check($content eq join('', @expected), $name,
		"[$obj] content read from file '$content' doesn't match expected") || return;

	my @content = $obj->content;
	for (my $n = 0; $n < @content; ++$n) {
		_check($content[$n] eq $expected[$n], $name,
			"[$obj] content read from line $n of file, '$content[$n]', doesn't match expected") || return;
	}

	if ($obj->is_appendable) {
		my $fh = $obj->open("a");
		_check(defined $fh, $name, "open('a') [$obj] returns undef") || return;

		_check(print($fh "quux\n"), $name, "print [$obj] failed on appendable file handle") || return;

		_check(close($fh), $name, "[$obj] failed to close appendable file handle") || return;

		push @expected, "quux\n";
		my $content = $obj->content;
		_check($content eq join('', @expected), $name,
			"[$obj] content read from appended file '$content' doesn't match expected") || return;
	}

	if ($obj->is_seekable) {
		my $fh = $obj->open("r+");
		_check(defined $fh, $name, "open('w') [$obj] returns undef") || return;

		_check(seek($fh, 16, 0), $name, "seek [$obj] returned a failure") || return;

		_check(print($fh "huh\n"), $name, "print [$obj] failed on seeked file handle") || return;

		_check(close($fh), $name, "[$obj] failed to close seeked file handle") || return;

		splice @expected, 2, 1, "huh\n";
		my $content = $obj->content;
		_check($content eq join('', @expected), $name,
			"[$obj] content read from seeked file '$content' doesn't match expected") || return;
	}

	$test->ok(1, $name);
}

=item is_container_mobile($obj, $dest, $name)

Checks to see if the container C<$obj> can be renamed (to 'renamed_container' and back), moved to the given container C<$dest> (and moved back), and copied to the given container (and the copy removed).

Checks to make sure that after each of these operations that the entire subtree is preserved.

=cut

sub is_container_mobile {
	my $obj  = shift;
	my $dest = shift;
	my $name = shift;

	# RENAME
	my $basename = $obj->basename;
	my $path = $obj->path;
	my $renamed_path = $obj->normalize_path($obj->dirname.'/renamed_container');

	my @files = $obj->find(sub { shift->path ne $obj->path });
	my @renamed_files = 
		map { my $p = $_->path; $p =~ s/^$obj/$renamed_path/; $p } @files;

	_check($obj->rename('renamed_container')->path eq $renamed_path, $name,
		"renamed container path is '$obj' rather than '$renamed_path'") || return;

	for my $path (@files) {
		_check(!$path->exists, $name,
			"renamed container '$obj' failed to rename child from '$path'") || return;
	}

	for my $path (@renamed_files) {
		_check($obj->exists($path), $name,
			"renamed container '$obj' failed to rename child to '$path'") || return;
	}

	_check($obj->rename($basename)->path eq $path, $name,
		"originally renamed container path is '$obj' rather than '$path'") || return;

	for my $path (@files) {
		_check($path->exists, $name,
			"originally renamed container '$obj' failed to rename child to '$path'") || return;
	}

	for my $path (@renamed_files) {
		_check(!$obj->exists($path), $name,
			"originally renamed container '$obj' failed to rename child from '$path'") || return;
	}

	# MOVE
	my $parent = $obj->parent;
	my $new_path = $obj->normalize_path($dest->path."/$basename");

	my @new_files = 
		map { my $p = $_->path; $p =~ s/^$obj/$new_path/; $p } @files;

	_check($obj->move($dest, 'force')->path eq $new_path, $name,
		"moved container path is '$obj' rather than '$new_path'") || return;

	for my $path (@files) {
		_check(!$obj->exists($path), $name,
			"moved container '$obj' failed to move child from '$path'") || return;
	}
	
	for my $path (@new_files) {
		_check($obj->exists($path), $name,
			"moved container '$obj' failed to move child to '$path'") || return;
	}

	_check($obj->move($parent, 'force')->path eq $path, $name,
		"originally moved container path is '$obj' rather than '$path'") || return;

	for my $path (@files) {
		_check($path->exists, $name,
			"originally moved container '$obj' failed to move child to '$path'") || return;
	}
	
	for my $path (@new_files) {
		_check(!$obj->exists($path), $name,
			"originally moved container '$obj' failed to move child from '$path'") || return;
	}

	# COPY
	my $copy = $obj->copy($dest, 'force');
	_check($copy->path eq $new_path, $name,
		"copied container path is '$obj' rather than '$new_path'") || return;

	for my $path (@files) {
		_check($obj->exists($path), $name,
			"original container '$obj' lost child from '$path' after copy") || return;
	}
	
	for my $path (@new_files) {
		_check($obj->exists($path), $name,
			"copied container '$copy' failed to copy child to '$path'") || return;
	}

	# REMOVE
	$copy->remove('force');
	_check(!$copy->is_valid, $name,
		"removed container '$copy' is still valid") || return;

	for my $path (@files) {
		_check($path->exists, $name,
			"pre-copy container '$obj' lost child to '$path' when copy container '$copy' was removed") || return;
	}
	
	for my $path (@new_files) {
		_check(!$obj->exists($path), $name,
			"removed container '$copy' failed to remove child from '$path'") || return;
	}

	$test->ok(1, $name);
}

=item is_container_mobile($obj, $dest, $name)

Checks to see if the content C<$obj> can be renamed (to 'renamed_content' and back), moved to the given container C<$dest> (and moved back), and copied to the given container (and the copy removed).

=cut

sub is_content_mobile {
	my $obj  = shift;
	my $dest = shift;
	my $name = shift;

	# RENAME
	my $basename = $obj->basename;
	my $path = $obj->path;
	my $renamed_path = $obj->normalize_path($obj->dirname.'/renamed_content');

	_check($obj->rename('renamed_content')->path eq $renamed_path, $name,
		"renamed content path is '$obj' rather than '$renamed_path'") || return;

	_check($obj->rename($basename)->path eq $path, $name,
		"originally renamed content path is '$obj' rather than '$path'") || return;

	# MOVE
	my $parent = $obj->parent;
	my $new_path = $obj->normalize_path($dest->path."/$basename");

	_check($obj->move($dest)->path eq $new_path, $name,
		"moved content path is '$obj' rather than '$new_path'") || return;

	_check($obj->move($parent)->path eq $path, $name,
		"originally moved content path is '$obj' rather than '$path'") || return;

	# COPY
	my $copy = $obj->copy($dest);
	_check($copy->path eq $new_path, $name,
		"copied content path is '$obj' rather than '$new_path'") || return;

	# REMOVE
	$copy->remove;
	_check(!$copy->is_valid, $name,
		"removed content '$copy' is still valid") || return;

	$test->ok(1, $name);
}

=item is_glob_and_find_consistent($obj, $name)

Checks several different glob patterns on the object to see if the glob patterns find the same set of objects that a similar find operation returns. The object passed can be a root object or any other object in the tree.

This method also tests to see that the various different ways of calling C<glob> and C<find> are self-consistent. That is,

  $obj->find(\&test) === $root->find(\&test, $obj)
  $obj->glob($test)  === $root->glob("$obj/$test")

=cut

sub is_glob_and_find_consistent {
	my $obj  = shift;
	my $name = shift;

	my @tests = (
		[ '*{ar,az}', sub { $_[0]->path !~ /\/\.[^\/]+$/ 
								&& $_[0]->parent eq $obj
								&& $_[0]->path =~ /ar$|az$/ } ],
		[ '*',        sub { $_[0]->parent eq $obj
								&& $_[0]->path !~ /\/\.[^\/]+$/
								&& $_[0]->path ne $obj->path } ],
		[ '.??*',     sub { $_[0]->parent eq $obj
								&& $_[0]->path =~ /\/\.[^\/]+$/ } ],
		[ '*/*',      sub { $_[0]->path =~ /^$obj\/?[^\/]+\//
								&& $_[0]->path !~ /^$obj\/?[^\/]+\/[^\/]+\//
								&& $_[0]->path !~ /\/\.[^\/]+$/
						   		&& $_[0]->path !~ /\/\.[^\/]+\/[^\/]+$/ } ],
	);

	my $root = $obj->root;
	for my $test (@tests) {
		my @glob = $obj->glob($test->[0]);
		my @find = $obj->find($test->[1]);

		my @root_glob = $root->glob("$obj/$test->[0]");
		my @root_find = $root->find($test->[1], $obj);

		my $glob_err = join ', ', @glob;
		my $find_err = join ', ', @find;

		my $root_glob_err = join ', ', @root_glob;
		my $root_find_err = join ', ', @root_find;

		_check(@glob eq @find, $name, "in '$obj' for '$test->[0]', glob returned [ $glob_err ] but find returned [ $find_err ]") || return;

		_check(@glob eq @root_glob, $name, "in '$obj' for '$test->[0]', obj glob returned [ $glob_err ] but root glob returned [ $root_glob_err ]") || return;

		_check(@find eq @root_find, $name, "in '$obj' for '$test->[0]', obj find returned [ $find_err ] but root find returned [ $root_find_err ]") || return;

		for (my $i = 0; $i < @glob; ++$i) {
			_check($glob[$i] eq $find[$i], $name, "in '$obj' element $i of glob was '$glob[$i]', but element $i of find was '$find[$i]'") || return;

			_check($glob[$i] eq $root_glob[$i], $name, "in '$obj' element $i of obj glob was '$glob[$i]', but element $i of root glob was '$root_glob[$i]'") || return;

			_check($find[$i] eq $root_find[$i], $name, "in '$obj' element $i of obj find was '$find[$i]', but element $i of root find was '$root_find[$i]'") || return;
		}
	}

	$test->ok(1, $name);
}

=head1 SEE ALSO

L<File::System::Object>

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 Andrew Sterling Hanenkamp. All Rights Reserved.

This library is licensed and distributed under the same terms as Perl itself.

=cut

1
