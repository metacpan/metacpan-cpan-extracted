#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib", "$FindBin::Bin/lib";
use Path::Tiny;
use ChainPlanReference qw(reference_walk plan_walk);

# BodyPlan against the undo walk on real signed mail: the generated chain
# fixtures, and, in the interop repository, the charset corpus as it came
# back through Mailman, Sympa and the stock-Mailman route (two and three
# instances, MIME wraps, footers, re-encoded bodies).

my @files = sort(path("$FindBin::Bin/../tests/expected")->children(qr/\.eml\z/));
my $capture = path("$FindBin::Bin/../../corpus/results/capture");
push @files, sort($capture->children(qr/\.eml\z/)) if $capture->is_dir;

my ($checked, $bad) = (0, 0);
for my $file (@files) {
    (my $raw = $file->slurp_raw) =~ s/\r?\n/\r\n/g;
    next unless $raw =~ /^Message-Instance:/mi;
    my $want = reference_walk($raw);
    # Fed in pieces that cut lines, as a milter hands them over.
    my @chunks = unpack('(a4093)*', $raw);
    my $have = plan_walk($raw, \@chunks);
    $checked++;
    next if is_deeply($have, $want, $file->basename);
    diag explain { want => $want, have => $have } if ++$bad <= 3;
}
cmp_ok($checked, '>', 0, "checked $checked messages");

# Both walks stop at an instance that does not parse, so such a message
# compares nothing. The -06 charset corpus captures carry "b" Recipe steps,
# invalid under -08: say how many, and keep it visible until the recapture.
TODO: {
    local $TODO = 'recapture the -06 charset corpus after the -07 deploy';
    is($ChainPlanReference::UNPARSED, 0,
       "every message was walked ($ChainPlanReference::UNPARSED stopped at an instance -07 cannot parse)");
}

done_testing;
