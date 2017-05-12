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
	use_ok( 'Language::Farnsworth::Error' );
  }

require_ok( 'Language::Farnsworth' );
require_ok( 'Language::Farnsworth::Value' );
require_ok( 'Language::Farnsworth::Output' );
require_ok( 'Language::Farnsworth::Error' );

lives_ok {$Language::Farnsworth::Error::level = 2;} 'setting error level';

my $hubert;
lives_ok { $hubert = Language::Farnsworth->new();} 'Startup'; #will attempt to load everything, doesn't die if it fails though, need a way to check that!.

my @tests = 
(   
	['var a=1; var sub={`x,y` x+y}; vararg{sub isa {``}, x isa ...} := {var input = x@0$ conforms [] ? x@0$ : x; var st = shift[input]; while(length[input] >= 1) {var next = shift[input]; st = sub[st, next];}; st}; vararg[sub, a,a]',        "2 ",             "assignment during use in a loop"],
	['var sub={`x,y` x+y}; vararg{sub isa {``}, x isa ...} := {var input = x@0$ conforms [] ? x@0$ : x; var st = shift[input]; while(length[input] >= 1) {var next = shift[input]; var st2 = sub[st, next];st=st2}; st}; vararg[sub, 1,1]',        "2 ",             "assignment during use in a loop, with work around"],
	['var a=2; var sub={`x,y` x+y}; a=sub[a,a]; a;', '4 ', 'simpler case of above'],
	['{`x=1` x} []', '1 ', 'Default arguments in lambdas'],
    ['var q={`x` x=x+1}; var a=1; q a; a', '1 ', 'Arguments to lambda are not passed by reference'],
    ['foo{bar,} := 1;', undef, 'Empty arguments in functions'],
    ['0x1', '1 ', "Single length hexidecimal numbers"],
    ['0b1', '1 ', "Single length binary numbers"],
    ['01', '1 ', "Single length octal numbers"],
    ['0.9', '0.9 ', "decimals not parsing as octal"],
# this is going to take some redesign in Variables.pm
#    ['var a=42; foo{x byref} := {x = 46; bar[x]}; bar{y byref} := {y = 12}; [a, foo[a], a];', '[42 , 12 , 12 ]', 'nested references'],
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
