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

Your code receives two parameters - the L<ETL::Pipeline> object and the current
record. These are the same arguments passed to L</write>. The current record is
a Perl hash reference.

=cut

package ETL::Pipeline::Output::Perl;

use 5.014000;
use warnings;

use Moose;


our $VERSION = '3.00';


=head1 METHODS & ATTRIBUTES

=head2 Arguments for L<ETL::Pipeline/output>

=head3 code

Required. Assign a code reference to this attribute. The code receives two
parameters. The first one is the L<ETL::Pipeline> object. The second is a hash
reference with the current record.

The code reference can do anything you want. If you need setup or shut down,
then create a L<custom output destination|ETL::Pipeline::Output> instead.

=cut

has 'code' => (
	is       => 'ro',
	isa      => 'CodeRef',
	required => 1,
);

=head2 Methods

=head3 close

This method doesn't do anything. There's nothing to close or shut down.

=cut

sub close {}


=head3 open

This method doesn't do anything. There's nothing to open or setup.

=cut

sub open {}


=head3 write

Executes the subroutine in L</code>. The arguments are passed directly into the
subroutine.

=cut

sub write { return shift->code->( @_ ); }


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Output>

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
