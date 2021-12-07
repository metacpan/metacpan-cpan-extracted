=pod

=head1 NAME

ETL::Pipeline::Input::File::List - Role for input sources with multiple files

=head1 SYNOPSIS

  # In the input source...
  use Moose;
  with 'ETL::Pipeline::Input';
  with 'ETL::Pipeline::Input::File::List';
  ...
  sub run {
    my ($self, $etl) = @_;
    ...
	while (my $path = $self->next_path( $etl )) {
	  ...
	}
  }

=head1 DESCRIPTION

This is a role used by input sources. It defines everything you need to process
multiple input files of the same format. The role uses L<Path::Class::Rule> to
locate matching files.

Your input source calls the L</next_path> method in a loop. That's it. The role
automatically processes constructor arguments that match L<Path::Class::Rule>
criteria. It then builds a list of matching files the first time your code calls
L</next_path>.

=cut

package ETL::Pipeline::Input::File::List;

use 5.014000;

use Carp;
use Moose::Role;
use MooseX::Types::Path::Class;
use Path::Class::Rule;


our $VERSION = '3.00';


=head1 METHODS & ATTRIBUTES

=head2 Arguments for L<ETL::Pipeline/input>

B<ETL::Pipeline::Input::File::List> accepts any of the tests provided by
L<Path::Iterator::Rule>. The value of the argument is passed directly into the
test. For boolean tests (e.g. readable, exists, etc.), pass an C<undef> value.

B<ETL::Pipeline::Input::File> automatically applies the C<file> filter. Do not
pass C<file> through L<ETL::Pipeline/input>.

C<iname> is the most common one that I use. It matches the file name, supports
wildcards and regular expressions, and is case insensitive.

  # Search using a regular expression...
  $etl->input( 'XmlFiles', iname => qr/\.xml$/ );

  # Search using a file glob...
  $etl->input( 'XmlFiles', iname => '*.xml' );

=cut

# BUILD in the consuming class will override this one. I add a fake BUILD in
# case the class doesn't have one. The method modifier then runs the code to
# extract search criteria from the constructor arguments. The modifier will
# run even if the consuming class has its own BUILD.
# https://www.perlmonks.org/?node_id=837369
sub BUILD {}

after 'BUILD' => sub {
	my $self = shift;
	my $arguments = shift;

	while (my ($name, $value) = each %$arguments) {
		$self->_add_criteria( $name, $value )
			if $name ne 'file' && Path::Class::Rule->can( $name );
	}
};


=head3 path

L<Path::Class::File> object for the currently selected file. This is first file
that matches the criteria. When you call L</next_path>, it finds the next match
and sets B<path>.

So B<path> always points to the current file. It should be used by your input
source class as the file name.

  # Inside the input source class...
  while ($self->next_path( $etl )) {
    open my $io, '<', $self->path;
    ...
  }

C<undef> means no more matches.

=cut

has 'path' => (
	coerce => 1,
	is     => 'ro',
	isa    => 'Path::Class::File|Undef',
	writer => '_set_path',
);


=head2 Methods

=head3 next_path

Looks for the next match in the list and sets the L</path> attribute. It also
returns the matching path. Your input source class should setup a loop calling
this method. Inside the loop, process each file.

B<next_path> takes one parameter - the L<ETL::Pipeline> object. The method
matches files in L<ETL::Pipeline/data_in>.

=cut

sub next_path {
	my ($self, $etl) = @_;

	if ($self->_list_built) {
		# Get the next file from the list. We'll return "undef" if you query
		# beyond the end of the list.
		$self->_next_file;
	} else {
		# Build the list the first time through.
		my $rule = Path::Class::Rule->new->file;
		foreach my $pair ($self->_search_criteria) {
			my $name  = $pair->[0];
			my $value = $pair->[1];

			eval "\$rule = \$rule->$name( \$value )";
			croak $@ unless $@ eq '';
		}
		$self->_matches( $rule->all( $etl->data_in ) );
		$self->_list_built( 1 );
	}

	# Set "position" to something more readable.
	my $file = $self->_set_path( $self->_file( $self->_file_index ) );

	if (defined $file) {
		$self->source( $file->relative( $etl->work_in )->stringify );
		$etl->status( 'INFO', 'Next file' );
	} else { $self->source( '' ); }

	return $file;
}


#-------------------------------------------------------------------------------
# Internal methods and attributes

# Search criteria for the file list. I capture the criteria from the constructor
# but don't build the iterator until the loop kicks off. Since the search
# depends on "data_in", this allows the user to setup the pipeline in whatever
# order they want and it will do the right thing.
has '_criteria' => (
	default => sub { {} },
	handles => {_add_criteria => 'set', _search_criteria => 'kv'},
	is      => 'ro',
	isa     => 'HashRef[Any]',
	traits  => [qw/Hash/],
);


# Index into "_file_list" for the current file. This counter is used to loop
# through the list by calling "next_path".
has '_file_index' => (
	default => 0,
	handles => {_next_file => 'inc'},
	is      => 'ro',
	isa     => 'Int',
	traits  => [qw/Counter/],
);


# List of files that match the search criteria. The list is built at the
# beginning of the pipeline. So your pipeline can't add files on the fly.
has '_file_list' => (
	default => sub { [] },
	handles => {_file => 'get', _matches => 'push'},
	is      => 'ro',
	isa     => 'ArrayRef[Any]',
	traits  => [qw/Array/],
);


# Since the list always exists, I needed a way to tell the difference between
# "no matches" and "not built yet". That way, "next_record" can build the list
# on the first pass.
has '_list_built' => (
	default => 0,
	is      => 'rw',
	isa     => 'Bool',
);


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Input>, L<Path::Class::File>,
L<Path::Class::Rule>, L<Path::Iterator::Rule>

=cut

=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vumc.org>

=head1 LICENSE

Copyright 2021 (c) Vanderbilt University Medical Center

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;

# Required by Perl to load the module.
1;
