package Lingua::TLH::Numbers;

use 5.008_001;
use strict;
use warnings;
use Readonly;
use Regexp::Common qw( number );

use base qw( Exporter );
our @EXPORT_OK = qw( num2tlh num2tlh_ordinal );
our %EXPORT_TAGS = ( all => \@EXPORT_OK );

our $VERSION = '0.01';

# up to 9 million supported
Readonly my $MAX_INT_DIGITS => 7;

Readonly my $EMPTY_STR => q{};
Readonly my $SPACE     => q{ };
Readonly my $MINUS     => q{-};

Readonly my $POINT          => q{vI'};
Readonly my $ORDINAL_SUFFIX => q{DIch};

Readonly my @NAMES1  => qw< pagh wa' cha' wej loS vagh jav Soch chorgh Hut >;
Readonly my @NAMES2  => $EMPTY_STR, qw< maH vatlh SaD netlh bIp 'uy' >;

# convert number to words
sub num2tlh {
    my ($number) = @_;
    my $digit_count = 0;
    my @names;

    return unless defined $number;

    # NaN and inf not supported
    return if $number eq 'NaN' || $number =~ m{^ [-+]? inf $}ix;

    return if $number !~ m{^ $RE{num}{real}{-keep} $}x;
    my ($sign, $int, $frac) = ($2, $4, $6);

    # negatives not supported
    return if $sign eq $MINUS;

    return if length $int > $MAX_INT_DIGITS;

    # integer
    DIGIT:
    for my $digit (reverse split $EMPTY_STR, $int) {
        # skip zero unless it is the only digit
        next DIGIT if $digit == 0 && $int != 0;

        unshift @names, $NAMES1[$digit] . $NAMES2[$digit_count];
    }
    continue {
        $digit_count++;
    }

    # fraction
    if (defined $frac && $frac ne $EMPTY_STR) {
        push @names, $POINT, map { $NAMES1[$_] } split $EMPTY_STR, $frac;
    }

    return join $SPACE, @names;
}

# convert number to ordinal words
sub num2tlh_ordinal {
    my ($number) = @_;
    my $name = num2tlh($number);

    return unless defined $name;
    return $name . $ORDINAL_SUFFIX;
}

1;

__END__

=head1 NAME

Lingua::TLH::Numbers - Convert numbers into Klingon words

=head1 VERSION

This document describes Lingua::TLH::Numbers version 0.01.

=head1 SYNOPSIS

    use 5.010;
    use Lingua::TLH::Numbers qw( num2tlh );

    for my $mI (reverse 0 .. 99) {
        say ucfirst num2tlh($mI), " bal vo' HIq Daq reD.";
    }

output:

    HutmaH Hut bal vo' HIq Daq reD.
    HutmaH chorgh bal vo' HIq Daq reD.
    HutmaH Soch bal vo' HIq Daq reD.
      ...
    pagh bal vo' HIq Daq reD.

=head1 DESCRIPTION

This module provides functions to convert numbers into words in Klingon, a
constructed fictional language created by Mark Okrand and introduced in 1984.

=head1 FUNCTIONS

The following functions are provided but are not exported by default.

=over 4

=item num2tlh EXPR

If EXPR looks like a number, the text describing the number is returned.  Both
integers and real numbers are supported, although negatives are not currently
supported.

=item num2tlh_ordinal EXPR

If EXPR looks like an integer, the text describing the number in ordinal form
is returned.  The behavior when passing a non-integer value is undefined.

=back

If EXPR is a value that does not look like a number or is not currently
supported by this module, C<undef> is returned.

The C<:all> tag can be used to import all functions.

    use Lingua::TLH::Numbers qw( :all );

=head1 TODO

=over 4

=item * support negatives, inf, and NaN

=item * support exponential notation

=item * option for the older ternary number system

=item * option for using "SanID" instead of "SaD" for "thousand"

=back

=head1 SEE ALSO

L<Lingua::Conlang::Numbers>, L<http://klingonska.org/ref/num.html>,
L<http://mughom.wikia.com/wiki/QaH:A_Guide_to_Klingon/others>

=head1 AUTHOR

Nick Patch <patch@cpan.org>

=head1 COPYRIGHT AND LICENSE

Copyright 2010 Nick Patch

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
