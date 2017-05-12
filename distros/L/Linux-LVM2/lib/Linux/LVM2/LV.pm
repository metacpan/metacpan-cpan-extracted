package Linux::LVM2::LV;
{
  $Linux::LVM2::LV::VERSION = '0.14';
}
BEGIN {
  $Linux::LVM2::LV::AUTHORITY = 'cpan:TEX';
}
# ABSTRACT: a class representing a LV in a Linux LVM2

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

has 'access' => (
    'is'       => 'rw',
    'isa'      => 'Int',
    'required' => 1,
);

has 'status' => (
    'is'       => 'rw',
    'isa'      => 'Int',
    'required' => 1,
);

has 'intlvnum' => (
    'is'       => 'rw',
    'isa'      => 'Int',
    'required' => 1,
);

has 'opencount' => (
    'is'       => 'rw',
    'isa'      => 'Int',
    'required' => 1,
);

has 'lvsize' => (
    'is'       => 'rw',
    'isa'      => 'Int',
    'required' => 1,
);

has 'leassoc' => (
    'is'       => 'rw',
    'isa'      => 'Int',
    'required' => 1,
);

has 'lealloc' => (
    'is'       => 'rw',
    'isa'      => 'Int',
    'required' => 1,
);

has 'allocpol' => (
    'is'       => 'rw',
    'isa'      => 'Int',
    'required' => 1,
);

has 'rasect' => (
    'is'       => 'rw',
    'isa'      => 'Int',
    'required' => 1,
);

has 'majornum' => (
    'is'       => 'rw',
    'isa'      => 'Int',
    'required' => 1,
);

has 'minornum' => (
    'is'       => 'rw',
    'isa'      => 'Int',
    'required' => 1,
);

has 'origin' => (
    'is'  => 'rw',
    'isa' => 'Linux::LVM2::LV',
);

has 'snap_pc' => (
    'is'  => 'rw',
    'isa' => 'Int',
);

has 'move' => (
    'is'  => 'rw',
    'isa' => 'Str',    # ???
);

has 'log' => (
    'is'  => 'rw',
    'isa' => 'Str',    # ???
);

has 'copy_pc' => (
    'is'  => 'rw',
    'isa' => 'Int',
);

has 'convert' => (
    'is'  => 'rw',
    'isa' => 'Str',    # ???
);

has 'mount_point' => (
    'is'      => 'rw',
    'isa'     => 'Str',
    'default' => q{},
);

has 'fs_type' => (
    'is'  => 'rw',
    'isa' => 'Str',
);

has 'fs_options' => (
    'is'  => 'rw',
    'isa' => 'Str',
);

sub BUILD {
    my $self = shift;

    $self->vg()->lvs()->{ $self->name() } = $self;

    return 1;
}

sub full_path {
    my $self = shift;

    return '/dev/' . $self->vg()->name() . '/' . $self->name();
}

sub mapper_path {
    my $self = shift;

    my $vg = $self->vg()->name();
    $vg =~ s/(?<!-)-(?!-)/--/;
    my $lv = $self->name();
    $lv =~ s/(?<!-)-(?!-)/--/;
    return '/dev/mapper/' . $vg . '-' . $lv;
}

sub valid {
    my $self = shift;
    $self->vg()->update();
    if ( $self->snap_pc() < 100 ) {
        return 1;
    }
    else {
        return;
    }
}

no Moose;
__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding utf-8

=head1 NAME

Linux::LVM2::LV - a class representing a LV in a Linux LVM2

=head1 SYNOPSIS

Instances of this class are usually created by Linux::LVM2::_find_vgs.

=head1 ATTRIBUTES

=head2 name

UNDOCUMENTED

=head2 vg

UNDOCUMENTED

=head2 access

UNDOCUMENTED

=head2 status

UNDOCUMENTED

=head2 intlvnum

UNDOCUMENTED

=head2 opencount

UNDOCUMENTED

=head2 lvsize

UNDOCUMENTED

=head2 leassoc

UNDOCUMENTED

=head2 lealloc

UNDOCUMENTED

=head2 allocpol

UNDOCUMENTED

=head2 rasect

UNDOCUMENTED

=head2 majornum

UNDOCUMENTED

=head2 minornum

UNDOCUMENTED

=head2 origin

UNDOCUMENTED

=head2 snap_pc

UNDOCUMENTED

=head2 move

UNDOCUMENTED

=head2 log

UNDOCUMENTED

=head2 copy_pc

UNDOCUMENTED

=head2 convert

UNDOCUMENTED

=head2 mount_point

UNDOCUMENTED

=head2 fs_type

UNDOCUMENTED

=head2 fs_options

UNDOCUMENTED

=head1 METHODS

=head2 BUILD

Invoked by Moose on construction. Sets a reference to this object in our VG.

=head2 full_path

Returns the /dev/<vg>/<lv> path to the LV.

=head2 mapper_path

Returns the /dev/mapper/.. path to the LV.

=head2 valid

Returns true if the snapshot percentage of this LV is below 100%.

=head1 NAME

Linux::LVM2::LV - Model a logical-volume

=head1 AUTHOR

Dominik Schulz <dominik.schulz@gauner.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Dominik Schulz.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
