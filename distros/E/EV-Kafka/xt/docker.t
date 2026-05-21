use strict;
use warnings;
use Test::More;

plan skip_all => 'set RELEASE_TESTING' unless $ENV{RELEASE_TESTING};
plan skip_all => 'docker not available'
    unless `which docker 2>/dev/null` && `docker version 2>&1` =~ /Server:/;
plan skip_all => 'docker compose not available'
    unless `docker compose version 2>&1` =~ /version/;

my $compose = 'eg/docker-compose.yml';
plan skip_all => "$compose missing" unless -f $compose;

note 'starting Redpanda via docker compose';
system "docker compose -f $compose up -d --wait" and
    BAIL_OUT 'docker compose up failed';

# Give Redpanda a moment past the healthcheck.
sleep 2;

local $ENV{TEST_KAFKA_BROKER} = '127.0.0.1:9092';

my @tests = sort glob 't/0[1-5]_*.t t/1[2-4]_*.t';
plan tests => scalar @tests;

for my $t (@tests) {
    my $rc = system "$^X -Ilib -Iblib/arch -Iblib/lib $t > /dev/null 2>&1";
    is $rc, 0, "$t passed against Redpanda";
}

note 'tearing down Redpanda';
system "docker compose -f $compose down -v";
