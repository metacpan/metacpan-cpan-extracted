package MIDI::Device::DX7;
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Yamaha DX7 MIDI Metadata

our $VERSION = '0.0101';

use Moo;
extends 'MIDI::Device';


has module => (
    is      => 'ro',
    default => 'MIDI::Device::DX7',
);


has name => (
    is      => 'ro',
    default => 'dx7',
);


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Device::DX7 - Yamaha DX7 MIDI Metadata

=head1 VERSION

version 0.0101

=head1 SYNOPSIS

  use MIDI::Device::DX7 ();
  my $device = MIDI::Device::DX7->new;
  print "Device: ", join(", ", $device->name, $device->manufacturer), "\n";
  my $ccs = $device->cc; # [ {} ] # None!

=head1 DESCRIPTION

Yamaha DX7 synthesizer device metadata. This device does not have control change messages, as the DX7 predates the widespread use of CC#s.

=head1 ATTRIBUTES

=head2 module

The name of this module: C<'MIDI::Device::DX7'>.

=head2 name

Device name: C<dx7>

=head1 METHODS

=head2 new

  $device = MIDI::Device::DX7->new;

Return a new C<MIDI::Device::DX7> object.

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
