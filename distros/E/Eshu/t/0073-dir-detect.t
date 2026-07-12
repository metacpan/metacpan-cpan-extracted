use strict;
use warnings;
use Test::More tests => 7;
use File::Temp qw(tempdir);
use File::Spec;

use_ok('Eshu');

my $dir = tempdir(CLEANUP => 1);

# C file
my $c_file = File::Spec->catfile($dir, 'test.c');
open my $fh, '>', $c_file or die;
print $fh "void f() {\nint x;\n}\n";
close $fh;

# Perl file
my $pl_file = File::Spec->catfile($dir, 'test.pl');
open $fh, '>', $pl_file or die;
print $fh "sub g {\nmy \$y = 1;\n}\n";
close $fh;

# CSS file
my $css_file = File::Spec->catfile($dir, 'style.css');
open $fh, '>', $css_file or die;
print $fh "body {\ncolor: red;\n}\n";
close $fh;

# XML file
my $xml_file = File::Spec->catfile($dir, 'data.xml');
open $fh, '>', $xml_file or die;
print $fh "<root>\n<child>text</child>\n</root>\n";
close $fh;

# Unknown extension (should be skipped)
my $txt_file = File::Spec->catfile($dir, 'readme.txt');
open $fh, '>', $txt_file or die;
print $fh "just some text\n";
close $fh;

my $report = Eshu->indent_dir($dir, fix => 1);

is($report->{files_checked}, 4, 'four recognised files checked');
is($report->{files_changed}, 4, 'all four fixed');
is($report->{files_skipped}, 1, 'txt file skipped');

# Verify each language detected correctly
my %by_file = map { $_->{file} => $_ } @{$report->{changes}};
is($by_file{$c_file}{lang}, 'c', 'C detected');
is($by_file{$pl_file}{lang}, 'perl', 'Perl detected');
is($by_file{$css_file}{lang}, 'css', 'CSS detected');
