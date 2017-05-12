use strict;
use Test::More;
use lib("t/lib");
use GunghoTest;

BEGIN
{
    GunghoTest->plan_or_skip(
        requires   => "POE", 
        test_count => 1
    );
    use_ok("Gungho::Engine::POE");
}
