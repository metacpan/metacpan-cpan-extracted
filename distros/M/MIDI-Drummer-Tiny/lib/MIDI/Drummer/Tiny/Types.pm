package MIDI::Drummer::Tiny::Types;
$MIDI::Drummer::Tiny::Types::VERSION = '0.6006';
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Type library for MIDI::Drummer::Tiny

use strict;
use warnings;

use Type::Library
    -extends => [ qw(
        Types::MIDI
        Types::Common::Numeric
        Types::Common::String
    ) ],
    -declare => qw(
        BPM
        Duration
    );
use Type::Utils -all;

use MIDI::Util qw(midi_dump);

#pod =type BPM
#pod
#pod A L<positive number|Types::Common::Numeric/PositiveNum> expressing
#pod beats per minute.
#pod
#pod =cut

declare BPM, as PositiveNum;

#pod =type Duration
#pod
#pod A L<non-empty string|Types::Common::String/Types> corresponding to
#pod a L<duration in MIDI::Simple|MIDI::Simple/"Parameters for n/r/noop">.
#pod
#pod =cut

my %length = %{ midi_dump('length') };
declare Duration, as NonEmptyStr, where { exists $length{$_} };

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Drummer::Tiny::Types - Type library for MIDI::Drummer::Tiny

=head1 VERSION

version 0.6006

=head1 TYPES

=head2 BPM

A L<positive number|Types::Common::Numeric/PositiveNum> expressing
beats per minute.

=head2 Duration

A L<non-empty string|Types::Common::String/Types> corresponding to
a L<duration in MIDI::Simple|MIDI::Simple/"Parameters for n/r/noop">.

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2025 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
