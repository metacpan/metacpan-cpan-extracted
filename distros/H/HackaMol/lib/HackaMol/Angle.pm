package HackaMol::Angle;
$HackaMol::Angle::VERSION = '0.049';
#ABSTRACT: Angle class for HackaMol
use 5.008;
use Moose;
use namespace::autoclean;
use Carp;
use Math::Vector::Real;
use MooseX::StrictConstructor;
#use MooseX::Storage;
#with Storage( 'io' => 'StorableFile' ), 
with 'HackaMol::Roles::NameRole', 'HackaMol::Roles::AtomGroupRole';

has $_ => (
    is        => 'rw',
    isa       => 'Num',
    default   => 0,
    lazy      => 1,
    clearer   => "clear_$_",
    predicate => "has_$_",
) foreach qw(ang_fc ang_eq);

sub ang_normvec {
    my $self  = shift;
    my @atoms = $self->all_atoms;
    my $ang   = $self->ang_deg;
    return V( 0, 0, 0 ) if ( $ang == 0 or $ang == 180 );
    my $vec1  = $atoms[1]->inter_dcoords( $atoms[0] );
    my $vec2  = $atoms[1]->inter_dcoords( $atoms[2] );
    my $v1xv2 = $vec1 x $vec2;
    return ( $v1xv2->versor );
}

sub bisector {
# vector that bisects the angle between two vectors of the angle
    my $self = shift;
    my @atoms = $self->all_atoms;
    my $ang   = $self->ang_deg;
    return V( 0, 0, 0 ) if ( $ang == 0 or $ang == 180 );
    my $vec1  = $atoms[1]->inter_dcoords( $atoms[0] );
    my $vec2  = $atoms[1]->inter_dcoords( $atoms[2] );
    my $bvec  = ($vec1->versor+$vec2->versor)->versor;
    return $bvec;
}

sub ang_deg {
    my $self  = shift;
    my @atoms = $self->all_atoms;
    return ( $atoms[1]->angle_deg( $atoms[0], $atoms[2] ) );
}

sub ang_rad {
    my $self  = shift;
    my @atoms = $self->all_atoms;
    return ( $atoms[1]->angle_rad( $atoms[0], $atoms[2] ) );
}

has 'angle_efunc' => (
    is      => 'rw',
    isa     => 'CodeRef',
    builder => "_build_angle_efunc",
    lazy    => 1,
);

sub _build_angle_efunc {

    #my $self = shift; #self is passed by moose, but we don't use it here
    my $subref = sub {
        my $angle = shift;
        my $val   = ( $angle->ang_deg - $angle->ang_eq )**2;
        return ( $angle->ang_fc * $val );
    };
    return ($subref);
}

sub angle_energy {
    my $self = shift;
    my $energy = &{ $self->angle_efunc }( $self, @_ );
    return ($energy);
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

HackaMol::Angle - Angle class for HackaMol

=head1 VERSION

version 0.049

=head1 SYNOPSIS

   use HackaMol::Atom;
   use HackaMol::Angle;

   my $atom1 = HackaMol::Atom->new(
       name    => 'O1',
       coords  => [ V( 2.05274, 0.01959, -0.07701 ) ],
       Z       => 8,
   );

   my $atom2 = HackaMol::Atom->new(
       name    => 'H1',
       coords  => [ V( 1.08388, 0.02164, -0.12303 ) ],
       Z       => 1,
   );
   
   my $atom3 = HackaMol::Atom->new(
       name    => 'H2',
       coords  => [ V( 2.33092, 0.06098, -1.00332 ) ],
       Z       => 1,
   );
   
   my $angle1 = HackaMol::Angle->new(name=>'OH2', atoms=>[$atom1,$atom2,$atom3]);
   my $angle2 = HackaMol::Angle->new(name=>'OH2', atoms=>[$atom2,$atom1,$atom3]);
   
   foreach my $angle ($angle1, $angle2){
     my $pangle = sprintf(
                   "Angle: %s, angle: %.2f, vector normal to angle plane: %.5 %.5 %.5 \n",
                   $angle->name, 
                   $angle->ang, 
                   @{$angle->ang_normvec},
     );
     print $pangle;
   }
   
   my @COM_ats = map {HackaMol::Atom->new(
                         name    => "X".$_->name."X",
                         coords  => [ $_->COM ],
                         Z       => 1)
                     }($angle1, $angle2);
   
   my @ang_w_HH = grep { $_->get_atoms(0)->Z == 1 and
                         $_->get_atoms(1)->Z == 1} ($angle1, $angle2);

=head1 DESCRIPTION

The HackaMol Angle class provides a set of methods and attributes for working 
with two connections between three atoms.  Like the Bond, the Angle class 
consumes the AtomGroupRole providing methods to determine the center of mass, 
total charge, etc (see L<HackaMol::AtomGroupRole>). An Angle containing 
(atom1,atom2,atom3) produce angles between the atom21 atom23 interatomic vectors.

The Angle class also provides attributes and methods to set force_constants and 
measure energy.  The angle_energy method calls on a CodeRef attribute that the 
user may define.  See descriptions below.  

=head1 METHODS

=head2 ang_normvec

no arguments. returns Math::Vector::Real (MVR) object from the normalized cross 
product of the atom21 and atom23 interatomic vectors.

=head2 bisector

no arguments. returns vector (MVR) that bisects the angle between the two
vectors of the angle.   

=head2 ang_deg 

no arguments. returns the angle (degrees) between the atom21 and atom23 vectors. 

=head2 ang_rad 

no arguments. returns the angle (radians) between the atom21 and atom23 vectors. 

=head2 angle_energy

arguments, as many as you want. Calculates energy using the angle_efunc 
described below, if the attribute, angle_fc > 0.  The angle_energy method calls 
the angle_efunc as follows: 

my $energy = &{$self->angle_efunc}($self,@_);

which will pass $self and that in @_ array to angle_efunc, which, similar 
to the Bond class, can be redefined.

=head1 ATTRIBUTES

=head2 name

isa Str that is lazy and rw. useful for labeling, bookkeeping...

=head2 angle_fc

isa Num that is lazy and rw. default = 0.  force constant for harmonic potentials.

=head2 ang_eq

isa Num that is lazy and rw. default = 0.  Equilibrium angle.  The ang method 
returns angle in degrees.

=head2 angle_efunc

isa CodeRef that is lazy and rw. default uses builder to generate harmonic 
potential from the angle_fc, ang_eq, and ang.  See the _build_angle_efunc,
if interested in changing the function form.

=head1 SEE ALSO

=over 4

=item *

L<HackaMol::AtomGroupRole>

=item *

L<HackaMol::Bond>

=item *

L<HackaMol::Dihedral>

=back

=head1 EXTENDS

=over 4

=item * L<Moose::Object>

=back

=head1 CONSUMES

=over 4

=item * L<HackaMol::Roles::AtomGroupRole>

=item * L<HackaMol::Roles::NameRole>

=item * L<HackaMol::Roles::NameRole|HackaMol::Roles::AtomGroupRole>

=back

=head1 AUTHOR

Demian Riccardi <demianriccardi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Demian Riccardi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
