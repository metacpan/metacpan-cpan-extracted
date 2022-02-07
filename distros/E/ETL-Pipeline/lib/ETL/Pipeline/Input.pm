=pod

=head1 NAME

ETL::Pipeline::Input - Role for ETL::Pipeline input sources

=head1 SYNOPSIS

  use Moose;
  with 'ETL::Pipeline::Input';

  sub run {
    # Add code to read your data here
    ...
  }

=head1 DESCRIPTION

An I<input source> feeds the B<extract> part of B<ETL>. This is where data comes
from. These are your data sources.

A data source may be anything - a file, a database, or maybe a socket. Each
I<format> is an L<ETL::Pipeline> input source. For example, Excel files
represent one input source. Perl reads every Excel file the same way. With a few
judicious attributes, we can re-use the same input source for just about any
type of Excel file.

L<ETL::Pipeline> defines an I<input source> as a Moose object with at least one
method - C<run>. This role basically defines the requirement for the B<run>
method. It should be consumed by B<all> input source classes. L<ETL::Pipeline>
relies on the input source having this role.

=head2 How do I create an I<input source>?

=over

=item 1. Start a new Perl module. I recommend putting it in the C<ETL::Pipeline::Input> namespace. L<ETL::Pipeline> will pick it up automatically.

=item 2. Make your module a L<Moose> class - C<use Moose;>.

=item 3. Consume this role - C<with 'ETL::Pipeline::Input';>.

=item 4. Write the L</run> method. L</run> follows this basic algorithmn...

=over

=item a. Open the source.

=item b. Loop reading the records. Each iteration should call L<ETL::Pipeline/record> to trigger the I<transform> step.

=item c. Close the source.

=back

=item 5. Add any attributes for your class.

=back

The new source is ready to use, like this...

  $etl->input( 'YourNewSource' );

You can leave off the leading B<ETL::Pipeline::Input::>.

When L<ETL::Pipeline> calls L</run>, it passes the L<ETL::Pipeline> object as
the only parameter.

=head2 Why this way?

Input sources mostly follow the basic algorithm of open, read, process, and
close. I originally had the role define methods for each of these steps. That
was a lot of work, and kind of confusing. This way, the input source only
I<needs> one code block that does all of these steps - in one place. So it's
easier to troubleshoot and write new sources.

In the work that I do, we have one output destination that rarely changes. It's
far more common to write new input sources - especially customized sources.
Making new sources easier saves time. Making it simpler means that more
developers can pick up those tasks.

=head2 Does B<ETL::Pipeline> only work with files?

No. B<ETL::Pipeline::Input> works for any source of data, such as SQL queries,
CSV files, or network sockets. Tailor the C<run> method for whatever suits your
needs.

Because files are most common, B<ETL::Pipeline> comes with a helpful role -
L<ETL::Pipeline::Input::File>. Consume L<ETL::Pipeline::Input::File> in your
inpiut source to access some standardized attributes.

=head2 Upgrading from older versions

L<ETL::Pipeline> version 3 is not compatible with input sources from older
versions. You will need to rewrite your custom input sources.

=over

=item Merge the C<setup>, C<finish>, and C<next_record> methods into L</run>.

=item Have L</run> call C<$etl->record> in place of C<next_record>.

=item Adjust attributes as necessary.

=back

=cut

package ETL::Pipeline::Input;

use 5.014000;
use warnings;

use Moose::Role;


our $VERSION = '3.00';


=head1 METHODS & ATTRIBUTES

=head3 path (optional)

If you define this, the standard logging will include it. The attribute is
named for file inputs. But it can return any value that is meaningful to your
users.

=head3 position (optional)

If you define this, the standard logging includes it with error or informational
messages. It can be any value that helps users locate the correct place to
troubleshoot.

=head3 run (required)

You define this method in the consuming class. It should open the file, read
each record, call L<ETL::Pipeline/record> after each record, and close the file.
This method is the workhorse. It defines the main ETL loop.
L<ETL::Pipeline/record> acts as a callback.

I say I<file>. It really means I<input source> - whatever that might be.

Some important things to remember about C<run>...

=over

=item C<run> receives one parameter - the L<ETL::Pipeline> object.

=item Should include all the code to open, read, and close the input source.

=item After reading a record, call L<ETL::Pipeline/record>.

=back

If your code encounters an error, B<run> can call L<ETL::Pipeline/status> with
the error message. L<ETL::Pipeline/status> should automatically include the
record count with the error message. You should add any other troubleshooting
information such as file names or key fields.

  $etl->status( "ERROR", "Error message here for id $id" );

For fatal errors, I recommend using the C<croak> command from L<Carp>.

=cut

requires 'run';


=head3 source

The location in the input source of the current record. For example, for files
this would be the file name and character position. The consuming class can set
this value in its L<run|ETL::Pipeline::Input/run> method.

L<Logging|ETL::Pipeline/log> uses this when displaying errors or informational
messages. The value should be something that helps the user troubleshoot issues.
It can be whatever is appropriate for the input source.

B<NOTE:> Don't capitalize the first letter, unless it's supposed to be.
L<Logging|ETL::Pipeline/log> will upper case the first letter if it's
appropriate.

=cut

has 'source' => (
	default => '',
	is      => 'rw',
	isa     => 'Str',
);


=head1 SEE ALSO

L<ETL::Pipeline>, L<ETL::Pipeline::Input::File>, L<ETL::Pipeline::Output>

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
