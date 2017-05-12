package EWS::Client::Calendar;
BEGIN {
  $EWS::Client::Calendar::VERSION = '1.143070';
}
use Moose;

with 'EWS::Calendar::Role::Reader';
# could add future roles for updates, here

has client => (
    is => 'ro',
    isa => 'EWS::Client',
    required => 1,
    weak_ref => 1,
);

__PACKAGE__->meta->make_immutable;
no Moose;
1;

# ABSTRACT: Calendar Entries from Microsoft Exchange Server


__END__
=pod

=head1 NAME

EWS::Client::Calendar - Calendar Entries from Microsoft Exchange Server

=head1 VERSION

version 1.143070

=head1 SYNOPSIS

First set up your Exchange Web Services client as per L<EWS::Client>:

 use EWS::Client;
 use DateTime;
 
 my $ews = EWS::Client->new({
     server      => 'exchangeserver.example.com',
     username    => 'oliver',
     password    => 's3krit', # or set in $ENV{EWS_PASS}
 });

Then perform operations on the calendar entries:

 my $entries = $ews->calendar->retrieve({
     start => DateTime->now(),
     end   => DateTime->now->add( months => 1 ),
 });
 
 print "I retrieved ". $entries->count ." items\n";
 
 while ($entries->has_next) {
     print $entries->next->Subject, "\n";
 }

=head1 DESCRIPTION

This module allows you to perform operations on the calendar entries in a
Microsoft Exchange server. At present only read operations are supported,
allowing you to retrieve calendar entries within a given time window. The
results are available in an iterator and convenience methods exist to access
the properties of each entry.

=head1 METHODS

=head2 CONSTRUCTOR

=head2 EWS::Client::Calendar->new( \%arguments )

You would not normally call this constructor. Use the L<EWS::Client>
constructor instead.

Instantiates a new calendar reader. Note that the action of performing a query
for a set of results is separated from this step, so you can perform multiple
queries using this same object. Pass the following arguments in a hash ref:

=over 4

=item C<client> => C<EWS::Client> object (required)

An instance of C<EWS::Client> which has been configured with your server
location, user credentials and SOAP APIs. This will be stored as a weak
reference.

=back

=head2 QUERY AND RESULT SET

=head2 $cal->retrieve( \%arguments )

Query the Exchange server and retrieve calendar entries between the given
timestamps. Pass the following arguments in a hash ref:

=over 4

=item C<start> => DateTime object (required)

Entries with an end date on or after this timestamp will be included in the
returned results.

=item C<end> => DateTime object (required)

Entries with a start date before this timestamp will be included in the
results.

=item C<email> => String (optional)

Passing the primary SMTP address of another account will retrieve the contacts
for that Exchange user instead using the I<Delegation> feature, assuming you
have rights to see their contacts (i.e. the user has shared their contacts).
If you do not have rights, an error will be thrown.

If you pass one of the account's secondary SMTP addresses this module
I<should> be able to divine the primary SMTP address required.

=item C<impersonate> => String (optional)

Passing the primary SMTP address of another account will retrieve the entries
for that Exchange user instead, assuming you have sufficient rights to
I<Impersonate> that account. If you do not have rights, an error will be
thrown.

=back

The returned object contains the collection of calendar entries which matched
the start and end criteria, and is of type C<EWS::Calendar::ResultSet>. It's
an iterator, so you can walk through the list of entries (see the synposis,
above). For example:

 my $entries = $cal->retrieve({start => '', end => ''});

=head2 $entries->next

Provides the next item in the collection of calendar entries, or C<undef> if
there are no more items to return. Usually used in a loop along with
C<has_next> like so:

 while ($entries->has_next) {
     print $entries->next->Subject, "\n";
 }

=head2 $entries->peek

Returns the next item without moving the state of the iterator forward. It
returns C<undef> if it is at the end of the collection and there are no more
items to return.

=head2 $entries->has_next

Returns a true value if there is another entry in the collection after the
current item, otherwise returns a false value.

=head2 $entries->reset

Resets the iterator's cursor, so you can walk through the entries again from
the start.

=head2 $entries->count

Returns the number of entries returned by the C<retrieve> server query.

=head2 $entries->items

Returns an array ref containing all the entries returned by the C<retrieve>
server query. They are each objects of type C<EWS::Calendar::Item>.

=head2 ITEM PROPERTIES

These descriptions are taken from Microsoft's on-line documentation.

=head2 $item->Start

A L<DateTime> object representing the starting date and time for a calendar
item.

=head2 $item->End

A L<DateTime> object representing the ending date and time for a calendar
item.

=head2 $item->TimeSpan

A human readable description of the time span of the event, for example:

=over 4

=item * 25 Feb 2010

=item * Feb 16 - 19, 2010

=item * 24 Feb 2010 15:00 - 16:00

=back

=head2 $item->Subject

Represents the subject of a calendar item.

=head2 $item->Body (optional)

Text attachment to the calendar entry which the user may have entered content
into.

=head2 $item->has_Body

Will return true if the event item has content in its Body property, otherwise
returns false. Actually returns the length of the Body text content.

=head2 $item->Location (optional)

Friendly name for where a calendar item pertains to (e.g., a physical address
or "My Office").

=head2 $item->has_Location

Will return true if the event item has content in its Location property,
otherwise returns false. Actually returns the length of the Location text
content.

=head2 $item->Type

The type of calendar item indicating its relationship to a recurrence, if any.
This will be a string value of one of the following, only:

=over 4

=item * Single

=item * Occurrence

=item * Exception

=back

=head2 $item->CalendarItemType

This is an alias (the native name, in fact) for the C<< $item->Type >>
property.

=head2 $item->IsRecurring

True if the event is of Type Occurrence or Exception, which means that it is
a recurring event, otherwise returns false.

=head2 $item->Sensitivity

Indicates the sensitivity of the item, which can be used to filter information
your user sees. Will be a string and one of the following four values, only:

=over 4

=item * Normal

=item * Personal

=item * Private

=item * Confidential

=back

=head2 $item->DisplayTo (optional)

When a client creates a calendar entry, there can be other people invited to
the event (usually via the To: box in Outlook, or similar). This property
contains an array ref of the display names ("Firstname Lastname") or the
parties invited to the event.

=head2 $item->has_DisplayTo

Will return true if there are entries in the C<< $item->DisplayTo >> property,
in other words there were invitees on this event, otherwise returns false.
Actually returns the number of entries in that list, which may be useful.

=head2 $item->Organizer

The display name (probably "Firstname Lastname") of the party responsible for
creating the entry.

=head2 $item->IsCancelled

True if the calendar item has been cancelled, otherwise false.

=head2 $item->AppointmentState

Contains a bitmask of flags on the entry, but you probably want to use
C<IsCancelled> instead.

=head2 $item->Status (optional)

Free/busy status for a calendar item, which can actually be one of the
following four string values:

=over 4

=item * Free

=item * Tentative

=item * Busy

=item * OOF (means Out Of Office)

=item * NoData (means something went wrong)

=back

If not provided the property will default to C<NoData>.

=head2 $item->LegacyFreeBusyStatus (optional)

This is an alias (the native name, in fact) for the C<< $item->Status >>
property.

=head2 $item->IsDraft

Indicates whether an item has not yet been sent.

=head2 $item->IsAllDayEvent

True if a calendar item is to be interpreted as lasting all day, otherwise
false.

=head1 TODO

There is currently no handling of time zone information whatsoever. I'm
waiting for my timezone to shift to UTC+1 in March before working on this, as
I don't really want to read the Exchange API docs. Patches are welcome if you
want to help out.

=head1 SEE ALSO

=over 4

=item * L<http://msdn.microsoft.com/en-us/library/aa580675.aspx>

=back

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by University of Oxford.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

