package EWS::Contacts::Role::Reader;
BEGIN {
  $EWS::Contacts::Role::Reader::VERSION = '1.143070';
}
use Moose::Role;

use EWS::Contacts::ResultSet;
use Carp;

sub _list_messages {
    my ($self, $kind, $response) = @_;
    return @{ $response->{"${kind}Result"}
                       ->{ResponseMessages}
                       ->{cho_CreateItemResponseMessage} };
}

sub _check_for_errors {
    my ($self, $kind, $response) = @_;

    foreach my $msg ( $self->_list_messages($kind, $response) ) {
        my $code = $msg->{"${kind}ResponseMessage"}->{ResponseCode} || '';
        croak "Fault returned from Exchange Server: $code\n"
            if $code ne 'NoError';
    }
}

sub _list_contactitems {
    my ($self, $kind, $response) = @_;

    if($kind eq 'ResolveNames'){
        return map { $_->{Contact} }
               grep { defined $_->{'Contact'}->{'DisplayName'} and length $_->{'Contact'}->{'DisplayName'} }
               map { @{ $_->{Resolution} } }
               map { $_->{ResolutionSet} }
               map { $_->{ResolveNamesResponseMessage} }
                   $self->_list_messages($kind, $response);
    }
    else {
        return map  { $_->{Contact} }
               grep { defined $_->{'Contact'}->{'DisplayName'} and length $_->{'Contact'}->{'DisplayName'} }
               map  { @{ $_->{Items}->{cho_Item} || [] } }
               map  { exists $_->{RootFolder} ? $_->{RootFolder} : $_ } 
               map  { $_->{"${kind}ResponseMessage"} }
                    $self->_list_messages($kind, $response);
    }
}

sub _get_contacts {
    my ($self, $opts) = @_;

    return scalar $self->client->FindItem->(
        (exists $opts->{impersonate} ? (
            Impersonation => {
                ConnectingSID => {
                    PrimarySmtpAddress => $opts->{impersonate},
                }
            },
        ) : ()),
        RequestVersion => {
            Version => $self->client->server_version,
        },
        ItemShape => { BaseShape => 'AllProperties' },
        ParentFolderIds => {
            cho_FolderId => [
                { DistinguishedFolderId =>
                    {
                        Id => 'contacts',
                        (exists $opts->{email} ? (
                            Mailbox => {
                                EmailAddress => $opts->{email},
                            },
                        ) : ()), # optional
                    }
                }
            ]
        },
        Traversal => 'Shallow',
    );
}

# find primarysmtp if passed an account id.
# then find contacts in the account.
sub retrieve {
    my ($self, $opts) = @_;

    my $get_response = $self->_get_contacts($opts);

    if (exists $get_response->{'ResponseCode'} and defined $get_response->{'ResponseCode'}
        and $get_response->{'ResponseCode'} eq 'ErrorNonPrimarySmtpAddress') {

        $self->retrieve({
            %$opts,
            email => $get_response->{'MessageXml'}->{'Value'}->{'_'},
        });
    }

    $self->_check_for_errors('FindItem', $get_response);

    return EWS::Contacts::ResultSet->new({
        items => [ $self->_list_contactitems('FindItem', $get_response) ]
    });
}

sub _get_resolvenames {
    my ($self, $opts) = @_;

    return scalar $self->client->ResolveNames->(
        (exists $opts->{impersonate} ? (
            Impersonation => {
                ConnectingSID => {
                    PrimarySmtpAddress => $opts->{impersonate},
                }
            },
        ) : ()),
        RequestVersion => {
            Version => $self->client->server_version,
        },
        ReturnFullContactData => 'true',
        UnresolvedEntry => $opts->{unresolved_entry}
    );
}

sub retrieve_gal {
    my ($self, $opts) = @_;

    my $get_response = $self->_get_resolvenames($opts);

    return EWS::Contacts::ResultSet->new({
            items => [ $self->_list_contactitems('ResolveNames', $get_response) ]
    });
}

no Moose::Role;
1;
