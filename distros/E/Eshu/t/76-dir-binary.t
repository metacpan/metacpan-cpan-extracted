use strict;
use warnings;
use Test::More tests => 5;
use File::Temp qw(tempdir);
use File::Spec;

use_ok('Eshu');

my $dir = tempdir(CLEANUP => 1);

# Create a binary file with NUL bytes
my $bin_file = File::Spec->catfile($dir, 'data.pm');
open my $fh, '>:raw', $bin_file or die;
print $fh "sub x {\nmy \$y;\n}\n\0\0binary data";
close $fh;

# Create a normal Perl file
my $pm_file = File::Spec->catfile($dir, 'good.pm');
open $fh, '>', $pm_file or die;
print $fh "sub z {\nreturn 1;\n}\n";
close $fh;

my $report = Eshu->indent_dir($dir, fix => 1);
is($report->{files_checked}, 1, 'only normal file checked');
is($report->{files_skipped}, 1, 'binary file skipped');

my %by_file = map { $_->{file} => $_ } @{$report->{changes}};
is($by_file{$bin_file}{status}, 'skipped', 'binary file status is skipped');
is($by_file{$bin_file}{reason}, 'binary file', 'reason is binary file');
