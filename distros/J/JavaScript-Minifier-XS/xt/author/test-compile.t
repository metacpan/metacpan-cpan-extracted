#!/usr/bin/perl
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
        my $res_original = js_compile($content);

        # minify the JS
        my $minified = minify($content);
        ok $minified, 'minified JS';

        # try to compile the minified JS
        my $res_minified = js_compile($minified);
        is $res_minified, $res_original, 'same errors/warnings as the original'
          and note $res_minified;
    };
}

###############################################################################
# All done!
done_testing();



###############################################################################
sub js_compile {
    my $js = shift;
    my ($out, $err);

    run [$jsl, '-stdin'], \$js, \$out, \$err;

    my $res = (split /^/, $out)[-1];
    $res =~ s{(\d+\s+error.*?),.*}{$1};

    unless ($res =~ /\d+\s+error/) {
      fail "Unexpected output from jsl";
      diag $res;
    }

    return $res;
}

