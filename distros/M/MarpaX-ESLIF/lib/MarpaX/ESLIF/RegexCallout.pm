use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::RegexCallout;

# ABSTRACT: ESLIF Regex Callout

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

our $VERSION = '6.0.22'; # VERSION


use constant PCRE2_ERROR_NOMATCH => -1;


use constant PCRE2_ERROR_PARTIAL => -2;


use constant PCRE2_ERROR_UTF8_ERR1 => -3;


use constant PCRE2_ERROR_UTF8_ERR2 => -4;


use constant PCRE2_ERROR_UTF8_ERR3 => -5;


use constant PCRE2_ERROR_UTF8_ERR4 => -6;


use constant PCRE2_ERROR_UTF8_ERR5 => -7;


use constant PCRE2_ERROR_UTF8_ERR6 => -8;


use constant PCRE2_ERROR_UTF8_ERR7 => -9;


use constant PCRE2_ERROR_UTF8_ERR8 => -10;


use constant PCRE2_ERROR_UTF8_ERR9 => -11;


use constant PCRE2_ERROR_UTF8_ERR10 => -12;


use constant PCRE2_ERROR_UTF8_ERR11 => -13;


use constant PCRE2_ERROR_UTF8_ERR12 => -14;


use constant PCRE2_ERROR_UTF8_ERR13 => -15;


use constant PCRE2_ERROR_UTF8_ERR14 => -16;


use constant PCRE2_ERROR_UTF8_ERR15 => -17;


use constant PCRE2_ERROR_UTF8_ERR16 => -18;


use constant PCRE2_ERROR_UTF8_ERR17 => -19;


use constant PCRE2_ERROR_UTF8_ERR18 => -20;


use constant PCRE2_ERROR_UTF8_ERR19 => -21;


use constant PCRE2_ERROR_UTF8_ERR20 => -22;


use constant PCRE2_ERROR_UTF8_ERR21 => -23;


use constant PCRE2_ERROR_UTF16_ERR1 => -24;


use constant PCRE2_ERROR_UTF16_ERR2 => -25;


use constant PCRE2_ERROR_UTF16_ERR3 => -26;


use constant PCRE2_ERROR_UTF32_ERR1 => -27;


use constant PCRE2_ERROR_UTF32_ERR2 => -28;


use constant PCRE2_ERROR_BADDATA => -29;


use constant PCRE2_ERROR_MIXEDTABLES => -30;


use constant PCRE2_ERROR_BADMAGIC => -31;


use constant PCRE2_ERROR_BADMODE => -32;


use constant PCRE2_ERROR_BADOFFSET => -33;


use constant PCRE2_ERROR_BADOPTION => -34;


use constant PCRE2_ERROR_BADREPLACEMENT => -35;


use constant PCRE2_ERROR_BADUTFOFFSET => -36;


use constant PCRE2_ERROR_CALLOUT => -37;


use constant PCRE2_ERROR_DFA_BADRESTART => -38;


use constant PCRE2_ERROR_DFA_RECURSE => -39;


use constant PCRE2_ERROR_DFA_UCOND => -40;


use constant PCRE2_ERROR_DFA_UFUNC => -41;


use constant PCRE2_ERROR_DFA_UITEM => -42;


use constant PCRE2_ERROR_DFA_WSSIZE => -43;


use constant PCRE2_ERROR_INTERNAL => -44;


use constant PCRE2_ERROR_JIT_BADOPTION => -45;


use constant PCRE2_ERROR_JIT_STACKLIMIT => -46;


use constant PCRE2_ERROR_MATCHLIMIT => -47;


use constant PCRE2_ERROR_NOMEMORY => -48;


use constant PCRE2_ERROR_NOSUBSTRING => -49;


use constant PCRE2_ERROR_NOUNIQUESUBSTRING => -50;


use constant PCRE2_ERROR_NULL => -51;


use constant PCRE2_ERROR_RECURSELOOP => -52;


use constant PCRE2_ERROR_DEPTHLIMIT => -53;


use constant PCRE2_ERROR_RECURSIONLIMIT => -53;


use constant PCRE2_ERROR_UNAVAILABLE => -54;


use constant PCRE2_ERROR_UNSET => -55;


use constant PCRE2_ERROR_BADOFFSETLIMIT => -56;


use constant PCRE2_ERROR_BADREPESCAPE => -57;


use constant PCRE2_ERROR_REPMISSINGBRACE => -58;


use constant PCRE2_ERROR_BADSUBSTITUTION => -59;


use constant PCRE2_ERROR_BADSUBSPATTERN => -60;


use constant PCRE2_ERROR_TOOMANYREPLACE => -61;


use constant PCRE2_ERROR_BADSERIALIZEDDATA => -62;


use constant PCRE2_ERROR_HEAPLIMIT => -63;


use constant PCRE2_ERROR_CONVERT_SYNTAX => -64;


use constant PCRE2_ERROR_INTERNAL_DUPMATCH => -65;


#
# old-style perl - getters only in java style
#


sub getCalloutNumber { return $_[0]->{callout_number} }



sub getCalloutString { return $_[0]->{callout_string} }


sub getSubject { return $_[0]->{subject} }


sub getPattern { return $_[0]->{pattern} }


sub getCaptureTop { return $_[0]->{capture_top} }


sub getCaptureLast { return $_[0]->{capture_last} }


sub getOffsetVector { return $_[0]->{offset_vector} }


sub getMark { return $_[0]->{mark} }


sub getStartMatch { return $_[0]->{start_match} }


sub getCurrentPosition { return $_[0]->{current_position} }


sub getNextItem { return $_[0]->{next_item} }


sub getGrammarLevel { return $_[0]->{grammar_level} }


sub getSymbolId { return $_[0]->{symbol_id} }


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::ESLIF::RegexCallout - ESLIF Regex Callout

=head1 VERSION

version 6.0.22

=head1 SYNOPSIS

  package MyRecognizerInterface;
  use Data::Dumper;

  sub new                    { bless { data => $_[1] }, $_[0] }
  sub read                   { 1 }
  sub isEof                  { 1 }
  sub isCharacterStream      { 1 }
  sub encoding               { }
  sub data                   { $_[0]->{data} }
  sub isWithDisableThreshold { 1 }
  sub isWithExhaustion       { 0 }
  sub isWithNewline          { 1 }
  sub isWithTrack            { 0 }

  sub do_regexCallout {
      my ($self, $regexCallout) = @_;
      print STDERR "Regex callout: " . Dumper($regexCallout);
      return 0;
  }

  1;

  package MyValueInterface;

  sub new                    { bless { result => undef }, $_[0] }
  sub isWithHighRankOnly     { 1 }
  sub isWithOrderByRank      { 1 }
  sub isWithAmbiguous        { 0 }
  sub isWithNull             { 0 }
  sub maxParses              { 0 }
  sub setResult              { $_[0]->{result} = $_[1] }
  sub getResult              { $_[0]->{result} }

  1;

  package main;
  use MarpaX::ESLIF;

  my $eslif = MarpaX::ESLIF->new();
  my $data = do { local $/; <DATA> };
  my $eslifGrammar = MarpaX::ESLIF::Grammar->new($eslif, $data);
  foreach (qw/123XX XX/) {
      my $recognizerInterface = MyRecognizerInterface->new($_);
      my $valueInterface      = MyValueInterface->new();
      $eslifGrammar->parse($recognizerInterface, $valueInterface);
      print STDERR "Value: " . $valueInterface->getResult() . "\n";
  }

  __DATA__
  #
  # This is an example of a calculator grammar
  #
  :default ::= regex-action  => do_regexCallout

  topRule ::= /[\d]+(?C"Digits")(.*)(?C"Rest")/
  topRule ::= /X+(?C123)/

=head1 DESCRIPTION

ESLIF Regex Callout.

Regular expression callbacks have an argument that is hash blessed to this package. Regular expression callback is a grammar setting using the C<::default> meta rule, e.g.:

  :default ::= regex-action  => do_regexCallout

where the callback, C<do_regexCallout> here, must reside in the recognizer interface. Callouts are writen as per PCRE2 syntax, e.g.:

  someRule ::= /[\d]+(?C"CallbackIdentifier as a string")/
  someRule ::= /X(?C123)/

The callout function is interpreted as an integer, whose value conforms to PCRE2 specification at https://www.pcre.org/current/doc/html/pcre2callout.html:

=over

=item If the value is zero, matching proceeds as normal

=item If the value is greater than zero, matching fails at the current point, but the testing of other matching possibilities goes ahead, just as if a lookahead assertion had failed.

=item If the value is less than zero, the match is abandoned, and the matching function returns the negative value. 

=back

ESLIF prevents negative values to be lower than the most negative meaningful value. Exhaustive current list is as of PCRE2 version 10.33, i.e.:

=over

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_NOMATCH          (-1)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_PARTIAL          (-2)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_UTF8_ERR1        (-3)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_UTF8_ERR2        (-4)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_UTF8_ERR3        (-5)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_UTF8_ERR4        (-6)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_UTF8_ERR5        (-7)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_UTF8_ERR6        (-8)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_UTF8_ERR7        (-9)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_UTF8_ERR8       (-10)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_UTF8_ERR9       (-11)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_UTF8_ERR10      (-12)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_UTF8_ERR11      (-13)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_UTF8_ERR12      (-14)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_UTF8_ERR13      (-15)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_UTF8_ERR14      (-16)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_UTF8_ERR15      (-17)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_UTF8_ERR16      (-18)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_UTF8_ERR17      (-19)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_UTF8_ERR18      (-20)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_UTF8_ERR19      (-21)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_UTF8_ERR20      (-22)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_UTF8_ERR21      (-23)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_UTF16_ERR1      (-24)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_UTF16_ERR2      (-25)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_UTF16_ERR3      (-26)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_UTF32_ERR1      (-27)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_UTF32_ERR2      (-28)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_BADDATA           (-29)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_MIXEDTABLES       (-30)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_BADMAGIC          (-31)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_BADMODE           (-32)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_BADOFFSET         (-33)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_BADOPTION         (-34)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_BADREPLACEMENT    (-35)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_BADUTFOFFSET      (-36)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_CALLOUT           (-37)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_DFA_BADRESTART    (-38)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_DFA_RECURSE       (-39)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_DFA_UCOND         (-40)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_DFA_UFUNC         (-41)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_DFA_UITEM         (-42)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_DFA_WSSIZE        (-43)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_INTERNAL          (-44)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_JIT_BADOPTION     (-45)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_JIT_STACKLIMIT    (-46)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_MATCHLIMIT        (-47)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_NOMEMORY          (-48)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_NOSUBSTRING       (-49)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_NOUNIQUESUBSTRING (-50)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_NULL              (-51)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_RECURSELOOP       (-52)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_DEPTHLIMIT        (-53)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_RECURSIONLIMIT    (-53)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_UNAVAILABLE       (-54)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_UNSET             (-55)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_BADOFFSETLIMIT    (-56)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_BADREPESCAPE      (-57)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_REPMISSINGBRACE   (-58)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_BADSUBSTITUTION   (-59)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_BADSUBSPATTERN    (-60)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_TOOMANYREPLACE    (-61)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_BADSERIALIZEDDATA (-62)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_HEAPLIMIT         (-63)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_CONVERT_SYNTAX    (-64)

=item MarpaX::ESLIF::RegexCallout::PCRE2_ERROR_INTERNAL_DUPMATCH (-65)

=back

Any value lower than C<PCRE2_ERROR_INTERNAL_DUPMATCH> will emit a warning by ESLIF, the later changing it to C<PCRE2_ERROR_CALLOUT>.

=head1 METHODS

=head2 $self->getCalloutNumber

Returns callout number or undef

=head2 $self->getCalloutString

Returns callout string or undef

=head2 $self->getSubject

Returns current subject. Always undef unless ESLIF is compiled in trace mode.

=head2 $self->getPattern

Returns pattern. Always undef unless ESLIF is compiled in trace mode.

=head2 $self->getCaptureTop

Returns the max recent capture

=head2 $self->getCaptureLast

Returns the most recently closed capture

=head2 $self->getOffsetVector

Returns a reference to an array containing offsets

=head2 $self->getMark

Returns the most recently passed C<NAME> of a C<(*MARK:NAME)>, C<(*PRUNE:NAME)> or C<(*THEN:NAME)> item in the match, undef if none.

=head2 $self->getStartMatch

Returns the current mark start attempt offset

=head2 $self->getCurrentPosition

Returns the current subject offset

=head2 $self->getNextItem

Returns the next item in the pattern

=head2 $self->getGrammarLevel

Returns the current grammar level

=head2 $self->getSymbolId

Returns the current symbol id

=head1 SEE ALSO

L<PCRE2 Callout Specification|https://www.pcre.org/current/doc/html/pcre2callout.html>

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
