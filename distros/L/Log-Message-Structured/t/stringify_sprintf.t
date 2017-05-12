use strict;
use warnings;
use Test::More;

{
    package TestEventSprintf;
    use Moose;

    has [qw/foo bar baz/] => ( is => 'ro', required => 1);

    with 'Log::Message::Structured';
    with 'Log::Message::Structured::Stringify::Sprintf' => {
        format_string => "%s lala %s baba %s caca",
        attributes => [qw/ foo bar baz /],
    }, ;
    with 'Log::Message::Structured::Stringify::Sprintf' => {
        format_string => "<PREFIX>%s",
        attributes => [qw/ previous_string /],
    };

}

my $exp = '<PREFIX>2 lala 3 baba 4 caca';

my $e = TestEventSprintf->new(foo => 2, bar => 3, baz => 4);
ok $e;
is $e.'', $exp;

done_testing;
