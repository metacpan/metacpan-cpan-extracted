package Language::Farnsworth::Functions::StdMath;

use strict;
use warnings;

use Math::Pari;
use Data::Dumper;
use Language::Farnsworth::Value::Pari;
use Language::Farnsworth::Value::Array;
use Language::Farnsworth::Value::Lambda;
use Language::Farnsworth::Value::Boolean;
use Language::Farnsworth::Error;

sub init
{
   my $env = shift;

   my $array = new Language::Farnsworth::Value::Array([]);
   my $string = new Language::Farnsworth::Value::String("");
   my $lambda = new Language::Farnsworth::Value::Lambda();
   my $number = new Language::Farnsworth::Value::Pari(0);

   $env->{funcs}->addfunc("ln",  [["in", undef, $number, 0]],\&log,$env);
   $env->eval("log{x isa 1} := {ln[x]/ln[10]}"); 
   $env->{funcs}->addfunc("sin", [["in", undef, $number, 0]],\&sin,$env);
   $env->{funcs}->addfunc("cos", [["in", undef, $number, 0]],\&cos,$env);
   $env->{funcs}->addfunc("tan", [["in", undef, $number, 0]],\&tan,$env);
   $env->eval("csc{x isa 1} := {1/sin[x]}");
   $env->eval("sec{x isa 1} := {1/cos[x]}");
   $env->eval("cot{x isa 1} := {1/tan[x]}");
   $env->eval("atan2{x isa 1,y isa 1} := {var s=x^2+y^2; var r=y+x i; -i * ln[r / sqrt[s]]}");
   $env->{funcs}->addfunc("sinh", [["in", undef, $number, 0]],\&sinh,$env);
   $env->{funcs}->addfunc("cosh", [["in", undef, $number, 0]],\&cosh,$env);
   $env->{funcs}->addfunc("tanh", [["in", undef, $number, 0]],\&tanh,$env);
   $env->{funcs}->addfunc("arcsin", [["in", undef, $number, 0]],\&arcsin,$env);
   $env->{funcs}->addfunc("arccos", [["in", undef, $number, 0]],\&arccos,$env);
   $env->{funcs}->addfunc("arctan", [["in", undef, $number, 0]],\&arctan,$env);
   $env->{funcs}->addfunc("arcsinh", [["in", undef, $number, 0]],\&arcsinh,$env);
   $env->{funcs}->addfunc("arccosh", [["in", undef, $number, 0]],\&arccosh,$env);
   $env->{funcs}->addfunc("arctanh", [["in", undef, $number, 0]],\&arctanh,$env);
   $env->{funcs}->addfunc("asin", [["in", undef, $number, 0]],\&arcsin,$env);
   $env->{funcs}->addfunc("acos", [["in", undef, $number, 0]],\&arccos,$env);
   $env->{funcs}->addfunc("atan", [["in", undef, $number, 0]],\&arctan,$env);
   $env->{funcs}->addfunc("asinh", [["in", undef, $number, 0]],\&arcsinh,$env);
   $env->{funcs}->addfunc("acosh", [["in", undef, $number, 0]],\&arccosh,$env);
   $env->{funcs}->addfunc("atanh", [["in", undef, $number, 0]],\&arctanh,$env);
   $env->{funcs}->addfunc("abs", [["in", undef, undef, 0]],\&abs,$env);
   $env->{funcs}->addfunc("floor", [["in", undef, undef, 0]],\&floor,$env);
   $env->{funcs}->addfunc("ceil", [["in", undef, undef, 0]],\&ceil,$env);
   $env->{funcs}->addfunc("int", [["in", undef, undef, 0]],\&int,$env);
   $env->{funcs}->addfunc("rint", [["in", undef, undef, 0]],\&rint,$env);
   $env->eval("round{x, d isa 1} := {var m = x * 10 ** d; rint[m] * 10 ** -d+0.0};");
   $env->{funcs}->addfunc("trunc", [["in", undef, undef, 0]],\&int,$env);
   $env->{funcs}->addfunc("numerator", [["in", undef, $number, 0]],\&numerator,$env);
   $env->{funcs}->addfunc("denominator", [["in", undef, $number, 0]],\&denominator,$env);
   
   $env->{funcs}->addfunc("real", [["in", undef, $number, 0]],\&real,$env);
   $env->{funcs}->addfunc("imag", [["in", undef, $number, 0]],\&imag,$env);
   $env->eval("imaginary{x isa 1} := imag[x]");
   $env->{funcs}->addfunc("conj", [["in", undef, $number, 0]],\&conj,$env);
   $env->{funcs}->addfunc("norm", [["in", undef, $number, 0]],\&norm,$env);
   
   $env->{funcs}->addfunc("isprime", [["in", undef, $number, 0]],\&isprime,$env);
   $env->{funcs}->addfunc("prime", [["in", undef, $number, 0]],\&prime,$env);
	$env->{funcs}->addfunc("precprime", [["in", undef, $number, 0]],\&precprime,$env);
	$env->{funcs}->addfunc("nextprime", [["in", undef, $number, 0]],\&nextprime,$env);
	$env->{funcs}->addfunc("factor", [["in", undef, $number, 0]],\&factor,$env);
   
   $env->{funcs}->addfunc("randmax", [["in", undef, $number, 0]],\&randmax,$env);
   $env->{funcs}->addfunc("getrseed", [[]],\&getrseed,$env);
   $env->{funcs}->addfunc("setrseed", [[]],\&setrseed,$env);
   $env->eval("random{} := randmax[10**30]/10.0**30");
   $env->eval("quad{a isa 1, b isa 1, c isa 1} := [(-b + sqrt[b^2 - 4 a c]) / 2a, (-b - sqrt[b^2 - 4 a c]) / 2a]");
   $env->eval("quadratic{a, b, c} := quad[a,b,c]");
   $env->eval("randrange{x,y} := {var min=min[x,y]; var max=max[x,y]; min+randmax[max-min+1]}");

   $env->{funcs}->addfunc("gcd", [["left", undef, $number, 0],["right", undef, $number, 0]],\&gcd,$env);
   $env->{funcs}->addfunc("lcm", [["left", undef, $number, 0],["right", undef, $number, 0]],\&lcm,$env);

   #these functions are simple enough to implement in farnsworth itself, so why not
   $env->{funcs}->addfunc("sqrt", [["in", undef, undef, 0]],\&sqrt,$env); #putting in like this to see if it brings better luck
   $env->eval("i := sqrt[-1]"); #since we have a better sqrt, use it to make a better i
#   $env->eval("sqrt{x} := {x ^ 0.5}"); 
   $env->eval("exp{x isa 1} := {e ^ x}");
   $env->eval("inv{x} := {1/x}"); 
   $env->eval("recip{x} := {1/x}"); 

   #$env->eval("_tohex{x isa 1} := { if(x < 16) { substrLen[\"0123456789abcdef\", x, 1] } else { _tohex[floor[x/16]] + _tohex[x%16] } }; tohex{x isa 1} := {\"0x\"+_tohex[x]}");

}

sub sqrt
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too

	my $units = $input->getdimen();
	$units = $units->mult(PARI '1/2'); #half them all!

	return  Language::Farnsworth::Value::Pari->new(Math::Pari::sqrt($input->getpari()), $units);
}

sub sin
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too

	return Language::Farnsworth::Value::Pari->new(Math::Pari::sin($input->getpari()));
}

sub cos
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too

	return  Language::Farnsworth::Value::Pari->new(Math::Pari::cos($input->getpari()));
}

sub tan
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too

	return  Language::Farnsworth::Value::Pari->new(Math::Pari::tan($input->getpari()));
}

sub arcsin
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too

	return  Language::Farnsworth::Value::Pari->new(Math::Pari::asin($input->getpari()));
}

sub arccos
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too

	return  Language::Farnsworth::Value::Pari->new(Math::Pari::acos($input->getpari()));
}

sub arctan
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too

	return  Language::Farnsworth::Value::Pari->new(Math::Pari::atan($input->getpari()));
}

sub sinh
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too

	return Language::Farnsworth::Value::Pari->new(Math::Pari::sinh($input->getpari()));
}

sub cosh
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too

	return Language::Farnsworth::Value::Pari->new(Math::Pari::cosh($input->getpari()));
}

sub tanh
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too

	return Language::Farnsworth::Value::Pari->new(Math::Pari::tanh($input->getpari()));
}

sub arcsinh
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too

	return Language::Farnsworth::Value::Pari->new(Math::Pari::asinh($input->getpari()));
}

sub arccosh
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too

	return Language::Farnsworth::Value::Pari->new(Math::Pari::acosh($input->getpari()));
}

sub arctanh
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too

	return Language::Farnsworth::Value::Pari->new(Math::Pari::atanh($input->getpari()));
}

sub abs
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too

	return Language::Farnsworth::Value::Pari->new(Math::Pari::abs($input->getpari()), $input->getdimen());
}

sub floor
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too

	return Language::Farnsworth::Value::Pari->new(Math::Pari::floor($input->getpari()), $input->getdimen());
}

sub ceil
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too

	return Language::Farnsworth::Value::Pari->new(Math::Pari::ceil($input->getpari()), $input->getdimen());
}

sub int
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too

	my $e = PARI '0';
	my $r = Language::Farnsworth::Value::Pari->new(Math::Pari::truncate($input->getpari(),$e), $input->getdimen());
	debug 5, Data::Dumper->Dump([$r], ["\$r"]);
	return $r;
}

sub numerator
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too

	#bug? should i make it pull the positive dimensions?
	return Language::Farnsworth::Value::Pari->new(Math::Pari::numerator($input->getpari()));
}

sub denominator
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too

	#bug? should i make it pull the negative dimensions?
	return Language::Farnsworth::Value::Pari->new(Math::Pari::denominator($input->getpari()));
}

sub real
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too
	
	return  Language::Farnsworth::Value::Pari->new(Math::Pari::real($input->getpari()), $input->getdimen());
}

sub imag
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too
	
	return  Language::Farnsworth::Value::Pari->new(Math::Pari::imag($input->getpari()), $input->getdimen());
}

sub conj
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too
	
	return  Language::Farnsworth::Value::Pari->new(Math::Pari::conj($input->getpari()), $input->getdimen());
}

sub norm
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too
	
	return  Language::Farnsworth::Value::Pari->new(Math::Pari::norm($input->getpari()), $input->getdimen());
}

sub isprime
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too
	
	return Language::Farnsworth::Value::Boolean->new(Math::Pari::isprime($input->getpari()));
}

sub prime
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too
	
	return Language::Farnsworth::Value::Pari->new(Math::Pari::prime($input->getpari()));
}

sub nextprime
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too
	
	return Language::Farnsworth::Value::Pari->new(Math::Pari::nextprime($input->getpari()));
}

sub precprime
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too
	
	return Language::Farnsworth::Value::Pari->new(Math::Pari::precprime($input->getpari()));
}

sub factor
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too
	
	return Language::Farnsworth::Value::Pari->new(Math::Pari::factor($input->getpari()));
}

sub randmax
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too
	
	return Language::Farnsworth::Value::Pari->new(Math::Pari::random($input->getpari()));
}

sub setrseed 
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too
	
	my $oldseed = Math::Pari::getrand();
	Math::Pari::setrand($input->getpari());

	return Language::Farnsworth::Value::Pari->new($oldseed);
}

sub getrseed 
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	return Language::Farnsworth::Value::Pari->new(Math::Pari::getrand());
}

sub rint
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too

	#die "Argument to rint[] is not a numeric value" unless $input->isPARI();
	my $e = PARI '0';
	return  Language::Farnsworth::Value::Pari->new(Math::Pari::round($input->getpari(), $e), $input->getdimen());
}

sub gcd
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $left = $eval->{vars}->getvar("left"); #i should clean this up more too
	my $right = $eval->{vars}->getvar("right"); #i should clean this up more too
	
	return Language::Farnsworth::Value::Pari->new(Math::Pari::gcd($left->getpari(), $right->getpari()));
}

sub lcm
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $left = $eval->{vars}->getvar("left"); #i should clean this up more too
	my $right = $eval->{vars}->getvar("right"); #i should clean this up more too
	
	return Language::Farnsworth::Value::Pari->new(Math::Pari::lcm($left->getpari(), $right->getpari()));
}

sub log
{
	#with an array we give the number of elements, with a string we give the length of the string
	my ($args, $eval, $branches)= @_;

	my $input = $eval->{vars}->getvar("in"); #i should clean this up more too

	return Language::Farnsworth::Value::Pari->new(Math::Pari::log($input->getpari()));
}

1;
