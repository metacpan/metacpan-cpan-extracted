#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

BEGIN {
    eval { require DBD::SQLite }
        or plan skip_all => 'DBD::SQLite is required for this test';
    $ENV{TEST_FOORUM} = 1;
    plan tests => 3;
}

use FindBin;
use File::Spec;
use lib File::Spec->catdir( $FindBin::Bin, '..', 'lib' );
use Foorum::SUtils qw/schema/;
use Foorum::XUtils qw/cache/;
use Foorum::TestUtils qw/rollback_db/;
my $schema = schema();
my $cache  = cache();

my $banned_ip_res = $schema->resultset('BannedIp');

# create
$banned_ip_res->create(
    {   cidr_ip => '192.168.0.0/24',
        time    => time()
    }
);
$banned_ip_res->create(
    {   cidr_ip => '192.168.1.0/24',
        time    => time()
    }
);

$cache->remove('global|banned_ip');
my @ips = $banned_ip_res->get();

ok( grep { '192.168.0.0/24' eq $_ } @ips, q~get '192.168.0.0/24'~ );
ok( grep { '192.168.1.0/24' eq $_ } @ips, q~get '192.168.1.0/24'~ );

# test is_ip_banned
my $flag = $banned_ip_res->is_ip_banned('192.168.0.1');
is( $flag, 1, 'is_ip_banned OK' );

#remove
$banned_ip_res->search(
    {   -or => [
            cidr_ip => '192.168.0.0/24',
            cidr_ip => '192.168.1.0/24'
        ],
    }
)->delete;
$cache->remove('global|banned_ip');

END {

    # Keep Database the same from original
    rollback_db();
}

1;
