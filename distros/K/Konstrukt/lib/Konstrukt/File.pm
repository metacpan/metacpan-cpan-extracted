=head1 NAME

Konstrukt::File - Comfortable handling of files, file names and paths

=head1 SYNOPSIS

	#read a file with a path relative to the current path and set the current
	#path to the path of the read file and save the read file as current file
	$Konstrukt::File->read_and_track('realative/path/file');
	
	#change to the previous dir and file
	$Konstrukt::File->pop();
	
	#read a file with an absolute path with the document_root the root dir without
	#updating the current path and file
	$Konstrukt::File->read('/absolute/path/from/doc_root/file');
	
	#read a file without the built-in path mangling
	$Konstrukt::File->raw_read('/really/absolute/path/file');

	#write a file without the built-in path mangling
	$Konstrukt::File->raw_write('/really/absolute/path/file', 'some content');

=head1 DESCRIPTION

This module allows to easily read files relatively to a your document root
respectively to an imaginary current directory. So you don't have to care about
generating the I<real> path of a file.

Let's say you have this statement inside your webpage:
	
	<& template src="/templates/layout.template" / &>

In fact this file isn't located in C</templates> on your system, it's located in
C</.../your/document_root/templates>. So using

	$Konstrukt::File->read_and_track('/templates/main.template');

will just return the file located at C</.../your/document_root/templates> and
update the current dir to the path of the read file.
Within this template you may want to load another file:

	<& template src="navigation/top.template" / &>

Actually this file is located at C</.../your/document_root/templates/navigation>
as it is called from within the parent file, to which the path relates.
This module will do this nasty path management for you.

To let the module know, when a file has been processed and you want to go back
to the previous path, you must state:

	$Konstrukt::File->pop();

=cut

package Konstrukt::File;

use strict;
use warnings;

use Konstrukt::Debug;

=head1 METHODS

=head2 new

Constructor of this class

=cut
sub new {
	my ($class) = @_;
	return bless { root => '/' }, $class;
}
#= /new

=head2 set_root

Sets the root directory of this object and resets the current-dir-stack.

B<Parameters>:

=over

=item * $root - The pseudo-root dir. Will be the root of a C<$Konstrukt::File->read('/path/file')>.
Usually your document root. Should always be an absolute path, otherwise you may
get really weird results.

=back

=cut
sub set_root {
	my ($self, $root) = @_;
	#set root
	$root = $self->clean_path($root);
	substr($root, -1) eq '/' or $root .= '/';
	$self->{root} = $root;
	#reset dir stack
	$self->{current_dir} = [$root];
	$self->{current_file} = [];
	
	return $root;
}
#= /set_root

=head2 get_root

Returns the root directory (with a trailing slash) of this object.

B<Parameters>: none

=cut
sub get_root {
	my ($self) = @_;

	return $self->{root};
}
#= /get_root

=head2 push

Saves the current file and its path. The paths will be the current "working directory".

Usually only used internally. A plugin developer should rather use L</read_and_track> or
L</read>.

B<Parameters>:

=over

=item * $file - The absolute path to the filename

=back

=cut
sub push {
	my ($self, $file) = @_;
	
	push @{$self->{current_file}}, $file;
	push @{$self->{current_dir}}, $self->extract_path($file);
}
#= /push

=head2 current_dir

Returns the absolute path to the current virtual directory

=cut
sub current_dir {
	my ($self) = @_;
	
	return $self->{current_dir}->[-1];
}
#= /current_dir

=head2 current_file

Returns the absolute path to the last file that has been read and tracked

=cut
sub current_file {
	my ($self) = @_;
	
	return $self->{current_file}->[-1];
}
#= /current_file

=head2 pop

Returns to the directory and the file that has been current before we read and
tracked a new file.

=cut
sub pop {
	my ($self) = @_;
	
	pop @{$self->{current_dir}};
	pop @{$self->{current_file}};
}
#= /pop

=head2 get_files

Returns the stack of the absolute path to the currently tracked files as an array.

=cut
sub get_files {
	my ($self) = @_;
	
	return (exists $self->{current_file} ? @{$self->{current_file}} : ());
}
#= /get_files

=head2 get_dirs

Returns the stack of the absolute paths to the currently tracked dirs as an array.

=cut
sub get_dirs {
	my ($self) = @_;
	
	return (exists $self->{current_dir} ? @{$self->{current_dir}} : ());
}
#= /get_dirs

=head2 absolute_path

Returns the full path to a partially given filename.

If the path begins with a / this / will be substituted with our root.
Otherwise it is relative to our L<current_dir>.

B<Parameters>:

=over

=item * $path - The path

=back

=cut
sub absolute_path {
	my ($self, $path) = @_;

	$path = $self->clean_path($path);

	if (substr($path,0,1) eq '/') { #beginning from root. replace leading / with $root
		$path = $self->{root} . substr($path, 1);
	} else { #beginning from current_dir
		$path = $self->current_dir() . $path;
	}

	$path = $self->clean_path($path);
	
	return $path;
}
#= /absolute_path

=head2 relative_path

Returns the path from a given absolute filename relatively to the document root.

Example:

	#assume that the document root is '/foo/bar/'
	/foo/bar/baz => baz
	/foo/bar/baz/bim/bam => baz/bim/bam
	/foo/baz => ../baz

B<Parameters>:

=over

=item * $path - The absolute path

=back

=cut
sub relative_path {
	my ($self, $path) = @_;
	
	$path = $self->clean_path($path);
	
	#remove leading slash
	$path = substr($path, 1) if $path =~ /^\//;
	
	#remove each dir, if it matches
	my @dirs = split /[\/\\]/, $self->{root};
	while (@dirs) {
		my $dir = shift @dirs;
		next unless length($dir);
		$dir = "$dir/";
		if (substr($path, 0, length $dir) eq $dir) {
			#cut off path
			$path = substr($path, length $dir);
		} else {
			#add "../" for each remaining dir
			$path = "../" x (@dirs + 1) . $path;
			last;
		}
	}
		
	return $path;
}
#= /relative_path

=head2 raw_read

Returns the content of a given filename as a scalar. Returns undef on error.

Will not care about the path management within this module.

B<Parameters>:

=over

=item * $filename - The name of the file to read

=item * $asref - Boolean value. If true, the result will be returned by reference
to avoid copying of large data within the memory.

=back

=cut
sub raw_read {
	my ($self, $filename, $asref) = @_;

	if (-f $filename) {
		unless (open FILE, $filename) {
			$Konstrukt::Debug->error_message("Could not open '$filename'! $!") if Konstrukt::Debug::ERROR;
			return undef;
		}
		local $/ = undef;
		my $file = <FILE>;
		close FILE;
		return \$file if $asref;
		return $file;
	} else {
		$Konstrukt::Debug->error_message("File '$filename' doesn't exist!") if Konstrukt::Debug::ERROR;
		return undef;
	}
}
#= /raw_read

=head2 raw_write

Writes a given scalars in the passed filename.

=over

=item * $filename - The name of the file to write to

=item * @scalars  - The scalars which should be written to disk. May be references (which will be dereferenced).

=back

=cut
sub raw_write {
	my ($self, $filename) = (shift, shift);
	
	unless (open(FILE, ">$filename")) {
		$Konstrukt::Debug->error_message("Couldn't write to '$filename'! $!") if Konstrukt::Debug::ERROR;
		return undef;
	}
	foreach my $scalar (@_) {
		print FILE (ref($scalar) eq 'SCALAR' ? $$scalar : $scalar);
	}
	close(FILE);
	return 1;
}
#= /raw_write

=head2 read_and_track

Will read a file relatively to the current directory and will change the current
directory to the one of the file that shall be read if no errors occured.
Will also save the read file as the current file, which can be obtained with the
L</current_file> method.

The root directory will be the one specified on construction of this object
(usually your document root).

C<$Konstrukt::File->read_and_track('/test.txt')> will read the file test.txt
located in the document root, not in the system root.

A file read with this method will be put on a stack of "open" files. So all files
read will be tracked as "opened"/"currently used". If you're done with a file,
you should call $Konstrukt::File->L</pop> to remove it from the stack of currently
used files. The </current_file> method will then return the last filename.

This method will also add a (file date) cache condition (with the file and date
of the read file) to each tracked (currently used) file.
So if any of the files, which have been read after a file during a
process, has changed until a next request the cache for this will be invalid as
it is supposed that the file depends on the files which have been read as the
file was tracked.

B<Parameters>:

=over

=item * $filename - The name of the file to read relative to the current directory

=item * $asref - Boolean value. If true, the result will be returned by reference
to avoid copying of large data within the memory.

=back

=cut
sub read_and_track {
	my ($self, $filename, $asref) = @_;
	my $result;
	
	my $abs_path = $self->absolute_path($filename);
	$result = $self->raw_read($abs_path, $asref);
	$self->push($abs_path);
	
	#add cache condition
	$Konstrukt::Cache->add_condition_file($abs_path) if defined $result;
	
	return $result;
}
#= /read_and_track

=head2 read

Will read a file relatively to the current directory.

The root directory will be the one specified on construction of this object
(usually your document root).

C<$Konstrukt::File->read('/test.txt')> will read the file test.txt
located in the document root, not in the system root.

B<Parameters>:

=over

=item * $filename - The name of the file to read

=item * $asref - Boolean value. If true, the result will be returned by reference
to avoid copying of large data within the memory.

=back

=cut
sub read {
	my ($self, $filename, $asref) = @_;
	
	return $self->raw_read($self->absolute_path($filename), $asref);
}
#= /read

=head2 write

Will write a file relatively to the current directory.

The root directory will be the one specified on construction of this object
(usually your document root).

C<$Konstrukt::File->write('/test.txt', 'some data')> will (over)write the file test.txt
located in the document root, not in the system root.

B<Parameters>:

=over

=item * $filename - The name of the file to write

=item * @scalars  - The scalars which should be written to disk. May be references (which will be dereferenced).

=back

=cut
sub write {
	my ($self, $filename) = (shift, shift);
	
	return $self->raw_write($self->absolute_path($filename), @_);
}
#= /write

=head2 clean_path

Returns a clean path.

Converts "\" to "/", replaces everything to a "//" with "/", removes
everything to a "Drive:\" (MS paths), removes "path/../", removes ./ and
converts the path to lowercase on MS OSes.

=over

=item * $path - The path

=back

=cut
sub clean_path {
	my ($self, $path) = @_;
	
	$path =~ s/\\/\//go; #convert all \ to /
	$path =~ s/\/\/+/\//go; #replace multiple / with a single /
	
	if ($path =~ /^.*(\w\:.*?)$/o) { #microsoft: drive letter included. fully qualified path!
		$path = $1;                   #strip everything up to the drive letter
	}
	
	#kill ./
	while ($path =~ s/\/\.\//\//go) {}; # replace /./ with /
	$path =~ s/^\.\///go;               # kill ./ at the beginning
	
	#kill dir/../
	while ($path =~ s/[^\/\.]+\/\.\.\///go) {}; 
	
	return $path;
}
#= /clean_path

=head2 extract_path

Extracts the path from a filename

=over

=item * $filename - The filename

=back

=cut
sub extract_path {
	my ($self, $filename) = @_;

	$filename =~ /^(.*[\\\/])/o;
	
	return $1 || './';
}
#= /extract_path

=head2 extract_file

Extracts the filename from a full path to a file

=over

=item * $filename - The filename

=back

=cut
sub extract_file {
	my ($self, $filename) = @_;

	$filename =~ /.*[\\\/](.*?)$/o;

	return $1 || $filename;
}
#= /extract_file

=head2 create_dirs

Creates non existing directories in a given path

=over

=item * $path - The (absolute) path

=back

=cut
sub create_dirs {
	my ($self, $path) = @_;
	
	unless (defined $path) {
		$Konstrukt::Debug->error_message("No path specified!") if Konstrukt::Debug::ERROR;
		return;
	}
	
	unless (-d $path) {
		my @dirs = split /[\\\/]/, $path;
		$path = '';
		while (@dirs) {
			$path .= (shift @dirs) . '/';
			unless (-d $path) {
				mkdir $path or $Konstrukt::Debug->error_message("Cannot create $path! $!");
			}
		}
	}
	
	return 1;
}
#= /create_dirs

#create global object
sub BEGIN { $Konstrukt::File = __PACKAGE__->new() unless defined $Konstrukt::File; }

1;

=head1 AUTHOR

Copyright 2006 Thomas Wittek (mail at gedankenkonstrukt dot de). All rights reserved. 

This document is free software.
It is distributed under the same terms as Perl itself.

=head1 SEE ALSO

L<Konstrukt>

=cut
