use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::ECMA404::RecognizerInterface;

# ABSTRACT: MarpaX::ESLIF::ECMA404 Recognizer Interface

our $VERSION = '0.009'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY



# -----------
# Constructor
# -----------


sub new {
    my ($pkg, %options) = @_;
    bless \%options, $pkg
}

# ----------------
# Required methods
# ----------------


sub read                   {        1 } # First read callback will be ok


sub isEof                  {        1 } # ../. and we will say this is EOF


sub isCharacterStream      {        1 } # MarpaX::ESLIF will validate the input


sub encoding               { $_[0]->{encoding} } # Let MarpaX::ESLIF guess eventually


sub data                   { $_[0]->{data} } # Data itself


sub isWithDisableThreshold {        0 } # Disable threshold warning ?


sub isWithExhaustion       {        0 } # Exhaustion event ?


sub isWithNewline          {        0 } # Newline count ?


sub isWithTrack            {        0 } # Absolute position tracking ?


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::ESLIF::ECMA404::RecognizerInterface - MarpaX::ESLIF::ECMA404 Recognizer Interface

=head1 VERSION

version 0.009

=head1 SYNOPSIS

    use MarpaX::ESLIF::ECMA404::RecognizerInterface;

    my $recognizerInterface = MarpaX::ESLIF::ECMA404::RecognizerInterface->new();

=head1 DESCRIPTION

MarpaX::ESLIF::ECMA404's Recognizer Interface

=head1 SUBROUTINES/METHODS

=head2 new($class, %options)

Instantiate a new recognizer interface object. C<%options> may contain:

=over

=item data

The data to parse

=item encoding

The encoding of the data

=back

=head2 Required methods

=head3 read($self)

Returns a true or a false value, indicating if last read was successful. Default is a true value.

=head3 isEof($self)

Returns a true or a false value, indicating if end-of-data is reached. Default is a true value.

=head3 isCharacterStream($self)

Returns a true or a false value, indicating if last read is a stream of characters. Default is a true value.

=head3 encoding($self)

Returns encoding information. Default is undef.

=head3 data($self)

Returns last bunch of data. Default is the string passed in the constructor.

=head3 isWithDisableThreshold($self)

Returns a true or a false value, indicating if threshold warning is on or off, respectively. Default is a false value.

=head3 isWithExhaustion($self)

Returns a true or a false value, indicating if exhaustion event is on or off, respectively. Default is a false value.

=head3 isWithNewline($self)

Returns a true or a false value, indicating if newline count is on or off, respectively. Default is a false value.

=head3 isWithTrack($self)

Returns a true or a false value, indicating if absolute position tracking is on or off, respectively. Default is a false value.

=head1 SEE ALSO

L<MarpaX::ESLIF::ECMA404>

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
