package EWS::Client::Contacts;
BEGIN {
  $EWS::Client::Contacts::VERSION = '1.143070';
}
use Moose;

with 'EWS::Contacts::Role::Reader';
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

# ABSTRACT: Contact Entries from Microsoft Exchange Server


__END__
=pod

=head1 NAME

EWS::Client::Contacts - Contact Entries from Microsoft Exchange Server

=head1 VERSION

version 1.143070

=head1 SYNOPSIS

First set up your Exchange Web Services client as per L<EWS::Client>:

 use EWS::Client;
 
 my $ews = EWS::Client->new({
     server      => 'exchangeserver.example.com',
     username    => 'oliver',
     password    => 's3krit', # or set in $ENV{EWS_PASS}
 });

Then retrieve the contact entries:

 my $entries = $ews->contacts->retrieve;
 print "I retrieved ". $entries->count ." items\n";
 
 while ($entries->has_next) {
     print $entries->next->DisplayName, "\n";
 }

=head1 DESCRIPTION

This module allows you to retrieve the set of contact entries for a user
on a Microsoft Exchange server. At present only read operations are supported.
The results are available in an iterator and convenience methods exist to
access the properties of each entry.

=head1 METHODS

=head2 CONSTRUCTOR

=head2 EWS::Client::Contacts->new( \%arguments )

You would not normally call this constructor. Use the L<EWS::Client>
constructor instead.

Instantiates a new contacts reader. Note that the action of performing a query
for a set of results is separated from this step, so you can perform multiple
queries using this same object. Pass the following arguments in a hash ref:

=over 4

=item C<client> => C<EWS::Client> object (required)

An instance of C<EWS::Client> which has been configured with your server
location, user credentials and SOAP APIs. This will be stored as a weak
reference.

=back

=head2 QUERY AND RESULT SET

=head2 $contacts->retrieve( \%arguments )

Query the Exchange server and retrieve contact entries. By default the
C<retrieve()> method will return contacts for the account under which you
authenticated to the Exchange server (that is, the credentials passed to the
L<EWS::Client> constructor). The following arguments will change this
behaviour:

=over 4

=item C<email> => String (optional)

Passing the primary SMTP address of another account will retrieve the contacts
for that Exchange user instead using the I<Delegation> feature, assuming you
have rights to see their contacts (i.e. the user has shared their contacts).
If you do not have rights, an error will be thrown.

If you pass one of the account's secondary SMTP addresses this module
I<should> be able to divine the primary SMTP address required.

=item C<impersonate> => String (optional)

Passing the primary SMTP address of another account will retrieve the contacts
for that Exchange user instead, assuming you have sufficient rights to
I<Impersonate> that account. If you do not have rights, an error will be
thrown.

=back

The returned object contains the collection of contact entries and is of type
C<EWS::Contacts::ResultSet>. It's an iterator, so you can walk through the
list of entries (see the synposis, above). For example:

 my $entries = $contacts->retrieve({email => 'nobody@example.com'});

=head2 $entries->next

Provides the next item in the collection of contact entries, or C<undef> if
there are no more items to return. Usually used in a loop along with
C<has_next> like so:

 while ($entries->has_next) {
     print $entries->next->DisplayName, "\n";
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
server query. They are each objects of type C<EWS::Contacts::Item>.

=head2 ITEM PROPERTIES

=head2 $item->DisplayName

The field you should use to describe this entry, being probably the person or
business's name.

=head2 $item->JobTitle

The Job Title field of the contact.

=head2 $item->CompanyName

The Comany Name field of the contact.

=head2 $item->BusinessHomePage

The Business Home Page field within the contact.

=head2 $item->PhoneNumbers

This property comprises all the phone numbers associated with the contact.

An Exchange contact has a number of fields for storing numbers of different
types, such as Mobile Phone, Business Line, and so on. Each of these may in
turn store a free text field so people often put multiple numbers in,
separated by a delimiter.

As a result of this freedom, this module makes no effort to interpret the
content of the number fields, only to retrieve them. It's assumed you are
familiar with your own number storage conventions, or can use a module such
as L<Number::Phone::Normalize> to parse the result.

In this property you'll find a hash ref of all this data, with keys being the
number types (Mobile Phone, etc), and values being array refs of I<data>. As
explained above, the data might be single numbers or free text with several
telephone numbers that you will need to parse yourself. For example:

 my $numbers = $entry->PhoneNumbers;
 
 foreach my $type (keys %{ $numbers }) {
 
     foreach my $extn (@{ $numbers->{$type} }) {
 
         print "$type : $extn \n";
     }
 }
 
 # might print something like:
 
 Mobile Phone : 73244
 Business Line : 88888

=head2 $item->EmailAddresses

This property comprises all the email addresses associated with the contact.

Similar to the C<PhoneNumbers> property, this is a hash ref of all data, with
keys being the email address type and values being array refs of I<data>.

See C<PhoneNumbers>, above for an example of how to process this property.

=head2 $item->PhysicalAddresses

This property comprises all the physical addresses associated with the
contact.

Again, like the C<PhoneNumbers> and C<EmailAddresses> properties, this is a
hash ref of array refs, where the hash keys are address identifiers, and the
values are lists of addresses.

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

