=pod

=head1 NAME

ETL::Pipeline::Output - Role for ETL::Pipeline output destinations

=head1 SYNOPSIS

  use Moose;
  with 'ETL::Pipeline::Output';

  sub write_record {
    # Add code to save your data here
    ...
  }

=head1 DESCRIPTION

L<ETL::Pipeline> reads data from an input source, transforms it, and writes
the information to an output destination. This role defines the required
methods and attributes for output destinations. Every output destination
B<must> implement B<ETL::Pipeline::Output>.

L<ETL::Pipeline> works by calling the methods defined in this role. The role
presents a common interface. It works as a shim, tying database or file access
modules with L<ETL::Pipeline>. For example, SQL databases may use L<DBI> or
L<DBIx::Class>.

=head2 Adding a new output destination

While L<ETL::Pipeline> provides a couple generic output destinations, the real
value of L<ETL::Pipeline> comes from adding your own, business specific,
destinations...

=over

=item 1. Create a Perl module. Name it C<ETL::Pipeline::Output::...>.

=item 2. Make it a Moose object: C<use Moose;>.

=item 3. Include the role: C<with 'ETL::Pipeline::Output';>.

=item 4. Add the L</write_record> method: C<sub write_record { ... }>.

=item 5. Add the L</set> method: C<sub set { ... }>.

=item 6. Add the L</new_record> method: C<sub new_record { ... }>.

=item 7. Add the L</configure> method: C<sub configure { ... }>.

=item 8. Add the L</finish> method: C<sub finish { ... }>.

=back

Ta-da! Your output destination is ready to use:

  $etl->output( 'YourNewDestination' );

=head2 Provided out of the box

L<ETL::Pipeline> comes with a couple of generic output destinations...

=over

=item L<ETL::Pipeline::Output::Hash>

Stores records in a Perl hash. Useful for loading support files and tying
them together later.

=item L<ETL::Pipeline::Output::Perl>

Executes a subroutine against the record. Useful for debugging data issues.

=back

=cut

package ETL::Pipeline::Output;
use Moose::Role;


our $VERSION = '2.00';


=head1 METHODS & ATTRIBUTES

=head3 pipeline

B<pipeline> returns the L<ETL::Pipeline> object using this input source. You
can access information about the pipeline inside the methods.

L<ETL::Pipeline/input> automatically sets this attribute.

=cut

has 'pipeline' => (
	is       => 'ro',
	isa      => 'ETL::Pipeline',
	required => 1,
);


=head2 Arguments for L<ETL::Pipeline/output>

B<Note:> This role defines no attributes that are set with the
L<ETL::Pipeline/output> command. Each child class defines its own options.

=head2 Called from L<ETL::Pipeline/process>

=head3 set

B<set> temporarily saves the value of an individual output field.
L</write_record> will later copy these values to the correct destination.

L<ETL::Pipeline/process> calls B<set> inside of a loop - once for each field.
B<set> accepts two parameters:

=over

=item 1. The output field name.

=item 2. The value for that field.

=back

There is no return value.

=head4 Couldn't you just use a hash?

B<set> allows your output destination to choose the in-memory storage that
best fits. This might be a hash, a list, or an object of some type. B<set>
merely provides a common interface for L<ETL::Pipeline>.

=cut

requires 'set';


=head3 write_record

B<write_record> sends the current record to its final destination.
L<ETL::Pipeline/process> calls this method once for each record.
B<write_record> is the I<last> thing done with this record.

B<write_record> returns a boolean flag. A I<true> value means success saving
the record. A I<false> value indicates an error.

When your code encounters an error, call the L</error> method like this...

  return $self->error( 'Error message here' );

L</error> returns a false value. The default L</error> does nothing. To save
errors, override L</error> and add the new functionality. When overriding
L</error>, it is not necessary to return anything. B<ETL::Pipeline::Output>
ensures that L</error> I<always> returns false.

For fatal errors, use the C<croak> command from L<Carp> instead.

=cut

requires 'write_record';


=head3 new_record

Start a brand new, clean record. L</write_record> automatically calls
B<new_record>, every time, after L</write_record> finishes. This means that
even if the save failed, L</write_record> still calls B<new_record>. The
original record with the error is lost.

=cut

requires 'new_record';

after 'configure'    => sub { shift->new_record };
after 'write_record' => sub { shift->new_record };


=head3 configure

B<configure> prepares the output destination. It can open files, make database
connections, or anything else required before saving the first record.

Why not do this in the class constructor? Some roles add automatic
configuration. Those roles use the usual Moose method modifiers, which would
not work with the constructor.

This B<configure> - for the output destination - is called I<after> the
L<ETL::Pipeline::Input/configure> of the input source. This method can expect
that the input source is fully configured and ready for use.

=cut

requires 'configure';


=head3 finish

B<finish> shuts down the output destination. It can close files, disconnect
from the database, or anything else required to cleanly terminate the output.

Why not do this in the class destructor? Some roles add automatic functionality
via Moose method modifiers. This would not work with a destructor.

This B<finish> - for the output destination - is called I<before> the
L<ETL::Pipeline::Input/finish> of the input source. This method should expect
that the input source has reached end-of-file by this point, but is not
closed yet.

=cut

requires 'finish';


=head2 Other methods and attributes

=head3 record_number

The B<record_number> attribute tells you how many total records have been
saved by L</write_record>. The first record is always B<1>.

B<ETL::Pipeline::Output> automatically increments the counter after
L</write_record>. The L</write_record> method should not change
B<record_number>.

=head3 decrement_record_number

This method decreases L</record_number> by one. It can be used to I<back out>
header records from the count.

=head3 increment_record_number

This method increases L</record_number> by one.

=cut

has 'record_number' => (
	default => '0',
	handles => {
		decrement_record_number => 'dec',
		increment_record_number => 'inc',
	},
	is      => 'ro',
	isa     => 'Int',
	traits  => [qw/Counter/],
);

around 'write_record' => sub {
	my $original = shift;
	my $self     = shift;

	my $result = $self->$original( @_ );
	$self->increment_record_number if $result;
	return $result;
};


=head3 error

B<error> handles errors from L</write_record>. The default B<error> discards
any error messages. Override B<error> if you want to capture the messages
and/or the record that caused it.

B<error> I<always> returns a false value - even if you override it.

=cut

sub error {}

around 'error' => sub {
	my $original = shift;
	my $self     = shift;

	$self->$original( @_ );
	return 0;
};


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Input>, L<ETL::Pipeline::Output::Hash>,
L<ETL::Pipeline::Output::Perl>, L<ETL::Pipeline::Output::UnitTest>

=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vanderbilt.edu>

=head1 LICENSE

Copyright 2016 (c) Vanderbilt University

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;

# Required by Perl to load the module.
1;
