package HackaMol::AtomGroup;
$HackaMol::AtomGroup::VERSION = '0.044';
#ABSTRACT: HackaMol AtomGroup class
use 5.008;
use Moose;
use namespace::autoclean;
use Carp;
use MooseX::StrictConstructor;
#use MooseX::Storage;
#with Storage( 'io' => 'StorableFile' ), 
with 'HackaMol::Roles::NameRole', 'HackaMol::Roles::AtomGroupRole';

sub Rg {

    #radius of gyration.
    my $self = shift;
    return (0) unless ( $self->count_atoms );
    my @atoms      = $self->all_atoms;
    my $com        = $self->COM;
    my $total_mass = $self->total_mass;
    my @masses     = map { $_->mass } @atoms;
    my @dvec2 = map { $_ * $_ } map { $_->get_coords( $_->t ) - $com } @atoms;
    my $sum   = 0;
    $sum += $masses[$_] * $dvec2[$_] foreach 0 .. $#dvec2;
    return ( sqrt( $sum / $total_mass ) );
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

HackaMol::AtomGroup - HackaMol AtomGroup class

=head1 VERSION

version 0.044

=head1 SYNOPSIS

   use HackaMol::AtomGroup;
   use Math::Vector::Real;
   use Math::Vector::Real::Random;

   my $radius = 16;
   my $natoms = int(0.0334*($radius**3)*4*pi/3);

   my @atoms = map {Atom->new(Z => 8, charges=> [0], coords => [$_]) }
               map {$_*$radius}
               map {Math::Vector::Real->random_in_sphere(3)} 1 .. $natoms;

   my $group = AtomGroup->new(gname => 'biggroup', atoms=> [@atoms]);

   print $group->count_atoms . "\n";

   print $group->count_unique_atoms . "\n";

   print $group->Rg . "\n";

   my $numerical_error = $radius*sqrt($radius*3/5) - $group->Rg;

=head1 DESCRIPTION

The HackaMol AtomGroup class provides methods and attributes for groups of atoms.
Atom groupings can be defined to mimic conventional forcefields or manipulated to 
generate novel analytical tools.  For example, with a trajectory loaded, a dynamic 
cluster of atoms can be placed in a group and monitored in time. Or, perhaps, track 
regional charges of a quantum mechanical molecule with changes in configuration or 
external field.  The AtomGroup class consumes the AtomGroupRole and provides the 
parent class for the Molecule class.

=head1 METHODS

=head2 Rg 

no arguments. returns the scalar radius of gyration for the group of atoms

=head1 ATTRIBUTES

=head2 name

isa Str that is lazy and rw. useful for labeling, bookkeeping...

=head1 SEE ALSO

=over 4

=item *

L<HackaMol::Molecule>

=item *

L<HackaMol::AtomGroupRole>

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
