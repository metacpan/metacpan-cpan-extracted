
use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::ECMA404;

# ABSTRACT: JSON Data Interchange Format following ECMA-404 specification

our $VERSION = '0.003'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY


use Carp qw/croak/;
use MarpaX::ESLIF 2.0.9;   # :discard[on] and :discard[off] handling in parse() method start here
use MarpaX::ESLIF::ECMA404::RecognizerInterface;
use MarpaX::ESLIF::ECMA404::ValueInterface;

our $_BNF    = do { local $/; <DATA> };


sub new {
  my ($pkg, %options) = @_;
  bless \MarpaX::ESLIF::Grammar->new(MarpaX::ESLIF->new($options{logger}), $_BNF), $pkg
}


sub decode {
  my ($self, $input) = @_;

  # ----------------------------------
  # Instanciate a recognizer interface
  # ----------------------------------
  my $recognizerInterface = MarpaX::ESLIF::ECMA404::RecognizerInterface->new($input);

  # -----------------------------
  # Instanciate a value interface
  # -----------------------------
  my $valueInterface = MarpaX::ESLIF::ECMA404::ValueInterface->new();

  # ---------------
  # Parse the input
  # ---------------
  return unless ${$self}->parse($recognizerInterface, $valueInterface);

  # ------------------------
  # Return the value
  # ------------------------
  $valueInterface->getResult
}


1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::ESLIF::ECMA404 - JSON Data Interchange Format following ECMA-404 specification

=head1 VERSION

version 0.003

=head1 SYNOPSIS

    use MarpaX::ESLIF::ECMA404;

    my $ecma404 = MarpaX::ESLIF::ECMA404->new();
    my $input   = '["JSON",{},[]]';
    my $json    = $ecma404->decode($input);

=head1 DESCRIPTION

This module decodes strict JSON input using L<MarpaX::ESLIF>.

=for html <a href="https://travis-ci.org/jddurand/MarpaX-ESLIF-ECMA404"><img src="https://travis-ci.org/jddurand/MarpaX-ESLIF-ECMA404.svg?branch=master" alt="Travis CI build status" height="18"></a> <a href="https://badge.fury.io/gh/jddurand%2FMarpaX-ESLIF-ECMA404"><img src="https://badge.fury.io/gh/jddurand%2FMarpaX-ESLIF-ECMA404.svg" alt="GitHub version" height="18"></a> <a href="http://opensource.org/licenses/MIT" rel="nofollow noreferrer"><img src="https://img.shields.io/badge/license-Perl%205-blue.svg" alt="License Perl5" height="18">

=head1 SUBROUTINES/METHODS

=head2 new($class, %options)

Instantiate a new object. Takes as parameter an optional hash of options that can be:

=over

=item logger

An optional logger object instance that must do methods compliant with L<Log::Any> interface.

=back

=head2 decode($self, $input)

Parses JSON that is in C<$input> and returns a perl variable containing the corresponding structured representation, or C<undef> in case of failure.

=head1 SEE ALSO

L<MarpaX::ESLIF>, L<Log::Any>

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
#
# Default action is to propagate the first RHS value
#
:default ::= action => ::shift
#
# JSON starting point is value
#
:start ::= value
# ----------------------------
# JSON Grammar as per ECMA-404
# I explicitely expose string grammar for one reason: inner string elements have specific actions
# ----------------------------
object   ::= '{' members '}'         action => ::copy[1] # Returns ${members}
members  ::= pairs* separator => ',' action => members   # Returns a hash reference of all @{$pairs} (separator have to be skipped)
pairs    ::= string ':' value        action => pairs     # Returns an array reference [ $string, $value ]
array    ::= '[' elements ']'        action => ::copy[1] # Returns ${elements}
elements ::= value* separator => ',' action => array_ref # Returns an array reference [ @{$value} ] (separator have to be skipped)
value    ::= string
           | number
           | object
           | array
           | 'true'
           | 'false'
           | 'null'

# -------------------------
# Unsignificant whitespaces
# -------------------------
:discard ::= /[\x{9}\x{A}\x{D}\x{20}]*/

# -----------
# JSON string
# -----------
# Executed in the top grammar and not as a lexeme. This is why we shutdown temporarily :discard in it
#
string     ::= '"' discardOff chars '"' discardOn    action => ::copy[2]               # Only chars is of interest
discardOff ::=                                                                         # Nullable rule used to disable discard
discardOn  ::=                                                                         # Nullable rule used to enable discard

event :discard[on]  = nulled discardOn                                                 # Implementation of discard disabing with reserved ':discard[on]' keyword
event :discard[off] = nulled discardOff                                                # Implementation of discard enabling with reserved ':discard[off]' keyword

# Default action is ::concat, that will return undef if there is nothing, so we concat ourself to handle this case
chars   ::= filled                                                                     # Returns ${filled}
filled  ::= char+                                    action => ::concat                # Returns join('', @{$char})
chars   ::=                                          action => empty_string            # Prefering empty string instead of undef
char    ::= [^"\\[:cntrl:]]                                                            # Returns matched data
          | '\\' '"'                                 action => ::copy[1]               # Returns double quote
          | '\\' '\\'                                action => ::copy[1]               # Returns backslash
          | '\\' '/'                                 action => ::copy[1]               # Returns slash
          | '\\' 'b'                                 action => backspace_character     # Returns perl's vision of \b
          | '\\' 'f'                                 action => formfeed_character      # Returns perl's vision of \f
          | '\\' 'n'                                 action => newline_character       # Returns perl's vision of \n
          | '\\' 'r'                                 action => return_character        # Returns perl's vision of \r
          | '\\' 't'                                 action => tabulation_character    # Returns perl's vision of \t
          | '\\' 'u' /[[:xdigit:]]{4}/               action => hex2codepoint_character # Returns perl's vision of \u

# -------------------------------------------------------------------------------------------------------------
# JSON number: defined as a single terminal: ECMA404 numbers can be are 100% compliant with perl numbers syntax
# -------------------------------------------------------------------------------------------------------------
#
number ::= /\-?(?:(?:[1-9]?[0-9]*)|[0-9])(?:\.[0-9]*)?(?:[eE](?:[+-])?[0-9]*)?/

# Original BNF for number follows
#
#number    ~ int
#          | int frac
#          | int exp
#          | int frac exp
#int       ~ digit
#          | digit19 digits
#          | '-' digit
#          | '-' digit19 digits
#digit     ~ [[:digit:]]
#digit19   ~ [1-9]
#frac      ~ '.' digits
#exp       ~ e digits
#digits    ~ digit*
#e         ~ /e[+-]?/i
