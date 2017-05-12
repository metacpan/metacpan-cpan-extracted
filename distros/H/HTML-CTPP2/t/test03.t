# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl HTML-CTPP2.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 5;
BEGIN { use_ok('HTML::CTPP2') };

use strict;

my $T = new HTML::CTPP2();
ok( ref $T eq "HTML::CTPP2", "Create object.");

my $Bytecode = $T -> parse_template("math_expr.tmpl");
ok( ref $Bytecode eq "HTML::CTPP2::Bytecode", "Create object.");

my %H = ("a" => 2, "b" => 3, "age" => 31);
ok( $T -> param(\%H) == 0);

my $Result = $T -> output($Bytecode);
ok( $Result eq "  (2 + 3) / 5 = 1\n  Age correct\n");

