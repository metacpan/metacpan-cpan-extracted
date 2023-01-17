use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::JSON::Decoder::RecognizerInterface;
use Carp qw/croak/;

# ABSTRACT: MarpaX::ESLIF::JSON Recognizer Interface

our $VERSION = '6.0.29'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY



# ============================================================================
# new
# ============================================================================


sub new {
    my ($pkg, $string, $encoding) = @_;

    return bless { input => $string // '', encoding => $encoding }, $pkg
}


# ============================================================================
# read
# ============================================================================


sub read {
    return 1 # First read callback will be ok
}

# ============================================================================
# isEof
# ============================================================================


sub isEof {
    return 1 # ../. and we will say this is EOF
}

# ============================================================================
# isCharacterStream
# ============================================================================


sub isCharacterStream {
    return 1 # MarpaX::ESLIF will validate the input
}

# ============================================================================
# encoding
# ============================================================================


sub encoding {
    return $_[0]->{encoding} # Let MarpaX::ESLIF guess eventually - undef is ok
}

# ============================================================================
# data
# ============================================================================


sub data {
    return $_[0]->{input} // croak 'Undefined input' # Data itself
}

# ============================================================================
# isWithDisableThreshold
# ============================================================================


sub isWithDisableThreshold {
    return 0
}

# ============================================================================
# isWithExhaustion
# ============================================================================


sub isWithExhaustion {
    return $_[0]->{exhaustion} // 0
}

# ============================================================================
# isWithNewline
# ============================================================================


sub isWithNewline {
    return 1
}

# ============================================================================
# isWithTrack
# ============================================================================


sub isWithTrack {
    return 0
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::ESLIF::JSON::Decoder::RecognizerInterface - MarpaX::ESLIF::JSON Recognizer Interface

=head1 VERSION

version 6.0.29

=head1 SYNOPSIS

    use MarpaX::ESLIF::JSON::Decoder::RecognizerInterface;

    my $recognizerInterface = MarpaX::ESLIF::JSON::Decoder::RecognizerInterface->new();

=head1 DESCRIPTION

MarpaX::ESLIF::JSON's Decoder Recognizer Interface

=head1 SUBROUTINES/METHODS

=head2 new($class, $string, $encoding)

Instantiate a new recognizer interface object. Parameters are:

=over

=item input

The input to parse. Default to the empty string.

=item encoding

The input's encoding. Can be C<undef>.

=back

=head2 Required methods

=head3 read($self)

Returns a true or a false value, indicating if last read was successful.

=head3 isEof($self)

Returns a true or a false value, indicating if end-of-data is reached.

=head3 isCharacterStream($self)

Returns a true or a false value, indicating if last read is a stream of characters.

=head3 encoding($self)

Returns encoding information.

=head3 data($self)

Returns last bunch of data. Default is the string passed in the constructor.

=head3 isWithDisableThreshold($self)

Returns a true or a false value, indicating if threshold warning is on or off, respectively.

=head3 isWithExhaustion($self)

Returns a true or a false value, indicating if exhaustion event is on or off, respectively.

=head3 isWithNewline($self)

Returns a true or a false value, indicating if newline count is on or off, respectively.

=head3 isWithTrack($self)

Returns a true or a false value, indicating if absolute position tracking is on or off, respectively.

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
