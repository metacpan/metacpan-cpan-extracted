use strict;
use warnings;
use Test::More;

plan skip_all => 'author test: set AUTHOR_TESTING=1' unless $ENV{AUTHOR_TESTING};

# MANIFEST is hand-maintained and nothing else checks it: xt/provides.t globs
# lib/ off disk, so a file missing here passes there and surfaces only as a
# tarball that ships without the module.
open my $fh, '<', 'MANIFEST' or die "MANIFEST: $!";
my %listed;
while (<$fh>) {
    chomp;
    next if /\A\s*(#|\z)/;
    s/\s.*//;                       # entries may carry a padded comment
    $listed{$_} = 1 if length;
}
close $fh;

my @on_disk = (
    'lib/EV/Telegram/TDLib.pm',
    glob('lib/EV/Telegram/TDLib/*.pm'),
    glob('lib/EV/Telegram/TDLib/*.pod'),
    glob('t/*.t'),
    glob('xt/*.t'),
    glob('eg/*.pl'),
);

my @missing = grep { !$listed{$_} } @on_disk;
is_deeply \@missing, [], 'every shipped file is in MANIFEST';
diag "not in MANIFEST: $_" for @missing;

# the reverse direction too: a MANIFEST line naming a file that no longer
# exists breaks `make dist`, and the check above cannot see it
my @stale = grep { !-e $_ } sort keys %listed;
is_deeply \@stale, [], 'every MANIFEST entry exists on disk';
diag "in MANIFEST but missing from disk: $_" for @stale;

done_testing;
