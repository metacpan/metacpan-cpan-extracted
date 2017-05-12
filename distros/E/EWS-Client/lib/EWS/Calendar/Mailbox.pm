package EWS::Calendar::Mailbox;
BEGIN {
  $EWS::Calendar::Mailbox::VERSION = '1.143070';
}

use Moose;
use Moose::Util::TypeConstraints;

has EmailAddress => (
    is => 'ro',
    isa => 'Str',
    required => 0,
    default => '',
);

has Name => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

has RoutingType => (
    is => 'ro',
    isa => 'Str',
    required => 0,
    default => '',
);

sub BUILDARGS {
    my ($class, @rest) = @_;
    my $params = (scalar @rest == 1 ? $rest[0] : {@rest});

    return $params;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;
