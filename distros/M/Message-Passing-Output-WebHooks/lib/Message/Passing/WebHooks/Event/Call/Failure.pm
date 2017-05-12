package Message::Passing::WebHooks::Event::Call::Failure;
use Moose;

with 'Message::Passing::WebHooks::Event::Call';

has code => (
    isa => 'Int',
    is => 'ro',
    required => 1,
);

with 'Log::Message::Structured::Stringify::Sprintf' => {
    format_string => "webhook call to %s failed, return code %s",
    attributes => [qw/ url code /],
}, 'Log::Message::Structured';

no Moose;
__PACKAGE__->meta->make_immutable;
1;

