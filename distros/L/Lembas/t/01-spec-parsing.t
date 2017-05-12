use strict;
use warnings;
use 5.010;
use Carp;

use Test::More;
use Test::Exception;
use Test::Builder;
use IO::Scalar;

use_ok 'Lembas';

my $spec = <<'EOSPEC';
#!examples/ush --horns 1
preamble
re: This is unicorn-shell version [\d.]+
    You have asked for a shell with 1 horn(s)
fastforward some
    Starting REPL...
    
    $ exit

EOSPEC

my $lembas = Lembas->new_from_test_spec(
    handle => IO::Scalar->new(\$spec));

isa_ok($lembas, 'Lembas');
is_deeply($lembas->shell, [ qw{examples/ush --horns 1} ],
          q{... and the shell attribute can be populated from the spec shebang});
is_deeply($lembas->commands, [
              { shell => undef,
                outputs => [
                    { match_type => 'regex',
                      output => 'This is unicorn-shell version [\\d.]+', },
                    { match_type => 'literal',
                      output => 'You have asked for a shell with 1 horn(s)' },
                    { command => 'fastforward',
                      parameters => [ 'some' ] },
                    { match_type => 'literal',
                      output => 'Starting REPL...' },
                    { match_type => 'literal',
                      output => '' } ] },
              { shell => 'exit',
                outputs => [] },
          ],
          q{... and the commands are all listed});
is($lembas->plan_size, 6,
   q{... and they have a plan.});

done_testing;
