use strict;
use warnings;

use HTML::Parser ();
use Test::More tests => 11;

{

    package MyParser;
    use strict;
    use warnings;
    require HTML::Parser;
    our @ISA = qw(HTML::Parser);

    sub foo {
        Test::More::is($_[1]{testno}, Test::More->builder->current_test + 1);
    }

    sub bar {
        Test::More::is($_[1], Test::More->builder->current_test + 1);
    }

    1;
}

my $p = MyParser->new(api_version => 3);

{
    local $@;
    my $error;

    #<<<  do not let perltidy touch this
    $error = $@ || 'Error' unless eval {
        $p->handler(foo => "foo", "foo");
        1;
    };
    #>>>
    like($error, qr/^No handler for foo events/);
}

{
    local $@;
    my $error;

    #<<<  do not let perltidy touch this
    $error = $@ || 'Error' unless eval {
        $p->handler(start => "foo", "foo");
        1;
    };
    #>>>
    like($error, qr/^Unrecognized identifier foo in argspec/);
}

my $h = $p->handler(start => "foo", "self,tagname");
ok(!defined($h));

my $x = \substr("xfoo", 1);
$p->handler(start => $$x, "self,attr");
$p->parse("<a testno=4>");

$p->handler(start => \&MyParser::foo, "self,attr");
$p->parse("<a testno=5>");

$p->handler(start => "foo");
$p->parse("<a testno=6>");

$p->handler(start => "bar", "self,'7'");
$p->parse("<a>");

{
    local $@;
    my $error;

    #<<<  do not let perltidy touch this
    $error = $@ || 'Error' unless eval {
        $p->handler(start => {}, "self");
        1;
    };
    #>>>
    like($error, qr/^Only code or array references allowed as handler/);
}

$x = [];
$p->handler(start => $x);
$h = $p->handler("start");
is($p->handler("start", "foo"), $x);

is($p->handler("start", \&MyParser::foo, ""), "foo");

is($p->handler("start"), \&MyParser::foo);
