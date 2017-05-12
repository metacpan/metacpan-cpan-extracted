#!perl -T

use strict;
use warnings;

use Test::More tests => 6;
use Test::Exception;

use Error qw(:try);
use POSIX;

BEGIN {
    use_ok('Konfidi::Client');
    use_ok('Konfidi::Client::Error');
}

=head2

Taken from http://perldoc.perl.org/POSIX.html#strtod

=cut
sub is_float {
    $! = 0;
    my ($num, $n_unparsed) = POSIX::strtod($_[0]);
    return !(($_[0] eq '') || ($n_unparsed != 0) || $!);
}

my $dave = 'EAB0FABEDEA81AD4086902FE56F0526F9BB3CE70';
my $andy = '8A335B856C4AE39A0C36A47F152C15A0F2454727';

my $k = Konfidi::Client->new();
$k->server('http://bogus');
throws_ok {
    $k->query($dave,$andy,'http://www.konfidi.org/ns/topics/0.0#internet-communication');
} 'Konfidi::Client::Error', 'invalid server';

$k->server('http://test-server.konfidi.org/');
lives_and {
    my $r = $k->query($dave,$andy,'http://www.konfidi.org/ns/topics/0.0#internet-communication')->{'Rating'};
    ok(is_float($r), "response is a float") or diag "response is " . $r;
    cmp_ok($r, '>=', 0, "response value lower bound");
    cmp_ok($r, '<=', 1, "response value upper bound");
} 'basic query';

