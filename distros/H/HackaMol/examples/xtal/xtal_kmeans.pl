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

my $pdbid = shift || '2cba';
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

# bin up the symops
my %sym_op = (); 
foreach my $line ( @symop_lines ) {
    my @entries = split(/\s+/, $line);
    push @{$sym_op{$entries[3]}}, V(@entries[4,5,6,7]);
}

# build the p1 unit cell
printf ("%8.3f %8.3f %8.3f\n", @{ $cart_to_fract->( $mol->COM )} );
recenter($cart_to_fract,$mol,$av,$bv,$cv);

my @kmeans = kmeans_mvr(map{$_->xyz} $mol->all_atoms);
my $i = 0;
my $cg_mol = HackaMol::Molecule->new(
                atoms => [
                          map{HackaMol::Atom->new(
                          Z => '80',
                          name => 'HG2',
                          resname => 'HG2',
                          resid => ++$i, 
                          serial => $i,
                          occ => 1.0,
                          bfact => 20.0, 
                          coords => [$_]
                )} @kmeans]
);

$cg_mol->print_pdb("$pdbid\_cg_mol.pdb");

my $xtal_mol = $hack->read_file_mol("$pdbid\_cg_mol.pdb");

$mol->print_pdb( "$pdbid\_asy.pdb" );
printf ("%8.3f %8.3f %8.3f\n", @{ $cart_to_fract->( $mol->COM )} );

my $i_chain = 1;
my $serial = $mol->count_atoms + 1;
foreach my $symop (grep {$_ ne 1} keys %sym_op){
    my @mat_d = @{$sym_op{$symop}};
    my $cx = V(map{$_->[0]} @mat_d);
    my $cy = V(map{$_->[1]} @mat_d);
    my $cz = V(map{$_->[2]} @mat_d);
    my $dxyz = V(map{$_->[3]} @mat_d);

    my $lmol = $hack->read_file_mol("$pdbid\_asy.pdb"); 
    foreach my $atom ($lmol->all_atoms){
        my ($x,$y,$z) = @{$atom->xyz};
        my $chain = chain_incr($atom->chain,$i_chain);
        my $xyz_new = $x*$cx + $y*$cy + $z*$cz + $dxyz;  
        #              + $da * $av + $db * $bv + $dc * $cv; # -$bv + $av ;
        $atom->chain($chain);
        $atom->set_coords(0,$xyz_new);
        $atom->serial( ++$serial );
        $mol->push_atoms($atom);
    }
    $i_chain++;
    recenter($cart_to_fract,$lmol,$av,$bv,$cv);
    foreach my $atom ($lmol->all_atoms){
        if ( grep {$atom->distance( $_ ) <= 20} $cg_mol->all_atoms){
            if (grep {$atom->distance($_) <= 7.0} $mol->select_group('protein')->all_atoms){
                say "pushing atom!";
                $atom->chain('Z');
                $xtal_mol->push_atoms($atom);
            }
        }
    }
    my $cent = $cart_to_fract->( $lmol->COM );
    printf ("%8.3f %8.3f %8.3f\n", @{ $cart_to_fract->( $lmol->COM )} );
}

$mol->print_pdb("$pdbid\_p1.pdb"); 

foreach my $na (-1,0,1){
  foreach my $nb (-1,0,1){
    foreach my $nc (-1,0,1){
      next if (!$na and !$nb and !$nc); # dont repeat 0 0 0
      my $lmol = $hack->read_file_mol("$pdbid\_p1.pdb"); 
      print "translation $na av; $nb bv ; $nc cv\n";
      my $dxyz = $na*$av + $nb*$bv +$nc*$cv;
      foreach my $atom ($lmol->all_atoms){
        my $xyz_new = $atom->xyz + $dxyz;
        #$atom->push_coords($xyz_new);
        $atom->set_coords(0,$xyz_new);
        #$atom->serial( ++$serial );
        if ( grep {$atom->distance( $_ ) <= 20} $cg_mol->all_atoms){
            if (grep {$atom->distance($_) <= 7.0} $mol->select_group('protein')->all_atoms){
                say "pushing atom!";
                $atom->chain('Z');
                $xtal_mol->push_atoms($atom);
            }
        }
      }
    }
  }
}

#$xtal_mol->select_group('.not. Z 80')->print_pdb("$pdbid\_xtal.pdb");
$xtal_mol->print_pdb("$pdbid\_xtal.pdb");
my $asy = $hack->read_file_mol("$pdbid\_asy.pdb");
$asy->push_atoms($xtal_mol->all_atoms);
$asy->print_pdb("$pdbid\_asy_xtal.pdb");
exit;
foreach my $t (0 .. $mol->tmax) {
    $mol->t($t);
    printf ("%8.3f %8.3f %8.3f\n", @{ $cart_to_fract->( $mol->COM )} );
    say "$pdbid\_$t.pdb";
    my $label = $t =~  /\d\d/ ? $t : "0$t"; 
    $mol->print_pdb("$pdbid\_$label.pdb");
}

sub kmeans_mvr{
  my @mvr = @_;
  
  my $tree = Math::Vector::Real::kdTree->new(@mvr);

  my @means;
  my @dist;
  my $ki = 20;
  my $rcut = 7.5;

  while ($ki){
    @means = $tree->k_means_start($ki);
    @means = $tree->k_means_loop(@means);
    my @ineigh = Math::Vector::Real::Neighbors->neighbors(@means);
    @dist = map {$means[$_]->dist($means[$ineigh[$_]]) } 0 .. $#ineigh;
    if (grep {$_ < $rcut} @dist){
      $ki--;
      next;
    }
    else {
      last;
    }
  }
  
  return @means;

}

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

sub chain_incr{
  my $chain  = shift;
  my $repeat = shift;
  if ($repeat <= 0){
    return $chain;
  }
  $repeat--;
  if ($chain eq ' '){
    chain_incr('A',$repeat);
  }
  elsif(lc($chain) eq 'z'){
    chain_incr(1,$repeat);
  }
  chain_incr(++$chain,$repeat);
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

