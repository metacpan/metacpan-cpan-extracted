#!/usr/bin/perl
package ModeratelyLongNamespace;
use strict;
use warnings;
use Dir::Self;
use lib __DIR__;
use lf_out_test qw(logtester $Output);
use Log::Fu { target => \&logtester };
use Test::More;

sub complainer {
    log_err("Grr...");
}
Log::Fu::Configure(
    Strip => 1,
    StripTopLevelNamespace => 5,
    StripSubBasename => 0
);
complainer();
unlike($Output, qr/LongNamespace/, "Long name chomped out");
like($Output, qr/complainer/, "Subname not yet chomped");

Log::Fu::Configure(
    StripTopLevelNamespace => 0,
    StripSubBasename    => 3
);
complainer();
like($Output, qr/LongNamespace/, "TLNS not chomped");
like($Output, qr/~ner/, "Sub reduced to three characters");
Log::Fu::Configure(Strip => 0);
complainer();
like($Output, qr/ModeratelyLongNamespace::complainer/, "Stripping off");
Log::Fu::AddHandler('Moderately',
    sub { 
        my $msg = $_[0];
        my $sub = (split(/::/, $msg))[-1];
        return "-Oy-$sub";
    });
complainer();
like($Output, qr/-Oy-complainer/, "Handlers");

done_testing();
