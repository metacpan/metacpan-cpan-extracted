#!/usr/bin/env perl

use 5.006;
use strict;
use warnings FATAL => 'all';

use Test::More;
use English qw(-no_match_vars);

BEGIN {
    use_ok 'JIP::Mock::Event';
}

## no critic (TestingAndDebugging::RequireTestLabels)

subtest 'Require some module' => sub {
    require_ok 'JIP::Mock::Event';

    diag(
        sprintf(
            'Testing JIP::Mock::Event %s, Perl %s, %s',
            $JIP::Mock::Event::VERSION,
            $PERL_VERSION,
            $EXECUTABLE_NAME,
        ),
    );
};

subtest 'new()' => sub {
    my $method     = 'tratata method';
    my $arguments  = 'tratata arguments';
    my $want_array = 'tratata want_array';
    my $times      = 'tratata times';

    my $sut = JIP::Mock::Event->new(
        method     => $method,
        arguments  => $arguments,
        want_array => $want_array,
        times      => $times,
    );

    isa_ok $sut, 'JIP::Mock::Event';

    is $sut->method(),     $method;
    is $sut->arguments(),  $arguments;
    is $sut->want_array(), $want_array;
    is $sut->times(),      $times;
};

done_testing();
