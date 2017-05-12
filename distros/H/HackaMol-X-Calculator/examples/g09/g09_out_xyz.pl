#!/usr/bin/env perl
# DMR April 30, 2014
#
#   perl examples/g09_xyz.pl ~/some/path
#
# pull coordinates (all) from Gaussian output (path submitted
# on commandline)
# write out xyzs in tmp directory
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
    my $xyz = $Calc->out_fn->basename;
    $xyz =~ s/\.out/\.xyz/;

    $Calc->map_output;
    my $mol = $Calc->mol;
    $mol->print_xyz_ts([0 .. $mol->tmax],$xyz);

}

#  our function to map molec info from output
sub output_map {
    my $calc  = shift;
    my $resn  = shift || "TMP";
    my $resid = shift || 1;
    my @lines = $calc->out_fn->lines;
    my @atoms = Zxyz(@lines);
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

