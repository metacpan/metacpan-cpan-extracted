use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::URI::_generic::RecognizerInterface;

our $VERSION = '0.003'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

# ABSTRACT: MarpaX::ESLIF's URI Recognizer Interface

#
# This class is very internal and should not harm Pod coverage test
#


#
# Optimized constructor
#
sub new { bless \$_[1], $_[0] }
#
# Recognizer Interface required methods
#
sub read                   {          1 } # First read callback will be ok
sub isEof                  {          1 } # ../. and we will say this is EOF
sub isCharacterStream      {          1 } # MarpaX::ESLIF will validate the input
sub encoding               {          } # Let MarpaX::ESLIF guess
sub data                   { "${$_[0]}" } # Forced stringified input
sub isWithDisableThreshold {          0 } # Disable threshold warning ?
sub isWithExhaustion       {          0 } # Exhaustion event ?
sub isWithNewline          {          0 } # Newline count ?
sub isWithTrack            {          0 } # Absolute position tracking ?

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::ESLIF::URI::_generic::RecognizerInterface - MarpaX::ESLIF's URI Recognizer Interface

=head1 VERSION

version 0.003

=for Pod::Coverage *EVERYTHING*

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
