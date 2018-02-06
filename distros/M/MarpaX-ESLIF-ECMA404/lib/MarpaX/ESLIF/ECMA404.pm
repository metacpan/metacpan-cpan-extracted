
use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::ECMA404;

# ABSTRACT: JSON Data Interchange Format following ECMA-404 specification

our $VERSION = '0.010'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY


use Carp qw/croak/;
use MarpaX::ESLIF 2.0.34;   # bundled libiconv
use MarpaX::ESLIF::ECMA404::RecognizerInterface;
use MarpaX::ESLIF::ECMA404::ValueInterface;
use Scalar::Util qw/looks_like_number/;

our $_BNF    = do { local $/; <DATA> };


sub new {
    my ($pkg, %options) = @_;

    my $bnf = $_BNF;

    if ($options{unlimited_commas}) {
        my $tag = quotemeta('# /* Unlimited commas */');
        $bnf =~ s/$tag//g;
        $bnf =~ s/\bseparator\s*=>\s*comma\b/separator => commas/g;
    }
    if ($options{trailing_separator}) {
        $bnf =~ s/\bproper\s*=>\s*1\b/proper => 0/g;
    }
    if ($options{perl_comment}) {
        my $tag = quotemeta('# /* Perl comment */');
        $bnf =~ s/$tag//g;
    }
    if ($options{cplusplus_comment}) {
        my $tag = quotemeta('# /* C++ comment */');
        $bnf =~ s/$tag//g;
    }
    if ($options{bignum}) {
        my $tag = quotemeta('# /* bignum */');
        $bnf =~ s/$tag//g;
    }
    if ($options{inf}) {
        my $tag = quotemeta('# /* inf */');
        $bnf =~ s/$tag//g;
    }
    if ($options{nan}) {
        my $tag = quotemeta('# /* nan */');
        $bnf =~ s/$tag//g;
    }
    if ($options{cntrl}) {
        my $tag = quotemeta('# /* cntrl */');
        $bnf =~ s/$tag//g;
    }
    #
    # Check that max_depth looks like a number
    #
    my $max_depth = $options{max_depth} //= 0;
    croak "max_depth option does not look like a number" unless looks_like_number $max_depth;
    #
    # And that it is an integer
    #
    $max_depth =~ s/\s//g;
    croak "max_depth option does not look an integer >= 0" unless $max_depth =~  /^\+?\d+/;
    $options{max_depth} = int($max_depth);
    if ($options{max_depth}) {
        my $tag = quotemeta('# /* max_depth */');
        $bnf =~ s/$tag//g;
    }

    bless {
           grammar => MarpaX::ESLIF::Grammar->new(MarpaX::ESLIF->new($options{logger}), $bnf),
           %options
          }, $pkg
}


sub decode {
  my ($self, $input, $encoding) = @_;

  # ----------------------------------
  # Instanciate a recognizer interface
  # ----------------------------------
  my $recognizerInterface = MarpaX::ESLIF::ECMA404::RecognizerInterface->new(data => $input, encoding => $encoding);

  # -----------------------------
  # Instanciate a value interface
  # -----------------------------
  my $valueInterface = MarpaX::ESLIF::ECMA404::ValueInterface->new(logger => $self->{logger}, disallow_dupkeys => $self->{disallow_dupkeys});

  # ---------------
  # Parse the input
  # ---------------
  my $max_depth = $self->{max_depth};
  if ($max_depth) {
    $self->{cur_depth} = 0;
    #
    # We need to use the recognizer loop to have access to the inc/dec events
    #
    my $eslifRecognizer = MarpaX::ESLIF::Recognizer->new($self->{grammar}, $recognizerInterface);
    return unless eval {
      $eslifRecognizer->scan() || die "scan() failed";
      $self->_manage_events($eslifRecognizer);
      if ($eslifRecognizer->isCanContinue) {
        do {
          $eslifRecognizer->resume || die "resume() failed";
          $self->_manage_events($eslifRecognizer)
        } while ($eslifRecognizer->isCanContinue)
      }
      #
      # We configured value interface to not accept ambiguity not null parse.
      # So no need to loop on value()
      #
      MarpaX::ESLIF::Value->new($eslifRecognizer, $valueInterface)->value()
    }
  } else {
    return unless eval { $self->{grammar}->parse($recognizerInterface, $valueInterface) }
  }

  # ------------------------
  # Return the value
  # ------------------------
  $valueInterface->getResult
}

sub _manage_events {
  my ($self, $eslifRecognizer) = @_;

  foreach (@{$eslifRecognizer->events()}) {
    my $event = $_->{event};
    next unless $event;  # Can be undef for exhaustion
    if ($event eq 'inc[]') {
      croak "Maximum depth $self->{max_depth} reached" if ++$self->{cur_depth} > $self->{max_depth}
    } elsif ($event eq 'dec[]') {
       --$self->{cur_depth}
     }
  }
}


1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::ESLIF::ECMA404 - JSON Data Interchange Format following ECMA-404 specification

=head1 VERSION

version 0.010

=head1 SYNOPSIS

    use MarpaX::ESLIF::ECMA404;

    my $ecma404 = MarpaX::ESLIF::ECMA404->new();
    my $input   = '["JSON",{},[]]';
    my $json    = $ecma404->decode($input);

=head1 DESCRIPTION

This module decodes strict JSON input using L<MarpaX::ESLIF>.

=for html <a href="https://travis-ci.org/jddurand/MarpaX-ESLIF-ECMA404"><img src="https://travis-ci.org/jddurand/MarpaX-ESLIF-ECMA404.svg?branch=master" alt="Travis CI build status" height="18"></a> <a href="https://badge.fury.io/gh/jddurand%2FMarpaX-ESLIF-ECMA404"><img src="https://badge.fury.io/gh/jddurand%2FMarpaX-ESLIF-ECMA404.svg" alt="GitHub version" height="18"></a> <a href="https://dev.perl.org/licenses/" rel="nofollow noreferrer"><img src="https://img.shields.io/badge/license-Perl%205-blue.svg" alt="License Perl5" height="18">

=head1 SUBROUTINES/METHODS

=head2 new($class, %options)

Instantiate a new object. Takes as parameter an optional hash of options that can be:

=over

=item logger

An optional logger object instance that must do methods compliant with L<Log::Any> interface.

=back

and the following extensions:

=over

=item unlimited_commas

Allow unlimited number of commas between object pairs or array elements.

=item trailing_separator

Allow trailing separator (i.e. a comma, eventually an unlimited number of them (c.f. C<unlimited_commas> option) after object pairs or array elements.

=item perl_comment

Allow perl style comments.

=item cplusplus_comment

Allow C++ style comments.

=item bignum

Use perl's bignum to store numbers. Default perl's bignum accuracy and precision will be in effect.

=item inf

Support of C<infinity> or C<inf>, case insensitive, eventually preceded by a C<+> or a C<-> sign.

=item nan

Support of C<nan>, case insensitive, eventually preceded by a C<+> or a C<-> sign (even if this is meaningless).

=item cntrl

Support of Unicode's control characters (i.e. the range C<[\x00-\x1F]>).

=item disallow_dupkeys

Dot not allow duplicate key in an object.

=back

=head2 decode($self, $input, $encoding)

Parses JSON that is in C<$input> and returns a perl variable containing the corresponding structured representation, or C<undef> in case of failure. C<$encoding> is an optional parameter: JSON parser is using L<MarpaX::ESLIF> that will I<guess> about the encoding if not specified, this guess is not 100% reliable - so if you know the encoding of your data, in particular if it is not in UTF-8, you should give the information to the parser. Default is to guess.

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

                   #######################################################
                   # >>>>>>>>>>>>>>>> Strict JSON Grammar <<<<<<<<<<<<<<<<
                   #######################################################

# ----------------
# Start is a value
# ----------------
:start ::= value

# -------------------
# Composite separator
# -------------------
comma    ::= ','                                  action         => ::undef   # No-op anyway, override ::shift (default action)

# ----------
# JSON value
# ----------
value    ::= string                                                           # ::shift (default action)
           | number                                                           # ::shift (default action)
           | object                                                           # ::shift (default action)
           | array                                                            # ::shift (default action)
           | 'true'                               action         => true      # Returns a perl true value
           | 'false'                              action         => false     # Returns a perl false value
           | 'null'

# -----------
# JSON object
# -----------
object   ::= '{' inc members '}' dec              action         => ::copy[2] # Returns members
members  ::= pairs*                               action         => members   # Returns { @{pairs1}, ..., @{pair2} }
                                                  separator      => comma     # ... separated by comma
                                                  proper         => 1         # ... with no trailing separator
                                                  hide-separator => 1         # ... and hide separator in the action
                                                  
pairs    ::= string ':' value                     action         => pairs     # Returns [ string, value ]

# -----------
# JSON Arrays
# -----------
array    ::= '[' inc elements ']' dec             action         => ::copy[2] # Returns elements
elements ::= value*                               action => elements          # Returns [ value1, ..., valuen ]
                                                  separator      => comma     # ... separated by comma
                                                  proper         => 1         # ... with no trailing separator
                                                  hide-separator => 1         # ... and hide separator in the action
                                                  

# ------------
# JSON Numbers
# ------------
number ::= NUMBER            # /* bignum */       action => number            # Prepare for eventual bignum extension

NUMBER   ~ _INT
         | _INT _FRAC
         | _INT _EXP
         | _INT _FRAC _EXP
_INT     ~ _DIGIT
         | _DIGIT19 _DIGITS
         | '-' _DIGIT
         | '-' _DIGIT19 _DIGITS
_DIGIT   ~ [0-9]
_DIGIT19 ~ [1-9]
_FRAC    ~ '.' _DIGITS
_EXP     ~ _E _DIGITS
_DIGITS  ~ _DIGIT+
_E       ~ /e[+-]?/i

# -----------
# JSON String
# -----------
string     ::= '"' discardOff chars '"' discardOn action => ::copy[2]               # Only chars is of interest
discardOff ::=                                    action => ::undef                 # Nullable rule used to disable discard
discardOn  ::=                                    action => ::undef                 # Nullable rule used to enable discard

event :discard[on]  = nulled discardOn                                                           # Implementation of discard disabing using reserved ':discard[on]' keyword
event :discard[off] = nulled discardOff                                                          # Implementation of discard enabling using reserved ':discard[off]' keyword

chars   ::= filled                                                                               # ::shift (default action)
filled  ::= char+                                 action => ::concat                # Returns join('', char1, ..., charn)
chars   ::=                                       action => empty_string            # Prefering empty string instead of undef
char    ::= [^"\\\x00-\x1F]                                                         # ::shift (default action) - take care PCRE2 [:cntrl:] includes DEL character
          | '\\' '"'                              action => ::copy[1]               # Returns double quote, already ok in data
          | '\\' '\\'                             action => ::copy[1]               # Returns backslash, already ok in data
          | '\\' '/'                              action => ::copy[1]               # Returns slash, already ok in data
          | '\\' 'b'                              action => ::u8"\x{08}"
          | '\\' 'f'                              action => ::u8"\x{0C}"
          | '\\' 'n'                              action => ::u8"\x{0A}"
          | '\\' 'r'                              action => ::u8"\x{0D}"
          | '\\' 't'                              action => ::u8"\x{09}"
          | /(?:\\u[[:xdigit:]]{4})+/             action => unicode


# -------------------------
# Unsignificant whitespaces
# -------------------------
:discard ::= /[\x{9}\x{A}\x{D}\x{20}]+/

# ------------------------------------------------------
# Needed for eventual depth extension - no op by default
# ------------------------------------------------------
inc ::=                                                        action => ::undef
dec ::=                                                        action => ::undef

                   #######################################################
                   # >>>>>>>>>>>>>>>>>> JSON Extensions <<<<<<<<<<<<<<<<<<
                   #######################################################

# --------------------------
# Unlimited commas extension
# --------------------------
# /* Unlimited commas */commas   ::= comma+

# --------------------------
# Perl comment extension
# --------------------------
# /* Perl comment */:discard ::= /(?:(?:#)(?:[^\n]*)(?:\n|\z))/u

# --------------------------
# C++ comment extension
# --------------------------
# /* C++ comment */:discard ::= /(?:(?:(?:\/\/)(?:[^\n]*)(?:\n|\z))|(?:(?:\/\*)(?:(?:[^\*]+|\*(?!\/))*)(?:\*\/)))/

# --------------------------
# Max depth extension
# --------------------------
# /* max_depth */event inc[] = nulled inc                                                        # Increment depth
# /* max_depth */event dec[] = nulled dec                                                        # Decrement depth

# ----------------
# Number extension
# ----------------
#
# number ::= /\-?(?:(?:[1-9]?[0-9]+)|[0-9])(?:\.[0-9]+)?(?:[eE](?:[+-])?[0-9]+)?/ # /* bignum */action => number

# /* nan */number   ::= '-NaN':i                               action => nan
# /* nan */number   ::=  'NaN':i                               action => nan
# /* nan */number   ::= '+NaN':i                               action => nan
# /* inf */number   ::= '-Infinity':i                          action => negative_infinity
# /* inf */number   ::=  'Infinity':i                          action => positive_infinity
# /* inf */number   ::= '+Infinity':i                          action => positive_infinity
# /* inf */number   ::= '-Inf':i                               action => negative_infinity
# /* inf            ::=  'Inf':i                               action => positive_infinity
# /* inf */number   ::= '+Inf':i                               action => positive_infinity

# -----------------
# Control character
# -----------------
# /* cntrl */char      ::= /[\x00-\x1F]/                                                          # Because [:cntrl:] includes DEL (x7F)
