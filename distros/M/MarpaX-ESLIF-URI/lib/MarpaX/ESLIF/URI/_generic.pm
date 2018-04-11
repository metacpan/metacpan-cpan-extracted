use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::URI::_generic;

# ABSTRACT: URI Generic syntax as per RFC3986/RFC6874

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY

our $VERSION = '0.005'; # VERSION

use Carp qw/croak/;
use Class::Method::Modifiers qw/fresh around/;
use Class::Tiny::Antlers;
use Log::Any qw/$log/;
use MarpaX::ESLIF;
use MarpaX::ESLIF::URI;   # Because of resolve()
use MarpaX::ESLIF::URI::_generic::RecognizerInterface;
use MarpaX::ESLIF::URI::_generic::ValueInterface;
use Safe::Isa qw/$_isa/;
use overload '""' => 'string', 'eq' => 'eq', fallback => 1;

has '_origin'    => ( is => 'ro' );
has '_string'    => ( is => 'rwp' );
has '_scheme'    => ( is => 'rwp' );
has '_authority' => ( is => 'rwp' );
has '_userinfo'  => ( is => 'rwp' );
has '_host'      => ( is => 'rwp' );
has '_ip'        => ( is => 'rwp' );
has '_ipv4'      => ( is => 'rwp' );
has '_ipv6'      => ( is => 'rwp' );
has '_ipvx'      => ( is => 'rwp' );
has '_zone'      => ( is => 'rwp' );
has '_port'      => ( is => 'rwp' );
has '_path'      => ( is => 'rwp', default => sub { { origin => '', decoded => '', normalized => '' } }); # Default is empty path ./..
has '_segments'  => ( is => 'rwp', default => sub { { origin => [], decoded => [], normalized => [] } });  # ../. i.e. no component
has '_query'     => ( is => 'rwp' );
has '_fragment'  => ( is => 'rwp' );

#
# All attributes starting with an underscore are the result of parsing
#
__PACKAGE__->_generate_actions(qw/_string _scheme _authority _userinfo _host _ip _ipv4 _ipv6 _ipvx _zone _port _path _segments _query _fragment/);

#
# Constants
#
my $BNF = do { local $/; <DATA> };
my $ESLIF = MarpaX::ESLIF->new($log);
my $GRAMMAR = MarpaX::ESLIF::Grammar->new(__PACKAGE__->eslif, __PACKAGE__->bnf);


#
# BUILDARGS is completely internal
#


sub BUILDARGS {
  my ($class, @args) = @_;

  croak "Usage: $class->new(\$uri)" unless $#args == 0;

  return { _origin => $args[0] }
}

#
# BUILD is completely internal
#


sub BUILD {
    my ($self) = @_;

    my $_origin = $self->_origin;
    $_origin = "$_origin";
    if (length($_origin)) {
        my $recognizerInterface = MarpaX::ESLIF::URI::_generic::RecognizerInterface->new($_origin);
        my $valueInterface = MarpaX::ESLIF::URI::_generic::ValueInterface->new($self);

        $self->grammar->parse($recognizerInterface, $valueInterface) || croak 'Parse failure'
    }
}


sub bnf {
  my ($class) = @_;

  return $BNF
}


sub eslif {
  my ($class) = @_;

  return $ESLIF
}


sub grammar {
  my ($class) = @_;

  return $GRAMMAR;
}

#
# Class::Tiny generated methods
#


sub string {
    my ($self, $type) = @_;

    return $self->_generic_getter('_string', $type)
}


sub scheme {
    my ($self, $type) = @_;
    #
    # scheme never have a percent encoded character
    #
    return $self->_generic_getter('_scheme', $type)
}


sub authority {
    my ($self, $type) = @_;

    return $self->_generic_getter('_authority', $type)
}


sub userinfo {
    my ($self, $type) = @_;

    return $self->_generic_getter('_userinfo', $type)
}


sub host {
    my ($self, $type) = @_;

    return $self->_generic_getter('_host', $type)
}


sub hostname {
    my ($self, $type) = @_;

    my $hostname = $self->_generic_getter('_host', $type);
    $hostname =~ s/^\[(.*)\]$/$1/ if defined($hostname);
    return $hostname
}


sub ip {
    my ($self, $type) = @_;

    return $self->_generic_getter('_ip', $type)
}


sub ipv4 {
    my ($self, $type) = @_;

    return $self->_generic_getter('_ipv4', $type)
}


sub ipv6 {
    my ($self, $type) = @_;

    return $self->_generic_getter('_ipv6', $type)
}


sub ipvx {
    my ($self, $type) = @_;

    return $self->_generic_getter('_ipvx', $type)
}


sub zone {
    my ($self, $type) = @_;

    return $self->_generic_getter('_zone', $type)
}


sub port {
    my ($self) = @_;

    return $self->_generic_getter('_port')
}


sub path {
    my ($self, $type) = @_;

    return $self->_generic_getter('_path', $type)
}


sub segments {
    my ($self, $type) = @_;

    return $self->_generic_getter('_segments', $type)
}


sub query {
    my ($self, $type) = @_;

    return $self->_generic_getter('_query', $type)
}


sub fragment {
    my ($self, $type) = @_;

    return $self->_generic_getter('_fragment', $type)
}


sub is_abs {
  my ($self) = @_;

  return defined($self->scheme) && ! defined($self->fragment)
}


sub base {
  my ($self) = @_;

  if ($self->is_abs) {
    return $self
  } else {
    #
    # We need the scheme
    #
    croak "Cannot derive a base URI without a scheme" unless defined $self->_scheme;
    my $origin = $self->string('origin');
    my $fragment = $self->fragment('origin');
    my $quote_fragment = quotemeta($fragment);
    $origin =~ s/#$quote_fragment$//;
    return ref($self)->new($origin)
  }
}


sub normalized {
  my ($self) = @_;

  return $self->string('normalized')
}


sub decoded {
  my ($self) = @_;

  return $self->string('decoded')
}


sub resolve {
    my ($self, $base, $strict) = @_;

    $base //= $self->base;
    $strict //= 1;

    croak "$base must be absolute" unless $base->is_abs;

    #
    # 5.2.2.  Transform References
    #
    my %R;
    $R{scheme}    = $self->scheme('origin');
    $R{authority} = $self->authority('origin');
    $R{path}      = $self->path('origin');
    $R{query}     = $self->query('origin');
    $R{fragment}  = $self->fragment('origin');

    my %Base;
    $Base{scheme}    = $base->scheme('origin');
    $Base{authority} = $base->authority('origin');
    $Base{path}      = $base->path('origin');
    $Base{query}     = $base->query('origin');
    $Base{fragment}  = $base->fragment('origin');

    if ((! $strict) && (($R{scheme} // '') == $Base{scheme})) {
        $R{scheme} = undef
    }

    my %T;
    if (defined($R{scheme})) {
        $T{scheme}    = $R{scheme};
        $T{authority} = $R{authority};
        $T{path}      = __PACKAGE__->remove_dot_segments($R{path});
        $T{query}     = $R{query};
    } else {
        if (defined($R{authority})) {
            $T{authority} = $R{authority};
            $T{path}      = __PACKAGE__->remove_dot_segments($R{path});
            $T{query}     = $R{query};
        } else {
            if (! length($R{path})) {
                $T{path} = $Base{path};
                if (defined(R{query})) {
                    $T{query} = $R{query};
                } else {
                    $T{query} = $Base{query};
                }
            } else {
                if (substr($R{path}, 0, 1) eq '/') {
                    $T{path} = __PACKAGE__->remove_dot_segments($R{path});
                } else {
                    $T{path} = $self->_merge_paths($base);
                    $T{path} = __PACKAGE__->remove_dot_segments($T{path});
                }
                $T{query} = $R{query};
            }
            $T{authority} = $Base{authority};
        }
        $T{scheme} = $Base{scheme};
    }

    $T{fragment} = $R{fragment};

    #
    # 5.3.  Component Recomposition
    #
    my $str;

    my $scheme = $T{scheme};
    $str .= "$scheme:" if defined($scheme);

    my $authority = $T{authority};
    $str .= "//$authority" if defined($authority);

    $str .= $T{path};  # Always defined as per the algorithm

    my $query = $T{query};
    $str .= "?$query" if defined($query);

    my $fragment = $T{fragment};
    $str .= "#$fragment" if defined($fragment);

    return MarpaX::ESLIF::URI->new($str)
}


sub eq {
    my ($self, $other) = @_;

    eval {
        $other = MarpaX::ESLIF::URI->new($other) unless $other->$_isa(__PACKAGE__);
        #
        # Since we already do full normalization when valuating the parse tree, we use it
        #
        $self->string('normalized') eq $other->string('normalized')
    }
}


sub clone {
    my ($self) = @_;

    return ref($self)->new($self->_origin)
}


sub as_string {
    goto &string
}


sub remove_dot_segments {
    my ($class, $path) = @_;

    # 1.  The input buffer is initialized with the now-appended path
    #     components and the output buffer is initialized to the empty
    #     string.
    my $input = $path;
    my $output = '';

    # printf "%s %-20s %-20s\n", 1, $output, $input;
    # 2.  While the input buffer is not empty, loop as follows:
    while (length($input)) {

        # A.  If the input buffer begins with a prefix of "../" or "./",
        #     then remove that prefix from the input buffer; otherwise,
        if (substr($input, 0, 3) eq '../') {
            substr($input, 0, 3, '');
            # printf "%s %-20s %-20s\n", 'A', $output, $input;
            next;
        } elsif (substr($input, 0, 2) eq './') {
            substr($input, 0, 2, '');
            # printf "%s %-20s %-20s\n", 'A', $output, $input;
            next;
        }

        # B.  if the input buffer begins with a prefix of "/./" or "/.",
        #     where "." is a complete path segment, then replace that
        #     prefix with "/" in the input buffer; otherwise,
        if (substr($input, 0, 3) eq '/./') {
            substr($input, 0, 3, '/');
            # printf "%s %-20s %-20s\n", 'B', $output, $input;
            next;
        } elsif ($input =~ /^\/\.(?:\/|\z)/) {
            substr($input, 0, 2, '/');
            # printf "%s %-20s %-20s\n", 'B', $output, $input;
            next;
        }

        # C.  if the input buffer begins with a prefix of "/../" or "/..",
        #     where ".." is a complete path segment, then replace that
        #     prefix with "/" in the input buffer and remove the last
        #     segment and its preceding "/" (if any) from the output
        #     buffer; otherwise,
        if (substr($input, 0, 4) eq '/../') {
            substr($input, 0, 4, '/');
            $output =~ s/\/?[^\/]*\z//;
            # printf "%s %-20s %-20s\n", 'C', $output, $input;
            next;
        } elsif ($input =~ /^\/\.\.(?:\/|\z)/) {
            substr($input, 0, 3, '/');
            $output =~ s/\/?[^\/]*\z//;
            # printf "%s %-20s %-20s\n", 'C', $output, $input;
            next;
        }

        # D.  if the input buffer consists only of "." or "..", then remove
        #     that from the input buffer; otherwise,
        if (($input eq '.') || ($input eq '..')) {
            $input = '';
            # printf "%s %-20s %-20s\n", 'D', $output, $input;
            next;
        }

        # E.  move the first path segment in the input buffer to the end of
        #     the output buffer, including the initial "/" character (if
        #     any and any subsequent characters up to, but not including,
        #     the next "/" character or the end of the input buffer.
        $input =~ s/^(\/?[^\/]*)//;
        $output .= $1;
        # printf "%s %-20s %-20s\n", 'E', $output, $input;
    }

    # 3.  Finally, the output buffer is returned as the result of
    #     remove_dot_segments.
    return $output
}

# ----------------
# Internal helpers
# ----------------

sub _generic_getter {
    my ($self, $_what, $type) = @_;

    $type //= 'decoded';
    my $value = $self->$_what;

    return unless defined($value);
    return $value->{$type}
}

sub _generate_actions {
  my ($class, @attributes) = @_;
  #
  # All the attributes have an associate explicit action called _action${attribute}
  #
  foreach my $attribute (@attributes) {
    my $method = "_action$attribute";
    next if $class->can($method);
    my $stub = eval "sub { my (\$self, \@args) = \@_; \$self->_set_$attribute(\$self->__concat(\@args)) }" || croak "Failed to create action stub for attribute $attribute, $@"; ## no critic
    fresh $method => $stub;
  }
}

sub _merge_paths {
    #
    # In theory, this method should never be called with type != 'origin'
    #
    my ($self, $base, $type) = @_;
    $type //= 'origin';

    # If the base URI has a defined authority component and an empty
    # path, then return a string consisting of "/" concatenated with the
    # reference's path; otherwise,
    return '/' . $self->path($type) if (defined($base->authority($type)) && ! length($base->path($type)));

    # return a string consisting of the reference's path component
    # appended to all but the last segment of the base URI's path (i.e.,
    # excluding any characters after the right-most "/" in the base URI
    # path, or excluding the entire base URI path if it does not contain
    # any "/" characters).}
    my $base_path = $base->path($type);
    my $rindex = rindex($base_path, '/');
    my $new_path;
    if ($rindex >= 0) {
        if ($rindex < (length($base_path) - 1)) {
            $new_path = substr($base_path, 0, $rindex + 1)
        } else {
            $new_path = $base_path
        }
    } else {
        $new_path = '';
    }
    return $new_path . $self->path($type)
}

# -------------
# Normalization
# -------------
around _set__scheme => sub {
    my ($orig, $self, $value) = @_;

    #
    # Normalized scheme is case insensitive and should be lowercased
    #
    $value->{normalized} = lc($value->{normalized});
    $self->$orig($value)
};

around _set__host => sub {
    my ($orig, $self, $value) = @_;

    #
    # Normalized host is case insensitive and should be lowercased
    #
    $value->{normalized} = lc($value->{normalized});
    $self->$orig($value)
};

around _set__ipv4 => sub {
    my ($orig, $self, $value) = @_;

    #
    # IP is a host, and normalized host is case insensitive and should be lowercased
    #
    $value->{normalized} = lc($value->{normalized});
    $self->$orig($value)
};

around _set__ipv6 => sub {
    my ($orig, $self, $value) = @_;

    #
    # IP is a host, and normalized host is case insensitive and should be lowercased
    #
    $value->{normalized} = lc($value->{normalized});
    $self->$orig($value)
};

around _set__ipvx => sub {
    my ($orig, $self, $value) = @_;

    #
    # IP is a host, and normalized host is case insensitive and should be lowercased
    #
    $value->{normalized} = lc($value->{normalized});
    $self->$orig($value)
};

around _set__zone => sub {
    my ($orig, $self, $value) = @_;

    #
    # Zone is part of host, so a normalized zone is case insensitive and should be lowercased
    #
    $value->{normalized} = lc($value->{normalized});
    $self->$orig($value)
};

around _set__path => sub {
    my ($orig, $self, $value) = @_;
    #
    # Normalized path is done by removing dot segments
    #
    $value->{normalized} = __PACKAGE__->remove_dot_segments($value->{normalized});
    $self->$orig($value)
};

# ------------------------
# Grammar Internal helpers
# ------------------------
#
# This _pct_encoded method guarantees that the output is a sequence of ASCII characters
# even if the UTF-8 flag would be set. For instance sequence %ce%a3 will be
# seen as "\x{ce}\x{a3}" in the resulting string, and NOT "\x{cea3}".
#
sub __pct_encoded {
    my ($self, undef, $hex1, $hex2) = @_;
    #
    # Note that here $hex are terminals, so in fact hex's origin == decoded == normalized
    #
    my $origin = join('', '%', $hex1->{origin}, $hex2->{origin});
    my $decoded = chr(hex(join('', $hex1->{decoded}, $hex2->{decoded})));
    #
    # Normalization is decoding any percent-encoded octet that corresponds
    # to an unreserved character, as described in Section 2.3:
    # unreserved  = ALPHA / DIGIT / "-" / "." / "_" / "~"
    # else it should be normalized to uppercase.
    #
    my $normalized = ($decoded =~ /[A-Za-z0-9\-._~]/) ? $decoded : uc($origin);
    return { origin => $origin, decoded => $decoded, normalized => $normalized }
}
#
# Special for zone
#
sub __encoded_percent_character {
    #
    # '%' decoded character is not an unreserved character, so the
    # normalized form remains %25
    #
    return { origin => '%25', decoded => '%', normalized => '%25'}
}
sub __not_encoded_percent_character {
    #
    # Same as __encoded_percent_character(), except that origin is '%' character
    #
    return { origin => '%', decoded => '%', normalized => '%25'}
}
#
# Pushes segments in a _segment[] array
#
sub __segment {
    my ($self, @args) = @_;

    my $concat = $self->__concat(@args);
    push(@{$self->_segments->{origin}},     $concat->{origin});
    push(@{$self->_segments->{decoded}},    $concat->{decoded});
    push(@{$self->_segments->{normalized}}, $concat->{normalized});
    return $concat
}
#
# Exactly the same as ESLIF's ::concat built-in, but revisited
# to work on original, decoded and normalized strings at the same time
#
sub __concat {
    my ($self, @args) = @_;

    my %rc = ( origin => '', decoded => '', normalized => '' );
    foreach my $arg (@args) {
        next unless ref($arg);
        $rc{origin}     .= $arg->{origin}     // '';
        $rc{decoded}    .= $arg->{decoded}    // '';
        $rc{normalized} .= $arg->{normalized} // '';
      }
    return \%rc
}
#
# Exactly the same as ESLIF's ::transfer built-in, but revisited
# to work on original and decoded strings at the same time
#
sub __symbol {
    my ($self, $symbol) = @_;
    #
    # No normalization on symbol until we know the context
    #
    return { origin => $symbol, decoded => $symbol, normalized => $symbol }
}


1;

=pod

=encoding UTF-8

=head1 NAME

MarpaX::ESLIF::URI::_generic - URI Generic syntax as per RFC3986/RFC6874

=head1 VERSION

version 0.005

=head1 SUBROUTINES/METHODS

=head2 $class->new($uri)

Instantiate a new object, or croak on failure. Takes as parameter an URI that will be parsed. The object instance is noted C<$self> below.

=for Pod::Coverage BUILDARGS

=for Pod::Coverage BUILD

=head2 $class->bnf

Returns the BNF used to parse the input.

=head2 $class->eslif

Returns a MarpaX::ESLIF singleton.

=head2 $class->grammar

Returns the compiled BNF used to parse the input as MarpaX::ESLIF::Grammar singleton.

=head2 $self->string($type)

Returns the string version of the URI, C<$type> is either 'decoded' (default value), 'origin' or 'normalized'.

=head2 $self->scheme($type)

Returns the scheme, or undef. C<$type> is either 'decoded' (default value), 'origin' or 'normalized'.

=head2 $self->authority($type)

Returns the authority, or undef. C<$type> is either 'decoded' (default value), 'origin' or 'normalized'.

=head2 $self->userinfo($type)

Returns the userinfo, or undef. C<$type> is either 'decoded' (default value), 'origin' or 'normalized'.

=head2 $self->host($type)

Returns the host (which may contain C<[]> delimiters in case of IPv6 literal), or undef. C<$type> is either 'decoded' (default value), 'origin' or 'normalized'.

=head2 $self->hostname($type)

Returns the hostname (without eventual C<[]> delimiters), or undef. C<$type> is either 'decoded' (default value), 'origin' or 'normalized'.

=head2 $self->ip($type)

Returns the IP when host is such a literal, or undef. C<$type> is either 'decoded' (default value), 'origin' or 'normalized'.

Note that this is the full concatenation of what makes an IP, in particular you will get the eventual IPv6 Zone Id if there is one.

=head2 $self->ipv4($type)

Returns the IPv4 when host is such a literal, or undef. C<$type> is either 'decoded' (default value), 'origin' or 'normalized'.

=head2 $self->ipv6($type)

Returns the IPv6 when host is such a literal, or undef. C<$type> is either 'decoded' (default value), 'origin' or 'normalized'.

=head2 $self->ipvx($type)

Returns the decoded IPvI<future> (as per the spec) when host is such a literal, or undef. C<$type> is either 'decoded' (default value), 'origin' or 'normalized'.

=head2 $self->zone($type)

Returns the IPv6 Zone Id, or undef. C<$type> is either 'decoded' (default value), 'origin' or 'normalized'.

=head2 $self->port

Returns the port, or undef.

=head2 $self->path($type)

Returns the path, or the empty string. C<$type> is either 'decoded' (default value), 'origin' or 'normalized'.

=head2 $self->segments($type)

Returns the path segments as an array reference, which may be empty. C<$type> is either 'decoded' (default value), 'origin' or 'normalized'.

=head2 $self->query($type)

Returns the query, or undef. C<$type> is either 'decoded' (default value), 'origin' or 'normalized'.

=head2 $self->fragment($type)

Returns the fragment, or undef. C<$type> is either 'decoded' (default value), 'origin' or 'normalized'.

=head2 $self->is_abs

Returns a true value if the URI is absolute.

=head2 $self->base

Returns a instance that is the absolute version of C<$self> if possible, or croak on failure.

When C<$self> is absolute, C<$self> itself is returned, otherwise it must have a scheme and a new instance without the origin fragment is returned.

=head2 $self->normalized

Returns the normalized string of C<$self>.

Equivalent to C<< $self->string('normalized') >>.

=head2 $self->decoded

Returns the decoded string of C<$self>.

Equivalent to C<< $self->string('decoded') >>.

=head2 $self->resolve($base, $strict)

Returns a instance that converts C<$self> into C<$base> URI, or croak on failure.

Default base is C<< $self->base >>.

If C<$strict> is a true value, C<$self> is always considered relative to C<$base>, otherwise a new URI without C<$self>'s dot segments is returned when C<$self> has a scheme. Default is a true value.

=head2 $self->eq($other)

Returns a instance that is the absolute version of current instance if possible, or croak on failure.

=head2 $self->clone

Returns a clone of current instance.

=head2 $self->as_string

Alias to C<string> method.

=head2 $class->remove_dot_segments($path)

Implementation of L<RFC3896's remove_dot_segments|https://tools.ietf.org/html/rfc3986#section-5.2.4>.

=head1 NOTES

=over

=item Logging

This package is L<Log::Any> aware, and will use the later in case parsing fails to output error messages.

=back

=head1 SEE ALSO

L<MarpaX::ESLIF::URI>, L<RFC3986|https://tools.ietf.org/html/rfc3986>, L<RFC6874|https://tools.ietf.org/html/rfc6874>

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__DATA__
#
# We maintain two string version in parallel when valuating the parse tree:
# - original
# - decoded
:default ::= action        => __concat
             symbol-action => __symbol

# :start ::= <URI reference>
<URI reference>          ::= <URI>                                                          action => _action_string
                           | <relative ref>                                                 action => _action_string
#
# Reference: https://tools.ietf.org/html/rfc3986#appendix-A
# Reference: https://tools.ietf.org/html/rfc6874
#
<URI>                    ::= <scheme> ":" <hier part> <URI query> <URI fragment>
<URI query>              ::= "?" <query>
<URI query>              ::=
<URI fragment>           ::= "#" <fragment>
<URI fragment>           ::=

<hier part>              ::= "//" <authority> <path abempty>
                           | <path absolute>
                           | <path rootless>
                           | <path empty>


<absolute URI>           ::= <scheme> ":" <hier part> <URI query>

<relative ref>           ::= <relative part> <URI query> <URI fragment>

<relative part>          ::= "//" <authority> <path abempty>
                           | <path absolute>
                           | <path noscheme>
                           | <path empty>

<scheme>                 ::= <scheme value>                                                 action => _action_scheme
<scheme value>           ::= <ALPHA> <scheme trailer>
<scheme trailer unit>    ::= <ALPHA> | <DIGIT> | "+" | "-" | "."
<scheme trailer>         ::= <scheme trailer unit>*

<authority userinfo>     ::= <userinfo> "@"
<authority userinfo>     ::=
<authority port>         ::= ":" <port>
<authority port>         ::=
<authority>              ::= <authority value>                                              action => _action_authority
<authority value>        ::= <authority userinfo> <host> <authority port>
<userinfo unit>          ::= <unreserved> | <pct encoded> | <sub delims> | ":"
<userinfo>               ::= <userinfo value>                                               action => _action_userinfo
<userinfo value>         ::= <userinfo unit>*
#
# The syntax rule for host is ambiguous because it does not completely
# distinguish between an IPv4address and a reg-name.  In order to
# disambiguate the syntax, we apply the "first-match-wins" algorithm:
# If host matches the rule for IPv4address, then it should be
# considered an IPv4 address literal and not a reg-name.
#
<host>                   ::= <IP literal>            rank =>  0                             action => _action_host
                           | <IPv4address>           rank => -1                             action => _action_host
                           | <reg name>              rank => -2                             action => _action_host
<port>                   ::= <port value>                                                   action => _action_port
<port value>             ::= <DIGIT>*

<IP literal interior>    ::= <IPv6address>                                                  action => _action_ip
                           | <IPv6addrz>                                                    action => _action_ip
                           | <IPvFuture>                                                    action => _action_ip
<IP literal>             ::= "[" <IP literal interior> "]"
<ZoneID interior>        ::= <unreserved>  | <pct encoded>
<ZoneID>                 ::= <ZoneID interior>+                                             action => _action_zone
<IPv6addrz percent char> ::= "%25"                                                          action => __encoded_percent_character
#
# From https://tools.ietf.org/html/rfc6874#section-3:
#
# "we also suggest that URI parsers accept bare "%" signs when possible"
#
<IPv6addrz percent char> ::= "%"                                                            action => __not_encoded_percent_character
<IPv6addrz>              ::= <IPv6address> <IPv6addrz percent char> <ZoneID>

<IPvFuture>              ::= "v" <HEXDIG many> "." <IPvFuture trailer>                      action => _action_ipvx
<IPvFuture trailer unit> ::= <unreserved> | <sub delims> | ":"
<IPvFuture trailer>      ::= <IPvFuture trailer unit>+

<IPv6address>            ::=                                   <6 h16 colon> <ls32>         action => _action_ipv6
                           |                              "::" <5 h16 colon> <ls32>         action => _action_ipv6
                           |                      <h16>   "::" <4 h16 colon> <ls32>         action => _action_ipv6
                           |                              "::" <4 h16 colon> <ls32>         action => _action_ipv6
                           |   <0 to 1 h16 colon> <h16>   "::" <3 h16 colon> <ls32>         action => _action_ipv6
                           |                              "::" <3 h16 colon> <ls32>         action => _action_ipv6
                           |   <0 to 2 h16 colon> <h16>   "::" <2 h16 colon> <ls32>         action => _action_ipv6
                           |                              "::" <2 h16 colon> <ls32>         action => _action_ipv6
                           |   <0 to 3 h16 colon> <h16>   "::" <1 h16 colon> <ls32>         action => _action_ipv6
                           |                              "::" <1 h16 colon> <ls32>         action => _action_ipv6
                           |   <0 to 4 h16 colon> <h16>   "::"               <ls32>         action => _action_ipv6
                           |                              "::"               <ls32>         action => _action_ipv6
                           |   <0 to 5 h16 colon> <h16>   "::"               <h16>          action => _action_ipv6
                           |                              "::"               <h16>          action => _action_ipv6
                           |   <0 to 6 h16 colon> <h16>   "::"                              action => _action_ipv6
                           |                              "::"                              action => _action_ipv6

<1 h16 colon>            ::= <h16> ":"
<2 h16 colon>            ::= <h16> ":" <h16> ":"
<3 h16 colon>            ::= <h16> ":" <h16> ":" <h16> ":"
<4 h16 colon>            ::= <h16> ":" <h16> ":" <h16> ":" <h16> ":"
<5 h16 colon>            ::= <h16> ":" <h16> ":" <h16> ":" <h16> ":" <h16> ":"
<6 h16 colon>            ::= <h16> ":" <h16> ":" <h16> ":" <h16> ":" <h16> ":" <h16> ":"

#
# These productions are ambiguous without ranking (rank is equivalent to make regexps greedy)
#
<0 to 1 h16 colon>       ::=
<0 to 1 h16 colon>       ::= <1 h16 colon>                    rank => 1
<0 to 2 h16 colon>       ::= <0 to 1 h16 colon>
<0 to 2 h16 colon>       ::= <0 to 1 h16 colon> <1 h16 colon> rank => 1
<0 to 3 h16 colon>       ::= <0 to 2 h16 colon>
<0 to 3 h16 colon>       ::= <0 to 2 h16 colon> <1 h16 colon> rank => 1
<0 to 4 h16 colon>       ::= <0 to 3 h16 colon>
<0 to 4 h16 colon>       ::= <0 to 3 h16 colon> <1 h16 colon> rank => 1
<0 to 5 h16 colon>       ::= <0 to 4 h16 colon>
<0 to 5 h16 colon>       ::= <0 to 4 h16 colon> <1 h16 colon> rank => 1
<0 to 6 h16 colon>       ::= <0 to 5 h16 colon>
<0 to 6 h16 colon>       ::= <0 to 5 h16 colon> <1 h16 colon> rank => 1

<h16>                    ::= <HEXDIG>
                           | <HEXDIG> <HEXDIG>
                           | <HEXDIG> <HEXDIG> <HEXDIG>
                           | <HEXDIG> <HEXDIG> <HEXDIG> <HEXDIG>

<ls32>                   ::= <h16> ":" <h16> | <IPv4address>
<IPv4address>            ::= <dec octet> "." <dec octet> "." <dec octet> "." <dec octet> action => _action_ipv4

<dec octet>              ::= <DIGIT>                     # 0-9
                           | [\x{31}-\x{39}] <DIGIT>     # 10-99
                           | "1" <DIGIT> <DIGIT>         # 100-199
                           | "2" [\x{30}-\x{34}] <DIGIT> # 200-249
                           | "25" [\x{30}-\x{35}]        # 250-255

<reg name unit>          ::= <unreserved> | <pct encoded> | <sub delims>
<reg name>               ::= <reg name unit>*

<path>                   ::= <path abempty>                                                 # begins with "/" or is empty
                           | <path absolute>                                                # begins with "/" but not "//"
                           | <path noscheme>                                                # begins with a non-colon segment
                           | <path rootless>                                                # begins with a segment
                           | <path empty>                                                   # zero characters

<path abempty unit>      ::= "/" <segment>
<path abempty>           ::= <path abempty value>                                           action => _action_path
<path abempty value>     ::= <path abempty unit>*
<path absolute>          ::= <path absolute value>                                          action => _action_path
<path absolute value>    ::= "/"
                           | "/" <segment nz> <path abempty value>
<path noscheme>          ::= <path noscheme value>                                          action => _action_path
<path noscheme value>    ::= <segment nz nc> <path abempty value>
<path rootless>          ::= <path rootless value>                                          action => _action_path
<path rootless value>    ::= <segment nz> <path abempty value>
<path empty>             ::=                                                                # Default value for path is ''

<segment>                ::= <pchar>*                                                       action => __segment
<segment nz>             ::= <pchar>+                                                       action => __segment
<segment nz nc unit>     ::= <unreserved> | <pct encoded> | <sub delims> | "@" # non-zero-length segment without any colon ":"
<segment nz nc>          ::= <segment nz nc unit>+                                          action => __segment

<pchar>                  ::= <unreserved> | <pct encoded> | <sub delims> | ":" | "@"

<query unit>             ::= <pchar> | "/" | "?"
<query>                  ::= <query value>                                                  action => _action_query
<query value>            ::= <query unit>*

<fragment unit>          ::= <pchar> | "/" | "?"
<fragment>               ::= <fragment value>                                               action => _action_fragment
<fragment value>         ::= <fragment unit>*

<pct encoded>            ::= "%" <HEXDIG> <HEXDIG>                                          action => __pct_encoded

<unreserved>             ::= <ALPHA> | <DIGIT> | "-" | "." | "_" | "~"
<reserved>               ::= <gen delims> | <sub delims>
<gen delims>             ::= ":" | "/" | "?" | "#" | "[" | "]" | "@"
<sub delims>             ::= "!" | "$" | "&" | "'" | "(" | ")"
                           | "*" | "+" | "," | ";" | "="

<HEXDIG many>            ::= <HEXDIG>+
<ALPHA>                  ::= [A-Za-z]
<DIGIT>                  ::= [0-9]
<HEXDIG>                 ::= [0-9A-Fa-f]          # case insensitive
