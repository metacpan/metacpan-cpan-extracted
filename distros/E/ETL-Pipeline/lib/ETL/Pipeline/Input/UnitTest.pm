=pod

=head1 NAME

ETL::Pipeline::Input::UnitTest - Input source for unit tests

=head1 SYNOPSIS

  use ETL::Pipeline;
  ETL::Pipeline->new( {
    input   => ['UnitTest'],
    mapping => {First => 'Header1', Second => 'Header2'},
    output  => ['UnitTest']
  } )->process;

=head1 DESCRIPTION

B<ETL::Pipeline::Input::UnitTest> is an input source used by the unit tests.
It proves that the L<ETL::Pipeline::Input> role works.

The "data" is hard coded.

=cut

package ETL::Pipeline::Input::UnitTest;
use Moose;

use strict;
use warnings;

use 5.014;


our $VERSION = '2.00';


=head1 METHODS & ATTRIBUTES

=head3 current

This array reference holds the current record.

=cut

has 'current' => (
	handles => {
		fields           => 'elements', 
		_get_value       => 'get',
		number_of_fields => 'count',
	},
	is     => 'rw',
	isa    => 'ArrayRef[Str]',
	traits => [qw/Array/],
);


=head3 data

The real input source. This is the data returned by L</next_record>.

=cut

has 'data' => (
	default => sub { [
		[qw/Header1 Header2 Header3/, '  Header4  '],
		[qw/Field1 Field2 Field3 Field4 Field5/],
		[qw/Field6 Field7 Field8 Field9 Field0/],
	] },
	handles => {retrieve => 'shift'},
	is      => 'ro',
	isa     => 'ArrayRef[ArrayRef[Str]]',
	traits  => [qw/Array/],
);


=head2 Called from L<ETL::Pipeline/process>

=head3 get

B<get> retrieves one field from the record. Pass an index number as the field
name. The test data has 4 header fields and 5 values in each data row.
Remember that index numbers start at zero.

=cut

sub get {
	my ($self, $index) = @_;
	return undef unless $index =~ m/^\d+$/;
	return $self->_get_value( $index );
}


=head3 next_record

B<ETL::Pipeline::Input::UnitTest> returns 3 records by cycling through
L</data>.

=cut

sub next_record {
	my $self = shift;

	my $record = $self->retrieve;
	if (defined $record) {
		$self->current( $record );
		return 1;
	} else { return 0; }
}


=head3 configure

B<configure> doesn't actually do anything. But it is required by
L<ETL::Pipeline/process>.

=cut

sub configure {}


=head3 finish

B<finish> doesn't actually do anything. But it is required by
L<ETL::Pipeline/process>.

=cut

sub finish {}


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Input>, L<ETL::Pipeline::Output::UnitTest>

=cut

with 'ETL::Pipeline::Input';


=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=head1 LICENSE

Copyright 2016 (c) Vanderbilt University

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
