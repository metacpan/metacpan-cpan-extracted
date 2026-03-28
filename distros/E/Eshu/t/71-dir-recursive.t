use strict;
use warnings;
use Test::More tests => 7;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(mkpath);

use_ok('Eshu');

my $dir = tempdir(CLEANUP => 1);

# Create nested directory structure
my $sub = File::Spec->catdir($dir, 'lib', 'Foo');
mkpath($sub);

my $top = File::Spec->catfile($dir, 'top.pl');
open my $fh, '>', $top or die;
print $fh "if (1) {\nprint 1;\n}\n";
close $fh;

my $mid = File::Spec->catfile($dir, 'lib', 'mid.pm');
open $fh, '>', $mid or die;
print $fh "sub x {\nreturn 1;\n}\n";
close $fh;

my $deep = File::Spec->catfile($sub, 'deep.pm');
open $fh, '>', $deep or die;
print $fh "sub y {\nmy \$a = 1;\n}\n";
close $fh;

# Recursive (default)
my $report = Eshu->indent_dir($dir);
is($report->{files_checked}, 3, 'recursive finds all 3 files');
is($report->{files_changed}, 3, 'all 3 need fixing');

# Non-recursive
$report = Eshu->indent_dir($dir, recursive => 0);
is($report->{files_checked}, 1, 'non-recursive finds only top-level file');
is($report->{files_changed}, 1, 'one file needs fixing');

# Fix recursively
$report = Eshu->indent_dir($dir, fix => 1);
is($report->{files_changed}, 3, 'all 3 fixed');

# Verify nested file is fixed
open $fh, '<', $deep or die;
my $content = do { local $/; <$fh> };
close $fh;
like($content, qr/^\tmy \$a = 1;/m, 'deeply nested file indented');
