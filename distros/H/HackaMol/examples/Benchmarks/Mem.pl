use Modern::Perl;
use Devel::Size;
use HackaMol;
use Math::Vector::Real;
use Time::HiRes qw(time);

my $t1 = time;
my @atoms = map {HackaMol::Atom->new(Z=>'1', coords=>[V(rand,rand,rand)])} 0 .. 100000; 
my $t2 = time;

printf ("Time: %.3f\n", $t2-$t1);
