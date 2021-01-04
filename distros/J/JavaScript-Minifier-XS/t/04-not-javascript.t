use strict;
use warnings;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use Test::More;
use JavaScript::Minifier::XS qw(minify);

###############################################################################
# RT#58416; don't crash if attempting to minify something that isn't JS
# ... while there's no guarantee that what we get back is _sane_, we should at
#     least not blow up or segfault.
subtest "Minifying non-JS shouldn't crash" => sub {
    my $results = minify("not javascript");
    pass "didn't segfault while processing non-javascript";
};

###############################################################################
done_testing();
