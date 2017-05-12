#!perl
use warnings;
use strict;

use Test::More tests => 4;

use Data::Dumper;

BEGIN {#1-2
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
    use_ok( 'Devel::Examine::Subs::Engine' ) || print "Bail out!\n";
}
{#3
    my $des = Devel::Examine::Subs->new();

    eval {
        $des->run({pre_proc => '_test_bad'});
    };

    like ( $@, qr/dispatch table/, "pre_proc module croaks if the dt key is ok, but the value doesn't point to a callback" );
}
{#4
    my $des = Devel::Examine::Subs->new();

    eval {
        $des->run({pre_proc => 'asdfasdf'});
    };

    like ( $@, qr/'asdfasdf'/, "pre_procmodule croaks if an invalid internal engine is called" );
}
