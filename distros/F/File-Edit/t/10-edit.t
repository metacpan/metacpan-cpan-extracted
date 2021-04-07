#!perl
use strict; use warnings; use utf8; use 5.10.0;
use Test::More tests => 7;
use Data::Dumper;

use lib qw(./lib);
use File::Edit;

my ($exp,$got,$msg,$tmp,$ed);

$msg = 'Basic test - ok';
$got = 1;
$exp = 1;
is($got, $exp, $msg);

BEGIN {
    use_ok( 'File::Edit' ) || print "Bail out!\n";
}

$msg = '->text ok';
$ed = File::Edit->new
                ->text("  minSdkVersion 16\n  targetSdkVersion 29");
$got = join '', @{$ed->_lines};
$exp = "  minSdkVersion 16\n  targetSdkVersion 29";
is($got, $exp, $msg);

$msg = '->_find_one - found ok';
$ed = File::Edit->new;
$ed->_lines(["  minSdkVersion 16\n","  targetSdkVersion 29"]);
$ed->_find_one("targetSdkVersion 29");
$got = join '', @{$ed->found};
$exp = '1';
is($got, $exp, $msg);

$msg = '->_find_one - line_re ok';
$got = $ed->_line_re;
$exp = qr/targetSdkVersion 29/;
is($got, $exp, $msg);


$msg = '->_replace_found ok';
$ed = File::Edit->new;
$ed->_lines(["  minSdkVersion 16\n","  targetSdkVersion 29"]);
$ed->found([1])
   ->_line_re(qr/targetSdkVersion 29/);
$ed->_replace_found('targetSdkVersion 30');
$got = join '', @{$ed->_lines};
$exp = "  minSdkVersion 16\n  targetSdkVersion 30";
is($got, $exp, $msg);


$msg = '->replace ok';
$ed = File::Edit->new;
$ed->_lines(["  minSdkVersion 16\n","  targetSdkVersion 29"])
   ->replace('targetSdkVersion 29', 'targetSdkVersion 30');
$got = join '', @{$ed->_lines};
$exp = "  minSdkVersion 16\n  targetSdkVersion 30";
is($got, $exp, $msg);

diag( "Testing File::Edit $File::Edit::VERSION, Perl $], $^X" );

