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

my $time_num = (time - 100) * 1000;
my $time_str = $time_num;
$time_str .= '';

for my $time ($time_num, $time_str) {
    my $settime_return = $date->setTime($time);
    is(
        $settime_return,
        $date->getTime(),
        "setTime() returns as expected",
    );

    is(
        $js->eval("mydate.getTime()"),
        $time,
        "setTime() has the intended effect",
    );
}

for my $settable (@settables) {
    my $value_to_set = '' . (($settable eq 'FullYear') ? 1976 : 11);

    for my $settable2 ( $settable, "UTC$settable" ) {
        my $setter = "set$settable2";

        my $getter = "get$settable2";

        # print "calling $setter($value_to_set)\n";

        my $setter_return = $date->$setter($value_to_set);

        is(
            $setter_return,
            $date->getTime(),
            "$setter() returns as expected",
        );

        is(
            $js->eval("mydate.get$settable2()"),
            $value_to_set,
            "$setter($value_to_set)",
        );

        # Avoid this bug: https://github.com/bellard/quickjs/issues/238
        if ($^O ne 'MSWin32' || $settable ne 'FullYear') {
            $date->$setter(-$value_to_set);
            is(
                $js->eval("mydate.get$settable2()"),
                $date->$getter(),
                "$setter(-$value_to_set)",
            );
        }
    }
}

done_testing;

1;
