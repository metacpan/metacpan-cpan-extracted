use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;
use File::Path qw(mkpath);

# Symlinks may not be supported on all platforms
eval { symlink("", ""); 1 } or plan skip_all => 'symlinks not supported';

plan tests => 5;

use_ok('Eshu');

my $dir = tempdir(CLEANUP => 1);

# Create a real file
my $real = File::Spec->catfile($dir, 'real.pm');
open my $fh, '>', $real or die;
print $fh "sub a {\nmy \$x;\n}\n";
close $fh;

# Symlink to a file (should be followed)
my $link = File::Spec->catfile($dir, 'link.pm');
symlink($real, $link) or die "Cannot create symlink: $!";

# Create a subdirectory and symlink to it (should NOT be followed)
my $subdir = File::Spec->catdir($dir, 'real_sub');
mkpath($subdir);
my $sub_file = File::Spec->catfile($subdir, 'inner.pm');
open $fh, '>', $sub_file or die;
print $fh "sub b {\nreturn;\n}\n";
close $fh;

my $link_dir = File::Spec->catdir($dir, 'link_sub');
symlink($subdir, $link_dir) or die "Cannot create dir symlink: $!";

# Run indent_dir - should process real.pm, link.pm, real_sub/inner.pm
# but NOT link_sub/inner.pm (avoiding directory symlink cycle)
my $report = Eshu->indent_dir($dir);

# real.pm + link.pm + real_sub/inner.pm = 3 checked
# link_sub/inner.pm should be skipped because link_sub is a symlinked dir
is($report->{files_checked}, 3, 'three files checked (file symlink followed)');
is($report->{files_changed}, 3, 'all three need fixing');

# Fix them - link.pm -> real.pm, so fixing real.pm also fixes link.pm
# Only 2 distinct files get changed (real.pm and inner.pm; link.pm sees fixed content)
$report = Eshu->indent_dir($dir, fix => 1);
ok($report->{files_changed} >= 2, 'at least two files fixed');

# Verify the symlinked file is fixed (it targets real.pm)
open $fh, '<', $link or die;
my $content = do { local $/; <$fh> };
close $fh;
like($content, qr/^\tmy \$x;/m, 'symlinked file content fixed');
