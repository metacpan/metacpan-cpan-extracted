#!perl -T

use Test::More tests => 67;

BEGIN {
	use_ok( 'Interpolation' );
}

diag( "Testing Interpolation $Interpolation::VERSION, Perl $], $^X" );

ok( (import Interpolation N1 => 'null'), "Testing 'null'");
is( "$N1{1+2}", 3, "numerical expression");
is( "$N1{01+2.0}", 3, "numerical expression");
is( "$N1{substr('this', 1, 2)}", 'hi', "function call");
untie %N1;


ok( (import Interpolation N2 => 'eval'), "Testing 'eval'");
is( "$N2{1+2}", 3, "numerical expression");
is( "$N2{01+2.0}", 3, "numerical expression");
is( "$N2{substr('this', 1, 2)}", 'hi', "function call");
untie %N2;

ok( (import Interpolation N3 => 'identity'), "Testing 'identity'");
is( "$N3{1+2}", 3, "numerical expression");
is( "$N3{01+2.0}", 3, "numerical expression");
is( "$N3{substr('this', 1, 2)}", 'hi', "function call");
untie %N3;

ok( (import Interpolation U1 => 'ucwords'), "Testing 'ucwords'");
is("$U1{'the quick brown fox'}", 'The Quick Brown Fox');
is("$U1{'i LiVe In CaLgArY, aLbErTa.'}", 'I Live In Calgary, Alberta.');
is("$U1{'12 22 33'}", '12 22 33');
is( "$U1{substr('this', 1, 2)}", 'Hi');
untie %U1;


ok( (import Interpolation C1 => 'commify'), "Testing 'commify'");

$SIG{__WARN__} = sub { # catch the warning
	print STDERR $_[0]
		if ($_[0] !~ m/^Argument "the quick brown fox" isn't numeric in sprintf/);
};
is("$C1{'the quick brown fox'}", '0.00');
delete $SIG{__WARN__}; # stop catching warnings

is("$C1{123}", '123.00');
is("$C1{1234}", '1,234.00');
is("$C1{12345}", '12,345.00');
is("$C1{123456}", '123,456.00');
is("$C1{1234567}", '1,234,567.00');
is("$C1{10000/7}", '1,428.57');
is("$C1{2/3}", '0.67'); # Round off correctly?
is("$C1{1_000_000_000 / 3}", '333,333,333.33');
untie %C1;


ok( (import Interpolation R1 => 'reverse'), "Testing 'reverse'");
is("$R1{'the quick brown fox'}", 'xof nworb kciuq eht');
is("$R1{''}", '');
untie %R1;


ok( (import Interpolation S1 => 'sprintf'), "Testing 'sprintf'");
is("$S1{'%.2f'}{7/3}", '2.33');
is("$S1{'%04d'}{1}", '0001');
is("$S1{'%s'}{'snonk'}", 'snonk');
is("$S1{'%d-%d'}{3,4}", '3-4');
is("$S1{'%d:%02d:%02d'}{1,7,0}", '1:07:00');
untie %S1;


ok( (import Interpolation S2 => 'sprintf1'), "Testing 'sprintf1'");
is("$S2{'%.2f', 7/3}", '2.33');
is("$S2{'%04d', 1}", '0001');
is("$S2{'%s','snonk'}", 'snonk');
is("$S2{'%d-%d',3,4}", '3-4');
is("$S2{'%d:%02d:%02d',1,7,0}", '1:07:00');
untie %S2;


ok( (import Interpolation 'S3:$$*->$' => 'sprintfx'), "Testing 'sprintfx'");
is("$S3{'%.2f'}{7/3}", '2.33');
is("$S3{'%04d'}{1}", '0001');
is("$S3{'%s'}{'snonk'}", 'snonk');
is("$S3{'%d-%d'}{3}{4}", '3-4');
is("$S3{'%d:%02d:%02d'}{1}{7}{0}", '1:07:00');
untie %S3;


ok( (import Interpolation Q1 => 'sqlescape'), "Testing 'sqlescape'");
is("$Q1{'hello'}", "'hello"); # keep in mind that the sqlescape adds a quote in front of the text, but not at the end!
is(qq{$Q1{"d'Artagnan"}}, "'d''Artagnan");
untie %Q1;


SKIP: {
	eval { require HTML::Entities };

	skip "HTML::Entities not installed. htmlescape, tagescape and JSescape builtins not available", 3*5 if $@;

	ok( (import Interpolation H1 => 'htmlescape'), "Testing 'htmlescape'");
	is("$H1{'hello'}", 'hello');
	is("$H1{'1 < 2'}", '1 &lt; 2');
	is("$H1{'you & me'}", 'you &amp; me');
	is(qq{$H1{'I said: "Hello".'}}, 'I said: "Hello".');
	untie %H1;


	ok( (import Interpolation H2 => 'tagescape'), "Testing 'tagescape'");
	is("$H2{'hello'}", 'hello');
	is("$H2{'1 < 2'}", '1 &lt; 2');
	is("$H2{'you & me'}", 'you &amp; me');
	is(qq{$H2{'I said: "Hello".'}}, 'I said: &quot;Hello&quot;.');
	untie %H2;


	ok( (import Interpolation H3 => 'JSescape'), "Testing 'jsescape'");
	is("$H3{'hello'}", 'hello');
	is("$H3{'1 < 2'}", '1 &lt; 2');
	is("$H3{'you & me'}", 'you &amp; me');
	is(qq{$H3{'I said: "Hello".'}}, 'I said: \&quot;Hello\&quot;.');
	untie %H3;
}