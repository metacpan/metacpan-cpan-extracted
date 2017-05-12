#!perl
use warnings;
use strict;

use Data::Dumper;
use Test::More tests => 2;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $des = Devel::Examine::Subs->new();

my $params = {
            file => 't/sample.data',
            post_proc => 'subs',
        };

my $aref = $des->run($params);

ok (ref $aref eq 'ARRAY', "subs post_proc returns aref" );
