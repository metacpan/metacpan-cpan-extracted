package File::ShareDir::Tiny;
$File::ShareDir::Tiny::VERSION = '0.001';
use strict;
use warnings;

use Exporter 5.57 'import';
our @EXPORT_OK = qw/dist_dir module_dir dist_file module_file/;
our %EXPORT_TAGS = (ALL => \@EXPORT_OK);

use Carp 'croak';
use File::Spec::Functions qw/catfile catdir/;

sub _search_inc_path {
	my $path = catdir(@_);

	for my $candidate (@INC) {
		next if ref $candidate;
		my $dir = catdir($candidate, $path);
		return $dir if -d $dir;
	}

	return undef;
}

sub dist_dir {
	my $dist = shift;

	croak 'No dist given' if not length $dist;
	my $dir = _search_inc_path('auto', 'share', 'dist', $dist);

	croak("Failed to find share dir for dist '$dist'") if not defined $dir;
	return $dir;
}

sub module_dir {
	my $module = shift;

	croak 'No module given' if not length $module;
	(my $module_dir = $module) =~ s/::/-/g;
	my $dir = _search_inc_path('auto', 'share', 'module', $module_dir);

	croak("Failed to find share dir for module '$module'") if not defined $dir;
	return $dir;
}

sub dist_file {
	my ($dist, @file) = @_;
	my $dir = dist_dir($dist);
	my $path = catfile($dir, @file);
	-e $path or croak(sprintf 'File \'%s\' does not exist in dist dir of %s', catfile(@file), $dist);
	return $path;
}

sub module_file {
	my ($module, @file) = @_;
	my $dir = module_dir($module);
	my $path = catfile($dir, @file);
	-e $path or croak(sprintf 'File \'%s\' does not exist in module dir of %s', catfile(@file), $module);
	return $path;
}

1;

#ABSTRACT: Locate per-dist and per-module shared files

__END__

=pod

=encoding UTF-8

=head1 NAME

File::ShareDir::Tiny - Locate per-dist and per-module shared files

=head1 VERSION

version 0.001

=head1 SYNOPSIS

  use File::ShareDir::Tiny ':ALL';
   
  # Where are distribution-level shared data files kept
  $dir = dist_dir('File-ShareDir-Tiny');
   
  # Where are module-level shared data files kept
  $dir = module_dir('File::ShareDir::Tiny');
   
  # Find a specific file in our dist/module shared dir
  $file = dist_file('File-ShareDir-Tiny',  'file/name.txt');
  $file = module_file('File::ShareDir::Tiny', 'file/name.txt');

=head1 DESCRIPTION

Quite often you want or need your Perl module (CPAN or otherwise)
to have access to a large amount of read-only data that is stored
on the file-system at run-time.

On a linux-like system, this would be in a place such as /usr/share,
however Perl runs on a wide variety of different systems, and so
the use of any one location is unreliable.

This module provides a more portable way to have (read-only) data
for your module.

=head2 Using Data in your Module

C<File::ShareDir::Tiny> forms one half of a two part solution.
Once the files have been installed to the correct directory,
you can use C<File::ShareDir::Tiny> to find your files again after
the installation.

For the installation half of the solution, there are several options
available that depend on your installation tool. For L<ExtUtils::MakeMaker|ExtUtils::MakeMaker>
There is L<File::ShareDir::Install>. Other tools like L<Module::Build|Module::Build>,
L<Module::Build::Tiny|Module::Build::Tiny> and L<Dist::Build|Dist::Build> have
built in support for sharedirs.

=head1 FUNCTIONS

C<File::ShareDir::Tiny> provides four functions for locating files and
directories.

For greater maintainability, none of these are exported by default
and you are expected to name the ones you want at use-time, or provide
the C<':ALL'> tag. All of the following are equivalent.

  # Load but don't import, and then call directly
  use File::ShareDir::Tiny;
  $dir = File::ShareDir::Tiny::dist_dir('My-Dist');
  
  # Import a single function
  use File::ShareDir::Tiny 'dist_dir';
  dist_dir('My-Dist');
  
  # Import all the functions
  use File::ShareDir::Tiny ':ALL';
  dist_dir('My-Dist');

All of the functions will check for you that the dir/file actually
exists, and that you have read permissions, or they will throw an
exception.

=head2 dist_dir

  # Get a distribution's shared files directory
  my $dir = dist_dir('My-Distribution');

The C<dist_dir> function takes a single parameter of the name of an
installed (CPAN or otherwise) distribution, and locates the shared
data directory created at install time for it.

Returns the directory path as a string, or dies if it cannot be
located or is not readable.

=head2 module_dir

  # Get a module's shared files directory
  my $dir = module_dir('My::Module');

The C<module_dir> function takes a single parameter of the name of an
installed (CPAN or otherwise) module, and locates the shared data
directory created at install time for it.

Note that unlike L<File::ShareDir|File::ShareDir> the module does not
have be loaded when calling this function.

Returns the directory path as a string, or dies if it cannot be
located or is not readable.

=head2 dist_file

  # Find a file in our distribution shared dir
  my $dir = dist_file('My-Distribution', 'file/name.txt');

The C<dist_file> function takes two parameters of the distribution name
and file name, locates the dist directory, and then finds the file within
it, verifying that the file actually exists, and that it is readable.

The filename should be a relative path in the format of your local
filesystem. It will simply added to the directory using L<File::Spec>'s
C<catfile> method.

Returns the file path as a string, or dies if the file or the dist's
directory cannot be located, or the file is not readable.

=head2 module_file

  # Find a file in our module shared dir
  my $dir = module_file('My::Module', 'file/name.txt');

The C<module_file> function takes two parameters of the module name
and file name. It locates the module directory, and then finds the file
within it, verifying that the file actually exists, and that it is readable.

In order to find the directory, the module B<must> be loaded when
calling this function.

The filename should be a relative path in the format of your local
filesystem. It will simply added to the directory using L<File::Spec>'s
C<catfile> method.

Returns the file path as a string, or dies if the file or the dist's
directory cannot be located, or the file is not readable.

=head1 AUTHOR

Leon Timmermans <fawaka@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Leon Timmermans.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
