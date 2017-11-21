use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::URI::mailto;

# ABSTRACT: URI::mailto syntax as per RFC6068

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

our $VERSION = '0.003'; # VERSION

use Class::Tiny::Antlers;
use MarpaX::ESLIF;

extends 'MarpaX::ESLIF::URI::_generic';

has '_to'        => (is => 'rwp', default => sub { { origin => [], decoded => [], normalized => [] } });
has '_headers'   => (is => 'rwp', default => sub { { origin => [], decoded => [], normalized => [] } });

#
# All attributes starting with an underscore are the result of parsing
#
__PACKAGE__->_generate_actions(qw/_to _headers/);

#
# Constants
#
my $BNF = do { local $/; <DATA> };
my $GRAMMAR = MarpaX::ESLIF::Grammar->new(__PACKAGE__->eslif, __PACKAGE__->bnf);


sub bnf {
  my ($class) = @_;

  join("\n", $BNF, MarpaX::ESLIF::URI::_generic->bnf)
};


sub grammar {
  my ($class) = @_;

  return $GRAMMAR;
}


sub to {
    my ($self, $type) = @_;

    return $self->_generic_getter('_to', $type)
}


sub headers {
    my ($self, $type) = @_;

    return $self->_generic_getter('_headers', $type)
}

# ------------------------
# Specific grammar actions
# ------------------------
sub __to {
    my ($self, @args) = @_;

    #
    # <to> is also the <path> from generic URI point of view
    #
    $self->_action_path(@args);

    my $concat = $self->__concat(@args);

    while (@args) {
        my $addr = shift @args;
        my $comma = shift @args;
        foreach my $type (qw/origin decoded normalized/) {
            $self->_to->{$type} //= [];
            push(@{$self->_to->{$type}}, $addr->{$type})
        }
    }

    return $concat
}

sub __hfield {
    my ($self, $hfname, $equal, $hfvalue) = @_;

    my $concat = $self->__concat($hfname, $equal, $hfvalue);

    foreach my $type (qw/origin decoded normalized/) {
      $self->_headers->{$type} //= [];
      push(@{$self->_headers->{$type}}, { $hfname->{$type} => $hfvalue->{$type} })
    }

    return $concat
}

sub __hfname {
  my ($self, @args) = @_;

  #
  # <hfname> is case-insensitive. Since it may contain percent encoded characters that
  # are normalized to uppercase, we have to apply uppercase in normalization.
  #
  my $rc = $self->__concat(@args);
  $rc->{normalized} = uc($rc->{normalized});
  $rc
}

# -------------
# Normalization
# -------------


1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::ESLIF::URI::mailto - URI::mailto syntax as per RFC6068

=head1 VERSION

version 0.003

=head1 SUBROUTINES/METHODS

MarpaX::ESLIF::URI::mailto inherits, and eventually overwrites some, methods or MarpaX::ESLIF::URI::_generic.

=head2 $class->bnf

Overwrites parent's bnf implementation. Returns the BNF used to parse the input.

=head2 $class->grammar

Overwrite parent's grammar implementation. Returns the compiled BNF used to parse the input as MarpaX::ESLIF::Grammar singleton.

=head2 $self->to($type)

Returns the addresses as an array reference, that can be empty. C<$type> is either 'decoded' (default value), 'origin' or 'normalized'.

=head2 $self->headers($type)

Returns the headers as an array reference of single hashes, that can be empty. C<$type> is either 'decoded' (default value), 'origin' or 'normalized'.

There is no check of eventual duplicates, and it is reason why at every array indice, there is a hash reference where the key is a mailto header field, and the value is a mailto header value.

=head1 NOTES

The characters C</> and C<?> has been added to mailto syntax

=head1 SEE ALSO

L<RFC6068|https://tools.ietf.org/html/rfc6068>, L<MarpaX::ESLIF::URI::_generic>

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
#
# Reference: https://tools.ietf.org/html/rfc6068#section-2
#
# Note that <URI fragment> should not be used, still it is allowed
#
<mailto URI>              ::= <mailto scheme> ":" <mailto hier part> <URI fragment>             action => _action_string

<mailto scheme>           ::= "mailto":i                                                        action => _action_scheme

<mailto hier part>        ::=
<mailto hier part>        ::=      <hfields>
                            | <to>
                            | <to> <hfields>

<to>                      ::= <addr spec>+ separator => ','                                     action => __to

<mailto query>            ::= <hfield>+ separator => '&'                                        action => _action_query
<hfields>                 ::= "?" <mailto query>

<hfield>                  ::= <hfname> "=" <hfvalue>                                            action => __hfield
<hfname>                  ::= <hfname char>*                                                    action => __hfname
<hfvalue>                 ::= <hfvalue char>*

<addr spec>               ::= <local part> "@" <domain>
<local part>              ::= <dot atom text>
                            | <quoted string>

<dtext no obs any>        ::= <dtext no obs>*
<domain>                  ::= <dot atom text>
                            | "[" <dtext no obs any> "]"
<dtext no obs>            ::= [\x{21}-\x{5A}\x{5E}-\x{7E}] # Printable US-ASCII or characters not including "[", "]", or "\"
<hfname char>             ::= <unreserved>
                            | <hfname some delims>
                            | <hfname pct encoded>
<hfvalue char>            ::= <unreserved>
                            | <hfvalue some delims>
                            | <hfvalue pct encoded>
<hfname some delims>      ::= [!$'()*+,@/?]
<hfvalue some delims>     ::= [!$'()*+,:@/?] # hfname + ":"

#
# From https://tools.ietf.org/html/rfc5322#section-3.2.3
#
<dot atom text unit>      ::= <atext>+
<dot atom text>           ::= <dot atom text unit>+ separator => "."
<atext>                   ::= <ALPHA>
                            | <DIGIT>
                            | [!$'*+\-^_`{|}~]
                            | <atext pct encoded>
#
# A number of characters that can appear in <addr-spec> MUST be
# percent-encoded.  These are the characters that cannot appear in
# a URI according to [STD66] as well as "%" (because it is used for
# percent-encoding) and all the characters in gen-delims except "@"
# and ":" (i.e., "/", "?", "#", "[", and "]").  Of the characters
# in sub-delims, at least the following also have to be percent-
# encoded: "&", ";", and "=".  Care has to be taken both when
# encoding as well as when decoding to make sure these operations
# are applied only once.
#
<atext pct encoded>       ::= "%" '2' '5'                                          action => __pct_encoded # %
                            | "%" '2' 'F':i                                        action => __pct_encoded # /
                            | "%" '3' 'F':i                                        action => __pct_encoded # ?
                            | "%" '2' '3'                                          action => __pct_encoded # #
                            | "%" '5' 'B':i                                        action => __pct_encoded # [
                            | "%" '5' 'D':i                                        action => __pct_encoded # ]
                            | "%" '2' '6'                                          action => __pct_encoded # &
                            | "%" '3' 'B':i                                        action => __pct_encoded # ;
                            | "%" '3' 'D':i                                        action => __pct_encoded # =
                            # %23, %25, %26, %2F are forced to be encoded
                            | "%" '2' [0-247-9A-Ea-e]                              action => __pct_encoded
                            # %3B, %3D, %3F are forced to be encoded
                            | "%" '3' [0-9ACEace]                                  action => __pct_encoded
                            # %5B, %5D are forced to be encoded
                            | "%" '5' [0-9ACE-Face-f]                              action => __pct_encoded
                            # All the rest
                            | "%" [0-146-9A-Fa-f] [0-9A-Fa-f]                      action => __pct_encoded
#
# <hfname> and <hfvalue> are encodings of an [RFC5322] header field
# name and value, respectively.  Percent-encoding is needed for the
# same characters as listed above for <addr-spec>.
#
# Note that [RFC5322] allows all US-ASCII printable characters except ":" in
# optional header field names (Section 3.6.8). Its % encoded form is "%" "3" "A":i
#
<hfname pct encoded>      ::= "%" '2' '5'                                          action => __pct_encoded # %
                            | "%" '2' 'F':i                                        action => __pct_encoded # /
                            | "%" '3' 'F':i                                        action => __pct_encoded # ?
                            | "%" '2' '3'                                          action => __pct_encoded # #
                            | "%" '5' 'B':i                                        action => __pct_encoded # [
                            | "%" '5' 'D':i                                        action => __pct_encoded # ]
                            | "%" '2' '6'                                          action => __pct_encoded # &
                            | "%" '3' 'B':i                                        action => __pct_encoded # ;
                            | "%" '3' 'D':i                                        action => __pct_encoded # =
                            # %23, %25, %26, %2F are forced to be encoded
                            | "%" '2' [0-247-9A-Ea-e]                              action => __pct_encoded
                            # %3B, %3D, %3F are forced to be encoded,  %3A or %3a are excluded (character ":")
                            | "%" '3' [0-9CEce]                                    action => __pct_encoded
                            # %5B, %5D are forced to be encoded
                            | "%" '5' [0-9ACE-Face-f]                              action => __pct_encoded
                            # All the rest
                            | "%" [0-146-9A-Fa-f] [0-9A-Fa-f]                      action => __pct_encoded

<hfvalue pct encoded>     ::= "%" '2' '5'                                          action => __pct_encoded # %
                            | "%" '2' 'F':i                                        action => __pct_encoded # /
                            | "%" '3' 'F':i                                        action => __pct_encoded # ?
                            | "%" '2' '3'                                          action => __pct_encoded # #
                            | "%" '5' 'B':i                                        action => __pct_encoded # [
                            | "%" '5' 'D':i                                        action => __pct_encoded # ]
                            | "%" '2' '6'                                          action => __pct_encoded # &
                            | "%" '3' 'B':i                                        action => __pct_encoded # ;
                            | "%" '3' 'D':i                                        action => __pct_encoded # =
                            # %23, %25, %26, %2F are forced to be encoded
                            | "%" '2' [0-247-9A-Ea-e]                              action => __pct_encoded
                            # %3B, %3D, %3F are forced to be encoded
                            | "%" '3' [0-9ACEace]                                  action => __pct_encoded
                            # %5B, %5D are forced to be encoded
                            | "%" '5' [0-9ACE-Face-f]                              action => __pct_encoded
                            # All the rest
                            | "%" [0-146-9A-Fa-f] [0-9A-Fa-f]                      action => __pct_encoded

<quoted string char>      ::=       <qcontent>
                            | <FWS> <qcontent>
<quoted string interior>  ::= <quoted string char>*
<quoted string>           ::=        <DQUOTE> <quoted string interior>       <DQUOTE>
                            |        <DQUOTE> <quoted string interior>       <DQUOTE> <CFWS>
                            |        <DQUOTE> <quoted string interior> <FWS> <DQUOTE>
                            |        <DQUOTE> <quoted string interior> <FWS> <DQUOTE> <CFWS>
                            | <CFWS> <DQUOTE> <quoted string interior>       <DQUOTE>
                            | <CFWS> <DQUOTE> <quoted string interior>       <DQUOTE> <CFWS>
                            | <CFWS> <DQUOTE> <quoted string interior> <FWS> <DQUOTE>
                            | <CFWS> <DQUOTE> <quoted string interior> <FWS> <DQUOTE> <CFWS>
<qcontent>                ::= <qtext>
                            | <quoted pair>
<qtext>                   ::=   [\x{21}\x{23}-\x{5B}\x{5D}-\x{7E}]  # Characters not including "\" or the quote character

#
# From https://tools.ietf.org/html/rfc5322#section-3.2.2
#
<WSP many>                ::= <WSP>+
<WSP any>                 ::= <WSP>*
<FWS>                     ::=                  <WSP many>
                            | <WSP any> <CRLF> <WSP many>
                            | <obs FWS>
<CFWS comment>            ::=       <comment>
                            | <FWS> <comment>
<CFWS comment many>       ::=       <CFWS comment>+
<CFWS>                    ::= <CFWS comment many>
                            | <CFWS comment many> <FWS>
                            | <FWS>
<comment interior unit>   ::=       <ccontent>
                            | <FWS> <ccontent>
<comment interior units>  ::= <comment interior unit>*
<comment interior>        ::= <comment interior units>
                            | <comment interior units> <FWS>
<comment>                 ::= "(" <comment interior> ")"
<ccontent>                ::= <ctext>
                            | <quoted pair>
# <addr-spec> is a mail address as specified in [RFC5322], but excluding <comment> from [RFC5322]
#                            | <comment>
<ctext>                   ::= [\x{21}-\x{27}\x{2A}-\x{5B}\x{5D}-\x{7E}]
                            | <obs ctext>
<obs ctext>               ::= <obs NO WS CTL>
<obs NO WS CTL>           ::= [\x{01}-\x{08}\x{0B}\x{0C}\x{0E}-\x{1F}\x{7F}]
<obs qp>                  ::= "\\" [\x{00}]
                            | "\\" <obs NO WS CTL>
                            | "\\" <LF>
                            | "\\" <CR>
#
# From https://tools.ietf.org/html/rfc5322#section-3.2.1
#
<quoted pair>             ::= "\\" <VCHAR>
                            | "\\" <WSP>
                            | <obs qp>
#
# From https://tools.ietf.org/html/rfc5234#appendix-B.1
#
<CR>                      ::= [\x{0D}]
<LF>                      ::= [\x{0A}]
<CRLF>                    ::= <CR> <LF>
<DQUOTE>                  ::= [\x{22}]
<VCHAR>                   ::= [\x{21}-\x{7E}]
<WSP>                     ::= <SP>
                            | <HTAB>
<SP>                      ::= [\x{20}]
<HTAB>                    ::= [\x{09}]

#
# From https://tools.ietf.org/html/rfc5322#section-4.2
#
<obs FWS trailer unit>    ::= <CRLF> <WSP many>
<obs FWS trailer>         ::= <obs FWS trailer unit>*
<obs FWS>                 ::= <WSP many> <obs FWS trailer>
#
# Generic syntax will be appended here
#
