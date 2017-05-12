#===============================================================================
#
#         FILE:  Types.pm
#
#      PODNAME:  Games::Go::AGA::DataObjects::Game
#     ABSTRACT:  library of types and constraints for Games::Go::AGA
#
#       AUTHOR:  Reid Augustin (REID), <reid@hellosix.com>
#      CREATED:  11/22/2010 12:03:18 PM PST
#===============================================================================

use 5.008;
use strict;
use warnings;

package Games::Go::AGA::DataObjects::Types;
use Moo;
use namespace::clean;
use Scalar::Util::Numeric qw( isint isfloat );

BEGIN {
    use parent 'Exporter';
    our @EXPORT_OK = qw(
        is_Int
        is_ID
        is_Rank
        is_Rating
        is_Rank_or_Rating
        is_Handicap
        is_Komi
        is_Winner
        isa_Int
        isa_Num
        isa_ArrayRef
        isa_HashRef
        isa_CodeRef
        isa_Komi
        isa_Handicap
    );
}

our $VERSION = '0.152'; # VERSION

sub isa_Int      { die("$_[0] is not an integer\n")   if (not isint($_[0])) };
sub isa_Num      { die("$_[0] is not a number\n")     if (not isint($_[0]) or isfloat($_[0])) };
sub isa_ArrayRef { die("$_[0] is not an array ref\n") if (ref $_[0] ne 'ARRAY') };
sub isa_HashRef  { die("$_[0] is not a hash ref\n")   if (ref $_[0] ne 'HASH') };
sub isa_CodeRef  { die("$_[0] is not a code ref\n")   if (ref $_[0] ne 'CODE') };
sub isa_Komi     { die("$_[0] is not a Komi\n")       if (not is_Komi($_[0])) }
sub isa_Handicap { die("$_[0] is not a Handicap\n")   if (not is_Handicap($_[0])) }

# type definitions
sub is_Int {
    return isint(shift);
}

sub is_ID {
    $_ = shift;
    return (
        m/^\w+$/    # valid alpha-numeric characters
        and m/^\D/     # not digit in first character
    );
}

sub is_Rank {
    $_ = shift;
    return (
        (m/^(\d+)[dD]$/ and $1 >= 1 and $1 < 20) or
        (m/^(\d+)[kK]$/ and $1 >= 1 and $1 < 100)
    );
}

sub is_Rating {
    $_ = shift;
    return(
        $_ and
        (isint($_) or
         isfloat($_)) and
        (($_ < 20.0 and
          $_ >= 1.0) or
         ($_ <= -1.0 and
          $_ >  -100.0))
    );
}

sub is_Handicap {
    $_ = shift;
    return (
        defined $_ and
        isint($_) and
        (($_ >= 0) and
         ($_ <= 99))    # really should be 9, but let"s not be cops about it
    );
}

sub is_Komi {
    $_ = shift;
    return (defined $_ and (isint($_) or isfloat($_)));
}

sub is_Winner {
    $_ = shift;
    return $_ =~ m/^[wb?]$/i;  # w, b, or ?
}

sub is_Rank_or_Rating {
    $_ = shift;
    return (is_Rank($_) or is_Rating($_));
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Games::Go::AGA::DataObjects::Game - library of types and constraints for Games::Go::AGA

=head1 VERSION

version 0.152

=head1 SYNOPSIS

  use Games::Go::AGA::DataObjects::Types qw( is_ID is_Rank ... );

Supported types are:
    is_ID              string containing only word-like characters
    is_Rank            like 5D, 3k, etc
    is_Rating          decimal number from -100 to 20, excluding range from 1 to -1
    is_Rank_or_Rating  either a Rank or a Rating
    is_Handicap        non-negative integer less than 100
    is_Komi            decimal number
    is_Winner          b, B, w, W, or ? (black, white or unknown)

which all return true if the passed argument is valid, false otherwise.

Also provided are:
    isa_Int
    isa_CodeRef

=head1 SEE ALSO

=over 4

=item Games::Go::AGA

=item Games::Go::AGA::DataObjects

=item Games::Go::AGA::Parse

=item Games::Go::AGA::Gtd

=back

=head1 AUTHOR

Reid Augustin <reid@hellosix.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Reid Augustin.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
