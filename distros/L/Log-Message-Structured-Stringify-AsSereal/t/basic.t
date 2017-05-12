use strict;
use warnings;
use Test::More;

{
    package TestEventSprintf;
    use Moose;
    with qw( Log::Message::Structured
             Log::Message::Structured::Component::Date
             Log::Message::Structured::Stringify::AsSereal );

    has [qw/foo bar baz/] => ( is => 'ro', required => 1);
}

my $e = TestEventSprintf->new(foo => 2, bar => 3, baz => 4);
ok $e;

use MIME::Base64;
like decode_base64("$e"), qr/^=srl/, "it's a base64 encoded sereal string";;

done_testing;

