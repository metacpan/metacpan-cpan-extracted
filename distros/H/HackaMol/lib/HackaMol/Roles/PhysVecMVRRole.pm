package HackaMol::Roles::PhysVecMVRRole;
$HackaMol::Roles::PhysVecMVRRole::VERSION = '0.044';
# ABSTRACT: Provides the core of HackaMol Atom and Molecule classes.
use Math::Vector::Real;
use Math::Trig;

#use Moose::Util::TypeConstraints;
use Moose::Role;
use Carp;
#use Data::Structure::Util qw (unbless);
#use MooseX::Storage;

#with Storage( 'format' => 'JSON', 'io' => 'File' );

requires qw(_build_mass charge);

#MooseX::Storage::Engine->add_custom_type_handler(
#  'Math::Vector::Real' => (
#      expand    => sub {my $v   = shift; Math::Vector::Real->new(@{$v})},
#      collapse  => sub {my $mvr = shift; return (unbless($mvr)) },
#  )
#);
#use Data::Dumper;
#MooseX::Storage::Engine->add_custom_type_handler(
#  'ArrayRef[Math::Vector::Real]' => (
#      expand    => sub {print Dumper $_; my @vs = map {Math::Vector::Real->new(@{$_}); print $_} @$_; return [@vs] },
#      collapse  => sub {my $a_rf = shift; my @vs = map {unbless($_)} @$a_rf; return \@vs },
#  )
#);


has 't', is => 'rw', isa => 'Int|ScalarRef', default => 0;

has "$_" => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[Math::Vector::Real]',
    default => sub { [] },
    handles => {
        "push_$_"   => 'push',
        "get_$_"    => 'get',
        "delete_$_" => 'delete',
        "set_$_"    => 'set',
        "all_$_"    => 'elements',
        "clear_$_"  => 'clear',
        "count_$_"  => 'count',
    },
    lazy => 1,
) for qw(coords forces);

has "$_" => (
    traits  => ['Array'],
    is      => 'ro',
    isa     => 'ArrayRef[Num]',
    default => sub { [] },
    predicate => 'has_charges',
    handles => {
        "push_$_"   => 'push',
        "get_$_"    => 'get',
        "delete_$_" => 'delete',
        "set_$_"    => 'set',
        "all_$_"    => 'elements',
        "clear_$_"  => 'clear',
        "count_$_"  => 'count',
    },
    lazy => 1,
) for qw(charges);

has 'units', is => 'rw', isa => 'Str';    #flag for future use [SI]

has 'origin' => (
    is      => 'rw',
    isa     => 'Math::Vector::Real',
    default => sub { V( 0, 0, 0 ) },
    lazy    => 1,
);

has 'xyzfree' => (
    is      => 'rw',
    isa     => 'ArrayRef[Int]',
    default => sub { [ 1, 1, 1 ] },
    lazy    => 1,
    trigger => \&_freedom,
    clearer => 'clear_xyzfree',
);

has 'mass' => (
    is      => 'rw',
    isa     => 'Num',
    lazy    => 1,
    clearer => 'clear_mass',
    builder => '_build_mass',
);

sub _freedom {
    my ( $self, $new, $old ) = @_;
    if ( grep { $_ == 0 } @{$new} ) {
        $self->is_fixed(1);
    }
    else {
        $self->is_fixed(0);
    }
}

has 'is_fixed' => (
    is      => 'rw',
    isa     => 'Bool',
    lazy    => 1,
    default => 0,
);

#intraobject methods
sub intra_dcharges {
    my $self = shift;
    croak "intra_dcharges> pass initial and final time" unless ( @_ == 2 );
    my $ti = shift;
    my $tf = shift;
    return ( $self->get_charges($tf) - $self->get_charges($ti) );
}

sub mean_charges {
    my $self     = shift;
    my @tcharges = $self->all_charges;
    my $sum      = 0;
    $sum += $_ foreach @tcharges;
    return ( $sum / $self->count_charges );
}

sub msd_charges {
    my $self     = shift;
    my $avg      = $self->mean_charges;
    my @tcharges = $self->all_charges;
    my $sum      = 0;
    $sum += ( $_ - $avg )**2 foreach @tcharges;
    return ( $sum / $self->count_charges );
}

sub intra_dcoords {

    #M::V::R makes much simpler
    my $self = shift;
    croak "intra_dcoords> pass initial and final time" unless ( @_ == 2 );
    my $ti = shift;
    my $tf = shift;
    return ( $self->get_coords($tf) - $self->get_coords($ti) );
}

sub mean_coords {
    my $self    = shift;
    my @tcoords = $self->all_coords;
    my $sum     = V( 0, 0, 0 );
    $sum += $_ foreach @tcoords;
    return ( $sum / $self->count_coords );
}

sub msd_coords {

    # returns scalar
    my $self    = shift;
    my $avg     = $self->mean_coords;
    my @tcoords = $self->all_coords;
    my $sum     = 0;
    foreach my $c (@tcoords) {
        my $dc = $c - $avg;
        $sum += $dc * $dc;
    }
    return ( $sum / $self->count_coords );
}

sub intra_dforces {

    #M::V::R makes much simpler
    my $self = shift;
    croak "intra_dforces> pass initial and final time" unless ( @_ == 2 );
    my $ti = shift;
    my $tf = shift;
    return ( $self->get_forces($tf) - $self->get_forces($ti) );
}

sub mean_forces {
    my $self    = shift;
    my @tforces = $self->all_forces;
    my $sum     = V( 0, 0, 0 );
    $sum += $_ foreach @tforces;
    return ( $sum / $self->count_forces );
}

sub msd_forces {

    # returns scalar
    my $self    = shift;
    my $avg     = $self->mean_forces;
    my @tforces = $self->all_forces;
    my $sum     = 0;
    foreach my $c (@tforces) {
        my $dc = $c - $avg;
        $sum += $dc * $dc;
    }
    return ( $sum / $self->count_forces );
}

#interobject methods
sub distance {
    my $self = shift;
    my $obj2 = shift or croak "need to pass another obj that does PhysVec";
    my ( $ts, $t2 ) = ( $self->t, $obj2->t );
    carp "comparing objects with different times" unless ( $ts == $t2 );
    my $vs = $self->get_coords($ts);
    my $v2 = $obj2->get_coords($t2);
    return ( $vs->dist($v2) );
}

sub angle_rad {

    # obj2    obj3
    #   \ Ang /
    #    \   /
    #     self
    #
    # returns in degrees
    my ( $self, $obj2, $obj3 ) = @_;
    croak "need to pass two objects that do PhysVecMVR" unless ( @_ == 3 );
    my $v1 = $self->inter_dcoords($obj2);
    my $v2 = $self->inter_dcoords($obj3);
    return (0) if ( abs($v1) == 0 or abs($v2) == 0 );
    return ( atan2( $v1, $v2 ) );
}

sub angle_deg {
    my $self  = shift;
    my $angle = $self->angle_rad(@_);
    return ( rad2deg($angle) );
}

sub dihedral_rad {

    # self            obj4
    #   \             /
    #    \    Ang    /
    #     obj2---obj3
    #
    # returns in degrees
    my ( $self, $obj2, $obj3, $obj4 ) = @_;
    croak "need to pass three objects that do PhysVecMVR" unless ( @_ == 4 );

    my $v1      = $self->inter_dcoords($obj2);
    my $v2      = $obj2->inter_dcoords($obj3);
    my $v3      = $obj3->inter_dcoords($obj4);
    my $v3_x_v2 = $v3 x $v2;
    my $v2_x_v1 = $v2 x $v1;
    my $sign    = $v1 * $v3_x_v2;

    my $dihe = atan2( $v3_x_v2, $v2_x_v1 );
    $dihe *= -1 if ( $sign > 0 );
    return $dihe;
}

sub dihedral_deg {
    my $self = shift;
    my $dihe = $self->dihedral_rad(@_);
    return ( rad2deg($dihe) );
}

sub inter_dcharges {
    my $self = shift;
    my $obj2 = shift or croak "need to pass another obj that does PhysVec";
    my ( $ts, $t2 ) = ( $self->t, $obj2->t );
    carp "comparing objects with different times" unless ( $ts == $t2 );
    my $dvec = $obj2->get_charges($t2) - $self->get_charges($ts);
    return ($dvec);
}

sub inter_dcoords {
    my $self = shift;
    my $obj2 = shift or croak "need to pass another obj that does PhysVec";
    my ( $ts, $t2 ) = ( $self->t, $obj2->t );
    carp "comparing objects with different times" unless ( $ts == $t2 );
    my $dvec = $obj2->get_coords($t2) - $self->get_coords($ts);
    return ($dvec);
}

sub inter_dforces {
    my $self = shift;
    my $obj2 = shift or croak "need to pass another obj that does PhysVec";
    my ( $ts, $t2 ) = ( $self->t, $obj2->t );
    carp "comparing objects with different times" unless ( $ts == $t2 );
    my $dvec = $obj2->get_forces($t2) - $self->get_forces($ts);
    return ($dvec);
}

sub xyz {
    my $self = shift;
    carp "xyz> takes no arguments. returns get_coords(t)" if (@_);
    return ( $self->get_coords( $self->t ) );
}

sub clone_xyz {

    # returns a new MVR
    # optionally takes t
    my $self = shift;
    my $t    = shift;
    $t = $self->t unless ( defined($t) );
    return ( V( @{ $self->get_coords($t) } ) );
}

sub force {
    my $self = shift;
    carp "force> takes no arguments. returns get_forces(t)" if (@_);
    return ( $self->get_forces( $self->t ) );
}

sub clone_force {

    # returns a new MVR
    # optionally takes t
    my $self = shift;
    my $t    = shift;
    $t = $self->t unless ( defined($t) );
    return ( V( @{ $self->get_forces($t) } ) );
}

sub copy_ref_from_t1_through_t2 {
    croak "need to pass [charges|coords|forces] t and tf" unless @_ == 4;
    my ( $self, $qcf, $t, $tf ) = @_;
    my ( $get_qcf, $set_qcf ) = map { $_ . $qcf } qw(get_ set_);
    my $qcf_at_t = $self->$get_qcf($t);
    $self->$set_qcf( $_, $qcf_at_t ) foreach ( $t + 1 .. $tf );
}

no Moose::Role;

1;

__END__

=pod

=head1 NAME

HackaMol::Roles::PhysVecMVRRole - Provides the core of HackaMol Atom and Molecule classes.

=head1 VERSION

version 0.044

=head1 SYNOPSIS

   # instance of class that consumes the PhysVecRol
   use HackaMol::Molecule; 
   my $obj = HackaMol::Molecule->new( 
                 name => 'foo', 
                 t => 0 , 
                 charges => [0.1], 
                 coords => [ V(0,1,2) ]
   ); 

   # add some charges

   $obj->push_charges($_) foreach ( 0.3, 0.2, 0.1, -0.1, -0.2, -0.36 );

   my $sum_charges = 0;

   $sum_charges += $_ foreach $obj->all_charges;
   print "average charge: ", $sum_charges / $obj->count_charges;

   # add some coordinates

   $obj->push_coords($_) foreach ( V(0,0,0), V(1,1,1), V(-1.0,2.0,-4.0) ) );

   print $obj->mean_charges . "\n";
   print $obj->msd_charges . "\n";
   printf ("%10.3f %10.3f %10.3f \n", @{$obj->mean_coords};
   print $obj->msd_coords . "\n";

=head1 DESCRIPTION

PhysVecMVR provides the core attributes and methods shared between Atom 
and Molecule classes. Consuming this role gives Classes a place to store 
coordinates, forces, and charges, perhaps, over the course of a simulation 
or for a collection of configurations for which all other object metadata (name, 
mass, etc) remains fixed. As such, the 't' attribute, described below, is 
important to understand. The PhysVecMVR uses Math::Vector::Real (referred to as MVR), 
which has pure Perl and XS implementations.  MVR::XS is fast with many useful/powerful
overloaded methods. PhysVecMVR leaves many attributes rw so that they may be set and 
reset on the fly. This seems most intuitive from the 
perspective of carrying out computational work on molecules.  

Comparing the PhysVec within Atom and Molecule may be helpful. For both, the PhysVecRol 
generates a little metadata (mass, name, etc.) and an array of coordinates, forces, and 
charges.  For an atom, the array of coordinates gives an atom (with fixed metadata) the ability 
to store multiple [x,y,z] positions (as a function of time, symmetry, distribution, etc.). What 
is the array of coordinates for Molecule? Usually, the coordinates for a molecule will likely 
remain empty (because the atoms that Molecule contains have the more useful coordinates), but we
can imagine using the coordinates array to track the center of mass of the molecule if needed. 

In the following:  Methods with mean_foo msd_foo intra_dfoo out front, carries out some analysis
within $self. Methods with inter_ out front carries out some analysis between
two objects of classes that consume PhysVecMVR at the $self->t and $obj->t.

=head1 METHODS

=head2 distance

Takes one argument ($obj2) and calculates the distance using Math::Vector::Real

  $obj1->distance($obj2);

=head2 angle_deg

Takes two arguments ($obj2,$obj3) and calculates the angle (degrees) between 
the vectors with $obj1 as orgin using Math::Vector::Real.  

  $obj1->angle_deg($obj2,$obj3);

=head2 angle_rad

Takes two arguments ($obj2,$obj3) and calculates the angle (radians) between 
the vectors with $obj1 as orgin using Math::Vector::Real.  

  $obj1->angle_rad($obj2,$obj3);

=head2 dihedral_deg

Takes three arguments ($obj2,$obj3,obj4) and calculates the angle 
(degrees) between the vectors normal to the planes containing the first three
and last three objects using Math::Vector::Real.  

  $obj1->dihedral_deg($obj2,$obj3,$obj4);

=head2 dihedral_rad

Takes three arguments ($obj2,$obj3,obj4) and calculates the angle 
(radians) between the vectors normal to the planes containing the first three
and last three objects using Math::Vector::Real.  

  $obj1->dihedral_rad($obj2,$obj3,$obj4);

=head2 intra_dcharges

Calculates the change in charge from initial t ($ti) to final t ($tf). I.e.:

  $obj1->intra_dcharges( $ti, $tf );

yields the same as:

  $self->get_charges($tf) - $self->get_charges($ti);

=head2 mean_charges

No arguments.  Calculates the mean of all stored charges.

=head2 msd_charges

No arguments.  Calculates the mean square deviation of all stored charges.

=head2 intra_dcoords intra_dforces 

returns the difference (Math::Vector::Real object) from the initial t ($ti) to
the final t ($tf).

  $obj1->intra_dcoords($ti,$tf);

  $obj1->intra_dforces($ti,$tf);

=head2 mean_coords mean_forces 

No arguments. Calculates the mean (Math::Vector::Real object) vector.

=head2 msd_coords msd_forces 

No arguments. Calculates the mean (Math::Vector::Real object) dot product of the
vector difference of the xyz coords from the mean vector.

=head2 charge

called with no arguments.  returns $self->get_charges($self->t);

=head2 xyz

called with no arguments.  returns $self->get_coords($self->t);

=head2 clone_xyz

optionally called with t. t set to $self->t if not passed. 
This method is intended for mapping from one atom to another, where the 
coordinates are expected to be distinct. A copy of the xyz 
coordinates with a new memory location is returned via 
V( @{$self->get_coords($t)});  

  my @Aus = map {
                 HackaMol::Atom->new(Z=>79, coords=>[$_->clone_xyz])
                } grep {$_->Z == 80} @atoms;

=head2 force

called with no arguments.  returns $self->get_forces($self->t);

=head2 clone_force

optionally called with t. t set to $self->t if not passed. Analagous to 
clone_xyz.

=head2 copy_ref_from_t1_through_t2

called as $obj->copy_ref_from_t1_through_t2($qcf,$t,$tf); where qcf is
charges|coords|forces.  Fills the qcf from t+1 to tf with the value at t.
Added this while trying to compare a dipole as a function of changing charges
at a single set of coordinates.

=head1 ARRAY METHODS

=head2 push_$_, all_$_, get_$_, set_$_, count_$_, clear_$_ foreach qw(charges coords forces)

ARRAY traits, respectively: push, get, set, all, elements, delete, clear
  Descriptions for charges and coords follows.  forces analogous to coords.

=head2 push_charges

push value on to charges array

  $obj->push_charges($_) foreach (0.15, 0.17, 0.14, 0.13);

=head2 all_charges

returns array of all elements in charges array

    print $_ . " " foreach $obj->all_charges; # prints 0.15 0.17 0.14 0.13

=head2 get_charges

return element by index from charges array

    print $obj->get_charges(1); # prints 0.17

=head2 set_charges

set value of element by index from charges array

    $obj->set_charges(2, 1.00);
    print $_ . " " foreach $obj->all_charges; # prints 0.15 0.17 1.00 0.13

=head2 count_charges

return number of elements in charges array

    print $obj->count_charges; # prints 4 

=head2 delete_charges($index)

    Removes the element at the given index from the array.

    This method returns the deleted value. Note that if no value exists, it will return undef.

    This method requires one argument.

=head2 clear_charges

clears charges array

    $obj->clear_charges;
    print $_ . " " foreach $obj->all_charges; # does nothing 
    print $obj->count_charges; # prints 0

=head2 push_coords

push value on to coords array

  $obj->push_coords($_) foreach ([0,0,0],[1,1,1],[-1.0,2.0,-4.0], [3,3,3]);

=head2 all_coords

returns array of all elements in coords array

    printf ("%10.3f %10.3f %10.3f \n", @{$_}) foreach $obj->all_coords; 

    my @new_coords = map {[$_->[0]+1,$_->[1]+1,$_->[2]+1]} $obj->all_coords;

    printf ("%10.3f %10.3f %10.3f \n", @{$_}) foreach @new_coords; 

=head2 get_coords

return element by index from coords array

    printf ("%10.3f %10.3f %10.3f \n", @{$obj->get_coords(1)}); # 

=head2 set_coords

set value of element by index from coords array

    $obj->set_coords(2, [100,100,100]);
    printf ("%10.3f %10.3f %10.3f \n", @{$_}) foreach $obj->all_coords; 

=head2 count_coords

return number of elements in coords array

    print $obj->count_coords; # prints 4 

=head2 delete_coords($index)

    Removes the element at the given index from the array.

    This method returns the deleted value. Note that if no value exists, it will return undef.

    This method requires one argument.

clears coords array

    $obj->clear_coords;
    print $_ . " " foreach $obj->all_coords; # does nothing 
    print $obj->count_coords # prints 0

=head2 clear_coords

clears coords array

    $obj->clear_coords;
    print $_ . " " foreach $obj->all_coords; # does nothing 
    print $obj->count_coords # prints 0

=head1 ATTRIBUTES

=head2 t 

isa Int or ScalarRef that is rw with default of 0

t is intended to describe the current "setting" of the object. Objects that 
consume the PhysVecRol have  arrays of coordinates, forces, and charges to 
allow storage with the passing of time (hence t) or the generation alternative 
configurations.  For example, a crystal lattice can be stored as a single 
object that consumes PhysVec (with associated metadata) along with the 
array of 3d-coordinates resulting from lattice vector translations. 

Experimental: Setting t to a ScalarRef allows all objects to share the same t.  
Although, to use this, a $self->t accessor that dereferences the value would 
seem to be required.  There is nothing, currently, in the core to do so. Not 
sure yet if it is a good or bad idea to do so.

    my $t  = 0;
    my $rt = \$t;  
    $_->t($rt) for (@objects);
    $t = 1; # change t for all objects.

=head2 mass 

isa Num that is rw and lazy with a default of 0

=head2 xyzfree

isa ArrayRef that is rw and lazy with a default value [1,1,1]. Using this array
allows the object to be fixed for calculations that support it.  For example, to
fix the X and Y coordinates:

  $obj->xyzfree([0,0,1]);

fixing any coordinate will set trigger the is_fixed(1) flag.  

=head2 is_fixed

isa Bool that is rw and lazy with a default of 0 (false).

=head2 charges

isa ArrayRef[Num] that is lazy with public ARRAY traits described in ARRAY_METHODS

Gives atoms and molecules t-dependent arrays of charges. e.g. store and analyze
atomic charges from a quantum mechanical molecule in several intramolecular 
configurations or a fixed configuration in varied external potentials. 

=head2 coords forces

isa ArrayRef[Math::Vector::Real] that is lazy with public ARRAY traits described in ARRAY_METHODS

Gives atoms and molecules t-dependent arrays of coordinates and forces,
for the purpose of analysis.  

=head1 SEE ALSO

=over 4

=item *

L<HackaMol::Atom>

=item *

L<HackaMol::Molecule>

=back

=head1 AUTHOR

Demian Riccardi <demianriccardi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Demian Riccardi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
