use Modern::Perl;
use HackaMol;
use Math::Vector::Real;
use Math::Vector::Real::kdTree;
use Math::Vector::Real::Neighbors;
use Math::Trig qw(deg2rad);
use Math::MatrixReal;
use Scalar::Util qw(looks_like_number);
use Data::Dumper;

my $hack = HackaMol->new();

my $pdbid = shift || die "ARGS: pdbid rcut";
my $rcut  = shift || 5;
my $file  = "pdbs/$pdbid.pdb";

# save the file if we haven't done it
$hack->getstore_pdbid($pdbid,$file) unless -e $file;

# parse the file
my $mol = $hack->read_pdbfile_mol($file);

# pull out xtal info from the header
my @info_lines = split(/\n/,$mol->info); 
my ($latt_line) = grep m/^CRYST1/, @info_lines;
#my @symop_lines = grep m/^REMARK\s\d{3}\s+(SMTRY|BIOMT)/, @info_lines;
my @symop_lines = grep m/^REMARK\s\d{3}\s+(SMTRY)/, @info_lines;

say foreach @symop_lines;
print $latt_line . "\n";

my ($a,$b,$c,$alpha,$beta,$gamma) = grep looks_like_number($_), split (/\s+/,$latt_line);
# get the coordinate tranformation functions
my ($fract_to_cart,$cart_to_fract) = fract_cart([$a,$b,$c],[$alpha,$beta,$gamma]);
# create lattice vectors a, b, c
my $av = $fract_to_cart->(V(1,0,0));
my $bv = $fract_to_cart->(V(0,1,0));
my $cv = $fract_to_cart->(V(0,0,1));

recenter($cart_to_fract,$mol,$av,$bv,$cv);

# bin up the symops
my %sym_op = (); 
foreach my $line ( @symop_lines ) {
    my @entries = split(/\s+/, $line);
    push @{$sym_op{$entries[3]}}, V(@entries[4,5,6,7]);
}


my @atoms = $mol->all_atoms;
my $tree      = Math::Vector::Real::kdTree->new(map {$_->xyz} @atoms);

my @xtal;
my $serial = $atoms[-1]->serial;

foreach my $atom (@atoms){
    my $atom_xyz = $atom->xyz;
    my ($x,$y,$z) = @{$atom_xyz};
    my $resid = $atom->resid;
    my $name = $atom->name;
    my $record_name = $atom->record_name;
    my $Z = $atom->Z;
    my $resname = $atom->resname;
    foreach my $symop (keys %sym_op){
        my @mat_d = @{$sym_op{$symop}};
        my $cx = V(map{$_->[0]} @mat_d);
        my $cy = V(map{$_->[1]} @mat_d);
        my $cz = V(map{$_->[2]} @mat_d);
        my $dxyz = V(map{$_->[3]} @mat_d);

        foreach my $na (-1,0,1){
            foreach my $nb (-1,0,1){
                foreach my $nc (-1,0,1){
                    #skip self
                    next if ($na == 0 && $nb == 0 && $nc == 0 && $symop == 1 );

                    my $trans = $na*$av + $nb*$bv +$nc*$cv;
                    my $xyz_new = $x*$cx + $y*$cy + $z*$cz + $dxyz + $trans;

                    my @ix = $tree->find_in_ball($xyz_new, $rcut);
                    next unless @ix;
                    my $xtal_atom = HackaMol::Atom->new(
                        Z => $Z,
                        resid => $resid,
                        name => $name,
                        resname => $resname,
                        chain   => 'X',
                        coords => [$xyz_new],
                        record_name => $record_name,
                        serial => ++$serial,
                    );
                    $mol->push_atoms($xtal_atom);
                }
            }
        }
    }
}

$mol->print_pdb("$pdbid\_asy_xtal.pdb"); 

sub recenter{
    my ($cart_to_frac,$lmol,$av,$bv,$cv) = @_;

    my $cent = $cart_to_fract->( $lmol->COM );
    my $qav = V(1,0,0);
    my $qbv = V(0,1,0);
    my $qcv = V(0,0,1);
    # recenter a
    if( ($cent - $qav)->abs <  $cent->abs ){
      $lmol->translate(-$av);
      $cent = $cart_to_fract->( $lmol->COM );
    }

    if( ($cent + $qav)->abs < $cent->abs){
      $lmol->translate(+$av);
      $cent = $cart_to_fract->( $lmol->COM );
    }

    # recenter b
    if( ($cent - $qbv)->abs <  $cent->abs ){
      $lmol->translate(-$bv);
      $cent = $cart_to_fract->( $lmol->COM );
    }

    if( ($cent + $qbv)->abs < $cent->abs){
      $lmol->translate(+$bv);
      $cent = $cart_to_fract->( $lmol->COM );
    }

    # recenter c
    if( ($cent - $qcv)->abs <  $cent->abs ){
      $lmol->translate(-$cv);
      $cent = $cart_to_fract->( $lmol->COM );
    }

    if( ($cent + $qcv)->abs < $cent->abs){
      $lmol->translate(+$cv);
      $cent = $cart_to_fract->( $lmol->COM );
    }

}

sub fract_cart {
#perl version of crysFML subroutine: 
#
# Subroutine Get_Cryst_Orthog_Matrix(Cellv,Ang, Crystort,Cartype)
#   real(kind=sp), dimension(3  ), intent (in ) :: cellv           !  In ->  a,b,c parameters
#   real(kind=sp), dimension(3  ), intent (in ) :: ang             !  In ->  angles parameters of cell
#   real(kind=sp), dimension(3,3), intent (out) :: CrystOrt        ! Out ->  Conversion matrix (a) = (e) CrystOrt
#   character (len=1), optional,   intent (in)  :: CarType         !  In ->  Type of Cartesian axes
#
#   (PRIVATE)
#   Obtains the matrix giving the crystallographic basis in
#   direct space in terms of a cartesian basis. The output matrix
#   can be directly used for transforming crystallographic components
#   to Cartesian components of the components of a vector considered
#   as a column vector:   XC = CrystOrt X.
#
#   If CartType is not present, or if it is not equal to 'A',
#   the cartesian system is defined as:
#         z // c; y is in the bc-plane; x is y ^ z
#   a = (a sinbeta singamma*, -a sinbeta cosgamma*, a cosbeta )
#   b = (         0         ,     b sinalpha      , b cosalpha)
#   c = (         0         ,         0           , c         )
#
#   If CartType = 'A', the the cartesian system is defined as:
#        x // a; y is in the ab-plane; z is x ^ z
#   a = (       a   ,         0           ,       0             )
#   b = ( b cosgamma,    b singamma       ,       0             )
#   c = (  c cosbeta, -c sinbeta cosalpha*, c sinbeta sinalpha* )
#
#   The output matrix is the tranposed of the above one(s) so that the
#    matrix can directly be used for transforming "components" given
#    in a crystallographic basis to "components" in cartesian basis
#    when the components are used as "column" vectors.
#
#      [a] = C [e] , In [a],[e] basis vectors are in column form
#      (a) = (e) CT, In (a),(e) basis vectors are in row form
#      CrystOrt = CT  => (a) = (e) CystOrt
#
#    Remember that CT.C = C.CT = GD (direct cell metrics)
#
#
#     Xc = CrystOrt X (Xc Cartesian componets, X crystallographic components)
#
  my ($abc,$angs) = (shift, shift);
  my $cartype = shift || 'a'; 
  my @cellv = @$abc;
  my @ang   = map{deg2rad($_)} @$angs;

  my %CrystOrt;

  if (lc($cartype) eq 'a') {
             #  Transponse of the following matrix:
             #    a = (       a   ,         0           ,       0             )
             #    b = ( b cosgamma,    b singamma       ,       0             )
             #    c = (  c cosbeta, -c sinbeta cosalpha*, c sinbeta sinalpha* )
    my $cosgas =(cos($ang[2])*cos($ang[1])-cos($ang[0]))/(sin($ang[2])*sin($ang[1]));
    my $singas = sqrt(1.0-$cosgas**2);
    $CrystOrt{0}{0} = $cellv[0];
    $CrystOrt{0}{1} = $cellv[1]*cos($ang[2]);
    $CrystOrt{0}{2} = $cellv[2]*cos($ang[1]);
    $CrystOrt{1}{0} = 0.0;
    $CrystOrt{1}{1} = $cellv[1]*sin($ang[2]);
    $CrystOrt{1}{2} =-$cellv[2]*sin($ang[1])*$cosgas;
    $CrystOrt{2}{0} = 0.0;
    $CrystOrt{2}{1} = 0.0;
    $CrystOrt{2}{2} = $cellv[2]*sin($ang[1])*$singas;
  }
 else {
       #
       #  By default, the cartesian frame is such as z//c
       #  Transponse of the following matrix:
       #    a = (a sinbeta singamma*, -a sinbeta cosgamma*, a cosbeta )
       #    b = (         0         ,     b sinalpha      , b cosalpha)
       #    c = (         0         ,         0           , c         )
    my $cosgas = ( cos($ang[0])*cos($ang[1]) - cos($ang[2]) )
               / ( sin($ang[0])*sin($ang[0]) );
    my $singas = sqrt(1.0-$cosgas**2);
    $CrystOrt{0}{0} = $cellv[0]*sin($ang[1])*$singas;
    $CrystOrt{0}{1} = 0.0;
    $CrystOrt{0}{2} = 0.0;
    $CrystOrt{1}{0} =-$cellv[0]*sin($ang[1])*$cosgas;
    $CrystOrt{1}{1} = $cellv[1]*sin($ang[0]);
    $CrystOrt{1}{2} = 0.0;
    $CrystOrt{2}{0} = $cellv[0]*cos($ang[1]);
    $CrystOrt{2}{1} = $cellv[1]*cos($ang[0]);
    $CrystOrt{2}{2} = $cellv[2];
   }

   my $fract_cart_mvr =  [
      V($CrystOrt{0}{0},$CrystOrt{0}{1},$CrystOrt{0}{2}),
      V($CrystOrt{1}{0},$CrystOrt{1}{1},$CrystOrt{1}{2}),
      V($CrystOrt{2}{0},$CrystOrt{2}{1},$CrystOrt{2}{2}),
   ];

  my $fract_to_cart = sub{
    my $fract_mvr = shift;
    my $cart_mvr = V(
            $fract_cart_mvr->[0] * $fract_mvr,
            $fract_cart_mvr->[1] * $fract_mvr,
            $fract_cart_mvr->[2] * $fract_mvr,
    );
    return $cart_mvr;
  };

   my $cort = Math::MatrixReal->new_from_rows(
                [
                  [$CrystOrt{0}{0},$CrystOrt{0}{1},$CrystOrt{0}{2}],
                  [$CrystOrt{1}{0},$CrystOrt{1}{1},$CrystOrt{1}{2}],
                  [$CrystOrt{2}{0},$CrystOrt{2}{1},$CrystOrt{2}{2}],
                ]
             );

   my $cort_inv = $cort->inverse;
   my $cart_fract_mvr =  [
      V($cort_inv->row(1)->as_list),
      V($cort_inv->row(2)->as_list),
      V($cort_inv->row(3)->as_list),
   ];

   my $cart_to_fract = sub{
      my $cart_mvr = shift;
      my $fract_mvr = V(
            $cart_fract_mvr->[0] * $cart_mvr,
            $cart_fract_mvr->[1] * $cart_mvr,
            $cart_fract_mvr->[2] * $cart_mvr,
      );
      return $fract_mvr;
    };

    return ($fract_to_cart, $cart_to_fract);
}

1;

