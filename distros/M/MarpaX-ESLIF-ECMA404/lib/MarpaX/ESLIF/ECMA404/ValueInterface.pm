use strict;
use warnings FATAL => 'all';

package MarpaX::ESLIF::ECMA404::ValueInterface;
use Math::BigInt;
use Math::BigFloat;
use Carp qw/croak/;

our $FFFD = chr(0xFFFD);

# ABSTRACT: MarpaX::ESLIF::ECMA404 Value Interface

our $VERSION = '0.012'; # VERSION

our $AUTHORITY = 'cpan:JDDPAUSE'; # AUTHORITY


# -----------
# Constructor
# -----------


sub new {
    my ($pkg, %options) = @_;

    return bless { result => undef, %options }, $pkg
}

# ----------------
# Required methods
# ----------------


sub isWithHighRankOnly { return 1 }  # When there is the rank adverb: highest ranks only ?


sub isWithOrderByRank  { return 1 }  # When there is the rank adverb: order by rank ?


sub isWithAmbiguous    { return 0 }  # Allow ambiguous parse ?


sub isWithNull         { return 0 }  # Allow null parse ?


sub maxParses          { return 0 }  # Maximum number of parse tree values


sub getResult          { return $_[0]->{result} }


sub setResult          { return $_[0]->{result} = $_[1] }

# ----------------
# Specific actions
# ----------------


sub unicode {
  my ($self, $u) = @_;

  my @hex;
  while ($u =~ m/\\u([[:xdigit:]]{4})/g) {
    push(@hex, hex($1))
  }

  my $result;
  while (@hex) {
    if ($#hex > 0) {
      my ($high, $low) = @hex;
      #
      # An UTF-16 surrogate pair ?
      #
      if (($high >= 0xD800) && ($high <= 0xDBFF) && ($low >= 0xDC00) && ($low <= 0xDFFF)) {
        #
        # Yes.
        # This is evaled for one reason only: some old versions of perl may croak with special characters like
        # "Unicode character 0x10ffff is illegal"
        #
        $result .= eval {chr((($high - 0xD800) * 0x400) + ($low - 0xDC00) + 0x10000)} // $FFFD;
        splice(@hex, 0, 2)
      } else {
        #
        # No. Take first \uhhhh as a code point. Fallback to replacement character 0xFFFD if invalid.
        # Eval returns undef in scalar context if there is a failure.
        #
        $result .= eval {chr(shift @hex) } // $FFFD
      }
    } else {
      #
      # \uhhhh taken as a code point. Fallback to replacement character 0xFFFD if invalid.
      # Eval returns undef in scalar context if there is a failure.
      #
      $result .= eval {chr(shift @hex) } // $FFFD
    }
  }

  return $result
}


sub members {
    do { shift, return { map { $_->[0] => $_->[1] } @_ } } if !$_[0]->{disallow_dupkeys};

    my $self = shift;

    #
    # Arguments are: ($self, $pair1, $pair2, etc..., $pairn)
    #
    my %hash;
    foreach (@_) {
      my ($key, $value) = @{$_};
      if (exists $hash{$key}) {
        if ($self->{disallow_dupkeys}) {
          #
          # Just make sure the key printed out contains only printable things
          #
          my $ascii = $key;
          $ascii =~ s/[^[:print:]]/ /g;
          $ascii .= " (printable characters only)" unless $ascii eq $key;
          $self->{logger}->errorf('Duplicate key %s', $ascii) if $self->{logger};
          croak "Duplicate key $ascii"
        } else {
          $self->{logger}->warnf('Duplicate key %s', $key) if $self->{logger}
        }
      }
      $hash{$key} = $value
    }

    return \%hash
}


sub number {
  my ($self, $number) = @_;
  #
  # We are sure this is a float if there is the dot '.' or the exponent [eE]
  #
  return ($number =~ /[\.eE]/) ? Math::BigFloat->new($number) : Math::BigInt->new($number)
}


sub nan {
    return Math::BigInt->bnan()
}


sub negative_infinity {
    return Math::BigInt->binf('-')
}


sub positive_infinity {
    return Math::BigInt->binf()
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

MarpaX::ESLIF::ECMA404::ValueInterface - MarpaX::ESLIF::ECMA404 Value Interface

=head1 VERSION

version 0.012

=head1 SYNOPSIS

    use MarpaX::ESLIF::ECMA404::ValueInterface;

    my $valueInterface = MarpaX::ESLIF::ECMA404::ValueInterface->new();

=head1 DESCRIPTION

MarpaX::ESLIF::ECMA404's Value Interface

=head1 SUBROUTINES/METHODS

=head2 new($class)

Instantiate a new value interface object.

=head2 Required methods

=head3 isWithHighRankOnly

Returns a true or a false value, indicating if valuation should use highest ranked rules or not, respectively. Default is a true value.

=head3 isWithOrderByRank

Returns a true or a false value, indicating if valuation should order by rule rank or not, respectively. Default is a true value.

=head3 isWithAmbiguous

Returns a true or a false value, indicating if valuation should allow ambiguous parse tree or not, respectively. Default is a false value.

=head3 isWithNull

Returns a true or a false value, indicating if valuation should allow a null parse tree or not, respectively. Default is a false value.

=head3 maxParses

Returns the number of maximum parse tree valuations. Default is unlimited (i.e. a false value).

=head3 getResult

Returns the current parse tree value.

=head3 setResult

Sets the current parse tree value.

=head2 Specific actions

=head3 unicode

Action for rule C<char ::= /(?:\\u[[:xdigit:]]{4})+/>

=head3 members

Action for rule C<members  ::= pairs* separator => ','> hide-separator => 1>

=head3 number

Action for rule C<number ::= /\-?(?:(?:[1-9]?[0-9]*)|[0-9])(?:\.[0-9]*)?(?:[eE](?:[+-])?[0-9]+)?/>

=head3 nan

Action for rules C<number ::= '-' 'NaN'> and C<number ::= 'NaN'>

=head3 negative_infinity

Action for rule C<number ::= '-' 'Infinity'>

=head3 positive_infinity

Action for rule C<number ::= 'Infinity'>

=head1 SEE ALSO

L<MarpaX::ESLIF::ECMA404>

=head1 AUTHOR

Jean-Damien Durand <jeandamiendurand@free.fr>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Jean-Damien Durand.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
