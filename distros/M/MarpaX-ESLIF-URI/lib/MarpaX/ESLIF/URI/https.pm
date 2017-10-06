use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::URI::https;

# ABSTRACT: URI::https syntax as per RFC7230

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

our $VERSION = '0.002'; # VERSION

use Carp qw/croak/;
use Class::Tiny::Antlers;
use Class::Method::Modifiers qw/around/;
use MarpaX::ESLIF;
use Net::servent qw/getservbyname/;

extends 'MarpaX::ESLIF::URI::_generic';

#
# Constants
#
my $BNF = do { local $/; <DATA> };
my $GRAMMAR = MarpaX::ESLIF::Grammar->new(__PACKAGE__->eslif, __PACKAGE__->bnf);
my $DEFAULT_PORT;
BEGIN {
    my $s = getservbyname('https');
    $DEFAULT_PORT = $s->port if $s;
    $DEFAULT_PORT //= 443
}


sub bnf {
  my ($class) = @_;

  join("\n", $BNF, MarpaX::ESLIF::URI::_generic->bnf)
};


sub grammar {
  my ($class) = @_;

  return $GRAMMAR;
}

# -------------
# Normalization
# -------------
around _set__authority => sub {
    my ($orig, $self, $value) = @_;
    #
    # If the port is equal to the default port for a scheme, the normal
    # form is to omit the port subcomponent
    #
    my $port = $self->port;
    if (! defined($port) || ($port eq '') || ($port == $DEFAULT_PORT)) {
        my $new_port = $self->_port;
        $new_port->{normalized} = undef;
        $self->_set__port($new_port);
        $value->{normalized} =~ s/:[^:]*//
    }
    $self->$orig($value)
};

around _set__path => sub {
    my ($orig, $self, $value) = @_;
    #
    # Normalized path is '/' instead of empty, as if
    # it was a <path absolute>
    #
    if (! length($value->{normalized})) {
        $value->{normalized} = '/'
    }
    $self->$orig($value)
};


1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::ESLIF::URI::https - URI::https syntax as per RFC7230

=head1 VERSION

version 0.002

=head1 SUBROUTINES/METHODS

MarpaX::ESLIF::URI::https inherits, and eventually overwrites some, methods or MarpaX::ESLIF::URI::_generic.

=head2 $class->bnf

Overwrites parent's bnf implementation. Returns the BNF used to parse the input.

=head2 $class->grammar

Overwrite parent's grammar implementation. Returns the compiled BNF used to parse the input as MarpaX::ESLIF::Grammar singleton.

=head1 NOTES

The default https port is the one configured on caller's system, or 443.

=head1 SEE ALSO

L<RFC7230|https://tools.ietf.org/html/rfc7230>, L<MarpaX::ESLIF::URI::_generic>

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
#
# Reference: https://tools.ietf.org/html/rfc7230#section-2.7.1
#
<https URI>             ::= <https scheme> ":" <https hier part> <URI query> <URI fragment> action => _action_string

<https scheme>          ::= "https":i                                                       action => _action_scheme
#
# Empty host is invalid
#
<https hier part> ::= "//" <https authority> <path abempty>

<https authority>       ::= <https authority value>                                         action => _action_authority
<https authority value> ::= <authority userinfo> <https host> <authority port>
<https host>            ::= <IP literal>            rank =>  0                              action => _action_host
                         | <IPv4address>           rank => -1                               action => _action_host
                         | <https reg name>         rank => -2                              action => _action_host

<https reg name>        ::= <reg name unit>+

#
# Generic syntax will be appended here
#
