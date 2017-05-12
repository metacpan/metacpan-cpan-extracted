package EWS::DistributionList::Role::Reader;
BEGIN {
  $EWS::DistributionList::Role::Reader::VERSION = '1.143070';
}
use Moose::Role;

use EWS::DistributionList::ResultSet;
use Carp;

sub _list_messages {
    my ( $self, $kind, $response ) = @_;
    return @{ $response->{"${kind}Result"}->{ResponseMessages}->{cho_CreateItemResponseMessage} };
}

sub _check_for_errors {
    my ( $self, $kind, $response ) = @_;

    foreach my $msg ( $self->_list_messages( $kind, $response ) ) {
        my $code = $msg->{"${kind}ResponseMessage"}->{ResponseCode} || '';
        croak "Fault returned from Exchange Server: $code\n"
            if $code ne 'NoError';
    }
    return;
}

sub _list_dlitems {
    my ( $self, $kind, $response ) = @_;

    return map { @{ $_->{DLExpansion}->{Mailbox} || [] } }
        map { $_->{"${kind}ResponseMessage"} } $self->_list_messages( $kind, $response );
}

sub _get_dls {
    my ( $self, $opts ) = @_;

    return $self->client->ExpandDL->(
        (   exists $opts->{impersonate}
            ? ( Impersonation => { ConnectingSID => { PrimarySmtpAddress => $opts->{impersonate}, } }, )
            : ()
        ),
        RequestVersion => { Version      => $self->client->server_version, },
        Mailbox        => { EmailAddress => $opts->{distribution_email}, },
    );
}

# find primarysmtp if passed an account id.
# then find dls in the account.
sub retrieve {
    my ( $self, $opts ) = @_;

    my $get_response = $self->_get_dls($opts);

    if (    exists $get_response->{'ResponseCode'}
        and defined $get_response->{'ResponseCode'}
        and $get_response->{'ResponseCode'} eq 'ErrorNonPrimarySmtpAddress' )
    {

        $self->retrieve( { %{$opts}, distribution_email => $get_response->{DLExpansion}->{Mailbox} } );
    }

    $self->_check_for_errors( 'ExpandDL', $get_response );

    return EWS::DistributionList::ResultSet->new(
        { mailboxes => [ $self->_list_dlitems( 'ExpandDL', $get_response ) ] } );
}

sub expand {
    return shift->retrieve( { distribution_email => shift } );
}

no Moose::Role;
1;
