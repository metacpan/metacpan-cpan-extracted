#!perl
use strict; use warnings; use utf8; use 5.10.0;
use Test::More tests => 11;
use Data::Dumper;

use lib qw(./lib);
use File::Edit;

my ($exp,$got,$msg,$tmp,$ed);

{ ## Basic test - ok
$msg = 'Basic test - ok';
$got = 1;
$exp = 1;
is($got, $exp, $msg);
}
BEGIN { ## use module
    use_ok( 'File::Edit' ) || print "Bail out!\n";
}
{ ## text
$msg = '->text ok';
$ed = File::Edit->new
                ->text("  minSdkVersion 16\n  targetSdkVersion 29");
$got = join '', @{$ed->_lines};
$exp = "  minSdkVersion 16\n  targetSdkVersion 29";
is($got, $exp, $msg);
}
{ ## _find_one - match string with prefix
$msg = '->_find_one - match string with prefix';
$ed = File::Edit->new;
$ed->_lines(["  minSdkVersion 16\n","  targetSdkVersion 29"]);
$ed->_find_one("targetSdkVersion 29");
$got = join '', @{$ed->found};
$exp = '1';
is($got, $exp, $msg);
}
{ ## _find_one - match string with postfix
$msg = '->_find_one - match string with postfix';
$ed = File::Edit->new;
$ed->_lines(["  minSdkVersion 16\n","  targetSdkVersion 29 should work"]);
$ed->_find_one("targetSdkVersion 29");
$got = join '', @{$ed->found};
$exp = '1';
is($got, $exp, $msg);
}
{ ## _find_one - match string with meta characters
$msg = '->_find_one - match string with :+3d';
$ed = File::Edit->new;
$ed->_lines(["  minSdkVersion 16\n","  targetSdkVersion 29 :+3d should work"]);
$ed->_find_one('targetSdkVersion 29 :+3d');
$got = join '', @{$ed->found};
$exp = '1';
is($got, $exp, $msg);
}

{ ## _find_one - should fail
$msg = '->_find_one - should fail';
$ed = File::Edit->new;
$ed->_lines(["  minSdkVersion 16\n","  targetSdkVersion 19"]);
$got = eval { $ed->_find_one("targetSdkVersion 29") };
$exp = undef;
is($got, $exp, $msg);
}
{ ## _find_one - match multi-lines
$msg = '->_find_one - match multi-lines';
$ed = File::Edit->new;
$ed->_lines(["  minSdkVersion 16\n","  targetSdkVersion 29 \n multi-line works"]);
$ed->_find_one("targetSdkVersion 29");
$got = join '', @{$ed->found};
$exp = '1';
is($got, $exp, $msg);
}
{ ## Test that $o->_line_re stores regex
$msg = '->_find_one - line_re stores regex';
$got = "-- targetSdkVersion 29 --" =~ $ed->_line_re ? 1 : 0;
$exp = 1;
is($got, $exp, $msg);
}

{ ## Private method _replace_found() replaces correctly
$msg = '->_replace_found ok';
$ed = File::Edit->new;
$ed->_lines(["  minSdkVersion 16\n","  targetSdkVersion 29"]);
$ed->found([1])
   ->_line_re(qr/targetSdkVersion 29/);
$ed->_replace_found('targetSdkVersion 30');
$got = join '', @{$ed->_lines};
$exp = "  minSdkVersion 16\n  targetSdkVersion 30";
is($got, $exp, $msg);
}
{ ## Public method replace() replaces correctly
$msg = '->replace ok';
$ed = File::Edit->new;
$ed->_lines(["  minSdkVersion 16\n","  targetSdkVersion 29"])
   ->replace('targetSdkVersion 29', 'targetSdkVersion 30');
$got = join '', @{$ed->_lines};
$exp = "  minSdkVersion 16\n  targetSdkVersion 30";
is($got, $exp, $msg);
}
diag( "Testing File::Edit $File::Edit::VERSION, Perl $], $^X" );

