#!perl
use v5.10.1;
use strict;
use warnings;

use blib;
use MariaDB::NonBlocking::Select;


my $pool = [ map MariaDB::NonBlocking::Select->new, 1..5 ];
eval {
    MariaDB::NonBlocking::Select::connect(
        $pool,
        {
            host => "127.0.0.1",
            user => "root",
            password => ""
        },
    );
    1;
} or do {
    my $e = $@;
    warn "error: <$e>";
};

my $res = MariaDB::NonBlocking::Select::query_once_per_connection(
            $pool,
            q{SELECT 1, CONNECTION_ID(), RAND(50) as rand},
            {want_hashrefs => 1},
          );
use Data::Dumper; say Dumper($res);
$_->disconnect for @$pool;
undef $pool;

