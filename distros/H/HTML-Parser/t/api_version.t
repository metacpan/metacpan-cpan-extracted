use strict;
use warnings;

use HTML::Parser ();
use Test::More tests => 4;

my $p = HTML::Parser->new(api_version => 3);
ok(!$p->handler("start"), "API version 3");

my $error;
my $success = 0;
{
    local $@;
    #<<<  do not let perltidy touch this
    $error = $@ || 'Error' unless eval {
        my $p = HTML::Parser->new(api_version => 4);
        $success = 1;
    };
    #>>>
}

like($error, qr/^API version 4 not supported/, 'API v4 error');
ok(!$success, "!API version 4");

$p = HTML::Parser->new(api_version => 2);
is($p->handler("start"), "start", "API version 2");
