use strict;
use Test::More;
use lib("t/lib");
use GunghoTest;

BEGIN
{
    if (! GunghoTest::assert_engine()) {
        plan(skip_all => "No engine available");
    } else {
        eval "use HTML::RobotsMETA";
        if ($@) {
            plan(skip_all => "HTML::RobotsMETA not installed: $@");
        } else {
            plan(tests => 4);
            use_ok("Gungho");
        }
    }
}

Gungho->bootstrap({ 
    user_agent => "Install Test For Gungho $Gungho::VERSION",
    components => [
        'RobotsMETA'
    ],
    provider => {
        module => 'Simple'
    }
});

can_ok('Gungho', 'robots_meta');
ok(Gungho->robots_meta);
isa_ok(Gungho->robots_meta, "HTML::RobotsMETA");

1;