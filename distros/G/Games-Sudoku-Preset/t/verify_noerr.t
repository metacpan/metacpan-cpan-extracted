use strict;
use warnings FATAL => 'all';
use Test::More;

# CPAN Authors FAQ
use Tk;
my $mw = eval { MainWindow->new };
if (!$mw) { plan( skip_all => "Tk needs a graphical monitor" ); }
use Config;
my $path_to_perl = $Config{perlpath};

plan tests => 1;

use Games::Sudoku::Preset;

# pass game as ref to array

my @game = split("\n", <<END);
# Hidden singles only

uuu u9u u42
u35 2u1 uuu
9uu 3uu u7u

uuu u12 uu6
u8u uu5 uuu
u1u 6uu uuu

u97 uuu 81u
25u uuu uu7
8uu uuu u6u
END
#diag( "noerr.t: game \n", @game, "\nLength ", scalar @game);
my $puzzle = Games::Sudoku::Preset->validate(\@game);
#diag "puzzle +$puzzle+";
is($puzzle,
   'uuuu9uu42u352u1uuu9uu3uuu7uuuuu12uu6u8uuu5uuuu1u6uuuuuu97uuu81u25uuuuuu78uuuuuu6u',
   'verify puzzle without errors'
  );

