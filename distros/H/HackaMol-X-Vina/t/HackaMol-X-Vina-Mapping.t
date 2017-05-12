#!/usr/bin/env perl

use strict;
use warnings;
use Test::More;
use Test::Dir;
use HackaMol::X::Vina;
use HackaMol;
use Math::Vector::Real;
use Path::Tiny;

my $exe = $ENV{"HOME"}."/bin/vina";

SKIP: {
    skip "vina exe not in ~/bin", 18 unless ( -e $exe );

    my $receptor = path('t/lib/receptor.pdbqt');
    my $lig1     = path('t/lib/lig.pdbqt');
    my $lig2     = path('t/lib/lig.pdbqt');
    my $rmol     = HackaMol->new( hush_read => 1 )->read_file_mol($receptor);
    my $lmol     = HackaMol->new( hush_read => 1 )->read_file_mol($lig1);
    my $ligout   = $lig1->basename;
    $ligout =~ s/\.pdbqt/_out\.pdbqt/;

    my $obj = HackaMol::X::Vina->new(
        receptor       => $receptor->absolute->stringify,
        ligand         => $lig1->absolute->stringify,
        in_fn          => "config.txt",
        out_fn         => $ligout,
        center         => V( 6.865, 3.449, 85.230 ),
        size           => V( 10, 10, 10 ),
        cpu            => 1,
        num_modes      => 2,
        exhaustiveness => 1,
        exe            => $exe,
        scratch        => 't/tmp',
        seed           => 314159,
    );

    my $input = $obj->map_input;
    my @bes   = $obj->map_output;

    is_deeply( scalar(@bes), 2, 'two binding energies computed with vina' );

    $obj->ligand( $lig2->absolute->stringify );

    $input = $obj->map_input;
    @bes   = $obj->map_output;

    is_deeply( scalar(@bes), 2, 'two binding energies computed new ligand' );

    $obj->center( V( 18.073, -2.360, 90.288 ) );

    $input = $obj->map_input;
    @bes   = $obj->map_output;

    is_deeply( scalar(@bes), 2,
        'two binding energies computed with vina new center' );

    my @centers = map { $_->xyz }
      grep { $_->name    eq "OH" }
      grep { $_->resname eq "TYR" } $rmol->all_atoms;

    my $i = 0;
    foreach my $cent ( $centers[0] ) {
        $obj->center($cent);
        $obj->map_input;
        @bes = $obj->map_output;
        is_deeply( scalar(@bes), 2,
            "binding energies computed with vina, TYR $i" );
        $i++;
    }

    $obj->scratch->remove_tree;
    dir_not_exists_ok( "t/tmp", 'scratch directory deleted' );

    {    # try out a minimal instance

        my $vina = HackaMol::X::Vina->new(
            receptor       => $receptor,
            ligand         => $lig1,
            center         => V( 6.865, 3.449, 85.230 ),
            size           => V( 10, 10, 10 ),
            exhaustiveness => 1,                           #nonmiminal
            cpu            => 1,                           #nonmiminal
        );

        my $outlig = $vina->ligand->basename;
        $outlig =~ s/\.pdbqt/\_out\.pdbqt/;

        #  use Data::Dumper;
        #  print Dumper $vina;
        is( $vina->in_fn,  'conf.txt', 'conf.txt is default config file' );
        is( $vina->out_fn, $outlig,    'default output for ligand' );

        my @bes = $vina->dock(2);
        is( scalar(@bes), 2, 'two bes' );
        my $mol = $vina->dock_mol(2);
        is( $mol->tmax,        1,  'two ts loaded into mol' );
        is( $mol->count_atoms, 17, '17 atoms' );
        is( $mol->count_score, 2,  '2 scores' );
        $vina->in_fn->remove;
        $vina->out_fn->remove;
    }

    {    # try out a minimal instance with scratch

        my $vina = HackaMol::X::Vina->new(
            receptor       => $receptor,
            ligand         => $lig1,
            center         => V( 6.865, 3.449, 85.230 ),
            size           => V( 10, 10, 10 ),
            num_modes      => 1,
            scratch        => 't/tmp',
            exhaustiveness => 1,                           #nonmiminal
            cpu            => 1,                           #nonmiminal
        );

        my $outlig = $vina->ligand->basename;
        $outlig =~ s/\.pdbqt/\_out\.pdbqt/;

        #  use Data::Dumper;
        #  print Dumper $vina;
        is( $vina->in_fn,  'conf.txt', 'conf.txt is default config file' );
        is( $vina->out_fn, $outlig,    'default output for ligand' );

        my @bes = $vina->dock;
        is( scalar(@bes), 1, 'one be' );
        my $mol = $vina->dock_mol;
        is( $mol->tmax,        0,  'one ts loaded into mol' );
        is( $mol->count_atoms, 17, '17 atoms' );
        is( $mol->count_score, 1,  '1 scores' );
        $vina->scratch->remove_tree;
        dir_not_exists_ok( "t/tmp", 'scratch directory deleted' );
    }

}

done_testing();

