use strict;
use warnings;
use Test::More tests => 8;
use Test::Exception;

BEGIN { use_ok 'Games::Mastermind::Cracker' }
BEGIN { use_ok 'Games::Mastermind::Cracker::Random' }
BEGIN { use_ok 'Games::Mastermind::Cracker::Sequential' }
BEGIN { use_ok 'Games::Mastermind::Cracker::Basic' }

dies_ok  { Games::Mastermind::Cracker->new             }
         'Games::Mastermind::Cracker is not instantiable';

lives_ok { Games::Mastermind::Cracker::Random->new     }
         'Games::Mastermind::Cracker::Random is instantiable';

lives_ok { Games::Mastermind::Cracker::Sequential->new }
         'Games::Mastermind::Cracker::Sequential is instantiable';

lives_ok { Games::Mastermind::Cracker::Basic->new      }
         'Games::Mastermind::Cracker::Basic is instantiable';

