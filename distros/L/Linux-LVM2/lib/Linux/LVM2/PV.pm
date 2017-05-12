package Linux::LVM2::PV;
{
  $Linux::LVM2::PV::VERSION = '0.14';
}
BEGIN {
  $Linux::LVM2::PV::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: a class representing a PV in a Linux LVM2

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;

has 'name' => (
    'is'       => 'ro',
    'isa'      => 'Str',
    'required' => 1,
);

has 'vg' => (
    'is'       => 'ro',
    'isa'      => 'Linux::LVM2::VG',
    'required' => 1,
    'weak_ref' => 1,
);

has 'size' => (
    'is'       => 'ro',
    'isa'      => 'Int',
    'required' => 1,
);

has 'pesize' => (
    'is'       => 'ro',
    'isa'      => 'Int',
    'required' => 1,
);

has 'totalpe' => (
    'is'       => 'ro',
    'isa'      => 'Int',
    'required' => 1,
);

has 'freepe' => (
    'is'       => 'ro',
    'isa'      => 'Int',
    'required' => 1,
);

has 'allocpe' => (
    'is'       => 'ro',
    'isa'      => 'Int',
    'required' => 1,
);

has 'uuid' => (
    'is'       => 'ro',
    'isa'      => 'Str',
    'required' => 1,
);

sub BUILD {
    my $self = shift;

    $self->vg()->pvs()->{ $self->name() } = $self;

    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Linux::LVM2::PV - a class representing a PV in a Linux LVM2

=head1 SYNOPSIS

Instances of this class are usually create by Linux::LVM2::_find_vgs.

=head1 DESCRIPTION

This class models a physical-volume inside a Linux LVM2 setup.

=head1 ATTRIBUTES

=head2 name

The name of this PV

=head2 vg

The VG that is using this PV

=head2 size

The size of this PV

=head2 pesize

UNDOCUMENTED

=head2 totalpe

UNDOCUMENTED

=head2 freepe

UNDOCUMENTED

=head2 allocpe

UNDOCUMENTED

=head2 uuid

UNDOCUMENTED

=head1 METHODS

=head2 BUILD

Invoked by Moose on instantiation. Sets a reference to this class in our parent
VG.

=head1 NAME

Linux::LVM2::PV - Model a physical-volume.

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
