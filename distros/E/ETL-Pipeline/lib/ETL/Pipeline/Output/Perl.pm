=pod

=head1 NAME

ETL::Pipeline::Output::Perl - Execute arbitrary Perl code against every record

=head1 SYNOPSIS

  use ETL::Pipeline;
  ETL::Pipeline->new( {
    input   => ['UnitTest'],
    mapping => {First => 'Header1', Second => 'Header2'},
    output  => ['Perl', code => sub { say $_->{First} }]
  } )->process;

=head1 DESCRIPTION

B<ETL::Pipeline::Output::Perl> runs arbitrary Perl code for every record. It
comes in useful when debugging data issues or prototyping a new technique.

B<ETL::Pipeline::Output::Perl> stores the record in a hash (see L</current>).
The class passes that hash reference into your subroutine.

=cut

package ETL::Pipeline::Output::Perl;
use Moose;

use 5.14.0;
use warnings;

use Carp;
use String::Util qw/hascontent/;


our $VERSION = '2.00';


=head1 METHODS & ATTRIBUTES

=head2 Arguments for L<ETL::Pipeline/output>

=head3 code

Assign this attribute your code reference. Your code receives two parameters.
The first one is the L<ETL::Pipeline> object. The second is the hash reference
with the data record.

The code reference can do anything. It should return a boolean. B<True> means
success and B<false> means failure. You determine what I<success> or I<failure>
really means.

B<WARNING:> Do not save the hash reference. Make a copy of the hash instead.
B<ETL::Pipeline::Output::Perl> re-uses the same hash reference. The second
record will overwrite the first, etc.

=cut

has 'code' => (
	is       => 'ro',
	isa      => 'CodeRef',
	required => 1,
);


=head2 Called from L<ETL::Pipeline/process>

=head3 write_record

Passes the subroutine in L</code> to L<ETL::Pipeline/execute_code_ref>.
L</current> is passed to the subroutine as a parameter.

=cut

sub write_record {
	my $self = shift;
	return $self->pipeline->execute_code_ref( $self->code, $self->current );
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


=head2 Other methods and attributes

=head3 default_fields

Initialize L</current> for the next record.

=cut

sub default_fields { () }


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Output>, 
L<ETL::Pipeline::Output::Storage::Hash>

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
