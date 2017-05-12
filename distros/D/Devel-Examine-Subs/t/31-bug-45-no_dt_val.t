#!perl
use warnings;
use strict;

use Data::Dumper;
use Test::More tests => 4;

BEGIN {#1
    use_ok( 'Devel::Examine::Subs' ) || print "Bail out!\n";
}

my $des = Devel::Examine::Subs->new(file => 't/sample.data');

eval { $des->run({pre_proc => '_test_bad'}); };
like ($@, qr/dispatch table/, "pre_proc with bad method value in dispatch table confesses" );

eval { $des->run({post_proc => '_test_bad'}); };
like ($@, qr/dispatch table/, "post_proc with bad method value in dispatch table confesses" );

eval { $des->run({engine => '_test_bad'}); };
like ($@, qr/dispatch table/, "engine with bad method value in dispatch table confesses" );
