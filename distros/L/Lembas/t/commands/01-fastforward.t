use strict;
use warnings;
use 5.010;
use Carp;

use Test::More;
use Test::Exception;
use Test::Builder;
use Test::Builder::Tester;
use IO::Scalar;

use_ok 'Lembas';

my $lembas = new_ok('Lembas', [ shell => [ qw{examples/ush --horns 1} ],
                                commands => [ { shell => undef,
                                                outputs => [
                                                    { match_type => 'regex',
                                                      output => 'This is unicorn-shell version [\\d.]+', },
                                                    { match_type => 'literal',
                                                      output => 'You have asked for a shell with 1 horn(s)' },
                                                    { command => 'fastforward',
                                                      parameters => [ qw/some/ ] },
                                                    { match_type => 'literal',
                                                      output => '' },
                                                    ] } ] ]);

test_out(q{# Matching preamble output...});
test_out(q{ok 1 - regex match of 'This is unicorn-shell version [\d.]+'});
test_out(q{ok 2 - literal match of 'You have asked for a shell with 1 horn(s)'});
test_out(q{# Fastforwarding...});
test_out(q{ok 3 - literal match of ''});
test_out(q{ok 4 - all output tested for '<preamble>'});

$lembas->run;
test_test(q{'fastforward' command ignores output and generates no test});

done_testing;
