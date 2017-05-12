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
tests. It proves that the L<ETL::Pipeline::Output> role works.

The "data" is stored in memory.

=cut

package ETL::Pipeline::Output::UnitTest;
use Moose;

use Carp;
use String::Util qw/hascontent/;


our $VERSION = '2.00';


=head1 METHODS & ATTRIBUTES

=head3 records

In B<ETL::Pipeline::Output::UnitTest>, a record is a hash reference.
B<records> stores a list of record (hash references). The list survives after
calling L</finish>. This allows you to check the results of a test after
calling L<ETL::Pipeline/process>.

The list is cleared after calling L</configure>.

=head3 all_records

The B<all_records> method returns a list of all the records. It dereferences 
L</records>.

=head3 number_of_records

The B<number_of_records> method returns the count of records currently in the
list.

=cut

has 'records' => (
	default => sub { [] },
	handles => {
		all_records          => 'elements', 
		_reset               => 'clear', 
		get_record           => 'get',
		number_of_records    => 'count',
		_save_current_record => 'push',
	},
	is     => 'ro',
	isa    => 'ArrayRef[HashRef[Any]]',
	traits => [qw/Array/],
);


=head2 Called from L<ETL::Pipeline/process>

=head3 write_record

Saves the current record into L</records>.

=cut

sub write_record {
	my $self = shift;
	
	$self->_save_current_record( $self->current );
	return 1;
}


=head3 configure

B<configure> doesn't actually do anything. But it is required by
L<ETL::Pipeline/process>.

=cut

sub configure { }


=head3 finish

B<finish> doesn't actually do anything. But it is required by
L<ETL::Pipeline/process>. L</records> persists so that the unit test can check
its values.

=cut

sub finish {}


=head2 Other methods & attributes

=head3 default_fields

Initialize L</current> for the next record.

=cut

sub default_fields { () }


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Output>, 
L<ETL::Pipeline::Output::Storage::Hash>, L<ETL::Pipeline::Input::UnitTest>

=cut

with 'ETL::Pipeline::Output::Storage::Hash';
with 'ETL::Pipeline::Output';


=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=head1 LICENSE

Copyright 2016 (c) Vanderbilt University

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;
__PACKAGE__->meta->make_immutable;
