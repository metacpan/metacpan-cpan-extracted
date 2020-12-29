#!/usr/bin/perl

BEGIN {
  unless ($ENV{AUTHOR_TESTING}) {
    print qq{1..0 # SKIP these tests are for testing by the author\n};
    exit
  }
}

#
# test-compile.t
#
# Tries to minify a handful of JS libs and verify that they're still able to be
# compiled after being minified.  While not a 100% guarantee that we haven't
# broken anything, it does give us a chance to test minification against a
# larger suite of JS.
#
###############################################################################

use strict;
use warnings;
use Test::More;
use IPC::Run qw(run);
use File::Which qw(which);
use JavaScript::Minifier::XS qw(minify);

###############################################################################
# Make sure we've got "curl" and "jsl" installed.
my $curl = which('curl');
my $jsl  = which('jsl');
unless ($curl && $jsl) {
    plan skip_all => "Test requires 'curl' and 'jsl'";
}

###############################################################################
# What JS libraries should we try to minify?
my @libs = qw(
    https://ajax.googleapis.com/ajax/libs/jquery/1.11.2/jquery.js
    https://ajax.googleapis.com/ajax/libs/jqueryui/1.11.2/jquery-ui.js
    https://raw.githubusercontent.com/christianbach/tablesorter/master/jquery.tablesorter.js
);

###############################################################################
# Suck down a bunch of popular JS libraries, and try to minify them all.
foreach my $uri (@libs) {
    subtest $uri => sub {
        my $content = qx{$curl --silent $uri};
        ok defined $content, 'fetched JS';
        return unless (defined $content);

        # try to compile the original JS
        ok js_compile($content), 'original JS compiles';

        # minify the JS
        my $minified = minify($content);
        ok $minified, 'minified JS';

        # try to compile the minified JS
        ok js_compile($minified), 'minified JS compiles';
    };
}

sub js_compile {
    my $js = shift;
    my ($rc, $out, $err);

    run [$jsl, '-stdin', '-nosummary'], \$js, \$out, \$err;

    $rc = $? >> 8;
    return $rc <= 2;
}

###############################################################################
# All done!
done_testing();
