package Message::Passing::WebHooks::Event::Call;
use Moose::Role;

has url => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

no Moose::Role;
1;

