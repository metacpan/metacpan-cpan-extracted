package EventStore::Tiny::Event;
use Mo qw(default required build);

use UUID::Tiny qw(create_uuid_as_string);
use Time::HiRes qw(time);

has uuid            => sub {create_uuid_as_string};
has timestamp       => is => 'ro';
has name            => required => 1;
has transformation  => sub {sub {}};
has data            => {};

sub BUILD {
    my $self = shift;

    # make sure to set the timestamp non-lazy
    # see Mo issue #36 @ github
    $self->timestamp(time);
}

# lets transformation work on state by side-effect
sub apply_to {
    my ($self, $state, $logger) = @_;

    # apply the transformation by side effect
    $self->transformation->($state, $self->data);

    # log this event, if logger present
    $logger->($self) if defined $logger;

    # returned the same state just in case
    return $state;
}

1;
__END__
