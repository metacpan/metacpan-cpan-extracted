use strict;
use warnings;
use Test::More;

{
    package TestEvent;
    use Moose;
    with qw(Log::Message::Structured
            Log::Message::Structured::Component::Date
            Log::Message::Structured::Component::Hostname);

    sub as_string { 'MOO' }

    has foo => ( is => 'ro', required => 1);
}

my $e = TestEvent->new(foo => 2);
ok $e;
is $e.'', 'MOO';
foreach my $meth (qw/ as_string as_hash epochtime date hostname /) {
    ok $e->can($meth);
}

is $e->{class}, 'TestEvent';

done_testing;
