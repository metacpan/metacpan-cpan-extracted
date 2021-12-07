=pod

=head1 NAME

ETL::Pipeline::Output - Role for ETL::Pipeline output destinations

=head1 SYNOPSIS

  use Moose;
  with 'ETL::Pipeline::Output';

  sub open {
    # Add code to open the output destination
    ...
  }
  sub write {
    # Add code to save your data here
    ...
  }
  sub close {
    # Add code to close the destination
    ...
  }

=head1 DESCRIPTION

An I<output destination> fulfills the B<load> part of B<ETL>. This is where the
data ends up. These are the outputs of the process.

A destination can be anything - database, file, or anything. Destinations are
customized to your environment. And you will probably only have a few.

L<ETL::Pipeline> interacts with the output destination is 3 stages...

=over

=item 1. Open - connect to the database, open the file, whatever setup is appropriate for your destination.

=item 2. Write - called once per record. This is the part that actually performs the output.

=item 3. Close - finished processing and cleanly shut down the destination.

=back

This role sets the requirements for these 3 methods. It should be consumed by
B<all> output destination classes. L<ETL::Pipeline> relies on the destination
having this role.

=head2 How do I create an output destination?

L<ETL::Pipeline> provides a couple generic output destinations as exmaples or
for very simple uses. The real value of L<ETL::Pipeline> comes from adding your
own, business specific, destinations...

=over

=item 1. Start a new Perl module. I recommend putting it in the C<ETL::Pipeline::Output> namespace. L<ETL::Pipeline> will pick it up automatically.

=item 2. Make your module a L<Moose> class - C<use Moose;>.

=item 3. Consume this role - C<with 'ETL::Pipeline::Output';>.

=item 4. Write the L</open>, L</close>, and L</write> methods.

=item 5. Add any attributes for your class.

=back

The new destination is ready to use, like this...

  $etl->output( 'YourNewDestination' );

You can leave off the leading B<ETL::Pipeline::Output::>.

When L<ETL::Pipeline> calls L</open> or L</close>, it passes the
L<ETL::Pipeline> object as the only parameter. When L<ETL::Pipeline> calls
L</write>, it passed two parameters - the L<ETL::Pipeline> object and the
record. The record is a Perl hash.

=head2 Example destinations

L<ETL::Pipeline> comes with a couple of generic output destinations...

=over

=item L<ETL::Pipeline::Output::Hash>

Stores records in a Perl hash. Useful for loading support files and tying
them together later.

=item L<ETL::Pipeline::Output::Perl>

Executes a subroutine against the record. Useful for debugging data issues.

=back

=head2 Why this way?

My work involves a small number of destinations that rarely change and a greater
number of sources that do change. So I designed L<ETL::Pipeline> to minimize
time writing new input sources. The trade off was slightly more complex output
destinations.

=head2 Upgrading from older versions

L<ETL::Pipeline> version 3 is not compatible with output destinations from older
versions. You will need to rewrite your custom output destinations.

=over

=item Change the C<configure> to L</open>.

=item Change C<finish> to L</close>.

=item Change C<write_record> to L</write>.

=item Remove C<set> and C<new_record>. All records are Perl hashes.

=item Adjust attributes as necessary.

=back

=cut

package ETL::Pipeline::Output;

use 5.014000;
use warnings;

use Moose::Role;


our $VERSION = '3.00';


=head1 METHODS & ATTRIBUTES

=head3 close

Shut down the ouput destination. This method may close files, disconnect from
the database, or anything else required to cleanly terminate the output.

B<close> receives one parameter - the L<ETL::Pipeline> object.

The output destination is closed B<after> the input source, at the end of the
B<ETL> process.

=cut

requires 'close';


=head3 open

Prepare the output destination for use. It can open files, make database
connections, or anything else required to access the destination.

B<open> receives one parameter - the L<ETL::Pipeline> object.

The output destination is opened B<before> the input source, at the beginning
of the B<ETL> process.

=cut

requires 'open';


=head3 write

Send a single record to the destination. The ETL process calls this method in a
loop. It receives two parameters - the L<ETL::Pipeline> object, and the current
record as a Perl hash.

If your code encounters an error, B<write> can call L<ETL::Pipeline/error> with
the error message. L<ETL::Pipeline/error> automatically includes the record
count with the error message. You should add any other troubleshooting
information such as file names or key fields.

  sub write {
    my ($self, $etl, $record) = @_;
    my $id = $record->{ID};
    $etl->error( "Error message here for id $id" );
  }

For fatal errors, I recommend using the C<croak> command from L<Carp>.

=cut

requires 'write';


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Input>, L<ETL::Pipeline::Output::Hash>,
L<ETL::Pipeline::Output::Perl>, L<ETL::Pipeline::Output::UnitTest>

=head1 AUTHOR

Robert Wohlfarth <robert.j.wohlfarth@vumc.org>

=head1 LICENSE

Copyright 2021 (c) Vanderbilt University

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

no Moose;

# Required by Perl to load the module.
1;
