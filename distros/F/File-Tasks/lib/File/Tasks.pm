package File::Tasks;

# See POD at end for docs

use 5.005;
use strict;
use Clone                 ();
use Params::Util          '_INSTANCE';
use Params::Coerce        ();
use File::Tasks::Provider ();
use File::Tasks::Add      ();
use File::Tasks::Edit     ();
use File::Tasks::Remove   ();
use constant 'FFR'  => 'File::Find::Rule';
use overload 'bool' => sub () { 1 };
use overload '+'    => '_overlay';

use vars qw{$VERSION};
BEGIN {
	$VERSION = '0.07';
}





#####################################################################
# Constructor and Accessors

sub new {
	my $class  = ref $_[0] ? ref shift : shift;
	my %params = (ref $_[0] eq 'HASH') ? %{shift()} : @_;

	# Create the basic object
	my $self = bless {
		provider => 'File::Tasks::Provider',
		tasks    => {},
		ignore   => undef,
		}, $class;

	# Accept an alternate provider
	if ( _INSTANCE($params{provider}, 'File::Tasks::Provider') ) {
		$self->{provider} = $params{provider};
	}

	# Set the auto-ignore
	if ( _INSTANCE($params{ignore}, FFR) ) {
		$self->{ignore} = $params{ignore}->prune->discard;
	}

	$self;
}

sub provider { $_[0]->{provider} }

sub ignore { $_[0]->{ignore} }

# We need to do this ourself, as sort in scalar context returns undef
sub paths {
	wantarray
		? sort keys %{$_[0]->{tasks}}
		: scalar(keys %{$_[0]->{tasks}});
}

sub tasks {
	my $tasks = $_[0]->{tasks};
	map { $tasks->{$_} } $_[0]->paths;
}

sub task {
	my $self = shift;
	my $path = defined $_[0] ? shift : return undef;
	$self->{tasks}->{$path};
}





#####################################################################
# Building the File::Tasks

sub add {
	$_[0]->set(File::Tasks::Add->new(@_));
}

sub edit {
	$_[0]->set(File::Tasks::Edit->new(@_));
}

sub remove {
	$_[0]->set(File::Tasks::Remove->new(@_));
}

sub remove_dir {
	my $self = shift;
	my $dir  = -d $_[0] ? shift : return undef;
	require File::Find::Rule; # Only load as needed
	my $Rule = _INSTANCE(shift, 'File::Find::Rule') || FFR->new;
	$Rule = FFR->or( $self->{ignore} || (), $Rule )->relative->file;

	# Execute the file and add all resulting files as Remove entries
	my @files = $Rule->in($dir);
	foreach my $file ( @files ) {
		$self->remove( $file ) or return undef;
	}

	scalar @files;
}

sub set {
	my $self = shift;
	my $Task = _INSTANCE(shift, 'File::Tasks::Task') or return undef;
	$self->clashes($Task->path) and return undef;
	$self->{tasks}->{$Task} = $Task;
}

sub clashes {
	my $self = shift;
	my $path = defined $_[0] ? shift : return undef;
	return '' if $self->{tasks}->{$path};
	foreach ( sort keys %{$self->{tasks}} ) {
		return 1 if $path eq $_;
		return 1 if $_ =~ m!^$path/!;
		return 1 if $path =~ m!$_/!;
	}
	'';
}





#####################################################################
# Actions for the File::Tasks

sub test {
	my $self = shift;
	foreach my $path ( sort keys %{$self->{tasks}} ) {
		my $Task = $self->{tasks}->{$path} or return undef;
		$Task->test or return undef;
	}
	1;
}

sub execute {
	my $self = shift;
	foreach my $path ( sort keys %{$self->{tasks}} ) {
		my $Task = $self->{tasks}->{$path} or return undef;
		$Task->execute or return undef;
	}
	1;
}





#####################################################################
# Higher Order Methods

sub overlay {
	my $self  = Clone::clone shift;
	my $other = Params::Coerce::coerce('File::Tasks', shift) or return undef;
	foreach my $Task ( $other->tasks ) {
		my $Current = $self->task($Task->path);
		unless ( $Current ) {
			$self->set($Current) or return undef;
			next;
		}
		if ( $Task->type eq 'add' ) {
			if ( $Current->type eq 'add' ) {
				# Add over Add - Replace existing object
				$self->{tasks}->{$Task} = $Task;
			} else {
				# Add over Edit - Convert Add to Edit and replace
				# Add over Delete - Convert Add to Edit and replace
				my $Edit = File::Tasks::Edit->new(
					$self, $Task->path, $Task->source,
					) or return undef;
				$self->{tasks}->{$Edit} = $Edit;
			}
		} elsif ( $Task->type eq 'edit' ) {
			if ( $Current->type eq 'add' ) {
				# Edit over Add - Convert Edit to Add and replace
				my $Add = File::Tasks::Add->new(
					$self, $Task->path, $Task->source,
					) or return undef;
				$self->{tasks}->{$Add} = $Add;
			} else {
				# Edit over Edit - Replace existing object
				# Edit over Delete - Replace existing object
				$self->{tasks}->{$Task} = $Task;				
			}
		} else {
			if ( $Current->type eq 'add' ) {
				# Delete over Add - Tasks cancel each other out
				delete $self->{tasks}->{$Task};
			} elsif ( $Current->type eq 'edit' ) {
				# Delete over Edit - Replace existing object
				$self->{tasks}->{$Task} = $Task;
			} else {
				# Nothing to do
			}
		}
	}
	$self;
}

# A thin wrapper to handle the way overloaded arguments are provided
sub _overlay {
	my $left  = _INSTANCE(shift, 'File::Tasks') ? shift : return undef;
	my $right = Params::Coerce::coerce('File::Tasks', shift) or return undef;
	($left, $right) = ($right, $left) if $_[0];
	$left->overlay($right);
}





#####################################################################
# Coercion Support

# From an entire builder
sub __from_Archive_Builder {
	my $self    = shift->new;
	my $Builder = _INSTANCE(shift, 'Archive::Builder') or return undef;
	my $files   = $Builder->files;
	foreach my $path ( keys %$files ) {
		$self->add( $path, $files->{$path} ) or return undef;
	}
	$self;
}

# From a single Section
sub __from_Archive_Builder_Section {
	my $self    = shift->new;
	my $Section = _INSTANCE(shift, 'Archive::Builder::Section') or return undef;
	my $files   = $Section->files;
	foreach my $path ( keys %$files ) {
		$self->add( $path, $files->{$path} ) or return undef;
	}
	$self;
}
	
1;

__END__

=pod

=head1 NAME

File::Tasks - A set of file tasks to be executed in a directory

=head1 SYNOPSIS

  # Create a script
  my $Script = File::Tasks->new;
  
  # Add some new files
  $Script->add( 'Foo' );

=head1 DESCRIPTION

File::Tasks allows you to define a set of file tasks to be done to a local
filesystem. There are three basic tasks, L<Add|File::Tasks::Add>,
L<Edit|File::Tasks::Edit>, and L<Remove|File::Tasks::Remove>.

A single File::Tasks object is used to assemble a collection of these
tasks, and then execute them on a new or existing directory somewhere on
the local filesystem.

The File::Tasks will take care of making sure that the task paths are all
compatible with their resulting location, and that the tasks match the
current state of the filesystem.

Once fully verified, it will execute the tasks and make the changes to the
filesystem.

=head1 METHODS

=head2 new @params

Create and return a new C<File::Tasks> object. Takes as argument a number
of parameters in C<<Key => $value>> form.

=over 4

=item provider

Provide a custom Data Provider. The passed object must be a sub-class
of L<File::Tasks::Provider>.

=back

Returns a new C<File::Tasks> object.

=head2 provider

Returns the Provider object for the File::Tasks

=head2 ignore

Returns the original C<File::Find::Rule> for the files to be ignore
provided to the constructor.

=head2 paths

Returns as a sorted list the file paths of all of the Tasks

=head2 tasks

Returns all of the Tasks as a list, in the same order as for
L<paths|File::Tasks/paths>.

=head2 task $path

Access a single L<File::Tasks::Task> object by its path

=head2 add $path, $source

The C<add> method creates an "Add" task and adds it to the File::Tasks.
An Add task creates a new file where no file currently exists. Upon execution
of the File::Tasks, if a file already exists at the location, execution will
fail.

Returns the new File::Tasks::Add object as a convenience. Returns C<undef>
if the path clashes, or the source is not valid.

=head2 edit $path, $source

The C<edit> method creates as "Edit" task and adds it to the File::Tasks.
An Edit task replaces the contents of an existing file. Upon execution of the
File::Tasks, if no file exists the execution will fail.

Returns the File::Tasks::Edit object as a convenience. Returns C<undef>
if the path clashes, or the source is not valid.

=head2 remove $path

The C<remove> method creates a "Remove" task and adds it to the
File::Tasks. A Remove task deletes a file currently on the filesystem.
If no file exists, execution will fail.

Returns the File::Tasks::Remove object as a convenience. Returns C<undef>
if the path clashes.

=head2 remove_dir $dir [, $Rule ]

The C<remove_dir> method is specifically designed to remove an entire
directory. The directory passed as the first argument is scanned using
L<File::Find::Rule> to find all the files in it, and then a series
if "Remove" tasks are created and added based on the relative location
of the files in the existing directory.

A pre-built Rule object can be provided as the second argument to modify
the behaviour of File::Find::Rule when searching for files. In one example,
you might want to add Remove tasks for all the files in a CVS checkout,
without removing the .cvs directories.

  # Create the "leave .cvs dirs intact" rule
  my $Rule = File::Find::Rule->new;
  $Rule = $Rule->or(
  	$Rule->new->directory->name('.cvs')->prune,
  	$Rule->new->file
  	);
  
  # Add the Remove tasks
  $Script->remove_dir($dir, $Rule);

Returns the number of Remove tasks added, which may validly be zero.
On error, such as a bad directory, bad second argument, or failed
Remove Task addition, returns C<undef>.

=head2 set $Task

For a File::Tasks::Task object created outside of File::Tasks, the C<set>
method attempts to add it to the Script.

Returns the Task object as a convenience, or C<undef> on error.

=head2 clashes $path

The C<clashes> method is used to determine if a path clashes with an
existing Task in the File::Tasks object. Generally this is because a
file already exists for a directory you want to add, or vica versa.

Returns true if the path clashes, or false if not.

=head2 test $dir

The C<test> method does a complete dry run of the execution of the
File::Tasks object. This includes:

- Ensuring that no paths clash

- Checking that all files that should exist do

- Checking that all files that shouldn't exist don't

- Checking we have the correct permissions

Returns true if the test run was successful, or C<undef> otherwise.

=head1 execute $dir

Executes the File::Tasks. This will create, modify or remove files as
described in the Tasks.

Due to the delicate and somewhat complex nature of the installation, you
almost certainly will want to do a test run with C<<->test($dir)>> before
the live call.

Returns true if completed successfully, or C<undef> otherwise.

=head2 overlay $Under, $Over

To keep complexity down, a great way of generating File::Tasks objects
that will "overwrite" a previous installation is to do it in two parts.

  # Create a script to remove the old installation
  my $Old = File::Tasks->new;
  $Old->remove_dir($dir);
  
  # Script for a fresh install spat out by some module
  my $Install = My::Module->build->Script;
  
  # Overlay the new install over the old removal to create
  # a combined script that will "shift" the current files as needed.
  my $Script = $Old->overlay($Install);

Where this gets really cool is that if the new file is the same as the
old file, the Task will be optimised away.

This means that if the underlying data for a process changes, and you
rerun a generator of some sort, the only output files that are touched
are the ones that will actually change as a result of the underlying
data changing.

Given two File::Tasks objects, will create and return a new Script that
represents the combination of the two. Returns C<undef> on error.

The + operator is also effectively overloaded to this method

  # The explicit way
  my $Script = $Old->overlay($Install);
  
  # Via the overload
  my $Script = $Old + $Install;

=head1 TO DO

- Much more detailed unit testing

- Add various caching options

=head1 SUPPORT

Bugs should be reported via the CPAN bug tracker at

L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=File-Tasks>

For other issues, contact the author.

=head1 AUTHOR

Adam Kennedy E<lt>adamk@cpan.orgE<gt>, L<http://ali.as/>

=head1 COPYRIGHT

Copyright 2005, 2006 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
