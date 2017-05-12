package EWS::Client;
BEGIN {
  $EWS::Client::VERSION = '1.300000';
}
use Moose;

with qw/
    EWS::Client::Role::SOAP
    EWS::Client::Role::GetItem
    EWS::Client::Role::FindItem
    EWS::Client::Role::FindFolder
    EWS::Client::Role::GetFolder
    EWS::Client::Role::ExpandDL
    EWS::Client::Role::GetUserAvailability
    EWS::Client::Role::ResolveNames
/;
use EWS::Client::Contacts;
use EWS::Client::Calendar;
use EWS::Client::Folder;
use EWS::Client::DistributionList;
use URI::Escape ();
use Log::Report;

has username => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has password => (
    is => 'rw',
    isa => 'Str',
    required => 1,
);

has server => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has contacts => (
    is => 'ro',
    isa => 'EWS::Client::Contacts',
    lazy_build => 1,
);

sub _build_contacts {
    my $self = shift;
    return EWS::Client::Contacts->new({ client => $self });
}

has calendar => (
    is => 'ro',
    isa => 'EWS::Client::Calendar',
    lazy_build => 1,
);

sub _build_calendar {
    my $self = shift;
    return EWS::Client::Calendar->new({ client => $self });
}

has folders => (
    is => 'ro',
    isa => 'EWS::Client::Folder',
    lazy_build => 1,
);

sub _build_folders {
    my $self = shift;
    return EWS::Client::Folder->new({ client => $self });
}

has distribution_list => (
    is => 'ro',
    isa => 'EWS::Client::DistributionList',
    lazy_build => 1,
);

sub _build_distribution_list {
    my $self = shift;
    return EWS::Client::DistributionList->new({ client => $self });
}

sub BUILDARGS {
    my ($class, @rest) = @_;
    my $params = (scalar @rest == 1 ? $rest[0] : {@rest});

    # collect EWS password from environment as last resort
    $params->{password} ||= $ENV{EWS_PASS};

    return $params;
}

sub BUILD {
    my ($self, $params) = @_;

    if ($self->use_negotiated_auth) {
        die "please install LWP::Authen::Ntlm"
            unless eval { require LWP::Authen::Ntlm && $LWP::Authen::Ntlm::VERSION };
        die "please install Authen::NTLM"
            unless eval { require Authen::NTLM && $Authen::NTLM::VERSION };

        # change email style username to win-domain style
        if ($self->username =~ m/(.+)@(.+)/) {
            $self->username( $2 .'\\'. $1 );
        }
    }
    else {
        # URI escape the username and password
        $self->password( URI::Escape::uri_escape($self->password) );
        $self->username( URI::Escape::uri_escape($self->username) );
    }
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

=head1 NAME

EWS::Client - Microsoft Exchange Web Services Client

=head1 SYNOPSIS

Set up your Exchange Web Services client.

 use EWS::Client;
 use DateTime;
 
 my $ews = EWS::Client->new({
     server      => 'exchangeserver.example.com',
     username    => 'oliver',
     password    => 's3krit', # or set in $ENV{EWS_PASS}
 });

Then perform operations on the Exchange server:

 my $entries = $ews->calendar->retrieve({
     start => DateTime->now(),
     end   => DateTime->now->add( months => 1 ),
 });
 
 print "I retrieved ". $entries->count ." items\n";
 
 while ($entries->has_next) {
     print $entries->next->Subject, "\n";
 }
 
 my $contacts = $ews->contacts->retrieve;

=head1 DESCRIPTION

This module acts as a client to the Microsoft Exchange Web Services API. From
here you can access calendar and contact entries in a nicely abstracted
fashion. Query results are generally available in an iterator and convenience
methods exist to access the properties of each entry.

=head1 AUTHENTICATION

Depending on the configuration of the Microsoft Exchange server, you can use
either HTTP Basic Access Auth, or NTLM Negotiated Auth, from this module. The
default is HTTP Basic Access Auth, so if using NTLM, the following additional
option to C<new()> is required:

 use_negotiated_auth => 1,

=head1 METHODS

=head2 EWS::Client->new( \%arguments )

Instantiates a new EWS client. There won't be any connection to the server
until you call one of the calendar or contacts retrieval methods.

=over 4

=item C<server> => Fully Qualified Domain Name (required)

The host name of the Exchange server to which the module should connect.

=item C<username> => String (required)

The account username under which the module will connect to Exchange.

For Basic Access Auth this value will be URI encoded by the module, meaning
you don't have to worry about escaping any special characters. For NTLM
Negotiated Auth, pass a C<user@domain> format username and it will
automatically be converted into Windows' C<domain\user> format for you.

=item C<password> => String OR via C<$ENV{EWS_PASS}> (required)

The password of the account under which the module will connect to Exchange.

For Basic Access Auth this value will be URI encoded by the module. You can
also provide the password via the C<EWS_PASS> environment variable.

=item C<use_negotiated_auth> => True or False value

The module will assume you wish to use HTTP Basic Access Auth, in which case
you should enable that in your Exchange server. However for negotiated methods
such as NTLM set this to a True value.

=item C<schema_path> => String (optional)

A folder on your file system which contains the WSDL and two further Schema
files (messages, and types) which describe the Exchange 2007 Web Services SOAP
API. They are shipped with this module so your providing this is optional.

=item C<server_version> => String (optional)

In each request to the server is specified the API version we expect to use.
By default this is set to C<Exchange2007_SP1> but you have the opportunity to
set it to C<Exchange2007> if you wish using this option.

=back

=head2 $ews->calendar()

Retrieves the L<EWS::Client::Calendar> object which allows search and
retrieval of calendar entries and their various properties. See that linked
manual page for more details.

=head2 $ews->contacts()

Retrieves the L<EWS::Client::Contacts> object which allows retrieval of
contact entries and their telephone numbers. See that linked manual page for
more details.

=head2 $ews->folders()

Retrieves the L<EWS::Client::Folder> object which allows retrieval of
mailbox folder entries and their sizes. See that linked manual page for
more details.

=head2 $ews->dls()

Retrieves the L<EWS::Client::DistributionList> object which allows retrieval of
distribution list entries and their email addresses and names. See that linked
manual page for more details.

=head1 KNOWN ISSUES

=over 4

=item * No handling of time zone information, sorry.

=item * The C<SOAPAction> Header might be wrong for Exchange 2010.

=back

=head1 THANKS

To Greg Shaw for sending patches for NTLM Authentication support and User
Impersonation.

=head1 AUTHOR

Oliver Gorwits <oliver@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by University of Oxford.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

