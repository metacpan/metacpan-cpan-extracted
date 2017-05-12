package File::System::Object;

use strict;
use warnings;

our $VERSION = '1.16';

use Carp;
use File::System::Globber;

=head1 NAME

File::System::Object - Abstract class that every file system module builds upon

=head1 DESCRIPTION

Before reading this documentation, you should see L<File::System>.

File system modules extend this class to provide their functionality. A file system object represents a path in the file system and provides methods to locate other file system objects either relative to this object or from an absolute root.

If you wish to write your own file system module, see the documentation below for L</"MODULE AUTHORS">.

=head2 FEATURES

The basic idea is that every file system is comprised of objects. In general, all file systems will contain files and directories. Files are object which contain binary or textual data, while directories merely contain more files. Because any given file system might have arbitrarily many (or few) different types and the types might not always fall into the "file" or "directory" categories, the C<File::System::Object> attempts to generalize this functionality into "content" and "container". 

More advanced types might also be possible, e.g. symbolic links, devices, FIFOs, etc. However, at this time, no general solution is provided for handling these. (Individual file system modules may choose to add support for these in whatever way seems appropriate.)

Each file system object must specify a method stating whether it contains file content and another method stating whether it may contain child files. It is possible that a given file system implementation provides both simultaneously in a single object.

All file system objects allow for the lookup of other file system object by relative or absolute path names.

=head2 PATH METHODS

These methods provide the most generalized functionality provided by all objects. Each path specified to each of these must follow the rules given by the L</"FILE SYSTEM PATHS"> section and may either be relative or absolute. If absolute, the operation performed will be based around the file system root. If relative, the operation performed depends on whether the object is a container or not. If a container, paths are considered relative to I<this> object. If not a container, paths are considered relative to the I<parent> of the current object.

=over

=item $root = $obj-E<gt>root

Return an object for the root file system.

=item $test = $obj-E<gt>exists($path)

Check the given path C<$path> and determine whether a file system object exists at that path. Return a true value if there is such an object or false otherwise. If C<$path> is undefined, the method should assume C<$obj-E<gt>path>.

=cut

sub exists {
	my $self = shift;
	my $path = shift || $self->path;

	return defined $self->lookup($path);
}

=item $file = $obj-E<gt>lookup($path)

Lookup the given path C<$path> and return a L<File::System::Object> reference for that path or C<undef>.

=cut

sub lookup {
	my $self = shift;
	my $path = shift;

	my $abspath = $self->normalize_path($path);

	if ($self->is_root) {
		my $result = $self;
		my @components = split m#/#, $path;
		for my $component (@components) {
			$self->is_container && ($result = $result->child($component))
				or return undef;
		}

		return $result;
	} else {
		return $self->root->lookup($abspath);
	}
}

=item @objs = $obj->glob($glob)

Find all files matching the given file globs C<$glob>. The glob should be a typical csh-style file glob---see L</"FILE SYSTEM PATHS"> below. Returns all matching objects. Note that globs are matched against '.' and '..', so care must be taken in crafting a glob that hopes to match files starting with '.'. (The typical solution to match all files starting with '.' is '.??*' under the assumption that one letter names are exceedingly rare and to be avoided, by the same logic.)

=cut

sub glob {
	my $self = shift; 
	my $glob = $self->normalize_path(shift);

	my @components = split /\//, $glob;
	shift @components;

	my @open_list;
	my @matches = ([ $self->root->path, $self->root ]);

	for my $component (@components) {
		@open_list = 
			map {
			   my ($path, $obj) = @$_; 
			   map { [ $_, $obj->lookup($_) ] } $obj->children_paths 
			} grep { $_->[1]->is_container } @matches;

		return () unless @open_list;

		@matches = 
			grep { $self->match_glob($component, $_->[0]) } @open_list;
	}

	return sort map { $_->[1] } @matches;
}

=item @files = $obj->find($want, @paths)

This is similar in function to, but very different in implementation from L<File::Find>.

Find all files matching or within the given paths C<@paths> or any subdirectory of those paths, which pass the criteria specifed by the C<$want> subroutine.  If no C<@paths> are given, then "C<$obj>" is considered to be the path to search within.

The C<$want> subroutine will be called once for every file found under the give paths. The C<$want> subroutine may expect a single argument, the L<File::System::Object> representing the given file. The C<$want> subroutine should return true to add the file to the returned list or false to leave the file out. The C<$want> subroutine may also set the value of C<$File::System::prune> to a true value in order to cause all contained child object to be skipped from search.

The implementation should perform a depth first search so that children are checked immediately after their parent (unless the children are pruned, of course).

=cut

sub find {
	my $self = shift;
	my $want = shift;

	my @dirs = @_ ? @_ : ($self);

	my @open = map { $_ = $self->lookup($_) unless ref $_; $_ } @dirs;

	local $File::System::prune;

	my @found;
	while (my $file = shift @open) {
		$File::System::prune = 0;
		push @found, $file if $want->($file);

		unshift @open, $file->children
			if !$File::System::prune && $file->is_container;
	}

	return sort @found;
}

=item $test = $obj-E<gt>is_creatable($path, $type)

Returns true if the user can use the C<create> method to create an object at
C<$path>.

=item $new_obj = $obj-E<gt>create($path, $type)

Attempts to create the object at the given path, C<$path> with type C<$type>. Type is a string containing one or more case-sensitive characters describing the type. Here are the meanings of the possible characters:

=over

=item d

Create a container (named "d" for "directory"). This can be used alone or with the "f" flag.

=item f

Create a content object (named "f" for "file"). This can be used alone or with the "d" flag.

=back

The C<is_creatable> method may be used first to determine if the operation is possible.

=back

=head2 METADATA METHODS

These are the general methods that every L<File::System::Object> will provide.

=over

=item "$obj"

The stringify operator is overloaded so that if this value is treated as a string it will take on the value of the "C<path>" property.

=cut

use overload 
	'""'  => sub { shift->path },
	'eq'  => \&equals,
	'ne'  => \&not_equals,
	'cmp' => \&compare;

sub equals {
	my $self = shift;
	my $obj  = shift;

	if (UNIVERSAL::isa($obj, 'File::System::Object')) {
		return $self->path eq $obj->path;
	} else {
		return $self->path eq $obj;
	}
}

sub not_equals {
	my $self = shift;
	my $obj  = shift;

	if (UNIVERSAL::isa($obj, 'File::System::Object')) {
		return $self->path ne $obj->path;
	} else {
		return $self->path ne $obj;
	}
}

sub compare {
	my $self = shift;
	my $obj  = shift;

	if (UNIVERSAL::isa($obj, 'File::System::Object')) {
		return $self->path cmp $obj->path;
	} else {
		return $self->path cmp $obj;
	}
}

=item $name = $obj-E<gt>is_valid

This method returns whether or not the object is still valid (i.e., the object it refers to still exists).

=item $name = $obj-E<gt>basename

This is the base name of the object (local name with the rest of the path stripped out). This value is also available as C<$obj-E<gt>get_property('basename')>. Note that the root object C<basename> should be C<'/'>. This fits better with unix, but actually differs from how Perl normally works.

=cut

sub basename {
	my $self = shift;
	return $self->get_property('basename');
}

=item $path = $obj-E<gt>dirname

This the absolute canonical path up to but not including the base name. If the object represents the root path of the file system (i.e., F<..> = F<.>), then it is possible that C<basename> = C<dirname> = C<path>. This value is also available as C<$obj-E<gt>get_property('dirname')>.

=cut

sub dirname {
	my $self = shift;
	return $self->get_property('dirname');
}

=item $path = $obj-E<gt>path

This is the absolute canonical path to the object. This value is also available as C<$obj-E<gt>get_property('path')>.

=cut

sub path {
	my $self = shift;
	return $self->get_property('path');
}

=item $test = $obj-E<gt>is_root

Returns true if this file system object represents the file system root.

=cut

sub is_root {
	my $self = shift;
	return $self->path eq '/';
}

=item $parent_obj = $obj-E<gt>parent

This is equivalent to:

  $parent_obj = $obj->lookup($obj->dirname);

of you can think of it as:

  $parent_obj = $obj->lookup('..');

This will return the file system object for the container. It will return itself if this is the root container.

=cut

sub parent {
	my $self = shift;
	return $self->lookup($self->dirname);
}

=item @keys = $obj-E<gt>properties

Files may have an arbitrary set of properties associated with them. This method merely returns all the possible keys into the C<get_property> method.

=item @keys = $obj-E<gt>settable_properties

The keys returned by this method should be a subset of the keys returned by C<properties>. These are the modules upon which it is legal to call the C<set_property> method.

=item $value = $obj-E<gt>get_property($key)

Files may have an arbitrary set of properties associated with them. Many of the common accessors are just shortcuts to calling this method.

In every implementation it must return values for at least the following keys:

=over

=item basename

See C<basename> for a description. When implementing this, you may wish to use the C<basename_of_path> helper.

=item dirname

See C<dirname> for a description. When implementing this, you may wish to use the C<dirname_of_path> helper.

=item object_type

See C<object_type> for a description.

=item path

See C<path> for a description.

=back

=item $obj-E<gt>set_property($key, $value)

This sets the property given by C<$key> to the value in C<$value>. This should fail if the given key is not found in C<$key>.

=item $obj-E<gt>rename($name)

Renames the name of the file to the new name. This method cannot be used to move the file to a different location. See C<move> for that.

=item $obj-E<gt>move($to, $force)

Moves the file to the given path. After running, this object should refer to the file in it's new location. The C<$to> argument must be a reference to the file system container (from the same file system!) to move this object into.  This method must fail if C<$obj> is a container and C<$force> isn't given or is false.

If you move a container using the C<$force> option, and you have references to files held within that container, all of those references are probably now invalid.

=item $copy = $obj-E<gt>copy($to, $force)

Copies the file to the given path. This object should refer to the original. The object representing the copy is returned. The c<$to> argument must refer to a reference to a file system container (from the same file system!). This method must fail if C<$obj> is a container and C<$force> isn't given or is false.

=item $obj-E<gt>remove($force)

Deletes the object from the file system entirely. In general, this means that the object is now completely invalid. 

The C<$force> option, when set to a true value, will remove containers and all their children and children of children, etc.

=item $type = $obj-E<gt>object_type

Synonym for:

  $type = $obj->get_property("object_type");

The value returned is a string containing an arbitrary number of characters describing the type of the file system object. The following are defined:

=over

=item d

This object may contain other files.

=item f

This object may have content.

=back

=cut

sub object_type {
	my $self = shift;
	return $self->get_property('object_type');
}

=item $test = $obj-E<gt>has_content

Returns a true value if the object contains file content. See L</"CONTENT METHODS"> for additional methods.

This is equivalent to:

  $obj->object_type =~ /f/;

=cut

sub has_content {
	my $self = shift;
	return scalar $self->object_type =~ /f/;
}

=item $test = $obj-E<gt>is_container

Returns a true value if the object may container other objects. See L</"CONTAINER METHODS"> for additional methods.

This is equivalent to:

  $obj->object_type =~ /d/;

=cut

sub is_container {
	my $self = shift;
	return scalar $self->object_type =~ /d/;
}

=back

=head2 CONTENT METHODS

These methods are provided if C<has_content> returns a true value.

=over

=item $test = $obj-E<gt>is_readable

This returns a true value if the file data can be read from---this doesn't refer to file permissions, but to actual capabilities. Can someone read the file? This literally means, "Can the file be read as a stream?"

=item $test = $obj-E<gt>is_seekable

This returns a true value if the file data is available for random-access. This literally means, "Are the individual bytes of the file addressable?"

=item $test = $obj-E<gt>is_writable

This returns a true value if the file data can be written to---this doesn't refer to file permissions, but to actual capabilities. Can someone write to the file? This literally means, "Can the file be overwritten?"

I<TODO Can this be inferred from C<is_seekable> and C<is_appendable>?>

=item $test = $obj-E<gt>is_appendable

This returns a true value if the file data be appended to. This literally means, "Can the file be written to as a stream?" 

=item $fh = $obj-E<gt>open($access)

Using the same permissions, C<$access>, as L<FileHandle>, this method returns a file handle or a false value on failure.

=item $content = $obj-E<gt>content

=item @lines = $obj-E<gt>content

In scalar context, this method returns the whole file in a single scalar. In list context, this method returns the whole file as an array of lines (with the newline terminator defined for the current system left intact).

=back

=head2 CONTAINER METHODS

These methods are provided if C<is_container> returns a true value.

=over

=item $test = $obj-E<gt>has_children

Returns true if this container has any child objects (i.e., any child objects in addition to the mandatory '.' and '..').

=item @paths = $obj-E<gt>children_paths

Returns the relative paths of all children of the given container. The first two paths should always be '.' and '..', respectively. These two paths should be present within anything that returns true for C<is_container>.

=item @children = $obj-E<gt>children

Returns the child C<File::System::Object>s for all the actual children of this container. This is approxmiately the same as:

  @children = map { $vfs->lookup($_) } grep !/^\.\.?$/, $obj->children_paths;

Notice that the objects for '.' and '..' are I<not> returned.

=item $child = $obj-E<gt>child($name)

Returns the child C<File::System::Object> that matches the given C<$name> or C<undef>.

=back

=head1 FILE SYSTEM PATHS

Paths are noted as follows:

=over

=item "/"

The "/" alone represents the ultimate root of the file system.

=item "filename"

File names may contain any character except the forward slash. 

The underlying file system may not be able to cope with all characters. As such, it is legal for a file system module to throw an exception if it is not able to cope with a given file name.

Files can never have the name "." or ".." because of their special usage (see below). 

=item "filename1/filename2"

The slash is used to indicate that "filename2" is contained within "filename1". In general, the file system module doesn't really cope with "relative" file names, as might be indicated here. However, the L<File::System::Object> does provide this functionality in a way.

=item "."

The single period indicates the current file. It is legal to embed multiples of these into a file path (e.g., "/./././././././" is still the root). Technically, the "." may only refer to files that may contain other files (otherwise the term makes no sense). In canonical form, all "." will be resolved by simply being removed from the path. (For example, "/./foo/./bar/./." is "/foo/bar" in canonical form.)

The single period has another significant "feature". If a single period is placed at the start of a file name it takes on the Unix semantic of a "hidden file". Basically, all that means is that a glob wishing to match such a file must explicit start with a '.'.

=item ".."

The double period indicates the parent container. In the case of the root container, the root's parent is itself. In canonical form, all ".." will be resolved by replacing everything up to the ".." with the parent path. (For example, "/../foo/../bar/baz/.." is "/bar" in canonical form.)

=item "////"

All adjacent slashes are treated as a single slash. Thus, in canonical form, multiple adjacent slashes will be condenced into a single slash. (For example, "////foo//bar" is "/foo/bar" in canonical form.)

=item "?"

This character has special meaning in file globs. In a file glob it will match exactly one of any character. If you want to mean literally "?" instead, escape it with a backslash.

=item "*"

This character has special meaning in file globs. In a file glob it will match zero or more of any character non-greedily. If you want to mean literally "*" instead, escape it with a backslash.

=item "{a,b,c}"

The curly braces can be used to surround a comma separated list of alternatives in file globbing. If you mean a literal set of braces, then you need to escape them with a backslash.

=item "[abc0-9]"

The square brackets can be used to match any character within the given character class. If you mean a literal set of brackets, then you need to escape them with a backslash.

=back

=head1 MODULE AUTHORS

If you wish to extend this interface to provide a new implementation, do so by creating a class that subclasses L<File::System::Object>. That class must then define several methods. In the process you may override any method of this object, but make sure it adheres to the interface described in the documentation.

  package My::File::Sytem::Implementation;

  use strict;
  use warnings;

  use base qw( File::System::Object );

  # define your implementation...

Below are lists of the methods you must or should define for your implementation. There is also a section below containing documentation for additional helper methods module authors should find useful, but general users probably won't.

=head2 MUST DEFINE

A subclass of L<File::System::Object> must define the following methods:

=over

=item root

=item is_creatable

=item create

=item is_valid

=item properties

=item settable_properties

=item get_property

=item set_property

=item rename

=item move

=item copy

=item remove

=back

The following methods must be provided if your file system object implementation may return a true value for the C<has_content()> method.

=over

=item is_readable

=item is_seekable

=item is_writable

=item is_appendable

=item open

=item content

=back

The following methods are container methods and must be defined if your file system object implementation may return true from the C<is_container()> method.

=over

=item has_children

=item children_paths

=item children

=item child

=back

=head2 SHOULD DEFINE

A subclass of L<File::System::Object> ought to consider defining better implementations of the following. Once all the methods above are defined correctly, these methods will work. However, they may not work efficiently.

Any methods not listed here or in L</"MUST DEFINE"> have default implementations that are generally adequate. Also, the methods listed below in L</"HELPER METHODS"> probably shouldn't be overriden.

=over

=item exists

=item glob

=back

=head2 HELPER METHODS

This class also provides a few helpers that may be useful to module uathors, but probably not of much use to typical users.

=over

=item $clean_path = $obj-E<gt>normalize_path($messy_path)

This method creates a canonical path out of the given path C<$messy_path>. This is the single most important method offered to module authors. It provides several things:

=over

=item 1.

If the path being canonified is relative, this method checks to see if the current object is a container. Paths are relative to the current object if the current object is container. Otherwise, the paths are relative to this object's parent.

=item 2.

Converts all relative paths to absolute paths.

=item 3.

Removes all superfluous '.' and '..' names so that it gives the most concise and direct name for the named file.

=item 4.

Enforces the principle that '..' applied to the root returns the root. This provides security by preventing users from getting to a file outside of the root (assuming that is possible for a given file system implementation).

=back

Always, always, always use this method to clean up your paths.

=cut

sub normalize_path {
	my $self = shift;
	my $path = shift;

	defined $path
		or croak "normalize_path must be given a path";

	# Skipped so we can still get some benefit in constructors
	if (ref $self && $path !~ m#^/#) {
		# Relative to me (I am a container) or to parent (I am not a container)
		$self->is_container
			or $self = $self->parent;

		# Fix us up to an absolute path
		$path = $self->path."/$path";
	}

	# Break into components
	my @components = split m#/+#, $path;
	@components = ('', '') unless @components;
	unshift @components, '' unless @components > 1;

	for (my $i = 1; $i < @components;) {
		if ($components[$i] eq '.') {
			splice @components, $i, 1;
		} elsif ($components[$i] eq '..' && $i == 1) {
			splice @components, $i, 1;
		} elsif ($components[$i] eq '..') {
			splice @components, ($i - 1), 2;
			$i--;
		} else {
			$i++;
		}
	}

	unshift @components, '' unless @components > 1;

	return join '/', @components;
}

=item @matched_paths = $obj-E<gt>match_glob($glob, @all_paths)

This will match the given glob pattern C<$glob> against the given paths C<@all_paths> and will return only those paths that match. This provides a de facto implementation of globbing so that any module can provide this functionality without having to invent this functionality or rely upon a third party module.

=cut

my $globber = File::System::Globber->new;

sub match_glob {
	my $self = shift;
	my $glob = shift;
	my @tree = @{ $globber->glob($glob) };
	my @paths = @_;

	my @matches;
	MATCH: for my $str (@paths) {
		# Special circumstance: any pattern not explicitly starting with '.'
		# cannot match a file name starting with '.'
		next if $str =~ /^\./ && $glob !~ /^\./;

		my $orig = $str;

		my @backup = ();
		my $tree = [ @tree ];
		while (my $el = shift @$tree) {
			if (ref $el eq 'File::System::Glob::MatchOne') {
				goto BACKUP unless substr $str, 0, 1, '';
			} elsif (ref $el eq 'File::System::Glob::MatchAny') {
				push @backup, [ $str, 0, @$tree ];
			} elsif (ref $el eq 'File::System::Glob::MatchAlternative') {
				my $match = 0;
				for my $alt (@{ $el->{alternatives} }) {
					if ($alt eq substr($str, 0, length($alt))) {
						substr $str, 0, length($alt), '';
						$match = 1;
						last;
					}
				}

				goto BACKUP unless $match;
			} elsif (ref $el eq 'File::System::Glob::MatchCollection') {
				my $char = substr $str, 0, 1, '';
				
				my $match = 0;
				for my $class (@{ $el->{classes} }) {
					if ((ref $class) && ($char ge $class->[0]) && ($char le $class->[1])) {
						$match = 1;
						last;
					} elsif ($char eq $class) {
						$match = 1;
						last;
					}
				}

				goto BACKUP unless $match;
			} else {
				my $char = substr $str, 0, 1, '';

				goto BACKUP unless $char eq $el->{character};
			}

			next unless $str and !@$tree;

BACKUP:		my ($tstr, $amt, @ttree);
			do {
				next MATCH unless @backup;
				($tstr, $amt, @ttree) = @{ pop @backup };
			} while (++$amt > length $tstr);

			push @backup, [ $tstr, $amt, @ttree ];

			$str  = substr $tstr, $amt;
			$tree = \@ttree;
		}

		push @matches, $orig;
	}

	return @matches;
}

=item $basename = $obj-E<gt>basename_of_path($normalized_path)

Given a normalized path, this method will return the basename for that path according to the rules employed by C<File::System>. (Essentially, they are the same as L<File::Basename>, except that the basename of "/" is "/" rather than "".)

=cut

sub basename_of_path {
	my $self = shift;
	my $path = shift;

	if ($path eq '/') {
		return '/';
	} else {
		my @components = split m{/}, $path;
		return pop @components;
	}
}

=item $dirname = $obj-E<gt>dirname_of_path($normalized_path)

Given a normalized path, this method will return the dirname for that path according to the rules employed by C<File::System>. (These should be identical to the rules used by L<File::Basename> as far as I know.)

=cut

sub dirname_of_path {
	my $self = shift;
	my $path = shift;

	if ($path eq '/') {
		return '/';
	} else {
		my @components = split m{/}, $path;
		pop @components;
		push @components, '' if @components == 1;
		return join '/', @components;
	}
}

=back

=head1 SEE ALSO

L<File::System>

=head1 AUTHOR

Andrew Sterling Hanenkamp, E<lt>hanenkamp@users.sourceforge.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2005 Andrew Sterling Hanenkamp. All Rights Reserved.

This software is distributed and licensed under the same terms as Perl itself.

=cut

1
