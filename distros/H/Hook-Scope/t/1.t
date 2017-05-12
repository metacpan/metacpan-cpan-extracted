# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 1.t'

#########################



use Test::More;
plan tests => 17;
use_ok("Hook::Scope");
ok(1); # If we made it this far, we're ok.
my $test1 = "hi";
{
  Hook::Scope::POST(sub { is($test1,"hi2"); $test1 = "hi3"});
    is($test1,"hi");
    $test1 = "hi2";
}
is($test1,"hi3");

my $test2 = "1";
{
  Hook::Scope::POST(sub { is($test2,"4"); $test2 = 5});
    {
      Hook::Scope::POST(sub { is($test2,"2"); $test2 = "3"});
	is($test2,"1");
	$test2 = "2";
    }
    is($test2,"3");
    $test2 = 4;
}
is($test2, 5);

{
    eval {
      Hook::Scope::POST(sub { pass()});
	die();
    };
    eval {
	{
	  Hook::Scope::POST( sub { pass() });
	    die;
	}
    };
}
my $test3 = 1;
sub foobar {
    is($test3,2);
    $test3 = 3;
}
{
  Hook::Scope::POST('foobar');
    is($test3,1);
    $test3 = 2;
}
is($test3,3);
{
    use Hook::Scope qw(POST);
    my $foo = 1;
    POST { is($foo,2)};
    is($foo,1);
    $foo = 2;
}
