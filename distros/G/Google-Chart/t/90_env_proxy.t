use strict;
use Test::More (tests => 4);


BEGIN {
    use_ok("Google::Chart");
}

note "LWP::UserAgent: $LWP::UserAgent::VERSION\n";

{
    # self note: LWP::UserAgent 5.819 allowed $ENV{HTTP_PROXY} = '',
    # but I got a failure report for LWP::UserAgent 5.821

    local %ENV;
    delete $ENV{HTTP_PROXY};
    my $g = Google::Chart->new(type => 'Line');
    ok(! $g->ua->proxy('http'), "http proxy should not be set");
}

{
    local $ENV{HTTP_PROXY} = 'http://localhost:3128';
    my $g = Google::Chart->new(type => 'Line');
    is($g->ua->proxy('http'), $ENV{HTTP_PROXY}, "http proxy should be set");
}

{
    local $ENV{HTTP_PROXY} = 'http://localhost:3128';
    local $ENV{GOOGLE_CHART_ENV_PROXY} = 0;
    my $g = Google::Chart->new(type => 'Line');
    ok(! $g->ua->proxy('http'), "http proxy should not be set");
}

