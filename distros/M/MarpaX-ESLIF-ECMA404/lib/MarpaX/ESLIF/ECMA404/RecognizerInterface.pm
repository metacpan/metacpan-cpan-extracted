use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::ECMA404::RecognizerInterface;

# ABSTRACT: MarpaX::ESLIF::ECMA404 Recognizer Interface

our $VERSION = '0.001'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

# -----------
# Constructor
# -----------
sub new { bless \$_[1], $_[0] }

# ----------------
# Required methods
# ----------------
sub read                   {        1 } # First read callback will be ok
sub isEof                  {        1 } # ../. and we will say this is EOF
sub isCharacterStream      {        1 } # MarpaX::ESLIF will validate the input
sub encoding               {          } # Let MarpaX::ESLIF guess
sub data                   { ${$_[0]} } # Data itself
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

version 0.001

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
