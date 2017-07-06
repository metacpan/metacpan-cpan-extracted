package HackaMol::Roles::QmAtomRole;
$HackaMol::Roles::QmAtomRole::VERSION = '0.043';
#ABSTRACT: simple role that provides attributes needed for setting up quantum chemistry calculations
use Moose::Role;

has 'basis' => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'has_basis',
    clearer   => 'clear_basis',
    lazy      => 1,
    default => '6-31+G*',    #to provide example; EMSL Str can be many lines...
);
has 'ecp' => (
    is        => 'rw',
    isa       => 'Str',
    clearer   => 'clear_ecp',
    predicate => 'has_ecp',
);

has 'basis_geom', is => 'rw', isa => 'Str';

has 'dummy' => (
    is        => 'rw',
    isa       => 'Str',
    predicate => 'is_dummy',
    clearer   => 'clear_dummy',
);

no Moose::Role;

1;

__END__

=pod

=head1 NAME

HackaMol::Roles::QmAtomRole - simple role that provides attributes needed for setting up quantum chemistry calculations

=head1 VERSION

version 0.043

=head1 SYNOPSIS

   # instance of class that consumes the QmRole.
 
   $obj->basis_geom('spherical');
 
   $obj->basis_geom('cartesian');
 
   $obj->dummy('bq');
 
   print "dummy! "     if $obj->is_dummy;
 
   $obj->clear_dummy;
 
   print "not dummy! " unless $obj->is_dummy;
 
   $obj->basis('SDD');
 
   $obj->ecp('SDD');

=head1 DESCRIPTION

QmAtomRole provides attributes that will be useful for setting up interfaces to quantum chemistry
packages.  All attributes are 'rw' and lazy, so they will not contaminate the namespace unless 
called upon.  The functionality for QM calculations is extended in the QmMolRole. 
I have used earlier versions of these roles to load basis_sets and effective core potentials 
downloaded from the EMSL basis set exchange as a single Str. https://bse.pnl.gov/bse/portal

A dream is to interface with EMSL library directly.

=head1 ATTRIBUTES

=head2 basis_geom

isa Str that is lazy and rw

=head2 dummy

isa Str that is lazy and rw

=head2 basis

isa Str that is lazy and rw

=head2 ecp

isa Str that is lazy and rw

=head1 SEE ALSO

=over 4

=item *

L<HackaMol::Atom>

=item *

L<EMSL | https://bse.pnl.gov/bse/portal>

=back

=head1 AUTHOR

Demian Riccardi <demianriccardi@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Demian Riccardi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
