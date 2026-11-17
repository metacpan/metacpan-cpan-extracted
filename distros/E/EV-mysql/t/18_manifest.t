use strict;
use warnings;
use Test::More;

plan skip_all => 'no MANIFEST (not a source checkout)' unless -f 'MANIFEST';

open my $fh, '<', 'MANIFEST' or die "open MANIFEST: $!";
my %listed = map { /^(\S+)/ ? ($1 => 1) : () } <$fh>;
close $fh;

my @files = (glob('t/*.t'), glob('t/lib/*.pm'), glob('t/lib/*.c'), glob('bench/*.pl'), glob('eg/*.pl'));
ok(@files > 0, 'found dist files to check');
my @missing = grep { !$listed{$_} } @files;
is_deeply(\@missing, [], 'every t/bench/eg file is listed in MANIFEST');
my @stale = sort grep { !-f $_ } keys %listed;
is_deeply(\@stale, [], 'every MANIFEST entry exists on disk');

done_testing;
