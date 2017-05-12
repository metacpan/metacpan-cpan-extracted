package Linux::LVM2::VG;
{
  $Linux::LVM2::VG::VERSION = '0.14';
}
BEGIN {
  $Linux::LVM2::VG::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: a class representing an VG in a Linux LVM2

use 5.010_000;
use mro 'c3';
use feature ':5.10';

use Moose;
use namespace::autoclean;

# use IO::Handle;
# use autodie;
# use MooseX::Params::Validate;

has 'parent' => (
    'is'       => 'ro',
    'isa'      => 'Linux::LVM2',
    'required' => 1,
    'weak_ref' => 1,
);

has 'name' => (
    'is'       => 'ro',
    'isa'      => 'Str',
    'required' => 1,
);

has 'access' => (
    'is'       => 'rw',
    'isa'      => 'Str',
    'required' => 1,
);

has 'status' => (
    'is'       => 'rw',
    'isa'      => 'Int',
    'required' => 1,
);

has 'vgid' => (
    'is'       => 'ro',
    'isa'      => 'Int',
    'required' => 1,
);

has 'maxlvs' => (
    'is'       => 'ro',
    'isa'      => 'Int',
    'required' => 1,
);

has 'curlvs' => (
    'is'       => 'rw',
    'isa'      => 'Int',
    'required' => 1,
);

has 'openlvs' => (
    'is'       => 'rw',
    'isa'      => 'Int',
    'required' => 1,
);

has 'maxlvsize' => (
    'is'       => 'ro',
    'isa'      => 'Int',
    'required' => 1,
);

has 'maxpvs' => (
    'is'       => 'ro',
    'isa'      => 'Int',
    'required' => 1,
);

has 'curpvs' => (
    'is'       => 'rw',
    'isa'      => 'Int',
    'required' => 1,
);

has 'numpvs' => (
    'is'       => 'rw',
    'isa'      => 'Int',
    'required' => 1,
);

has 'vgsize' => (
    'is'       => 'rw',
    'isa'      => 'Int',
    'required' => 1,
);

has 'pesize' => (
    'is'       => 'rw',
    'isa'      => 'Int',
    'required' => 1,
);

has 'totalpe' => (
    'is'       => 'rw',
    'isa'      => 'Int',
    'required' => 1,
);

has 'allocpe' => (
    'is'       => 'rw',
    'isa'      => 'Int',
    'required' => 1,
);

has 'freepe' => (
    'is'       => 'rw',
    'isa'      => 'Int',
    'required' => 1,
);

has 'uuid' => (
    'is'       => 'rw',
    'isa'      => 'Str',
    'required' => 1,
);

has 'pvs' => (
    'is'      => 'rw',
    'isa'     => 'HashRef[Linux::LVM2::PV]',
    'default' => sub { {} },
);

has 'lvs' => (
    'is'      => 'rw',
    'isa'     => 'HashRef[Linux::LVM2::LV]',
    'default' => sub { {} },
);

sub update {
    my $self = shift;
    $self->parent()->update();
    return 1;
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

=pod

=encoding utf-8

=head1 NAME

Linux::LVM2::VG - a class representing an VG in a Linux LVM2

=head1 SYNOPSIS

Instances of this class are usually create by Linux::LVM2::_find_vgs.

=head1 DESCRIPTION

This clas models a volume-group inside a Linux LVM2 setup.

=head1 ATTRIBUTES

=head2 parent

Our parent node, must be an instance of Linux::LVM2

=head2 name

The name of this VG.

=head2 access

UNDOCUMENTED

=head2 status

UNDOCUMENTED

=head2 vgid

UNDOCUMENTED

=head2 maxlvs

UNDOCUMENTED

=head2 curlvs

UNDOCUMENTED

=head2 openlvs

UNDOCUMENTED

=head2 maxlvsize

UNDOCUMENTED

=head2 maxpvs

UNDOCUMENTED

=head2 curpvs

UNDOCUMENTED

=head2 numpvs

UNDOCUMENTED

=head2 vgsize

UNDOCUMENTED

=head2 pesize

UNDOCUMENTED

=head2 totalpe

UNDOCUMENTED

=head2 allocpe

UNDOCUMENTED

=head2 freepe

UNDOCUMENTED

=head2 uuid

UNDOCUMENTED

=head2 pvs

UNDOCUMENTED

=head2 lvs

UNDOCUMENTED

=head1 METHODS

=head2 update

Synchronize the model with the underlying data structures.

=head1 NAME

Linux::LVM2::VG - Model a LVM2 volume-group.

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__


1; # End of Linux::LVM2::VG
