package MarpaX::RFC::RFC3987;
use Moo;
use MooX::ClassAttribute;
use Types::Standard -all;
use strict;
use diagnostics;
use Marpa::R2;

# ABSTRACT: Internationalized Resource Identifier (IRI): Generic Syntax - Marpa Parser

# References: RFC 3987       IRI                                     http://tools.ietf.org/html/rfc3987

# AUTHORITY

our $VERSION = '0.001'; # VERSION


our $DATA = do { local $/; <DATA>; };

has value          => (is => 'ro', isa => Str, required => 1 );

class_has grammar  => (is => 'ro', isa => InstanceOf['Marpa::R2::Scanless:G'], default => sub { return Marpa::R2::Scanless::G->new({ source => \$DATA }) } );

class_has bnf      => (is => 'ro', isa => Str,                                 default => $DATA );

has scheme         => (is => 'ro', isa => Str|Undef,     default => undef,      writer => '_set_scheme');
has iauthority     => (is => 'ro', isa => Str|Undef,     default => undef,      writer => '_set_iauthority');
has ipath          => (is => 'ro', isa => Str,           default => '',         writer => '_set_ipath');        # There is always a path in an IRI
has iquery         => (is => 'ro', isa => Str|Undef,     default => undef,      writer => '_set_iquery');
has ifragment      => (is => 'ro', isa => Str|Undef,     default => undef,      writer => '_set_ifragment');

has ihier_part     => (is => 'ro', isa => Str|Undef,     default => undef,      writer => '_set_ihier_part');
has iuserinfo      => (is => 'ro', isa => Str|Undef,     default => undef,      writer => '_set_iuserinfo');
has ihost          => (is => 'ro', isa => Str|Undef,     default => undef,      writer => '_set_ihost');
has port           => (is => 'ro', isa => Str|Undef,     default => undef,      writer => '_set_port');
has irelative_part => (is => 'ro', isa => Str|Undef,     default => undef,      writer => '_set_irelative_part');
has ip_literal     => (is => 'ro', isa => Str|Undef,     default => undef,      writer => '_set_ip_literal');
has zoneid         => (is => 'ro', isa => Str|Undef,     default => undef,      writer => '_set_zoneid' );
has ipv4address    => (is => 'ro', isa => Str|Undef,     default => undef,      writer => '_set_ipv4address');
has ireg_name      => (is => 'ro', isa => Str|Undef,     default => undef,      writer => '_set_ireg_name');

sub BUILDARGS {
  my ($class, @args) = @_;

  unshift(@args, 'value') if (@args % 2 == 1);

  return { @args };
};

sub BUILD {
  my ($self) = @_;
  #
  # This hack just to avoid recursivity: we do not want Marpa to
  # call another new() but operate on our instance immediately
  #
  local $MarpaX::RFC::RFC3987::SELF = $self;
  $self->grammar->parse(\$self->value, { ranking_method => 'high_rule_only' });

  return;
}

sub is_absolute {
  my ($self) = @_;
  #
  ## No need to reparse. An absolute IRI is when scheme and ihier_part are defined
  #
  return Str->check($self->scheme) && Str->check($self->ihier_part);
}

#
# Grammar rules
#
sub _marpa_concat         { shift;                                         return join('', @_); }
sub _marpa_scheme         { shift; my $self = $MarpaX::RFC::RFC3987::SELF; return $self->_set_scheme         ($self->_marpa_concat(@_)); }
sub _marpa_iauthority     { shift; my $self = $MarpaX::RFC::RFC3987::SELF; return $self->_set_iauthority     ($self->_marpa_concat(@_)); }
sub _marpa_ipath          { shift; my $self = $MarpaX::RFC::RFC3987::SELF; return $self->_set_ipath          ($self->_marpa_concat(@_)); }
sub _marpa_iquery         { shift; my $self = $MarpaX::RFC::RFC3987::SELF; return $self->_set_iquery         ($self->_marpa_concat(@_)); }
sub _marpa_ifragment      { shift; my $self = $MarpaX::RFC::RFC3987::SELF; return $self->_set_ifragment      ($self->_marpa_concat(@_)); }

sub _marpa_ihier_part     { shift; my $self = $MarpaX::RFC::RFC3987::SELF; return $self->_set_ihier_part     ($self->_marpa_concat(@_)); }
sub _marpa_iuserinfo      { shift; my $self = $MarpaX::RFC::RFC3987::SELF; return $self->_set_iuserinfo      ($self->_marpa_concat(@_)); }
sub _marpa_ihost          { shift; my $self = $MarpaX::RFC::RFC3987::SELF; return $self->_set_ihost          ($self->_marpa_concat(@_)); }
sub _marpa_port           { shift; my $self = $MarpaX::RFC::RFC3987::SELF; return $self->_set_port           ($self->_marpa_concat(@_)); }
sub _marpa_irelative_part { shift; my $self = $MarpaX::RFC::RFC3987::SELF; return $self->_set_irelative_part ($self->_marpa_concat(@_)); }
sub _marpa_ip_literal     { shift; my $self = $MarpaX::RFC::RFC3987::SELF; return $self->_set_ip_literal     ($self->_marpa_concat(@_)); }
sub _marpa_zoneid         { shift; my $self = $MarpaX::RFC::RFC3987::SELF; return $self->_set_zoneid         ($self->_marpa_concat(@_)); }
sub _marpa_ipv4address    { shift; my $self = $MarpaX::RFC::RFC3987::SELF; return $self->_set_ipv4address    ($self->_marpa_concat(@_)); }
sub _marpa_ireg_name      { shift; my $self = $MarpaX::RFC::RFC3987::SELF; return $self->_set_ireg_name      ($self->_marpa_concat(@_)); }

1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::RFC::RFC3987 - Internationalized Resource Identifier (IRI): Generic Syntax - Marpa Parser

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    use MarpaX::RFC::RFC3987;
    use Try::Tiny;
    use Data::Dumper;

    print Dumper(MarpaX::RFC::RFC3987->new('http://www.perl.org'));

    try {
      print STDERR "\nThe following is an expected failure:\n";
      MarpaX::RFC::RFC3987->new('http://invalid##');
    } catch {
      print STDERR "$_\n";
      return;
    }

=head1 DESCRIPTION

This module parses an IRI reference as per RFC3987. It is intended as a data validation module using a strict grammar with good error reporting.

=head1 IRI DESCRIPTION

Quoted from the URI RFC 3986, with which an IRI is sharing the same principle, here is the overall structure of an URI that will help understand the meaning of the methods thereafter:

         foo://example.com:8042/over/there?name=ferret#nose
         \_/   \______________/\_________/ \_________/ \__/
          |           |            |            |        |
       scheme     authority       path        query   fragment
          |   _____________________|__
         / \ /                        \
         urn:example:animal:ferret:nose

The grammar is parsing both absolute IRI and relative IRI, the corresponding start rule being named a IRI reference.

An absolute IRI has the following structure:

         IRI = scheme ":" ihier-part [ "?" iquery ] [ "#" ifragment ]

while a relative IRI is split into:

         irelative-ref  = irelative-part [ "?" iquery ] [ "#" ifragment ]

Back to the overall structure, the authority is:

         iauthority   = [ iuserinfo "@" ] ihost [ ":" port ]

where the host can be an IP-literal with Zone information, and IPV4 address or a registered name:

         host = IP-literal / IPv4address / ireg-name

The Zone Identifier is an extension to original URI RFC3986, is defined in RFC6874, and has been applied into the IRI grammar (the current IRI spec just says it does not support Zone Identifiers); it is an IPv6addrz:

         IP-literal = "[" ( IPv6address / IPv6addrz / IPvFuture  ) "]"

         ZoneID = 1*( iunreserved / pct-encoded )

         IPv6addrz = IPv6address "%25" ZoneID

=head1 CLASS METHODS

=head2 MarpaX::RFC::RFC3987->new(@options --> InstanceOf['MarpaX::RFC::RFC3987'])

Instantiate a new object. Usage is either C<MarpaX::RFC::RFC3987-E<gt>new(value =E<gt> $iri)> or C<MarpaX::RFC::RFC3987-E<gt>new($iri)>. This method will croak if the the C<$iri> parameter cannot coerce to a string nor is a valid IRI. The variable C<$self> is used below to refer to this object instance.

=head2 MarpaX::RFC::RFC3987->grammar( --> InstanceOf['Marpa::R2::Scanless::G'])

A Marpa::R2::Scanless::G instance, hosting the computed grammar. This is a class variable, i.e. works also with C<$self>.

=head2 MarpaX::RFC::RFC3987->bnf( --> Str)

The BNF grammar used to parse an IRI. This is a class variable, i.e. works also with C<$self>.

=head1 OBJECT METHODS

=head2 $self->value( --> Str)

The variable given in input to C<new()>.

=head2 $self->scheme( --> Str|Undef)

The IRI scheme. Can be undefined.

=head2 $self->iauthority( --> Str|Undef)

The IRI authority. Can be undefined.

=head2 $self->ipath( --> Str)

The IRI path. Note that an IRI always have a path, although it can be empty.

=head2 $self->iquery( --> Str|Undef)

The IRI query. Can be undefined.

=head2 $self->ifragment( --> Str|Undef)

The IRI fragment. Can be undefined.

=head2 $self->ihier_part( --> Str|Undef)

The IRI hier part. Can be undefined.

=head2 $self->iuserinfo( --> Str|Undef)

The IRI userinfo. Can be undefined.

=head2 $self->ihost( --> Str|Undef)

The IRI host. Can be undefined.

=head2 $self->port( --> Str|Undef)

The IRI port. Can be undefined.

=head2 $self->irelative_part( --> Str|Undef)

The IRI relative part. Can be undefined.

=head2 $self->ip_literal( --> Str|Undef)

The IRI IP literal. Can be undefined.

=head2 $self->zoneid( --> Str|Undef)

The IRI IP's zone id. Can be undefined.

=head2 $self->ipv4address( --> Str|Undef)

The IRI IP Version 4 address. Can be undefined.

=head2 $self->ireg_name( --> Str|Undef)

The IRI registered name. Can be undefined.

=head2 $self->is_absolute( --> Bool)

Returns a true value if the IRI is absolute, false otherwise.

=head1 SEE ALSO

L<Marpa::R2>

L<IRI>

L<Uniform Resource Identifier (URI): Generic Syntax|http://tools.ietf.org/html/rfc3986>

L<Internationalized Resource Identifier (IRI): Generic Syntax|http://tools.ietf.org/html/rfc3987>

L<Formats for IPv6 Scope Zone Identifiers in Literal Address Formats|https://tools.ietf.org/html/draft-fenner-literal-zone-02>

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://rt.cpan.org/Public/Dist/Display.html?Name=MarpaX-RFC-RFC3987>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/jddurand/marpax-rfc-rfc3987>

  git clone git://github.com/jddurand/marpax-rfc-rfc3987.git

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
inaccessible is ok by default
:default ::= action => MarpaX::RFC::RFC3987::_marpa_concat
:start ::= <IRI reference>

<IRI>         ::= <scheme> ':' <ihier part> '?' <iquery> '#' <ifragment>
                | <scheme> ':' <ihier part> '?' <iquery>
                | <scheme> ':' <ihier part>              '#' <ifragment>
                | <scheme> ':' <ihier part>

<ihier part>     ::= '//' <iauthority> <ipath abempty>                    action => MarpaX::RFC::RFC3987::_marpa_ihier_part
                   | <ipath absolute>                                     action => MarpaX::RFC::RFC3987::_marpa_ihier_part
                   | <ipath rootless>                                     action => MarpaX::RFC::RFC3987::_marpa_ihier_part
                   | <ipath empty>                                        action => MarpaX::RFC::RFC3987::_marpa_ihier_part

<IRI reference> ::= <IRI>
                  | <irelative ref>

<absolute IRI>  ::= <scheme> ':' <ihier part> '?' <iquery>
                  | <scheme> ':' <ihier part>

<irelative ref>  ::= <irelative part> '?' <iquery> '#' <ifragment>
                   | <irelative part> '?' <iquery>
                   | <irelative part>              '#' <ifragment>
                   | <irelative part>

<irelative part> ::= '//' <iauthority> <ipath abempty>                    action => MarpaX::RFC::RFC3987::_marpa_irelative_part
                  | <ipath absolute>                                      action => MarpaX::RFC::RFC3987::_marpa_irelative_part
                  | <ipath noscheme>                                      action => MarpaX::RFC::RFC3987::_marpa_irelative_part
                  | <ipath empty>                                         action => MarpaX::RFC::RFC3987::_marpa_irelative_part

<scheme trailer unit> ::= ALPHA | DIGIT | [+-.]
<scheme header>       ::= ALPHA
<scheme trailer>      ::= <scheme trailer unit>*
<scheme>              ::= <scheme header> <scheme trailer>                 action => MarpaX::RFC::RFC3987::_marpa_scheme

<iauthority>     ::= <iuserinfo> '@' <ihost> ':' <port>                    action => MarpaX::RFC::RFC3987::_marpa_iauthority
                   | <iuserinfo> '@' <ihost>                               action => MarpaX::RFC::RFC3987::_marpa_iauthority
                   |                 <ihost> ':' <port>                    action => MarpaX::RFC::RFC3987::_marpa_iauthority
                   |                 <ihost>                               action => MarpaX::RFC::RFC3987::_marpa_iauthority

<iuserinfo unit> ::= <iunreserved> | <pct encoded> | <sub delims> | ':'
<iuserinfo>      ::= <iuserinfo unit>*                                     action => MarpaX::RFC::RFC3987::_marpa_iuserinfo

#
# As per the RFC:
# he syntax rule for host is ambiguous because it does not completely
# distinguish between an IPv4address and a reg-name.  In order to
# disambiguate the syntax, we apply the "first-match-wins" algorithm:
# If host matches the rule for IPv4address, then it should be
# considered an IPv4 address literal and not a reg-name.

<ihost>          ::= <IP literal>                                        action => MarpaX::RFC::RFC3987::_marpa_ihost
                   | <IPv4address>                            rank => 1  action => MarpaX::RFC::RFC3987::_marpa_ihost
                   | <ireg name>                                         action => MarpaX::RFC::RFC3987::_marpa_ihost

<port>          ::= DIGIT*                                              action => MarpaX::RFC::RFC3987::_marpa_port

<IP literal>    ::= '[' IPv6address ']'                                 action => MarpaX::RFC::RFC3987::_marpa_ip_literal
                  | '[' IPv6addrz   ']'                                 action => MarpaX::RFC::RFC3987::_marpa_ip_literal
                  | '[' IPvFuture   ']'                                 action => MarpaX::RFC::RFC3987::_marpa_ip_literal

<ZoneID unit>   ::= <iunreserved> | <pct encoded>
<ZoneID>        ::= <ZoneID unit>+                                      action => MarpaX::RFC::RFC3987::_marpa_zoneid

<IPv6addrz>     ::= <IPv6address> '%25' <ZoneID>

<hexdigit many>          ::= HEXDIG+
<IPvFuture trailer unit> ::= <iunreserved> | <sub delims> | ':'
<IPvFuture trailer>      ::= <IPvFuture trailer unit>+
<IPvFuture>              ::= 'v' <hexdigit many> '.' <IPvFuture trailer>

<1 h16 colon>   ::= <h16> ':'
<2 h16 colon>   ::= <1 h16 colon> <1 h16 colon>
<3 h16 colon>   ::= <2 h16 colon> <1 h16 colon>
<4 h16 colon>   ::= <3 h16 colon> <1 h16 colon>
<5 h16 colon>   ::= <4 h16 colon> <1 h16 colon>
<6 h16 colon>   ::= <5 h16 colon> <1 h16 colon>

<at most 1 h16 colon>  ::=                                              rank => 0
<at most 1 h16 colon>  ::=         <1 h16 colon>                        rank => 1
<at most 2 h16 colon>  ::= <at most 1 h16 colon>                        rank => 0
                         | <at most 1 h16 colon> <1 h16 colon>          rank => 1
<at most 3 h16 colon>  ::= <at most 2 h16 colon>                        rank => 0
                         | <at most 2 h16 colon> <1 h16 colon>          rank => 1
<at most 4 h16 colon>  ::= <at most 3 h16 colon>                        rank => 0
                         | <at most 3 h16 colon> <1 h16 colon>          rank => 1
<at most 5 h16 colon>  ::= <at most 4 h16 colon>                        rank => 0
                         | <at most 4 h16 colon> <1 h16 colon>          rank => 1
<at most 6 h16 colon>  ::= <at most 5 h16 colon>                        rank => 0
                         | <at most 5 h16 colon> <1 h16 colon>          rank => 1

<IPv6address>   ::=                                  <6 h16 colon> <ls32>
                  |                             '::' <5 h16 colon> <ls32>
                  |                       <h16> '::' <4 h16 colon> <ls32>
                  |                             '::' <4 h16 colon> <ls32>
                  | <at most 1 h16 colon> <h16> '::' <3 h16 colon> <ls32>
                  |                             '::' <3 h16 colon> <ls32>
                  | <at most 2 h16 colon> <h16> '::' <2 h16 colon> <ls32>
                  |                             '::' <2 h16 colon> <ls32>
                  | <at most 3 h16 colon> <h16> '::' <1 h16 colon> <ls32>
                  |                             '::' <1 h16 colon> <ls32>
                  | <at most 4 h16 colon> <h16> '::'               <ls32>
                  |                             '::'               <ls32>
                  | <at most 5 h16 colon> <h16> '::'               <h16>
                  |                             '::'               <h16>
                  | <at most 6 h16 colon> <h16> '::'
                  |                             '::'

<h16>            ::= HEXDIG
                   | HEXDIG HEXDIG
                   | HEXDIG HEXDIG HEXDIG
                   | HEXDIG HEXDIG HEXDIG HEXDIG

<ls32>          ::= <h16> ':' <h16>
                  | <IPv4address>

IPv4address     ::= <dec octet> '.' <dec octet> '.' <dec octet> '.' <dec octet> action => MarpaX::RFC::RFC3987::_marpa_ipv4address

<dec octet>     ::=                      DIGIT # 0-9
                  |      [\x{31}-\x{39}] DIGIT # 10-99
                  | '1'            DIGIT DIGIT # 100-199
                  | '2'  [\x{30}-\x{34}] DIGIT # 200-249
                  | '25' [\x{30}-\x{35}]       # 250-255

<ireg name unit> ::= <iunreserved> | <pct encoded> | <sub delims>
<ireg name>      ::= <ireg name unit>*                                 action => MarpaX::RFC::RFC3987::_marpa_ireg_name

<ipath>          ::= <ipath abempty>    # begins with "/" or is empty
                   | <ipath absolute>   # begins with "/" but not "//"
                   | <ipath noscheme>   # begins with a non-colon segment
                   | <ipath rootless>   # begins with a segment
                   | <ipath empty>      # zero character

<isegment unit> ::= '/' <isegment>
<isegments>     ::= <isegment unit>*
<ipath abempty>  ::= <isegments>                                       action => MarpaX::RFC::RFC3987::_marpa_ipath

<ipath absolute> ::= '/' <isegment nz> <isegments>                      action => MarpaX::RFC::RFC3987::_marpa_ipath
                   | '/'                                                action => MarpaX::RFC::RFC3987::_marpa_ipath
<ipath noscheme> ::= <isegment nz nc> <isegments>                       action => MarpaX::RFC::RFC3987::_marpa_ipath
<ipath rootless> ::= <isegment nz> <isegments>                          action => MarpaX::RFC::RFC3987::_marpa_ipath
<ipath empty>    ::=                                                    action => MarpaX::RFC::RFC3987::_marpa_ipath

#
# All possible segments are here
#
<isegment>       ::= <ipchar>*
<isegment nz>    ::= <ipchar>+
<isegment nz nc unit> ::= <iunreserved> | <pct encoded> | <sub delims> | '@'
<isegment nz nc> ::= <isegment nz nc unit>+                            # non-zero-length segment without any colon ":"

<ipchar>         ::= <iunreserved> | <pct encoded> | <sub delims> | [:@]

<iquery unit>    ::= <ipchar> | <iprivate> | [/?]
<iquery>         ::= <iquery unit>*                                    action => MarpaX::RFC::RFC3987::_marpa_iquery

<ifragment unit> ::= <ipchar> | [/?]
<ifragment>      ::= <ifragment unit>*                                 action => MarpaX::RFC::RFC3987::_marpa_ifragment

<pct encoded>    ::= '%' HEXDIG HEXDIG

<iunreserved>    ::= ALPHA | DIGIT | [-._~] | <ucschar>

<ucschar>        ::= [\x{A0}-\x{D7FF}\x{F900}-\x{FDCF}\x{FDF0}-\x{FFEF}\x{10000}-\x{1FFFD}\x{20000}-\x{2FFFD}\x{30000}-\x{3FFFD}\x{40000}-\x{4FFFD}\x{50000}-\x{5FFFD}\x{60000}-\x{6FFFD}\x{70000}-\x{7FFFD}\x{80000}-\x{8FFFD}\x{90000}-\x{9FFFD}\x{A0000}-\x{AFFFD}\x{B0000}-\x{BFFFD}\x{C0000}-\x{CFFFD}\x{D0000}-\x{DFFFD}\x{E1000}-\x{EFFFD}]

<iprivate>      ::= [\x{E000}-\x{F8FF}\x{F0000}-\x{FFFFD}\x{100000}-\x{10FFFD}]

<sub delims>    ::= [!$&'()*+,;=]

#
# These rules are informative: they are not productive
#
<reserved>      ::= <gen delims> | <sub delims>
<gen delims>    ::= [:/?#\[\]@]
#
# No perl meta-character, just to be sure
#
ALPHA         ::= [A-Za-z]
DIGIT         ::= [0-9]
HEXDIG        ::= [0-9A-Fa-f]
