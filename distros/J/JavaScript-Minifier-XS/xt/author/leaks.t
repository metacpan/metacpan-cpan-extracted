#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use File::Which qw(which);
use JavaScript::Minifier::XS qw(minify);

BEGIN {
    eval "use Test::LeakTrace";
    plan skip_all => "Test::LeakTrace required for leak testing" if $@;
}
use Test::LeakTrace;

###############################################################################
## What CSS docs do we want to try compressing?
my $curl = which('curl');
my @libs = (
    'http://stackpath.bootstrapcdn.com/bootstrap/4.5.2/js/bootstrap.js',
    'http://code.jquery.com/jquery-3.5.1.js',
    'http://cdnjs.cloudflare.com/ajax/libs/react/17.0.1/cjs/react.development.js',
);

###############################################################################
# Make sure we're not leaking memory when we minify
foreach my $url (@libs) {
    subtest $url => sub {
        my $js = qx{$curl --silent $url};
        ok $js, 'got some JS to minify';
        no_leaks_ok { minify($js) } "no leaks when minifying; $url";
    };
}

###############################################################################
done_testing();
