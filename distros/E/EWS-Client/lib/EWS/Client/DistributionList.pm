package EWS::Client::DistributionList;
BEGIN {
  $EWS::Client::DistributionList::VERSION = '1.143070';
}
use Moose;

with 'EWS::DistributionList::Role::Reader';

# could add future roles for updates, here

has client => (
    is       => 'ro',
    isa      => 'EWS::Client',
    required => 1,
    weak_ref => 1,
);

__PACKAGE__->meta->make_immutable;
no Moose;
1;

# ABSTRACT: Distribution List Entries from Microsoft Exchange Server



=pod

=head1 NAME

EWS::Client::DistributionList - Distribution List Entries from Microsoft Exchange Server

=head1 VERSION

version 1.143070

=head1 SYNOPSIS

First set up your Exchange Web Services client as per EWS::Client:

 use EWS::Client;

 my $ews = EWS::Client->new({
     server      => 'exchangeserver.example.com',
     username    => 'oliver',
     password    => 's3krit', # or set in $ENV{EWS_PASS}
 });

Then retrieve the distribution list entries:

 my $entries = $ews->distribution_list->retrieve( email => 'group@example.com');
 # OR
 $entries = $ews->distribution_list->expand('group@example.com');

 print "I retrieved ". $entries->count ." items\n";

 while ($entries->has_next) {
     print $entries->next->EmailAddress, "\n";
 }

=head1 DESCRIPTION

This module allows you to retrieve the set of Distribution List entries for an email address
on a Microsoft Exchange server. At present only read operations are supported.
The results are available in an iterator and convenience methods exist to
access the properties of each entry.

=head1 METHODS

=head2 CONSTRUCTOR

=head2 EWS::Client::DistributionList->new( \%arguments )

You would not normally call this constructor. Use the EWS::Client
constructor instead.

Instantiates a new distribution list reader. Note that the action of performing a query
for a set of results is separated from this step, so you can perform multiple
queries using this same object. Pass the following arguments in a hash ref:

=over 4

=item C<client> => C<EWS::Client> object (required)

An instance of C<EWS::Client> which has been configured with your server
location, user credentials and SOAP APIs. This will be stored as a weak
reference.

=back

=head2 QUERY AND RESULT SET

=head2 $distribution_list->retrieve( \%arguments )

Query the Exchange server and retrieve Mailbox members of the distribution list. Accepts the following arguments:

=over 4

=item C<distribution_email> => String (required)

Passing the primary SMTP address of a distribution list will retrieve the
members for that list, assuming it is public or you have right to see the
private list. If you do not have rights, an error will be thrown.

If you pass one of the account's secondary SMTP addresses this module
I<should> be able to divine the primary SMTP address required.

=item C<impersonate> => String (optional)

In addition to passing the 'distribution_email', passing the primary SMTP address of another account
will retrieve the requested private distribution list for the impersonated user. If you do not have
sufficient rights to I<Impersonate> that user, an error will be thrown.

By default the C<retrieve()> method will return distribution list members for
public distribution lists or private lists you have access to using the
account under which you authenticated to the Exchange server (that is, the credentials
passed to the EWS::Client constructor). This argument will change that
behaviour.

=back

The returned object contains the collection of distribution list members and is of type
C<EWS::DistributionList::ResultSet>. It's an iterator, so you can walk through the
list of entries (see the synposis, above). For example:

    my $entries = $distribution_list->retrieve({distribution_email => 'group@example.com'});

=head2 $distribution_list->expand( $string )

This is a convenience method for passing a just a distribution_email attribute:

    $distribution_list->expand('group@example.com');
    #is identical to:
    $distribution_list->retrieve({distribution_email => 'group@example.com'});

=head2 $entries->next

Provides the next mailbox in the collection of distribution list entries, or C<undef> if
there are no more mailboxes to return. Usually used in a loop along with
C<has_next> like so:

    while ($entries->has_next) {
        print $entries->next->Name, "\n";
    }

=head2 $entries->peek

Returns the next item without moving the state of the iterator forward. It
returns C<undef> if it is at the end of the collection and there are no more
mailboxes to return.

=head2 $entries->has_next

Returns a true value if there is another entry in the collection after the
current item, otherwise returns a false value.

=head2 $entries->reset

Resets the iterator's cursor, so you can walk through the entries again from
the start.

=head2 $entries->count

Returns the number of entries returned by the C<retrieve> server query.

=head2 $entries->mailboxes

Returns an array ref containing all the entries returned by the C<retrieve>
server query. They are each objects of type C<EWS::DistributionList::Mailbox>.

=head2 MAILBOX PROPERTIES

=head2 $mailbox->Name

Attribute contains the name of the mailbox user..

=head2 $mailbox->EmailAddress

Attribute contains the Simple Mail Transfer Protocol (SMTP) address of a mailbox user.

=head2 $mailbox->MailboxType

Attribute contains mailbox type of a mailbox user.

=head2 $mailbox->RoutingType

Attribute contains routing that is used for the mailbox. The default is SMTP.

=head1 SEE ALSO

=over 4

=item * L<http://msdn.microsoft.com/en-us/library/aa580675.aspx>

=back

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>
John Judd <jjudd@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by University of Oxford.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by University of Oxford.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut


__END__

