use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::ECMA404::ValueInterface;

# ABSTRACT: MarpaX::ESLIF::ECMA404 Value Interface

our $VERSION = '0.001'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

my $_BACKSPACE = chr(0x0008);
my $_FORMFEED  = chr(0x000C);
my $_NEWLINE   = chr(0x000A);
my $_RETURN    = chr(0x000D);
my $_TAB       = chr(0x0009);

# -----------
# Constructor
# -----------
sub new                { bless [], $_[0] }

# ----------------
# Required methods
# ----------------
sub isWithHighRankOnly { 1 }  # When there is the rank adverb: highest ranks only ?
sub isWithOrderByRank  { 1 }  # When there is the rank adverb: order by rank ?
sub isWithAmbiguous    { 0 }  # Allow ambiguous parse ?
sub isWithNull         { 0 }  # Allow null parse ?
sub maxParses          { 0 }  # Maximum number of parse tree values

# ----------------
# Specific actions
# ----------------
sub empty_string            { ''               } # chars ::=
sub hex2codepoint_character { chr(hex($_[3]))  } # char  ::= '\\' 'u' /[[:xdigit:]]{4}/
sub pairs                   { [ $_[1], $_[3] ] } # pairs ::= string ':' value
sub backspace_character     { $_BACKSPACE      } # char  ::= '\\' 'b'
sub formfeed_character      { $_FORMFEED       } # char  ::= '\\' 'f'
sub newline_character       { $_NEWLINE        } # char  ::= '\\' 'n'
sub return_character        { $_RETURN         } # char  ::= '\\' 'r'
sub tabulation_character    { $_TAB            } # char  ::= '\\' 't'
#
# Methods that need some hacking -;
#
# Separator is PART of the arguments i.e.:
# ($self, $value1, $separator, $value2, $separator, etc...)
#
# C.f. http://www.perlmonks.org/?node_id=566543 for explanation of the method
#
sub array_ref {                                 # elements ::= value*
    #
    # elements ::= value+ separator => ','
    #
    # i.e. arguments are: ($self, $value1, $separator, $value2, $separator, etc..., $valuen)
    # Where value is always a token
    #
    [ map { $_[$_*2+1] } 0..int(@_/2)-1 ]
}

sub members {                                   # members  ::= pairs*
    #
    # members  ::= pairs+ separator => ','
    #
    # i.e. arguments are: ($self, $pair1, $separator, $pair2, $separator, etc..., $pairn)
    #
    my %hash;
    # Where pairs is always an array ref [string,value]
    #
    foreach (map { $_[$_*2+1] } 0..int(@_/2)-1) {
        $hash{$_->[0]} = $_->[1]
    }
    \%hash
}

#
# Result getter and setter
#
sub getResult { $_[0]->[0] }
sub setResult { $_[0]->[0] = $_[1] }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::ESLIF::ECMA404::ValueInterface - MarpaX::ESLIF::ECMA404 Value Interface

=head1 VERSION

version 0.001

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
