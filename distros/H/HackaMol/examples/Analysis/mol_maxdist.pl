# Demian Riccardi May 23, 2014
# Quickly find the maximum distance in a molecule
# 
use Modern::Perl;
use Math::Vector::Real::Farthest;
use HackaMol;
use Time::HiRes qw(time);

my $hack = HackaMol->new(
    hush_read => 1,
    data      => "/lustre/pdbqts/NCI_diversitySet2/pdbqt"
);

my @pdbqts = $hack->data->children(qr/\.pdbqt/);

my $t1 = time;
my @ds;
foreach my $pdbqt (@pdbqts) {
    my @xyzs = map { $_->xyz } $hack->read_file_atoms($pdbqt);

    #my ($d2, $v0, $v1) = Math::Vector::Real::Farthest->find_brute_force(@xyzs);
    my ( $d2, $v0, $v1 ) = Math::Vector::Real::Farthest->find(@xyzs);
    push @ds, [ $d2, scalar(@xyzs), $pdbqt ];
}

my $t2 = time;

printf( "Time %10.3f\n", $t2 - $t1 );
printf(
    "nvec: %i max_vec: %10.6f pdbqt: %-50s\n",
    $_->[1], sqrt( $_->[0] ),
    $_->[2]
) foreach @ds;
