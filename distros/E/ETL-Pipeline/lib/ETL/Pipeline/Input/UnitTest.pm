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

The I<data> is hard coded.

=cut

package ETL::Pipeline::Input::UnitTest;
use Moose;

use strict;
use warnings;

use 5.014;


our $VERSION = '3.00';


=head1 METHODS & ATTRIBUTES

=head2 Arguments for L<ETL::Pipeline/input>

None - there's no configuration for this source. It's meant to be quick and
light for unit testing.

=head2 Methods

=head3 run

This is the main loop. For unit tests, I use hard coded data. This guarantees
consistent behavior.

L<ETL::Pipeline> automatically calls this method.

=cut

sub run {
	my ($self, $etl) = @_;

	$etl->aliases(
		{Header1       => 0},
		{Header2       => 1},
		{Header3       => 2},
		{'  Header4  ' => 3},
		{Header6       => 5},
		{Header6       => 6},
	);
	$etl->record( [qw/
		Field1
		Field2
		Field3
		Field4
		Field5
		Field6
		Field7
		Field8
		Field9
	/] );
	$etl->record( [qw/
		Field11
		Field12
		Field13
		Field14
		Field15
		Field16
		Field17
		Field18
		Field19
	/] );
}


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Input>, L<ETL::Pipeline::Output::UnitTest>

=cut

with 'ETL::Pipeline::Input';


=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vumc.org>

=head1 LICENSE

Copyright 2021 (c) Vanderbilt University

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
