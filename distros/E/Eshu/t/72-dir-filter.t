use strict;
use warnings;
use Test::More tests => 8;
use File::Temp qw(tempdir);
use File::Spec;

use_ok('Eshu');

my $dir = tempdir(CLEANUP => 1);

# Create several files
for my $name (qw(a.pm b.pl c.t d.pm)) {
	my $f = File::Spec->catfile($dir, $name);
	open my $fh, '>', $f or die;
	print $fh "if (1) {\nprint 1;\n}\n";
	close $fh;
}

# Exclude .t files
my $report = Eshu->indent_dir($dir, exclude => qr/\.t$/);
is($report->{files_checked}, 3, 'exclude .t: 3 checked');
is($report->{files_skipped}, 1, 'exclude .t: 1 skipped');

# Include only .pm files
$report = Eshu->indent_dir($dir, include => qr/\.pm$/);
is($report->{files_checked}, 2, 'include .pm: 2 checked');
is($report->{files_skipped}, 2, 'include .pm: 2 skipped');

# Multiple exclude patterns (array)
$report = Eshu->indent_dir($dir, exclude => [qr/\.t$/, qr/^.*b\.pl$/]);
is($report->{files_checked}, 2, 'multi exclude: 2 checked');
is($report->{files_skipped}, 2, 'multi exclude: 2 skipped');

# Include + exclude combined
$report = Eshu->indent_dir($dir, include => qr/\.p/, exclude => qr/\.pl$/);
is($report->{files_checked}, 2, 'include .p + exclude .pl: 2 .pm files checked');
