use strict;
use Test::More;
use lib("t/lib");
use GunghoTest;

BEGIN
{
    my $error;
    if (! GunghoTest::assert_engine()) {
        $error = "No engine available";
    } else {
        foreach my $module qw(URI WWW::RobotRules::Parser DB_File) {
            next unless $module;
            eval "use $module";
            if ($@) {
                $error = "$module not installed: $@";
                last;
            }
        }
    }

    if ($error) {
        plan(skip_all => $error);
    } else {
        plan(tests => 7);
        use_ok("Gungho");
    }
}

Gungho->bootstrap({ 
    user_agent => "Install Test For Gungho $Gungho::VERSION",
    components => [
        'RobotRules'
    ],
    provider => {
        module => 'Simple'
    }
});

can_ok('Gungho', 'pending_robots_txt');
can_ok('Gungho', 'robot_rules_parser');
can_ok('Gungho', 'robot_rules_storage');
can_ok('Gungho', 'allowed');
can_ok('Gungho', 'handle_response');

isa_ok(Gungho->robot_rules_parser, "WWW::RobotRules::Parser");

1;