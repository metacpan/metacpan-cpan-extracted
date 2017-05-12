use strict;
use warnings;
use Test::More;
use Time::Fake '1300000000';
use HTTP::Cookies::Opera;

my $file = 't/cookies4.dat';

my $jar = HTTP::Cookies::Opera->new(file => $file);
isa_ok($jar, 'HTTP::Cookies::Opera');

my %domains = qw(
    bing.com     4
    github.com   1
    google.com   2
    www.bing.com 1
    yahoo.com    1
);

my $href = $jar->{COOKIES};
is(keys %$href, keys %domains, 'Domain count');

for my $domain (keys %domains) {
    my $count = keys %{$href->{ $domain }{'/'}};
    is($count, $domains{$domain}, "$domain has $count cookies" );
}

is(
    $href->{'yahoo.com'}{'/'}{'B'}[1],
    '6bor3rl6lkbhv&b=3&s=6o',
    'Cookie has right value'
);

is(
    $href->{'bing.com'}{'/fd/fb'}{FBB}[1],
    'R=1&T=1297757622943',
    'Cookie with path has right value'
);

done_testing;
