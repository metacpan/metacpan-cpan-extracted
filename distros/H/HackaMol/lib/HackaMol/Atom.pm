package HackaMol::Atom;
$HackaMol::Atom::VERSION = '0.047';
#ABSTRACT: HackaMol Atom Class
use 5.008;
use Moose;
use namespace::autoclean;
use Carp;
use MooseX::StrictConstructor;
#use MooseX::Storage;
#with Storage('format' => 'JSON', 'io' => 'File');

with  'HackaMol::Roles::NameRole', 
      'HackaMol::Roles::PhysVecMVRRole',
      'HackaMol::Roles::PdbRole',  
      'HackaMol::Roles::QmAtomRole';
use HackaMol::PeriodicTable
  qw(@ELEMENTS %ELEMENTS %ATOMIC_MASSES @COVALENT_RADII @VDW_RADII %ATOM_MULTIPLICITY);

my @delta_attrs = qw(Z symbol mass vdw_radius covalent_radius);

has 'is_dirty' => (

    # when attributes change, the Atom gets dirty. change_symbol, change_Z
    # generally, classes that have Atom should decide whether to clean Atom
    is      => 'rw',
    isa     => 'Bool',
    lazy    => 1,
    default => 0,        # anytime called, the atom becomes dirty forever!
);

has 'bond_count' => (
    traits  => ['Counter'],
    is      => 'ro',
    isa     => 'Num',
    default => 0,
    handles => {
        inc_bond_count   => 'inc',
        dec_bond_count   => 'dec',
        reset_bond_count => 'reset',
    },
);

has 'symbol' => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_symbol',
    clearer   => 'clear_symbol',
    lazy      => 1,
    builder   => '_build_symbol',
);

sub _build_symbol {
    my $self = shift;
    return ( _Z_to_symbol( $self->Z ) );
}

has 'Z' => (
    is        => 'rw',
    isa       => 'Int',
    predicate => 'has_Z',
    clearer   => 'clear_Z',
    lazy      => 1,
    builder   => '_build_Z',
);

sub _build_Z {
    my $self = shift;
    return ( _symbol_to_Z( $self->symbol ) );
}

has $_ => (
    is        => 'rw',
    isa       => 'Num',
    predicate => "has_$_",
    clearer   => "clear_$_",
    lazy      => 1,
    builder   => "_build_$_",
) foreach (qw(covalent_radius vdw_radius));

sub _build_covalent_radius {
    my $self = shift;
    return ( _Z_to_covalent_radius( $self->Z ) );
}

sub _build_vdw_radius {
    my $self = shift;
    return ( _Z_to_vdw_radius( $self->Z ) );
}

sub change_Z {
    my $self = shift;
    my $Z = shift or croak "pass argument Z to change_Z method";
    $self->_clean_atom;
    $self->Z($Z);
}

sub change_symbol {
    my $self = shift;
    my $symbol = shift or croak "pass argument symbol to change_Z method";
    $self->_clean_atom;
    $self->symbol( _fix_symbol($symbol) );
}

sub charge {
    my $self = shift;
    carp "charge> takes no arguments. returns get_charges(t)" if (@_);
    if ($self->has_charges){
      return ( $self->get_charges( $self->t ) );
    } 
    else {
      return 0;
    }
}

sub _clean_atom {
    my $self = shift;
    foreach my $clearthis ( map { "clear_$_" } @delta_attrs ) {
        $self->$clearthis;
    }
    carp "cleaning atom attributes for in place change. setting atom->is_dirty";
    $self->is_dirty(1);
}

sub BUILD {
    my $self = shift;

    unless ( $self->has_Z or $self->has_symbol ) {
        croak "Either Z or Symbol must be set when calling Atom->new()";
    }

    if ( $self->has_Z ) {

        #clear out the symbol if Z is passed.  Z is faster and takes precedence
        $self->clear_symbol;
        return;
    }

    $self->symbol( _fix_symbol( $self->symbol ) );
    return;
}

sub _build_mass {
    my $self = shift;
    return ( _symbol_to_mass( $self->symbol ) );
}

sub _symbol_to_Z {
    my $symbol = shift;
    $symbol = ucfirst( lc($symbol) );
    return $ELEMENTS{$symbol};
}

sub _Z_to_symbol {
    my $Z = shift;
    return $ELEMENTS[$Z];
}

sub _symbol_to_mass {
    my $symbol = shift;
    return $ATOMIC_MASSES{$symbol};
}

sub _fix_symbol {
    return ucfirst( lc(shift) );
}

sub _Z_to_covalent_radius {
    my $Z = shift;

    # index 1 for single bond length..
    return $COVALENT_RADII[$Z][1] / 100;
}

sub _Z_to_vdw_radius {
    my $Z = shift;
    return $VDW_RADII[$Z][1] / 100;
}

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=head1 NAME

HackaMol::Atom - HackaMol Atom Class

=head1 VERSION

version 0.047

=head1 SYNOPSIS

   use HackaMol::Atom;
   use Math::Vector::Real;
   
   
   my $atom1 = HackaMol::Atom->new(
       name    => 'Zinc',
       coords  => [ V( 2.05274, 0.01959, -0.07701 ) ],
       Z       => 30,
   );
   print $atom->symbol ; #prints "Zn"
   
   print "clean " unless $atom->is_dirty; #prints clean
   
   $atom->change_symbol("Hg");
   print $atom->Z ; #prints 80
   
   print "dirty " if $atom->is_dirty; #prints dirty

=head1 DESCRIPTION

Central to HackaMol, the Atom class provides methods and attributes for a 
given atom. The Atom class consumes L<HackaMol::PhysVecMVRRole>, 
L<HackaMol::PdbRole>, and L<HackaMol::QmAtomRole>.  See the documentation 
of those roles for details.  The Atom class adds attributes (such as I<symbol>,
I<Z>, 
I<covalent_radius>) and methods (such as I<change_symbol>) specific to atoms. 
Creating an instance of an Atom object requires either the atomic number (I<Z>) 
or symbol (I<symbol>). The other attributes are lazily built when needed.  The 
Atom class is flexible. The atom type can be changed in place (e.g. convert 
a zinc atom to a mercury atom, see SYNOPSIS), but changing the type of atom 
will set the is_dirty flag so that other objects using the atom have the 
ability to know whether atom-type dependent attributes need to be updated 
(e.g. forcefield parameters, etc.).  Atom data is generated from the PeriodicTable 
module that borrows data from PerlMol.  The PeriodicTable module is for data and 
will be dumped into a YAML file in the future.

=head1 METHODS

=head2 change_Z

no arguments.  Changes the atom type using I<Z>.  I<change_Z> calls
I<_clean_atom> which clears all attributes and sets calls I<is_dirty(1)>.

=head2 change_symbol

no arguments.  Changes the atom type using symbol and is analogous to
I<change_Z>. 

=head1 ATTRIBUTES

=head2 is_dirty

isa Bool that is lazy and rw.  Default is 0.  $self->is_dirty(1) called 
during the I<change_symbol> and I<change_Z methods>.

=head2 symbol

isa Str that is lazy and rw. I<_build_symbol> builds the default. 

Generating an atom instance with I<symbol>, will run C<ucfirst(lc ($symbol))> 
to make sure the format is correct.  Thus, creating an atom object is 
slightly slower with symbol than with I<Z>. If I<Z> is used to generate the 
instance of the Atom class (C<my $atom = Atom->new(Z=>1)>), the C<_build_symbol> 
method generates the symbol from I<Z> only when the symbol attribute is read 
(I<symbol> attribute is lazy).

=head2 Z

isa Int that is lazy and rw. I<_build_Z> builds the default

I<Z> is the Atomic number.

=head2 covalent_radius

isa Num that is lazy and rw. I<_build_covalent_radius> builds the default.

the covalent radii are taken from those tabulated in:

P. Pyykkoe, M. Atsumi (2009). 
"Molecular Single-Bond Covalent Radii for Elements 1 to 118". Chemistry: A European Journal 15: 186.

Covalent radii for double and triple bonds, generated from the same authors, are
also tabulated but currently not used.

=head2 vdw_radius

isa Num that is lazy and rw. _build_vdw_radius builds the default. 

Atomic Van der Waals radii information will be revisited and revised. Included as 
reminder for now. See the source of PeriodicTable.pm for more information.

=bond_count

isa Num that is lazy with a default of 0. The value adjusted with public Counter traits:

  inc_bond_count    adds 1 by default
  dec_bond_count    subtracts 1 by default
  reset_bond_count   sets to zero

=head1 SEE ALSO

=over 4

=item *

L<HackaMol::PhysVecMVRRole>

=item *

L<HackaMol::PdbRole>

=item *

L<HackaMol::QmAtomRole>

=item *

L<Chemistry::Atom>

=back

=head1 EXTENDS

=over 4

=item * L<Moose::Object>

=back

=head1 CONSUMES

=over 4

=item * L<HackaMol::Roles::NameRole>

=item * L<HackaMol::Roles::NameRole|HackaMol::Roles::PhysVecMVRRole|HackaMol::Roles::PdbRole|HackaMol::Roles::QmAtomRole>

=item * L<HackaMol::Roles::PdbRole>

=item * L<HackaMol::Roles::PhysVecMVRRole>

=item * L<HackaMol::Roles::QmAtomRole>

=back

=head1 AUTHOR

Demian Riccardi <demianriccardi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Demian Riccardi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
