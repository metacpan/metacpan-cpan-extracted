package Lingua::ID::Words2Nums;

our $DATE = '2015-09-03'; # DATE
our $VERSION = '0.17'; # VERSION

use 5.010001;
use strict;
use warnings;
#use Log::Any qw($log);

our %SPEC;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(words2nums words2nums_simple $Pat);

use Parse::Number::ID qw(parse_number_id);
use Scalar::Util qw(looks_like_number);

my %Digits = (
    nol => 0, kosong => 0, ksg => 0, ksng => 0,
    se => 1, satu => 1, st => 1,
    dua => 2,
    tiga => 3, tg => 3,
    empat => 4, pat => 4, ampat => 4, mpat => 4,
    lima => 5, lm => 5,
    enam => 6, nam => 6,
    tujuh => 7, tjh => 7,
    delapan => 8, dlpn => 8, lapan => 8,
    sembilan => 9, smbln => 9,
);

my %Small_Mults = (
    puluh => 1e1, plh => 1e1,
    lusin => 12,
    kodi => 20,
    ratus => 1e2, rts => 1e2,
    gros => 144, gross => 144,
    ribu => 1e3, rb => 1e3,
    juta => 1e6, jt => 1e6,
    milyar => 1e9, milyard => 1e9, miliar => 1e9, miliard => 1e9,
    triliun => 1e12, trilyun => 1e12,
);

my %Big_Mults = (
    # -yun / kw- / etc variants?
    kuadriliun => 1e15,
    kuintiliun => 1e18,
    sekstiliun => 1e21,
    septiliun => 1e24,
    oktiliun => 1e27,
    noniliun => 1e30,
    desiliun => 1e33,
    undesiliun => 1e36,
    duodesiliun => 1e39,
    tredesiliun => 1e42,
    kuatuordesiliun => 1e45,
    kuindesiliun => 1e48,
    seksdesiliun => 1e51,
    septendesiliun => 1e54,
    oktodesiliun => 1e57,
    novemdesiliun => 1e60,
    vigintiliun => 1e63,
    googol => 1e100, gugol => 1e100,
    sentiliun => 1e303,
);

my %Mults = (%Small_Mults, %Big_Mults);

my %Teen_Words = (
    belas => 0,
    bls => 0,
);

my %Words = (
    %Digits, %Mults, %Teen_Words,
);

# doesn't contain big multipliers (usually only used in scientific and not in
# daily common text)
my %Words2 = (
    %Digits, %Small_Mults, %Teen_Words,
);

my %Se = ("se" => 0, "s" => 0);

# words that can be used with se- (or single digit), e.g. sebelas, tiga belas,
# sepuluh, seratus, dua ratus, ...
my %Se_Words = (
    %Mults, %Teen_Words,
);

my %Se_Words2 = (
    %Small_Mults, %Teen_Words,
);

my $Pos_pat  = qr/(?:positif|plus|pos)/;
my $Neg_pat  = qr/(?:negatif|ngtf|min|minus|mns)/;
my $Exp_pat  = qr/(?:(?:di)?\s*(?:kali|kl)(?:kan)?\s+(?:sepuluh|splh)
                      \s+(?:pangkat|pkt|pngkt))/x;
my $Dec_pat  = qr/(?:koma|km|titik|ttk)/;
my $Teen_pat = "(?:".join("|", sort keys %Teen_Words).")";
my $Mult_pat = "(?:" . join("|", sort keys %Se_Words).")";
my $Se_pat   = "(?:" . join("|", sort keys %Se).")";
my $Se_Mult_pat = "(?:(?:" . join("|", sort keys %Se).")".
    "(?:" . join("|", sort keys %Se_Words) . "))";
my $Se_Mult_pat2 = "(?:(?:" . join("|", sort keys %Se).")".
    "(?:" . join("|", sort keys %Se_Words2) . "))";

# quick pattern for extracting words
# neg_pat? (num + mult)+
our $Pat = join(
    "",
    '(?:(?:', "\n",
    '  (?:', $Neg_pat, '\s*)?', " # opt: negative\n",
    '  (?:', '(?:', join("|", sort(keys(%Se),keys(%Digits))), ')|', $Parse::Number::ID::Pat, ')', " # num\n",
    '  (?:', '\s*', $Dec_pat, '\s*', '(?:', join("|", sort keys %Digits), '\s*)+', ')?', " # opt: decimal\n",
    '  (?:', '\s*', '(?:', join("|", sort keys %Small_Mults), ')', '){0,3}', " # opt: mult\n",
    '\s*)+)',
);
$Pat  = qr/$Pat/x;

$SPEC{words2nums} = {
    v => 1.1,
    summary => 'Convert Indonesian verbage to number',
    description => <<'_',

Parse Indonesian verbage and return number, or undef if failed (unknown verbage
or 'syntax error'). In English, this is equivalent to converting "one hundred
and twenty three" to 123. Currently can handle real numbers in normal and
scientific form in the order of hundreds of trillions.

Will produce unexpected result if you feed it stupid verbage.

_
    args => {
        str => {
            schema => 'str*',
            summary => 'The verbage to convert',
            req => 1,
            pos => 0,
        },
    },
    args_as => 'array',
    result_naked => 1,
};
sub words2nums($) { _handle_exp(@_) }

$SPEC{words2nums_simple} = {
    v => 1.1,
    summary => 'Like words2nums, but can only parse sequence of digits',
    description => <<'_',

In English, this is equivalent to converting "one two three" to 123.

Will produce unexpected result if you feed it stupid verbage.

_
    args => {
        str => {
            schema => 'str*',
            summary => 'The verbage to convert',
            req => 1,
            pos => 0,
        },
    },
    args_as => 'array',
    result_naked => 1,
};
sub words2nums_simple($) { _handle_simple(@_) }

sub _handle_exp($) {
    my $words = lc shift;
    my ($num1, $num2);

    if( $words =~ /(.+)\s+$Exp_pat\s+(.+)/ ) {
        #$log->trace("it's an exponent");
        $num1 = _handle_neg($1);
        $num2 = _handle_neg($2);
        #$log->trace("num1 is $num1, num2 is $num2");
        !defined($num1) || !defined($num2) and return undef;
        return $num1 * 10 ** $num2;
    } else {
        #$log->trace("not an exponent");
        $num1 = _handle_neg($words);
        not defined $num1 and return undef;
        #$log->trace("num1 = $num1");
        return $num1;
    }
}

sub _handle_neg($) {
    my $words = lc shift;
    my $num1;

    if( $words =~ /^\s*$Neg_pat\s+(.+)/ ) {
        #$log->trace("it's negative");
        $num1 = -_handle_dec($1);
        not defined $num1 and return undef;
        #$log->trace("num1 = $num1");
        return $num1;
    } elsif( $words =~ /^\s*$Pos_pat\s+(.+)/ ) {
        #$log->trace("it's positif");
        $num1 = _handle_dec($1);
        not defined $num1 and return undef;
        #$log->trace("num1 = $num1");
        return $num1;
    } else {
        #$log->trace("it's not negative");
        $num1 = _handle_dec($words);
        not defined $num1 and return undef;
        #$log->trace("num1 = $num1");
        return $num1;
    }
}

sub _handle_dec($) {
    my $words = lc shift;
    my ($num1, $num2);

    if( $words =~ /(.+)\s+$Dec_pat\s+(.+)/ ) {
        #$log->trace("it has decimals (\$1=$1, \$2=$2)");
        $num1 = _handle_int($1);
        $num2 = _handle_simple($2);
        #$log->trace("num1 is $num1, num2 is $num2");
        !defined($num1) || !defined($num2) and return undef;
        return $num1 + ("0.".$num2);
    } else {
        #$log->trace("it's an integer");
        $num1 = _handle_int($words);
        not defined $num1 and return undef;
        #$log->trace("num1 is $num1");
        return $num1;
    }
}


# handle words before decimal (e.g, 'seratus dua puluh tiga', ...)
sub _handle_int($) {
    my @words = &_split_it( lc shift );
    my ($num, $mult);
    my $seen_digits = 0;
    my ($w, $a, $subtot, $tot);
    my @nums = ();

    $words[0] eq 'ERR' and return undef;
    #$log->trace("the words are @words");

    for $w (@words) {
        if( defined $Digits{$w} ) { # digits (satuan)
            #$log->trace("saw a digit: $w");
            $seen_digits and do { push @nums, ((10 * (pop @nums)) + $Digits{$w}) }
                or do { push @nums, $Digits{$w}; $seen_digits = 1 }
        }

        elsif ( looks_like_number $w ) { # digits (satuan) as number
            #$log->trace("saw a number: $w");
            return undef if $seen_digits; # 1 <spc> 2 is considered an error
            push @nums, $w;
            $seen_digits = 1;
        }

        elsif( $w =~ /^$Teen_pat$/ ) { # special case, teens (belasan)
            #$log->trace("saw a teen: $w");
            return undef unless $seen_digits; # mistake in writing teens
            push @nums, 10 + pop @nums;
            $seen_digits = 0;
        }

        else{ # must be a multiplier, or unknown
            #$log->trace( "saw a multiplier: $w");
            return undef unless defined $Mults{$w}; # unknown word
            return undef unless @nums; # mistake in writing tens/multiplier

            $a = 0; $subtot = 0;
               do { $a = pop @nums; $subtot += $a }
            until ( $a > $Mults{$w} || !@nums );

            if( $a > $Mults{$w} ) { push @nums, $a; $subtot -= $a }
            push @nums, $Mults{$w}*$subtot;
             $seen_digits = 0;
        }
    }

    # calculate total
    $tot = 0;
    while( @nums ){ $tot += shift @nums }
    $tot;
}


# handle words after decimal (simple with no 'belas', 'puluh', 'ratus', ...)
sub _handle_simple($) {
    #$log->tracef("-> _handle_simple(%s)", \@_);
    my @words = &_split_it( lc shift );
    #$log->tracef("words = %s", \@words);
    my ($num, $w);

    $words[0] eq 'ERR' and return undef;

    $num = "";
    for $w (@words) {
        if (looks_like_number $w) {
            $num .= $w;
        } else {
            not defined $Digits{$w} and return undef;
            $num .= $Digits{$w};
        }
    }

    $num;
}


# split string into array of words. also splits 'sepuluh' -> (se, puluh),
# 'tigabelas' -> (tiga, belas), etc.
sub _split_it($) {
    my $words = lc shift;
    my @words = ();
    my $w;

    for $w (split /\s+/, $words) {
        ##$log->trace("saw $w");
        if ($w =~ /^([-+]?[0-9.,]+(?:[Ee][+-]?\d+)?)(\D?.*)$/) {
            my ($n0, $w2) = ($1, $2);
            #print "n0=$n0, w2=$w2\n";
            my $n = parse_number_id(text => $n0);
            unless (defined $n) {
                unshift @words, 'ERR';
                last;
            }
            push @words, $n;
            push @words, $w2 if length($w2);
        }
        elsif( $w =~ /^($Se_pat)($Mult_pat)$/ and defined $Words{$1} ) {
            #$log->trace("i should split $w");
            push @words, $1, $2 }
        elsif( $w =~ /^(.+)\s+($Mult_pat)$/ and defined $Words{$1} ) {
            #$log->trace("i should split $w");
            push @words, $1, $2 }
        elsif( defined $Words{$w} ) {
            push @words, $w }
        else {
            #$log->trace("i don't recognize $w");
            unshift @words, 'ERR';
            last;
        }
    }

    #use Data::Dump; dd \@words;
    @words;
}

1;
# ABSTRACT: Convert Indonesian verbage to number

__END__

=pod

=encoding UTF-8

=head1 NAME

Lingua::ID::Words2Nums - Convert Indonesian verbage to number

=head1 VERSION

This document describes version 0.17 of Lingua::ID::Words2Nums (from Perl distribution Lingua-ID-Words2Nums), released on 2015-09-03.

=head1 SYNOPSIS

 use Lingua::ID::Words2Nums qw(words2nums words2nums_simple);

 print words2nums("seratus tiga koma dua");  # 103.2
 print words2nums("minus 3 juta 100 ribu");  # 3100000
 print words2nums("1,605 jt");               # 1605000 (abbreviations accepted)
 print words2nums("-1.3e4");                 # 13000

 print words2nums_simple("satu dua tiga");   # 123

=head1 DESCRIPTION

This module provides two functions, B<words2nums> and B<words2nums_simple>. They
are the counterpart of L<Lingua::ID::Nums2Words>'s B<nums2words> and
B<nums2words_simple>.

=head1 FUNCTIONS


=head2 words2nums($str) -> any

Convert Indonesian verbage to number.

Parse Indonesian verbage and return number, or undef if failed (unknown verbage
or 'syntax error'). In English, this is equivalent to converting "one hundred
and twenty three" to 123. Currently can handle real numbers in normal and
scientific form in the order of hundreds of trillions.

Will produce unexpected result if you feed it stupid verbage.

Arguments ('*' denotes required arguments):

=over 4

=item * B<str>* => I<str>

The verbage to convert.

=back

Return value:  (any)


=head2 words2nums_simple($str) -> any

Like words2nums, but can only parse sequence of digits.

In English, this is equivalent to converting "one two three" to 123.

Will produce unexpected result if you feed it stupid verbage.

Arguments ('*' denotes required arguments):

=over 4

=item * B<str>* => I<str>

The verbage to convert.

=back

Return value:  (any)

=head1 EXPORTS

None are exported by default, but they are exportable.

=head2 $Pat (regex)

A regex for quickly matching/extracting number verbage from text; it looks for a
string of words. It's not perfect (improper verbage might be allowed, e.g. "dua
ribu tiga juta"), but it's convenient.

Currently only multipliers up to trillions ("triliun") are recognized. Bigger
multipliers are usually only found in scientific text.

=head1 SEE ALSO

L<Lingua::ID::Nums2Words>

L<Parse::Number::ID> is used to parse numbers in the verbage.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Lingua-ID-Words2Nums>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Lingua-ID-Words2Nums>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Lingua-ID-Words2Nums>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
