#!/usr/bin/env perl
# 
use Modern::Perl;
use Math::Vector::Real;
use Time::HiRes qw(time);
use Benchmark qw(cmpthese);
use Scalar::Util qw(refaddr);
use HackaMol::Atom;

my $natoms = 100000;
print
"Atom-timer will time the construction of an array of  $natoms atoms to give idea about speed\n";

my $t1 = time;
my @atoms = map { HackaMol::Atom->new( Z => 80 ) } 1 .. $natoms;

my $t2 = time;
printf( "Time to Atom->new(Z => 80) for $natoms atoms: %10.3f\n", $t2 - $t1 );

my $t3;
foreach my $t ( 1 .. 3 ) {
    $_->push_coords( V( 2, 2, 2 ) ) foreach @atoms;
    $t3 = time;
    printf(
"$t time to push_coords( V(2.000,2.000,2.000) ) for $natoms atoms: %10.3f\n",
        $t3 - $t2 );
    $t2 = time;
}

foreach my $t ( 1 .. 3 ) {
    $atoms[$t]->push_coords( V( 2, 2, 2 ) ) foreach 1 .. 100;
    $t3 = time;
    printf(
"Time to push_coords( V(2.000,2.000,2.000) ) 100 times for atom $t: %.3g\n",
        $t3 - $t2 );
    $t2 = time;
}

$_->set_coords( 0, V( 1.000, 1.000, 1.000 ) ) foreach @atoms;
my $t4 = time;
printf(
    "Time to set_coords(0, V(1.000 ,1.000,1.000)) for $natoms atoms: %10.3f\n",
    $t4 - $t3 );

print "Dump the last atom: ", $#atoms, "\n";
print $atoms[$#atoms]->dump;

print "grep for some PdbRole defaults\n";

my @ala_atoms = grep { $_->resname eq 'ALA' } @atoms;
my $t5 = time;
printf( "time to grep resname eq ALA setting default: %10.3f\n", $t5 - $t4 );
print $atoms[$#atoms]->dump;
my @ala_atoms2 = grep { $_->resname eq 'ALA' } @atoms;
my $t6 = time;
printf( "time to grep resname eq ALA already set: %10.3f\n", $t6 - $t5 );

my $atoms_ala_atoms_match = 1;
foreach ( 0 .. $#ala_atoms ) {
    $atoms_ala_atoms_match = 0
      unless ( refaddr( $atoms[$_] ) == refaddr( $ala_atoms[$_] ) );
}
if ($atoms_ala_atoms_match) {
    print 'references within @atoms and @ala_atoms match!' . "\n";
}
else {
    print 'references within @atoms and @ala_atoms do not match!' . "\n";
}
print "construction comparison benchmarks Z vs Symbol with: \n";
print "   min attributes, many attributes, min attr with 100 coordinates\n";
cmpthese(
    50000,
    {
        'symb_min____attr' =>
          sub { my $atom = HackaMol::Atom->new( symbol => "HG" ) },
        'Z____min____attr' => sub { my $atom = HackaMol::Atom->new( Z => 80 ) },

        #      'Zmin push    100' => sub {
        #          my $atom = Atom->new( Z => 80 );
        #          $atom->push_coords( [ 1, 0, 3 ] ) foreach ( 1 .. 100 );
        #      },
        #      'symb many   attr' => sub {
        #          my $atom = Atom->new(
        #              symbol => "HG",
        #              mass   => 200.59,
        #              charge => [2],
        #              coords => [ [ 0, 0, 0 ] ],
        #              forces => [ [ 0, 0, 0 ] ],
        #          );
        #      },
        'Z____many___attr' => sub {
            my $atom = HackaMol::Atom->new(
                Z      => 80,
                mass   => 200.59,
                charge => [2],
                coords => [ V( 0, 0, 0 ) ],
                forces => [ V( 0, 0, 0 ) ],
            );
        },
        'Z____100__coords' => sub {
            my $atom = HackaMol::Atom->new(
                name   => 'something',
                coords => [
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                    V( 1, 0, 3 ),
                ],
                Z => 80
            );
        },
    }
);

