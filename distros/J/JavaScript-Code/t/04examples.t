#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 3;

my $result1 = qq~var a = "Var!";\n~;
my $result2 = "var b = 42;\n";
my $result3 = <<"RESULT";
<script language="Javascript" type="text/javascript"><!--

var a = "Var!";
var b = 42;

// --></script>
RESULT

use JavaScript::Code;
use JavaScript::Code::Variable;

my $code = JavaScript::Code->new();
my $var  = JavaScript::Code::Variable->new()->name('a')->value("Var!");

ok ( $var->output eq $result1 );

$code->add( $var );
$code->add( JavaScript::Code::Variable->new()->name('b')->value(42) );

ok ( $code->elements->[1]->output eq $result2 );

ok ( $code->output_for_html eq $result3 );