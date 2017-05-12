package Lingua::JBO::Numbers;

use 5.008_001;
use strict;
use warnings;
use Readonly;
use Regexp::Common qw( number );

use base qw( Exporter );
our @EXPORT_OK = qw( num2jbo num2jbo_ordinal );
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

our $VERSION = '0.03';

Readonly my $EMPTY_STR      => q{};
Readonly my $ORDINAL_SUFFIX => q{moi};

Readonly my @NAMES => qw< no pa re ci vo mu xa ze bi so >;
Readonly my %WORDS => (
    '.' => "pi",
    ',' => "ki'o",
    '-' => "ni'u",
    '+' => "ma'u",
    inf => "ci'i",
    NaN => "na namcu",
);

sub num2jbo {
    my ($number) = @_;
    my @names;

    return unless defined $number;
    return $WORDS{NaN} if $number eq 'NaN';

    if ($number =~ m/^ ( [-+] )? inf $/ix) {
        # infinity
        push @names, $1 ? $WORDS{$1} : (), $WORDS{inf};
    }
    elsif ($number =~ m/^ $RE{num}{real}{-keep} $/x) {
        my ($sign, $int, $frac) = ($2, $4, $6);

        # sign and integer
        push @names, (
            $WORDS{$sign} || (),
            map { $NAMES[$_] } split $EMPTY_STR, defined $int ? $int : $EMPTY_STR,
        );

        # fraction
        if (defined $frac && $frac ne $EMPTY_STR) {
            push @names, (
                $WORDS{'.'},
                map { $NAMES[$_] } split $EMPTY_STR, $frac,
            );
        }
    }
    else {
        return;
    }

    return join $EMPTY_STR, @names;
}

sub num2jbo_ordinal {
    my ($number) = @_;
    my $name = num2jbo($number);

    return unless defined $name;
    return $name . $ORDINAL_SUFFIX;
}

1;

__END__

=head1 NAME

Lingua::JBO::Numbers - Convert numbers into Lojban words

=head1 VERSION

This document describes Lingua::JBO::Numbers version 0.03.

=head1 SYNOPSIS

    use 5.010;
    use Lingua::JBO::Numbers qw( num2jbo );

    for my $namcu (reverse 0 .. 99) {
        say '.', num2jbo($namcu), ' botpi le birje cu cpana le bitmu';
    }

output:

    .soso botpi le birje cu cpana le bitmu
    .sobi botpi le birje cu cpana le bitmu
    .soze botpi le birje cu cpana le bitmu
      ...
    .no botpi le birje cu cpana le bitmu

=head1 DESCRIPTION

This module provides functions to convert numbers into words in Lojban, a
constructed logical language created by The Logical Language Group and
published in 1998.

=head1 FUNCTIONS

The following functions are provided but are not exported by default.

=over 4

=item num2jbo EXPR

If EXPR looks like a number, the text describing the number is returned.  Both
integers and real numbers are supported, including negatives.  Special values
such as "inf" and "NaN" are also supported.

=item num2jbo_ordinal EXPR

If EXPR looks like an integer, the text describing the number in ordinal form
is returned.  The behavior when passing a non-integer value is undefined.

=back

If EXPR is a value that does not look like a number or is not currently
supported by this module, C<undef> is returned.

The C<:all> tag can be used to import all functions.

    use Lingua::JBO::Numbers qw( :all );

=head1 TODO

=over 4

=item * support exponential notation

=item * support "ra'e" for repeating decimals

=item * option for using either space or nothing to separate output words

=item * option for using the thousands separator "ki'o" in output

=item * option for eluding to zeros using "ki'o"

=item * provide POD translation in Lojban

=back

=head1 SEE ALSO

L<Lingua::Conlang::Numbers>,
L<http://www.lojban.org/publications/reference_grammar/chapter18.html>

=head1 AUTHOR

Nick Patch <patch@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 Nick Patch

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
