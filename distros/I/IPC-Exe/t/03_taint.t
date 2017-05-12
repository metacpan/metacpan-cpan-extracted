#!perl -T

use warnings;
use strict;

use Test::More;
use Scalar::Util qw(tainted);

BEGIN {
    # need 5.6+ for lexical filehandles
    if ($] < 5.006_000)
    {
        plan skip_all => "- Perl v5.6.0+ required.";
    }

    # unfortunately, some platforms are not supported
    #   some of these platforms cannot fork()
    if ($^O =~ /^(?:VMS|dos|MacOS|riscos|amigaos|vmesa)$/)
    {
        plan skip_all => "- platform not supported: $^O";
    }
}

BEGIN { plan tests => 5 }
#BEGIN { plan "no_plan" }

use lib "../lib";
use IPC::Exe qw(exe);

my ($tainted) = grep { defined($_) } values %ENV;
ok(tainted($tainted), "sanity: tainted var");

SKIP: {
    skip("- env: PATH is not tainted", 1) unless tainted($ENV{PATH});

    eval { exe "abc" };
    like($@, qr/called with tainted vars/, "env: tainted");
}

delete @ENV{qw(PATH PATHEXT IFS CDPATH ENV BASH_ENV PERL5SHELL)};

eval { exe "abc" };
is($@, "", "env: no longer tainted");

eval { exe "abc", $tainted };
like($@, qr/called with tainted vars/, "args: tainted");

eval { exe "abc", undef, $ENV{PATH} };
is($@, "", "args: no longer tainted");

