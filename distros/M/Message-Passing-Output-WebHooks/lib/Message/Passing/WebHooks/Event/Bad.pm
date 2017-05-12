package Message::Passing::WebHooks::Event::Bad;
use Moose;

has bad_event => (
    isa => 'HashRef',
    is => 'ro',
    required => 1,
);

with 'Log::Message::Structured::Stringify::Sprintf' => {
    format_string => "webhook call got bad data",
    attributes => [],
}, 'Log::Message::Structured';

no Moose;
__PACKAGE__->meta->make_immutable;
1;

