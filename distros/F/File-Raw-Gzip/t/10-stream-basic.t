#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use IO::Compress::Gzip qw(gzip);
use File::Raw qw(import);
use File::Raw::Gzip;

my $dir = tempdir(CLEANUP => 1);

my @lines = (
    'first line',
    'second line with spaces',
    '',                          # empty line
    'tab\there',
    'last with trailing newline',
);

# Build a file with a trailing newline.
my $payload = join("\n", @lines) . "\n";
my $path    = "$dir/lines.gz";
gzip(\$payload, $path) or die "gzip failed";

my @seen;
File::Raw::each_line($path, sub { push @seen, $_ }, plugin => 'gzip');

is_deeply(\@seen, \@lines, 'each_line / gzip plugin: trailing-newline file');

# File without a trailing newline -> last line still emitted.
my $payload2 = join("\n", 'a', 'b', 'c-no-newline');
my $path2    = "$dir/no-trailing.gz";
gzip(\$payload2, $path2) or die "gzip failed";

@seen = ();
File::Raw::each_line($path2, sub { push @seen, $_ }, plugin => 'gzip');
is_deeply(\@seen, ['a', 'b', 'c-no-newline'],
    'final partial line is emitted on EOF');

# Empty gzip stream: no callbacks, no errors.
my $empty   = '';
my $epath   = "$dir/empty.gz";
gzip(\$empty, $epath) or die "gzip failed";

@seen = ();
File::Raw::each_line($epath, sub { push @seen, $_ }, plugin => 'gzip');
is_deeply(\@seen, [], 'empty file emits no lines');

done_testing;
