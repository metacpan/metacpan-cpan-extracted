package MIDI::Drummer::Tiny::Types::MIDI;
$MIDI::Drummer::Tiny::Types::MIDI::VERSION = '0.6004';
our $AUTHORITY = 'cpan:GENE';

# ABSTRACT: Type library for MIDI

use strict;
use warnings;

use Type::Library
    -extends => [ qw(
        Types::Common::Numeric
    ) ],
    -declare => qw(
        Channel
        Velocity
        Note
        PercussionNote
    );
use Type::Utils -all;

## no critic (ValuesAndExpressions::ProhibitMagicNumbers)

#pod =type Channel
#pod
#pod An L<integer from|Types::Common::Numeric/Types> 0 to 15 corresponding
#pod to a L<MIDI Channel|/"SEE ALSO">.
#pod
#pod =cut

declare Channel, as IntRange [ 0, 15 ];

#pod =type Velocity
#pod
#pod An L<integer from|Types::Common::Numeric/Types> 0 to 127 corresponding
#pod to a L<MIDI Velocity|/"SEE ALSO">.
#pod
#pod =cut

declare Velocity, as IntRange [ 0, 127 ];

#pod =type Note
#pod
#pod An L<integer from|Types::Common::Numeric/Types> 0 to 127 corresponding
#pod to a L<MIDI Note Number|/"SEE ALSO">.
#pod
#pod =cut

declare Note, as IntRange [ 0, 127 ];

#pod =type PercussionNote
#pod
#pod A L</Note> from 27 through 87, corresponding to a value in the
#pod L<General MIDI 2 Percussion Sound Set|/"SEE ALSO">.
#pod
#pod =cut

# TODO: update MIDI-Perl's %MIDI::notenum2percussion with all GM2 sounds?
declare PercussionNote, as Note, where { $_ >= 27 or $_ <= 87 };

#pod =head1 SEE ALSO
#pod
#pod =over
#pod
#pod =item *
#pod
#pod I<MIDI 1.0 Detailed Specification (Document Version 4.2.1)>,
#pod revised February 1996 by the MIDI Manufacturers Association:
#pod L<https://midi.org/midi-1-0-core-specifications>
#pod
#pod =item *
#pod
#pod B<Appendix B: GM 2 Percussion Sound Set> in
#pod I<General MIDI 2 (Version 1.2a)>,
#pod published February 6, 2007 by the MIDI Manufacturers Association:
#pod L<https://midi.org/general-midi-2>
#pod
#pod =back
#pod
#pod =cut

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MIDI::Drummer::Tiny::Types::MIDI - Type library for MIDI

=head1 VERSION

version 0.6004

=head1 TYPES

=head2 Channel

An L<integer from|Types::Common::Numeric/Types> 0 to 15 corresponding
to a L<MIDI Channel|/"SEE ALSO">.

=head2 Velocity

An L<integer from|Types::Common::Numeric/Types> 0 to 127 corresponding
to a L<MIDI Velocity|/"SEE ALSO">.

=head2 Note

An L<integer from|Types::Common::Numeric/Types> 0 to 127 corresponding
to a L<MIDI Note Number|/"SEE ALSO">.

=head2 PercussionNote

A L</Note> from 27 through 87, corresponding to a value in the
L<General MIDI 2 Percussion Sound Set|/"SEE ALSO">.

=head1 SEE ALSO

=over

=item *

I<MIDI 1.0 Detailed Specification (Document Version 4.2.1)>,
revised February 1996 by the MIDI Manufacturers Association:
L<https://midi.org/midi-1-0-core-specifications>

=item *

B<Appendix B: GM 2 Percussion Sound Set> in
I<General MIDI 2 (Version 1.2a)>,
published February 6, 2007 by the MIDI Manufacturers Association:
L<https://midi.org/general-midi-2>

=back

=head1 AUTHOR

Gene Boggs <gene.boggs@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014-2025 by Gene Boggs.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
