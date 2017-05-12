use strict;
use warnings;
use 5.010;
use Carp;

use Test::More;
use Test::Exception;
use Test::Builder;

use_ok 'Lembas';

new_ok 'Lembas', [ shell => 'examples/ush',
                   commands => [ { command => 'preamble' },
                                 { outputs => { match_type => 're',
                                                output => '' } } ] ];

my $lembas;

lives_ok(sub { $lembas = Lembas->new(commands => [],
                                     shell => 'examples/ush') },
         q{... and the shell attribute can be passed as a string});
is_deeply($lembas->shell, [ qw{examples/ush} ],
          q{... and it is coerced to an arrayref});

lives_ok(sub { $lembas = Lembas->new(commands => [],
                                     shell => [ 'examples/ush',
                                                '--horns' => 1 ]) },
         q{... and the shell attribute can be passed as an arrayref});
is_deeply($lembas->shell, [ qw{examples/ush --horns 1} ],
          q{... and it stays that way});

is($lembas->builder, Test::Builder->new,
       q{... and we can grab the global Test::Builder instance});

done_testing;
