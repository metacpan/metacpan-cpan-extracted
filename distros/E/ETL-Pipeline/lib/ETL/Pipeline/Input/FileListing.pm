=pod

=head1 NAME

ETL::Pipeline::Input::FileListing - Input source of a disk folder

=head1 SYNOPSIS

  use ETL::Pipeline;
  ETL::Pipeline->new( {
    input   => ['FileListing', from => 'Documents', name => qr/\.jpg$/i],
    mapping => {FileName => 'File', FullPath => 'Path'},
    output  => ['UnitTest']
  } )->process;

=head1 DESCRIPTION

B<ETL::Pipeline::Input::FileListing> defines an input source that reads a disk
directory. It returns information about each individual file. Use this input
source when you need information I<about> the files and not their content.

=cut

package ETL::Pipeline::Input::FileListing;
use Moose;

use 5.014000;
use Carp;
use MooseX::Types::Path::Class qw/Dir/;
use Path::Class;
use Path::Class::Rule;


our $VERSION = '2.00';


=head1 METHODS & ATTRIBUTES

=head2 Arguments for L<ETL::Pipeline/input>

=head3 from

B<from> tells B<ETL::Pipeline::Input::FileListing> where to find the files. By
default, B<ETL::Pipeline::Input::FileListing> looks in 
L<ETL::Pipeline/data_in>. B<from> tells the code to look in another place.

If B<from> is a regular expression, the code finds the first directory whose
name matches. If B<from> is a relative path, it is expected to reside under 
L<ETL::Pipeline/data_in>. An absolute path is exact.

=cut

has 'from' => (
	init_arg => undef,
	is       => 'bare',
	isa      => Dir,
	reader   => '_get_from',
	writer   => '_set_from',
);


sub from {
	my $self = shift;

	if (scalar( @_ ) > 0) {
		my $new = shift;
		if (ref( $new ) eq 'Regexp') {
			my $match = Path::Class::Rule->new
				->iname( $new )
				->max_depth( 1 )
				->directory
				->iter( $self->pipeline->data_in )
				->()
			;
			croak 'No matching directories' unless defined $match;
			$self->_set_from( $match );
		} else  { 
			my $folder = dir( $new );
			$folder = $folder->absolute( $self->pipeline->data_in ) 
				if $folder->is_relative;
			$self->_set_from( $folder );
		}
	}
	return $self->_get_from;
}


=head3 ...

B<ETL::Pipeline::Input::FileListing> accepts any of the tests provided by
L<Path::Iterator::Rule>. The value of the argument is passed directly into the 
test. For boolean tests (e.g. readable, exists, etc.), pass an C<undef> value.

B<ETL::Pipeline::Input::FileListing> automatically applies the C<file> filter.
Do not pass C<file> through L<ETL::Pipeline/input>.

C<name> is the most commonly used argument. It accepts a glob or regular 
expression to match file names.

=cut

sub BUILD {
	my $self = shift;
	my $arguments = shift;

	# Set the top level directory.
	if (defined $arguments->{from}) {
		$self->from( $arguments->{from} );
	} else { $self->from( '.' ); }

	# Configure the file search.
	my @criteria = grep { 
		$_ ne 'file' 
		&& !$self->meta->has_attribute( $_ ) 
	} keys %$arguments;
	my $search = Path::Class::Rule->new;
	foreach my $name (@criteria) {
		my $value = $arguments->{$name};
		eval "\$search->$name( \$value )";
		croak $@ unless $@ eq '';
	}
	$search->file;
	$self->_set_iterator( $search->iter( $self->from ) );
}


=head2 Called from L<ETL::Pipeline/process>

=head3 get

B<get> retrieves one field about the currently selected file. B<get> can
also return methods from the L<Path::Class::File> object. Any additional
arguments for B<get> are passed directly into the method.

  # ETL::Pipeline::Input::FileListing fields.
  $etl->get( 'Inside' );
  $etl->get( 'File' );
  
  # Path::Class::File methods.
  $etl->get( 'basename' );

B<ETL::Pipeline::Input::FileListing> provides these fields...

=over

=item Extension

The file extension, without a leading period.

=item File

The file name with the extension. No directory information.

=item Folder

The full directory where this file resides.

=item Inside

The relative directory name where this file resides. These are the directories
below L</from> where the file resides. You can use this to re-create the
directory structure.

=item Path

The complete path name of the file (directory, name, and extension). You can
use this to access the file contents.

=item Relative

The relative path name of the file. This is the part that comes after the
L</from> directory.

=item Object

The L<Path::Class::File> object for this entry.

=back

=cut

sub get {
	my ($self, $field, @arguments) = @_;

	my $record = $self->current;
	if (exists $record->{$field}) {
		return $record->{$field};
	} else {
		my $object = $record->{Object};
		return eval "\$object->$field( \@arguments )";
	}
}


=head3 next_record

Read one record from the file for processing. B<next_record> returns a boolean.
I<True> means success. I<False> means it reached the end of the listing (aka 
no more files).

  while ($input->next_record) {
    ...
  }

=cut

sub next_record {
	my ($self) = @_;

	my $object = $self->_next_file;
	if (defined $object) {
		my @pieces = split( /\./, $object->basename);
		$self->current( {
			Extension => $pieces[-1],
			File      => $object->basename,
			Folder    => $object->dir->absolute( $self->from )->stringify,
			Inside    => $object->dir->relative( $self->from )->stringify,
			Object    => $object,
			Path      => $object->absolute( $self->from )->stringify,
			Relative  => $object->relative( $self->from )->stringify,
		} );
		return 1;
	} else { return 0; }
}


=head3 configure

B<configure> doesn't actually do anything. But it is required by
L<ETL::Pipeline/process>.

=cut

sub configure { }


=head3 finish

B<finish> doesn't actually do anything. But it is required by
L<ETL::Pipeline/process>. 

=cut

sub finish { }


=head2 Other Methods & Attributes

=head3 current

B<current> holds the current record as a hash reference.

=cut

has 'current' => (
	is  => 'rw',
	isa => 'HashRef',
);


=head3 iterator

L<Path::Class::Rule> creates an iterator that returns each file in turn. 
B<iterator> holds it for L</next_record>.

=cut

has 'iterator' => (
	handles => {_next_file => 'execute'},
	is      => 'ro',
	isa     => 'CodeRef',
	traits  => [qw/Code/],
	writer  => '_set_iterator',
);


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Input>, L<Path::Class::File>,
L<Path::Class::Rule>, L<Path::Iterator::Rule>

=cut

with 'ETL::Pipeline::Input';


=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=head1 LICENSE

Copyright 2016 (c) Vanderbilt University Medical Center

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
