use HackaMol::X::NERF;
use Modern::Perl;
use Data::Dumper;
use Time::HiRes qw(time);

my $bld = HackaMol::X::NERF->new;

my @vecs = ();

push @vecs, $bld->init() ; # returns a Math::Vector::Real object
push @vecs, $bld->extend_a(  $vecs[0]  ,   1.47            );
push @vecs, $bld->extend_ab( @vecs[0,1],   1.47, 120.0     );

foreach my $j (3 .. 999){
  push @vecs, $bld->extend_abc(@vecs[$j-3,$j-2,$j-1], 1.47, 120.0, 20 );
}

print "1000\n\n";
printf ("C %10.6f %10.6f %10.6f\n", @$_ ) foreach @vecs;

