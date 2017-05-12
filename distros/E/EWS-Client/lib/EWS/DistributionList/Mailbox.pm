package EWS::DistributionList::Mailbox;
BEGIN {
  $EWS::DistributionList::Mailbox::VERSION = '1.143070';
}
use Moose;
use Encode;

has Name => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has EmailAddress => (
    is       => 'ro',
    isa      => 'Str',
    required => 1,
);

has MailboxType => (
    is  => 'ro',
    isa => 'Str',
);

has RoutingType => (
    is  => 'ro',
    isa => 'Str',
);

sub BUILDARGS {
    my ( $class, @rest ) = @_;
    my $params = ( scalar @rest == 1 ? $rest[0] : {@rest} );

    foreach my $key ( keys %{$params} ) {
        if ( not ref $params->{$key} ) {
            $params->{$key} = Encode::encode( 'utf8', $params->{$key} );
        }
    }

    return $params;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
