use strict;
use warnings;

use Dist::Zilla::Chrome::Test;
use Dist::Zilla::Plugin::PromptIfStale;
use Class::Method::Modifiers ();

# capture logging messages for situations where we don't get to see them
# otherwise

my $chrome = Dist::Zilla::Chrome::Test->new->logger->proxy({ proxy_prefix => '[PromptIfStale-CAPTURED] ', });

Class::Method::Modifiers::install_modifier(
    'Dist::Zilla::Plugin::PromptIfStale',
    'before',
    qw(log log_debug),
    sub {
        my $self = shift;
        $chrome->logger->log(@_);
    },
);

sub _clear_log_messages
{
    $chrome->logger->clear_events;
}

sub _log_messages
{
    [ map {; $_->{message} } @{ $chrome->logger->events } ];
}

1;
