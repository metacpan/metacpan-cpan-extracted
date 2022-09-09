#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::FailWarnings;
use Test::Fatal;

use JavaScript::QuickJS;

my $js = JavaScript::QuickJS->new();

my $date = $js->eval('let mydate = new Date(); mydate');

isa_ok($date, 'JavaScript::QuickJS::Date', 'JS Date() object');

my @settables = qw( Milliseconds Seconds Minutes Hours Date Month FullYear );

my @getters = (
    ( map { "get$_" }
        ( map { $_, "UTC$_" }
           @settables, 'Day',
        ),
        'TimezoneOffset',
        'Time',
    ),
    ( map { "to$_" }
        'String',
        'JSON',
        ( map { "${_}String" }
            qw( UTC GMT ISO Date Time Locale LocaleDate LocaleTime ),
        ),
    ),
);

for my $getter (@getters) {
    my $perl_got = $date->$getter();
    my $js_got = $js->eval("mydate.$getter()");

    is($perl_got, $js_got, "$getter() is the same in Perl and JS");
}

my $INT32_MAX = ( 1 << 31 ) - 1;
my $INT32_MIN = -$INT32_MAX - 1;

for my $settable (@settables) {
    my $value = '42';   # string on purpose

    for my $settable2 ( $settable, "UTC$settable" ) {
        my $setter = "set$settable2";

        my $getter = "get$settable2";

        my $setter_return = $date->$setter($value);

        is(
            $setter_return,
            $date->getTime(),
            "$setter() returns as expected",
        );

        is(
            $js->eval("mydate.get$settable2()"),
            $date->$getter(),
            "$setter($value)",
        );

        $date->$setter(-$value);
        is(
            $js->eval("mydate.get$settable2()"),
            $date->$getter(),
            "$setter(-$value)",
        );
    }
}

done_testing;

1;
