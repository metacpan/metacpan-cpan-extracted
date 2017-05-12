#use Test::More tests => 23;
  
  BEGIN 
  {
 	  eval "use Test::Exception";

    if ($@)
    {
		  eval 'use Test::More; plan skip_all => "Test::Exception needed"' if $@
    }
    else
    {
	    eval 'use Test::More; plan no_plan';
    }

	  use_ok( 'Language::Farnsworth' ); use_ok('Language::Farnsworth::Value'); use_ok('Language::Farnsworth::Output');
  }

require_ok( 'Language::Farnsworth' );
require_ok( 'Language::Farnsworth::Value' );
require_ok( 'Language::Farnsworth::Output' );

my $hubert;
lives_ok { $hubert = Language::Farnsworth->new();} 'Startup'; #will attempt to load everything, doesn't die if it fails though, need a way to check that!.

my @tests = 
(   ["4 + 4",  "8 ",             "addition"],
	["4 4",    "16 ",            "implicit multiplcation"],
	["4 * 4",  "16 ",            "multiplication"],
	["4 per 4", "1 ",            "division, per"],
	["4 / 4",  "1 ",             "division"],
	["4 - 4",  "0 ",             "subtraction"],
#	["4 - 4.", "(0.e-114) ",     "subtraction, floating"], #commented out for errors in floating point stuff, need to fix the tests
	["4 s",    "4 s /* time */", "units, time"],
	["4/0",    undef,            "division by zero"], #undef signals it should die
	["3 + 3 s", undef,           "inconsistent units"], #undef signals it should die
	["2 ** (2 s)", undef,        "units in power"], #undef signals it should die
	["2**2",    "4 ",            "exponents"], #undef signals it should die
	["4s ** 2",  "4 s^2",      "operator precedence"], #operator precedence when having no space doesn't work right! bug in parser
	["4(s)** 2",  "4 s^2",      "operator precedence, with parens 1"],
	["(4)s** 2",  "4 s^2",      "operator precedence, with parens 2"], 
	["(4)(s)** 2",  "4 s^2",      "operator precedence, with parens 3"],
	["(4)2** 2",  "16 ",      "operator precedence, with parens and nums"],
	["4(2)** 2",  "16 ",      "operator precedence, with parens and nums"],
	["log[10 m]", undef,         "log of units"],
	["log[10]",  "1.0 ",         "log"], 
#	["sin[0 radians]",  "(0.e-115) ",      "sin"],  #SAME AS ABOVE!
	["sin[45 degrees]^2",  "0.5 ",         "sin squared"], 
	["var q={`x` x + x}", "{`x` x + x; }",     "lambda + assignment"],
	["q 1", "2 ",                         "lambda call from variable"],
	["q[1]", "2 ",                        "lambda call from variable function syntax"],
	["(q)[1]", "2 ",                      "lambda call from variable forced syntax"],
	["{`x` 42} 1", "42 ",                 "lambda call from anonymous lambda"],
	["{`x` 42}[2]", "42 ",                "lambda call from anonymous lambda, function syntax"],
	["({`x` 42})[2]", "42 ",              "lambda call from anonymous lambda forced syntax"],
	["({`x,y` x * x + x * y + y * y})[3,2]", "19 ", "multi argument lambda call, direct"],
	['var q={`x byref` x=x+1}; var a=1; q a; a', '2 ', 'Lambda passing with byref'],
	["foo{x=1,y = 2 m isa m} := {x y}; 1", "1 ", "Function definition, with defaults and constraints"],
	["foo[]", "2 m /* length */", "function call using defaults"],
	["foo[2]", "4 m /* length */", "function call using one default"],
	["foo[2,3m]", "6 m /* length */", "function call no defaults"],
	["foo[2,3 s]", undef, "function call failing constraint"],
	["defun lfoo = {`x=1,y = 2 m isa m` x y}; 1", "1 ", "Lambda style function definition, with defaults and constraints"],
	["lfoo[]", "2 m /* length */", "lambda function call using defaults"],
	["lfoo[2]", "4 m /* length */", "lambda function call using one default"],
	["lfoo[2,3m]", "6 m /* length */", "lambda function call no defaults"],
	["lfoo[2,3 s]", undef, "lambda function call failing constraint"],
	["defun foo={`` var q=42; {`x` q}} []; foo[10]", "42 ", "Dynamically defined lambda style function"],
	["#today# + 4", undef, "units, date + 1"], #real bug involved here, fixed!
	["#2008-12-13# - #2008-12-12#", "86400 s /* time */", "date subtraction"],
	['"foo" + "bar"', '"foobar"', "string concat"],
	['var a=[1,2,3]; a@2$', '3 ', "array access"],
	['var a=[1,2,3,4]; a@2/2$', '2 ', "array access, rational"],
	['var a=[1,2,3,4]; a@2$=10; a@2$', '10 ', "array storage"],
	['10 m^(3/2)', '10.0 m^(3/2)', "rational powers"],
	['10 m^(1/2)', '10.0 m^(1/2)', "rational powers < 1 with 1 as numerator"],

);


for my $test (@tests)
{
	my $farn = $test->[0];
	my $expected = $test->[1];
	my $name = $test->[2];

	if (defined($expected))
	{
		lives_and {is $hubert->runString($farn), $expected, $name} $name." lives";
	}
	else
	{
		dies_ok {$hubert->runString($farn);} $name;
	}
}
