package TestStorage;
use Moose;

with qw/
    Log::Message::Structured
    Log::Message::Structured::Stringify::AsJSON
/;

has foo => (
    is => 'ro',
    isa => 'Str',
    required => 1,
);

1;

