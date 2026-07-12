use strict;
use warnings;
use Test::More tests => 8;
use File::Temp qw(tempdir);
use File::Spec;

use_ok('Eshu');

my $dir = tempdir(CLEANUP => 1);

# Create a Perl file with bad indentation
my $pm_file = File::Spec->catfile($dir, 'Foo.pm');
open my $fh, '>', $pm_file or die "Cannot write $pm_file: $!";
print $fh <<'PERL';
sub foo {
my $x = 1;
if ($x) {
print "hello\n";
}
}
PERL
close $fh;

# Create a C file with bad indentation
my $c_file = File::Spec->catfile($dir, 'bar.c');
open $fh, '>', $c_file or die "Cannot write $c_file: $!";
print $fh <<'C';
void bar() {
int x = 1;
if (x) {
printf("hello\n");
}
}
C
close $fh;

# Dry-run: check report
my $report = Eshu->indent_dir($dir);
is($report->{files_checked}, 2, 'two files checked');
is($report->{files_changed}, 2, 'two files need fixing');
is($report->{files_skipped}, 0, 'none skipped');

# Verify files are not modified in dry-run
open $fh, '<', $pm_file or die;
my $content = do { local $/; <$fh> };
close $fh;
like($content, qr/^my \$x = 1;/m, 'file untouched in dry-run');

# Now fix them
$report = Eshu->indent_dir($dir, fix => 1);
is($report->{files_checked}, 2, 'two files checked with fix');
is($report->{files_changed}, 2, 'two files changed');

# Verify the Perl file is fixed
open $fh, '<', $pm_file or die;
$content = do { local $/; <$fh> };
close $fh;
like($content, qr/^\tmy \$x = 1;/m, 'perl file properly indented after fix');
