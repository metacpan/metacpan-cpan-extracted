package MIDI::Drummer::Tiny::Types;
$MIDI::Drummer::Tiny::Types::VERSION = '0.6012';
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Type library for MIDI::Drummer::Tiny

use strict;
use warnings;

use Type::Library
    -extends => [ qw(
        Types::MIDI
        Types::Music
        Types::Common::String
    ) ],
    -declare => qw(
        Duration
        MIDI_File
        Soundfont_File
    );
use Type::Utils -all;
use Types::Standard   qw(FileHandle);
use Types::Path::Tiny qw(File Path);

use MIDI::Util qw(midi_dump);

#pod =type Duration
#pod
#pod A L<non-empty string|Types::Common::String/Types> corresponding to
#pod a L<duration in MIDI::Simple|MIDI::Simple/"Parameters for n/r/noop">.
#pod
#pod =cut

my %length = %{ midi_dump('length') };
declare Duration, as NonEmptyStr, where { exists $length{$_} };

#pod =type MIDI_File
#pod
#pod The name of the MIDI file to be written.
#pod
#pod =cut

declare MIDI_File, as NonEmptyStr | Path | FileHandle;

#pod =type Soundfont_File
#pod
#pod The name of the MIDI soundfont file to use.
#pod
#pod =cut

declare Soundfont_File, as NonEmptyStr | File;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Drummer::Tiny::Types - Type library for MIDI::Drummer::Tiny

=head1 VERSION

version 0.6012

=head1 TYPES

=head2 Duration

A L<non-empty string|Types::Common::String/Types> corresponding to
a L<duration in MIDI::Simple|MIDI::Simple/"Parameters for n/r/noop">.

=head2 MIDI_File

The name of the MIDI file to be written.

=head2 Soundfont_File

The name of the MIDI soundfont file to use.

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2025 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
