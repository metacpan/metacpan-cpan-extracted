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
        foreach my $module qw(MIME::Base64 URI HTTP::Status HTTP::Headers::Util) {
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
        plan(tests => 3);
        use_ok("Gungho");
    }
}

Gungho->bootstrap({ 
    user_agent => "Install Test For Gungho $Gungho::VERSION",
    components => [
        'Authentication::Basic'
    ],
    provider => {
        module => 'Simple'
    }
});

can_ok('Gungho', 'authenticate');
can_ok('Gungho', 'check_authentication_challenge');

1;