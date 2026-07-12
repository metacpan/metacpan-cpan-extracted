use strict;
use warnings;
use Test::More tests => 6;
use File::Temp qw(tempdir);
use File::Spec;

use_ok('Eshu');

my $dir = tempdir(CLEANUP => 1);

my $file = File::Spec->catfile($dir, 'test.pm');
my $orig = "sub f {\nmy \$x;\n}\n";
open my $fh, '>', $file or die;
print $fh $orig;
close $fh;

# Default is dry-run (no fix => 1)
my $report = Eshu->indent_dir($dir);
is($report->{files_changed}, 1, 'one file identified as needing fix');

# Check status is needs_fixing, not changed
my $entry = $report->{changes}[0];
is($entry->{status}, 'needs_fixing', 'status is needs_fixing in dry-run');

# File on disk should be unchanged
open $fh, '<', $file or die;
my $content = do { local $/; <$fh> };
close $fh;
is($content, $orig, 'file content unchanged after dry-run');

# diff mode
$report = Eshu->indent_dir($dir, diff => 1);
$entry = $report->{changes}[0];
ok(defined $entry->{diff}, 'diff output present');
like($entry->{diff}, qr/^\-my \$x;/m, 'diff contains removed line');
