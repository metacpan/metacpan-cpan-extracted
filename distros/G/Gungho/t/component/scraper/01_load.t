use strict;
use Test::More;
use lib("t/lib");
use GunghoTest;

BEGIN
{
    if (! GunghoTest::assert_engine()) {
        plan(skip_all => "No engine available");
    } else {
        eval "use Web::Scraper::Config";
        if ($@) {
            plan(skip_all => "Web::Scraper::Config not installed: $@");
        } else {
            plan(tests => 3);
            use_ok("Gungho");
        }
    }
}

Gungho->bootstrap({ 
    user_agent => "Install Test For Gungho $Gungho::VERSION",
    components => [
        'Scraper'
    ],
    provider => {
        module => 'Simple'
    }
});

can_ok('Gungho', 'scrape');
my $response = Gungho::Response->new(200, "OK", undef, <<EOM);
<html>
<head>
    <title>Zero</title>
</head>
<body>
    <ul>
        <li>One</li>
        <li>Two</li>
        <li>Three</li>
    </ul>
</body>
</html>
EOM
my $result = Gungho->scrape($response, {
    scraper => [
        { process => [ 'li', 'text[]', 'TEXT' ] }
    ]
});

is_deeply($result, { text => [ qw(One Two Three) ] });

1;