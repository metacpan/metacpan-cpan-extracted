use warnings;
use strict;
use Test::More;

use LWP::UserAgent::POE;

my @defaults = qw/
    agent
    from
    conn_cache
    cookie_jar
    default_headers
    max_size
    max_redirect
    parse_head
    protocols_allowed
    protocols_forbidden
    requests_redirectable
    timeout
/;

plan tests => scalar @defaults;

my $ua  = LWP::UserAgent->new;
my $uap = LWP::UserAgent::POE->new;

for(@defaults) {
    my $uapv = (defined $uap->$_ ? $uap->$_ : "[undef]");
    my $uav  = (defined $ua->$_ ? $ua->$_ : "[undef]");
    is_deeply $uapv, $uav, $_;
}

POE::Kernel->run();
