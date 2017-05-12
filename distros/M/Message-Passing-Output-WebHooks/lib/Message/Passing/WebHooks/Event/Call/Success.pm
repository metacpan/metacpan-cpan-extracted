package Message::Passing::WebHooks::Event::Call::Success;
use Moose;

with 'Message::Passing::WebHooks::Event::Call';

with 'Log::Message::Structured::Stringify::Sprintf' => {
    format_string => "webhook call to %s succeeded",
    attributes => [qw/ url /],
}, 'Log::Message::Structured';

no Moose;
__PACKAGE__->meta->make_immutable;
1;

