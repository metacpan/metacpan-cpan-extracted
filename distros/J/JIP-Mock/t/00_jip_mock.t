#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More;
use English qw(-no_match_vars);

BEGIN {
    use_ok 'JIP::Mock';
}

## no critic (TestingAndDebugging::RequireTestLabels)

package TestMe;

use strict;
use warnings;

package main;

subtest 'Require some module' => sub {
    require_ok 'JIP::Mock';

    diag(
        sprintf(
            'Testing JIP::Mock %s, Perl %s, %s',
            $JIP::Mock::VERSION,
            $PERL_VERSION,
            $EXECUTABLE_NAME,
        ),
    );
};

subtest 'Exportable function - take_control()' => sub {
    can_ok 'JIP::Mock', qw(take_control);

    eval {
        take_control();

        return;
    };

    like $EVAL_ERROR, qr{
        Undefined \s subroutine \s &main::take_control \s called
    }x;
};

subtest 'take_control()' => sub {
    my $package = 'TestMe';

    my $control = JIP::Mock::take_control($package);

    ok $control, 'got instance of JIP::Mock::Control';

    isa_ok $control, 'JIP::Mock::Control';

    is $control->package(),    $package;
    is $control->want_array(), undef;
};

subtest 'take_control() when want_array is present' => sub {
    my $package    = 'TestMe';
    my $want_array = !!1;

    my $control = JIP::Mock::take_control(
        $package,
        want_array => $want_array,
    );

    is $control->package(),    $package;
    is $control->want_array(), $want_array;
};

done_testing();
