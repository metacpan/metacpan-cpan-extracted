#!/usr/bin/perl
use strict;
use warnings;

use Test::More tests => 10;
use JavaScript::Ectype::Loader;

my $TEST_PATH = './t/js/ectype/';

{
    my $prev = JavaScript::Ectype::Loader->new(
        target   => 'require2.ectype.js',
        path     => $TEST_PATH,
    )->newest_mtime;
    my $next = JavaScript::Ectype::Loader->new(
        target   => 'require2.ectype.js',
        path     => $TEST_PATH,
    )->newest_mtime;
    ::is $prev,$next;
}



for(qw{
    ./t/js/ectype/require2.ectype.js
    ./t/js/ectype/require.ectype.js
    ./t/js/ectype/very/deep/namespace/class.js
})
{
    my $x = JavaScript::Ectype::Loader->new(
        target   => 'require2.ectype.js',
        path     => $TEST_PATH,
    );
    my $prev = $x->newest_mtime;
    my $body = $x->get_content;
    utime time(),time(),$_;

    my $y = JavaScript::Ectype::Loader->new(
        target   => 'require2.ectype.js',
        path     => $TEST_PATH,
    );

    ::ok $y->is_modified_from( $prev );
    ::ok $y->load_content;
    ::is $body , $y->get_content;
    sleep(1);
}

