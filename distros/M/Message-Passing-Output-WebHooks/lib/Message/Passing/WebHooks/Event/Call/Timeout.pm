package Message::Passing::WebHooks::Event::Call::Timeout;
use Moose;

with 'Message::Passing::WebHooks::Event::Call';

with 'Log::Message::Structured::Stringify::Sprintf' => {
    format_string => "webhook call to %s timed out",
    attributes => [qw/ url /],
}, 'Log::Message::Structured';

no Moose;
__PACKAGE__->meta->make_immutable;
1;

