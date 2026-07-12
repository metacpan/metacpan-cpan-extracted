use strict;
use warnings;
use Test::More tests => 12;
use File::Temp qw(tempdir);
use File::Spec;

use_ok('Eshu');

my $dir = tempdir(CLEANUP => 1);

# Create files: 2 need fixing, 1 is already correct, 1 unknown ext
my $bad1 = File::Spec->catfile($dir, 'bad1.pm');
open my $fh, '>', $bad1 or die;
print $fh "sub a {\nmy \$x;\n}\n";
close $fh;

my $bad2 = File::Spec->catfile($dir, 'bad2.pm');
open $fh, '>', $bad2 or die;
print $fh "if (1) {\nprint 1;\n}\n";
close $fh;

my $good = File::Spec->catfile($dir, 'good.pm');
open $fh, '>', $good or die;
print $fh "sub b {\n\treturn 1;\n}\n";
close $fh;

my $unknown = File::Spec->catfile($dir, 'notes.txt');
open $fh, '>', $unknown or die;
print $fh "hello world\n";
close $fh;

my $report = Eshu->indent_dir($dir);

# Report structure
is(ref $report, 'HASH', 'report is a hashref');
is(ref $report->{changes}, 'ARRAY', 'changes is arrayref');

# Counts
is($report->{files_checked}, 3, 'three files checked');
is($report->{files_changed}, 2, 'two need fixing');
is($report->{files_skipped}, 1, 'one skipped');
is($report->{files_errored}, 0, 'zero errors');

# Individual change records
my %by_file = map { $_->{file} => $_ } @{$report->{changes}};
is($by_file{$bad1}{status}, 'needs_fixing', 'bad1 needs fixing');
is($by_file{$bad2}{status}, 'needs_fixing', 'bad2 needs fixing');
is($by_file{$good}{status}, 'unchanged', 'good is unchanged');
is($by_file{$unknown}{status}, 'skipped', 'txt skipped');
is($by_file{$unknown}{reason}, 'unrecognised extension', 'skip reason recorded');
