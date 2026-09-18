package MIDI::Device;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: MIDI device access

our $VERSION = '0.0102';

use Moo;
use strictures 2;
use Carp qw(croak);
# use Data::Dumper::Compact qw(ddc);
use File::ShareDir qw(dist_dir);
use YAML::XS qw(LoadFile);
use namespace::clean;


has name => (
    is       => 'ro',
    required => 1,
);


has module => (
    is       => 'ro',
    default  => 'MIDI::Device',
    required => 1,
);


has shared => (
    is => 'lazy',
);
sub _build_shared {
    my ($self) = @_;
    my $shared = eval { dist_dir($self->module) } || './share/';
    croak "File $shared doesn't exist: $!" unless -e $shared;
    return $shared;
}

has _device => (
    is      => 'rw',
    default => sub { {} },
);


sub cc {
    my ($self) = @_;
    my $cc = $self->_device->{control_change} || {};
    return $cc;
}


sub manufacturer {
    my ($self) = @_;
    return $self->_device->{manufacturer};
}


sub BUILD {
    my ($self) = @_;
    return unless $self->name;

    my $file = $self->shared . $self->name . '.yml';
    croak "File $file doesn't exist: $!" unless -e $file;

    $self->_device(LoadFile($file));
}


sub note_on {
    my ($self) = @_;
    return $self->_device->{note_on};
}


sub port_in {
    my ($self) = @_;
    return $self->_device->{port}{in};
}


sub port_out {
    my ($self) = @_;
    return $self->_device->{port}{out};
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Device - MIDI device access

=head1 VERSION

version 0.0102

=head1 SYNOPSIS

  use MIDI::Device ();
  my $device = MIDI::Device->new(name => 'midi-device-name'); # e.g. 'hpd-15'
  print 'Device: ', join(", ", $device->name, $device->manufacturer), "\n";
  my $ccs = $device->cc; # [ { number => 1, name => 'Modulation' }, ... ]

=head1 DESCRIPTION

Point of reference for C<MIDI::Device::*> modules. Contains device
metadata and control change messages.

It is my hope to add more useful metadata and methods...

=head2 Extending

Make a L<YAML> file named for the device (preferably in lower-case).
Save it in the distribution F<share> directory. Make a package to
instantiate the device object.

YAML file F<share/my-device.yml>:

  name: "My Device"
  manufacturer: "My Company, Inc."
  port:
      in: "My MIDI Port In"  # "generic" for a non-class-compliant device
      out: "My MIDI Port Out"
  control_change:
    - number: 0
      name: "Bank Select"
    - number: 32
      name: "Bank Select"
    ...

Perl module F<lib/MIDI/Device/My_Device.pm>:

  package MIDI::Device::My_Device;

  # ABSTRACT: My Device MIDI device metadata

  our $VERSION = '0.0100';

  use Moo;
  extends 'MIDI::Device';

  =encoding utf8

  =head1 SYNOPSIS

    use MIDI::Device::My_Device ();
    my $device = MIDI::Device::My_Device->new;
    print "Device: ", join(", ", $device->name, $device->manufacturer), "\n";
    my $ccs = $device->cc; # [ { number => 0, name => 'Bank Select' }, ... ]

  =head1 DESCRIPTION

  My device metadata.

  =cut

  =head1 ATTRIBUTES

  =head2 module

  The name of this module: C<'MIDI::Device::My_Device'>.

  =cut

  has module => (
      is      => 'ro',
      default => 'MIDI::Device::My_Device',
  );

  =head2 name

  Device name: C<my_device>

  =cut

  has name => (
      is      => 'ro',
      default => 'my_device',
  );

  =head1 METHODS

  =head2 new

    $device = MIDI::Device::My_Device->new;

  Return a new C<MIDI::Device::My_Device> object.

  =cut

  1;

=head1 ATTRIBUTES

=head2 name

  $name = $device->name;

Name of the device

Known device names:

  ez-ag
  hpd-15
  kaoss-pad-v
  microkorg
  se-02
  volca-drum

=head2 module

  $module = $device->module;

Name of the module. This is the name of a subclass, like
C<'MIDI::Device::DX7'>.

Default: C<MIDI::Device>

=head2 shared

  $shared = $device->shared;

Name of the device shared directory

=head1 METHODS

=head2 cc

  $ccs = $device->cc;

List of control change numbers and names

List entries are typically of the form:

  { number => 1, name => 'Modulation' }

But these can also contain control value attributes:

  { number => 42, name => 'Switch', off => 0, on => 127 }

=head2 manufacturer

  $manufacturer = $device->manufacturer;

Manufacturer of the device

=head2 new

  $device = MIDI::Device->new($port_name)

Return a new C<MIDI::Device> object given a port name of an available
MIDI device on the system.

=for Pod::Coverage BUILD

=head2 note_on

  $note_on = $device->note_on;

The C<note_on> section of the device

=head2 port_in

  $port_in = $device->port_in;

Input port name of the device

=head2 port_out

  $port_out = $device->port_out;

Output port name of the device

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
