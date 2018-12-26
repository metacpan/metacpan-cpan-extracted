package Lingua::TR::Numbers;
$Lingua::TR::Numbers::VERSION = '0.34';
use 5.010;
use utf8;
use strict;
use warnings;
use subs qw( _log );

use constant RE_E2TR => qr{
    \A
    (
        [-+]?  # leading sign
        (?:
        [\d,]+  |  [\d,]*\.\d+  # number
        )
    )
    [eE]
    (-?\d+)   # mantissa, has to be an integer
    \z
}xms;
use constant RE_EMPTY     => qr//xms;
use constant EMPTY_STRING => q{};
use constant SPACE        => q{ };
use constant DIGITS       => 0..9;
use constant TENS         => map { 10 * $_ } 1..9;
use constant LAST_ELEMENT => -1;
use constant PREV_ELEMENT => -2;
use constant CHUNK_MAX    => 100;
use base qw( Exporter );
use Carp qw( croak );

BEGIN { *DEBUG = sub () {0} if ! defined &DEBUG } # setup a DEBUG constant

our @EXPORT_OK   = qw( num2tr num2tr_ordinal );
our %EXPORT_TAGS =   ( all => \@EXPORT_OK    );

my($RE_VOWEL, %D, %MULT, %CARD2ORD, %CARD2ORDTR);

POPULATE: {
    @D{ DIGITS() } = qw| sıfır bir     iki    üç     dört     beş     altı    yedi    sekiz     dokuz     |;
    @D{ TENS()   } = qw|       on      yirmi  otuz   kırk     elli    altmış  yetmiş  seksen    doksan    |;

    @CARD2ORD{       qw|       bir     iki    üç     dört     beş     altı    yedi    sekiz     dokuz     |}
                   = qw|       birinci ikinci üçüncü dördüncü beşinci altıncı yedinci sekizinci dokuzuncu |;

    @CARD2ORDTR{     qw| a   e   ı   i   u   ü   o   ö   |}
                   = qw| ncı nci ncı nci ncu ncü ncu ncü |;

    $RE_VOWEL = join EMPTY_STRING, keys %CARD2ORDTR;
    $RE_VOWEL = qr{([$RE_VOWEL])}xms;

    my @large = qw|
                   bin       milyon    milyar    trilyon  katrilyon
                   kentilyon seksilyon septilyon oktilyon nobilyon
                   desilyon
                |;
    my $c = 0;
    $MULT{ $c++ } = $_ for EMPTY_STRING, @large;
}

sub num2tr_ordinal {
    #  Cardinals are [bir     iki    üç     ...]
    #  Ordinals  are [birinci ikinci üçüncü ...]
    my $x = shift;

    return unless defined $x and length $x;

    $x = num2tr( $x );
    return $x if ! $x;

    my($ok, $end, $step);
    if ( $x =~ s/(\w+)\z//xms ) {
        $end  = $1;
        my @l = split RE_EMPTY, $end;
        $step = 1;

        foreach my $l ( reverse @l ) {
            next if not $l;
            if ( $l =~ $RE_VOWEL ) {
                $ok = $1;
                last;
            }
            $step++;
        }
    }
    else {
        return $x . q{.};
    }

    if ( ! $ok ) {
        #die "Can not happen: '$end'";
        return;
    }

    $end = $CARD2ORD{$end} || sub {
                                my $val = $CARD2ORDTR{$ok};
                                return $end . $val if $step == 1;
                                my $letter = (split RE_EMPTY, $val)[LAST_ELEMENT];
                                return $end.$letter.$val;
                            }->();

    return "$x$end";
}

sub num2tr {
    my $x = shift;
    return unless defined $x and length $x;

    return 'sayı-değil'  if $x eq 'NaN';
    return 'eksi sonsuz' if $x =~ m/ \A \+ inf(?:inity)? \z /xmsi;
    return 'artı sonsuz' if $x =~ m/ \A \- inf(?:inity)? \z /xmsi;
    return      'sonsuz' if $x =~ m/ \A    inf(?:inity)? \z /xmsi;
    return $D{$x}        if exists $D{$x};  # the most common cases

    # Make sure it's not in scientific notation:
    { my $e = _e2tr($x); return $e if defined $e; }

    my $orig = $x;

    $x =~ s/,//xmsg; # nix any commas

    my $sign;
    if ( $x =~ s/\A([-+])//xms ) {
        $sign = $1;
    }

    my($int, $fract);
       if( $x =~ m/ \A          \d+  \z/xms ) { $int = $x }
    elsif( $x =~ m/ \A (\d+)[.](\d+) \z/xms ) { $int = $1; $fract = $2 }
    elsif( $x =~ m/ \A      [.](\d+) \z/xms ) { $fract = $1 }
    else {
        _log "Not a number: '$orig'\n" if DEBUG;
        return;
    }

    _log(
        sprintf " Working on Sign[%s]  Int2tr[%s]  Fract[%s]  < '%s'\n",
                map { defined($_) ? $_ : 'nil' } $sign, $int, $fract, $orig
    ) if DEBUG;

    return join SPACE, grep { defined $_ && length $_ }
                            _sign2tr(  $sign  ),
                            _int2tr(   $int   ),
                            _fract2tr( $fract ),
    ;
}

sub _sign2tr {
    my $x = shift;
    return ! defined $x || ! length $x ? undef
         : $x eq q{-}                  ? 'eksi'
         : $x eq q{+}                  ? 'artı'
         :                               "WHAT_IS_$x"
         ;
}

sub _fract2tr { # "1234" => "point one two three four"
    my $x = shift;
    return unless defined $x and length $x;
    return join SPACE, 'nokta',
                        map { $D{$_} }
                            split RE_EMPTY, $x;
}

# The real work:

sub _int2tr {
    my $x = shift;
    return unless defined $x and length $x and $x =~ m/\A\d+\z/xms;
    return $D{$x} if defined $D{$x}; # most common/irreg cases

    if( $x =~ m/\A(.)(.)\z/xms ) {
        return  $D{$1 . '0'} . SPACE . $D{$2};
        # like    forty        -     two
        # note that neither bit can be zero at this point     
    }
    elsif ( $x =~ m/\A(.)(..)\z/xms ) {
        my $tmp = $1 == 1 ? EMPTY_STRING : $D{$1} . SPACE;
        my($h, $rest) = ($tmp.'yüz', $2);
        return $h if $rest eq '00';
        return "$h " . _int2tr(0 + $rest);
    }
    else {
        return _bigint2tr($x);
    }
}

sub _bigint2tr {
    my $x = shift;
    return unless defined $x and length $x and $x =~ m/\A\d+\z/xms;
    my @chunks;  # each:  [ string, exponent ]
    {
        my $groupnum = 0;
        my $num;
        while ( $x =~ s/(\d{1,3})\z//xms ) { # pull at most three digits from the end
            $num = $1 + 0;
            unshift @chunks, [ $num, $groupnum ] if $num;
            ++$groupnum;
        }
        return $D{'0'} unless @chunks;  # rare but possible
    }

    my $and;
    # junk
    $and = EMPTY_STRING if $chunks[LAST_ELEMENT][1] == 0 and $chunks[LAST_ELEMENT][0] < CHUNK_MAX;
    # The special 'and' that shows up in like "one thousand and eight"
    # and "two billion and fifteen", but not "one thousand [*and] five hundred"
    # or "one million, [*and] nine"

    _chunks2tr( \@chunks );

    $chunks[PREV_ELEMENT] .= SPACE if $and and @chunks > 1;
    return "$chunks[0] $chunks[1]" if @chunks == 2;
    # Avoid having a comma if just two units
    return join q{, }, @chunks;
}

sub _chunks2tr {
    my $chunks = shift;
    return if ! @{ $chunks };
    my @out;
    foreach my $c ( @{ $chunks } ) {
        push @out,   $c = _groupify( _int2tr( $c->[0] ),  $c->[1] ,$c->[0])  if $c->[0];
    }
    @{ $chunks } = @out;
    return;
}

sub _groupify {
    # turn ("seventeen", 3) => "seventeen billion"
    my($basic, $multnum, $raw) = @_;
    return  $basic unless $multnum;  # the first group is unitless
    _log "  Groupifying $basic x $multnum mults\n" if DEBUG > 2;
    return "$basic $MULT{$multnum}"  if  $MULT{$multnum};
    # Otherwise it must be huuuuuge, so fake it with scientific notation
    return $basic . ' çarpı on üzeri ' . num2tr( $raw * 3 );
}

# Because I can never remember this:
#
#  3.1E8
#  ^^^   is called the "mantissa"
#      ^ is called the "exponent"
#         (the implicit "10" is the "base" a/k/a "radix")

sub _e2tr {
    my $x = shift;
    if ( $x =~ RE_E2TR ) {
        my($m, $e) = ($1, $2);
        _log "  Scientific notation: [$x] => $m E $e\n" if DEBUG;
        $e += 0;
        return num2tr($m) . ' çarpı on üzeri ' . num2tr($e);
    }
    else {
        _log "  Okay, $x isn't in exponential notation\n" if DEBUG;
        return;
    }
}

sub _log {
    my @args = @_;
    print @args or croak "Unable to print to STDOUT: $!";
    return;
}

#==========================================================================

1;

=pod

=encoding UTF-8

=head1 NAME

Lingua::TR::Numbers

=head1 VERSION

version 0.34

=head1 SYNOPSIS

   use Lingua::TR::Numbers qw(num2tr num2tr_ordinal);
   
   my $x = 234;
   my $y = 54;
   print "Bugün yapman gereken ", num2tr($x), " tane işin var!\n";
   print "Yarın annemin ", num2tr_ordinal($y), " yaşgününü kutlayacağız.\n";

prints:

   Bugün yapman gereken iki yüz otuz dört tane işin var!
   Yarın annemin elli dördüncü yaşgününü kutlayacağız.

=head1 DESCRIPTION

Lingua::TR::Numbers turns numbers into Turkish text. It exports
(upon request) two functions, C<num2tr> and C<num2tr_ordinal>. 
Each takes a scalar value and returns a scalar value. The return 
value is the Turkish text expressing that number; or if what you 
provided wasn't a number, then they return undef.

This module can handle integers like "12" or "-3" and real numbers like "53.19".

This module also understands exponential notation -- it turns "4E9" into
"dört çarpı 10 üzeri dokuz"). And it even turns "INF", "-INF", "NaN"
into "sonsuz", "eksi sonsuz" and "sayı-değil" respectively.

Any commas in the input numbers are ignored.

=head1 NAME

Lingua::TR::Numbers - Converts numbers into Turkish text.

=head1 FUNCTIONS

You can import these one by one or use the special C<:all> tag:

   use Lingua::TR::Numbers qw(num2tr num2tr_ordinal);

or

   use Lingua::TR::Numbers qw(:all);

=head2 num2tr

Converts the supplied number into Turkish text.

=head2 num2tr_ordinal

Similar to C<num2tr>, but returns ordinal versions .

=head2 DEBUG

Define C<Lingua::TR::Numbers::DEBUG> to enable debugging.

=head1 LIMIT

This module supports any numbers upto 999 decillion (999*10**33). Any further 
range is currently not in commnon use and is not implemented.

=head1 SEE ALSO

L<Lingua::EN::Numbers>. L<http://www.radikal.com.tr/haber.php?haberno=66427>
L<http://en.wikipedia.org/wiki/Names_of_large_numbers>.

See C<NumbersTR.pod> (bundled with this distribution) for the Turkish translation of
this documentation.

=head1 CAVEATS

This module' s source file is UTF-8 encoded (without a BOM) and it returns UTF-8
values whenever possible.

Currently, the module won't work with any Perl older than 5.6.

=head1 ACKNOWLEDGEMENT

This module is based on and includes modified code 
portions from Sean M. Burke's Lingua::EN::Numbers.

Lingua::EN::Numbers is Copyright (c) 2005, Sean M. Burke.

=head1 AUTHOR

Burak Gursoy <burak@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2006 by Burak Gursoy.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut

__END__

#1 milyon    1.000.000
#1 milyar    1.000.000.000
#1 trilyon   1.000.000.000.000
#1 katrilyon 1.000.000.000.000.000
#1 kentilyon 1.000.000.000.000.000.000
#1 seksilyon 1.000.000.000.000.000.000.000
#1 septilyon 1.000.000.000.000.000.000.000.000
#1 oktilyon  1.000.000.000.000.000.000.000.000.000
#1 nobilyon  1.000.000.000.000.000.000.000.000.000.000
#1 desilyon  1.000.000.000.000.000.000.000.000.000.000.000

