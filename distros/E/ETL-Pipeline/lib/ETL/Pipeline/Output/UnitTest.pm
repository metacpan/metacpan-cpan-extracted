=pod

=head1 NAME

ETL::Pipeline::Output::UnitTest - Output destination for unit tests

=head1 SYNOPSIS

  use ETL::Pipeline;
  ETL::Pipeline->new( {
    input   => ['UnitTest'],
    mapping => {First => 'Header1', Second => 'Header2'},
    output  => ['UnitTest']
  } )->process;

=head1 DESCRIPTION

B<ETL::Pipeline::Output::UnitTest> is an output destination used by the unit
tests. It proves that the L<ETL::Pipeline::Output> role works. You should not
use this destination in production code - only unit tests.

The I<data> is stored in memory. The class provides methods to access the saved
records.

=cut

package ETL::Pipeline::Output::UnitTest;

use 5.014000;
use warnings;

use Carp;
use Moose;


our $VERSION = '3.00';


=head1 METHODS & ATTRIBUTES

=head2 Arguments for L<ETL::Pipeline/output>

None - there's no configuration for this destination. It's meant to be quick and
light for unit testing.

=head2 Attributes

=head3 records

In B<ETL::Pipeline::Output::UnitTest>, a record is a hash reference.
B<records> stores a list of record (hash references). The list survives after
calling L</finish>. This allows you to check the results of a test after
calling L<ETL::Pipeline/process>.

The list is cleared after calling L</configure>.

=cut

has 'records' => (
	default => sub { [] },
	handles => {
		_add_record       => 'push',
		all_records       => 'elements',
		_reset            => 'clear',
		get_record        => 'get',
		number_of_records => 'count',
	},
	is     => 'ro',
	isa    => 'ArrayRef[HashRef[Any]]',
	traits => [qw/Array/],
);


=head2 Methods

=head3 all_records

Returns a list of all the records. It dereferences L</records>.

=cut

# This method is defined by the "records" attribute.


=head3 close

Prevents further storage of records. L</write> will throw a fatal exception if
it is called after B<close>. This helps ensure that everything runs in the
proper order.

=cut

sub close { shift->_state( "already called 'closed'" ); }


=head3 get_record

Returns a single record from storage. Useful to check the values and make sure
things were added in the correct order. It returns the ame hash reference passed
into L</write>.

=head3 number_of_records

Returns the count of records currently in storage.

=cut

# These methods are defined by the "records" attribute.


=head3 open

Allows storage of records. L</write> will throw a fatal exception if it is
called before B<open>. This helps ensure that everything runs in the proper
order.

=cut

sub open { shift->_state( 'processing records' ); }


=head3 write

Add the current record into the L</records> attribute. Unit tests can then
check what was saved, to make sure the pipeline completed.

=cut

sub write {
	my ($self, $etl, $record) = @_;

	if ($self->_state eq 'processing records') {
		$self->_add_record( $record );
	} else {
		croak sprintf "'write' failed because ETL::Pipeline %s", $self->_state;
	}
}


#-------------------------------------------------------------------------------
# Internal methods and attributes

# Object state. It lets "write" verify that everything has happened in the
# correct order.
has '_state' => (
	default => "hasn't called 'open' yet",
	is      => 'rw',
	isa     => 'Str',
);


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Output>, L<ETL::Pipeline::Input::UnitTest>

=cut

with 'ETL::Pipeline::Output';


=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vumc.org>

=head1 LICENSE

Copyright 2021 (c) Vanderbilt University

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
