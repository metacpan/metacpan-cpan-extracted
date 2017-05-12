#!/usr/bin/env perl
# DMR April 30, 2014
#
#   perl examples/g09_pdb.pl ~/some/path
#
# pull coordinates (all) and charges from Gaussian output (path submitted
# on commandline)
# write out pdbs in tmp directory with charges in the bfactor column..
#

use Modern::Perl;
use HackaMol;
use HackaMol::X::Calculator;
use Math::Vector::Real;
use Path::Tiny;
use File::chdir;

my $path = shift || die "pass path to gaussian outputs";

my $hack = HackaMol->new( data => $path, );

foreach my $out ( $hack->data->children(qr/\.out$/) ) {

    my $Calc = HackaMol::X::Calculator->new(
        mol     => HackaMol::Molecule->new,
        out_fn  => $out,
        map_out => \&output_map,
        scratch => 'tmp',
    );

    local $CWD = $Calc->scratch;
    my $pdb = $Calc->out_fn->basename;
    $pdb =~ s/\.out/\.pdb/;

    $Calc->map_output;
    my $mol = $Calc->mol;

    $_->bfact( $_->charge ) foreach $mol->all_atoms;
    $mol->print_pdb_ts([0 .. $mol->tmax], $pdb);

}

#  our function to map molec info from output
sub output_map {
    my $calc  = shift;
    my $resn  = shift || "TMP";
    my $resid = shift || 1;
    my @lines = $calc->out_fn->lines;

    #my @qs    = nbo_qs(@lines);
    my @qs    = mulliken_qs(@lines);
    my @atoms = Zxyz(@lines);

    die "number of charges not equal to number of atoms" if ( @qs != @atoms );

    #add info for pdb printing
    my $i = 1;
    foreach my $at (@atoms) {
        $at->serial($i);
        $at->resname($resn);
        $at->resid($resid);
        $i++;
    }

    $atoms[$_]->push_charges( $qs[$_] ) foreach 0 .. $#qs;
    $calc->mol->push_atoms(@atoms);

}

sub Zxyz {

    #pull all coordinates... not at all optimized for speed!
    my @lines = @_;

    my @ati_zxyz = grep { m/(\s+\d+){3}(\s+-?\d+.\d+){3}/ }
      grep {
        m/(Input orientation)|(Standard orientation):|(Z-Matrix orientation:)/
          .. m/(Stoichiometry)|(Distance matrix \(angstroms\))|(Rotational constants) /
      } @lines;

    my @splits = map { [split] } @ati_zxyz;
    my @ati    = map { $_->[0] - 1 } @splits;
    my @Z      = map { $_->[1] } @splits;
    my @x      = map { $_->[3] } @splits;
    my @y      = map { $_->[4] } @splits;
    my @z      = map { $_->[5] } @splits;

    my @atoms;

    foreach my $i ( 0 .. $#ati ) {

        my $iat = $ati[$i];
        my $Z   = $Z[$i];
        my $xyz = V( $x[$i], $y[$i], $z[$i] );

        if ( $atoms[$iat] ) {
            die "atomtype mismatch while reading multiple coordinates"
              if ( $Z != $atoms[$iat]->Z );
            $atoms[$iat]->push_coords($xyz);
        }
        else {
            $atoms[$iat] =
              HackaMol::Atom->new( name => 'TMP', Z => $Z, coords => [$xyz] );
            $atoms[$iat]->name( $atoms[$iat]->symbol . $iat );
        }
    }

    return @atoms;

}

sub mulliken_qs {
    my @lines = @_;
    my @imuls = grep { $lines[$_] =~ m/Mulliken atomic charges/ } 0 .. $#lines;
    my @mull_ls =
      grep { m/\s+\d+\s+\w+\s+-*\d+/ } @lines[ $imuls[-2] .. $imuls[-1] ];
    my @mull_qs = map { $_->[2] } map { [split] } @mull_ls;
    return @mull_qs;
}

sub nbo_qs {
    my @lines = @_;
    my @inbos =
      grep { $lines[$_] =~ m/(\s){5}Natural Population/ } 0 .. $#lines;
    return 0 unless @inbos;
    my @nbo_ls =
      grep { m/\s+\w+\s+\d+\s+-*\d+.\d+/ } @lines[ $inbos[-2] .. $inbos[-1] ];
    my @nbo_qs = map { $_->[2] } map { [split] } @nbo_ls;
    return @nbo_qs;
}

