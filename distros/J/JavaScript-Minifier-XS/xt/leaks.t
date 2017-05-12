#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use File::Slurp qw(slurp);
use JavaScript::Minifier::XS qw(minify);

BEGIN {
    eval "use Test::LeakTrace";
    plan skip_all => "Test::LeakTrace required for leak testing" if $@;
    plan tests => 2;
}
use Test::LeakTrace;

###############################################################################
# Suck in a bunch of JS to use for testing.
my $js = '';
$js .= slurp($_) for (<t/js/*.js>);
ok length($js), 'got some JS to minify';

###############################################################################
# Make sure we're not leaking memory when we minify
no_leaks_ok { minify($js) } 'no leaks when minifying JS';
