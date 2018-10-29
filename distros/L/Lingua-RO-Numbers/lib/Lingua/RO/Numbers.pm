package Lingua::RO::Numbers;

#
## See: http://ro.wikipedia.org/wiki/Sistem_zecimal#Denumiri_ale_numerelor
#

use utf8;
use strict;
use warnings;

require Exporter;
our @ISA       = qw(Exporter);
our @EXPORT_OK = qw(number_to_ro ro_to_number);

=encoding utf8

=head1 NAME

Lingua::RO::Numbers - Convert numeric values into their Romanian string equivalents and viceversa

=head1 VERSION

Version 0.22

=cut

our $VERSION = '0.22';

# Numbers => text
our %DIGITS;
@DIGITS{'0' .. '19'} = qw(
  zero unu doi trei patru cinci șase șapte opt nouă zece
  unsprezece
  doisprezece
  treisprezece
  paisprezece
  cincisprezece
  șaisprezece
  șaptesprezece
  optsprezece
  nouăsprezece
  );

# Text => numbers
our %WORDS;
@WORDS{map { _remove_diacritics($_) } values %DIGITS} = keys %DIGITS;
@WORDS{qw(o un doua cin sai ob)} = (1, 1, 2, 5, 6, 8);

# Colocvial
@WORDS{qw(unspe doispe treispe paispe cinspe cinsprezece saispe saptespe saptuspe optspe optuspe nouaspe)} =
  (11, 12, 13, 14, 15, 15, 16, 17, 17, 18, 18, 19);

# This array contains number greater than 99 and it's used to convert numbers into text
our @BIGNUMS = (
                {num => 10**2,  sg => 'suta',        pl => 'sute', fem => 1},
                {num => 10**3,  sg => 'mie',         pl => 'mii',  fem => 1},
                {num => 10**6,  sg => 'milion',      pl => 'milioane'},
                {num => 10**9,  sg => 'miliard',     pl => 'miliarde'},
                {num => 10**12, sg => 'bilion',      pl => 'bilioane'},
                {num => 10**15, sg => 'biliard',     pl => 'biliarde'},
                {num => 10**18, sg => 'trilion',     pl => 'trilioane'},
                {num => 10**21, sg => 'triliard',    pl => 'triliarde'},
                {num => 10**24, sg => 'cvadrilion',  pl => 'cvadrilioane'},
                {num => 10**27, sg => 'cvadriliard', pl => 'cvadriliarde'},
                {num => 'inf',  sg => 'inifinit',    pl => 'infinit'},
               );

# This hash is a reversed version of the above array and it's used to convert text into numbers
our %BIGWORDS = (map { $_->{sg} => $_->{num}, $_->{pl} => $_->{num} } @BIGNUMS);

# Change 'suta' to 'sută'
$BIGNUMS[0]{'sg'} = 'sută';

=head1 SYNOPSIS

 use Lingua::RO::Numbers qw(number_to_ro ro_to_number);
 print number_to_ro(315);
 # prints: 'trei sute cincisprezece'

 print ro_to_number('trei sute douazeci si cinci virgula doi');
 # prints: 325.2

=head1 DESCRIPTION

Lingua::RO::Numbers converts arbitrary numbers into human-readable
Romanian text and viceversa, converting arbitrary Romanian text
into its corresponding numerical value.

=head2 EXPORT

Nothing is exported by default.
Only the functions B<number_to_ro()> and B<ro_to_number()> are exportable.

=over

=item B<new(;%opt)>

Initialize an object.

    my $obj = Lingua::RO::Numbers->new();

is equivalent with:

    my $obj = Lingua::RO::Numbers->new(
                      diacritics          => 1,
                      invalid_number      => undef,
                      negative_sign       => 'minus',
                      decimal_point       => 'virgulă',
                      thousands_separator => '',
                      infinity            => 'infinit',
                      not_a_number        => 'NaN',
              );

=item B<number_to_ro($number)>

Converts a number to its Romanian string representation.

  # Functional oriented usage
  $string = number_to_ro($number);
  $string = number_to_ro($number, %opts);

  # Object oriented usage
  my $obj = Lingua::RO::Numbers->new(%opts);
  $string = $obj->number_to_ro($number);

  # Example:
  print number_to_ro(98_765, thousands_separator => q{,});
    #=> 'nouăzeci și opt de mii, șapte sute șaizeci și cinci'

=item B<ro_to_number($text)>

Converts a Romanian text into its numeric value.

  # Functional oriented usage
  $number = ro_to_number($text);
  $number = ro_to_number($text, %opts);

  # Object oriented usage
  my $obj = Lingua::RO::Numbers->new(%opts);
  $number = $obj->ro_to_number($text);

  # Example:
  print ro_to_number('patruzeci si doi');  #=> 42

=back

=cut

sub new {
    my ($class, %opts) = @_;

    my $self = bless {
                      diacritics          => 1,
                      invalid_number      => undef,
                      negative_sign       => 'minus',
                      decimal_point       => 'virgulă',
                      thousands_separator => '',
                      infinity            => 'infinit',
                      not_a_number        => 'NaN',
                     }, $class;

    foreach my $key (keys %{$self}) {
        if (exists $opts{$key}) {
            $self->{$key} = delete $opts{$key};
        }
    }

    foreach my $invalid_key (keys %opts) {
        warn "Invalid option: <$invalid_key>";
    }

    return $self;
}

# This function it's an interface to a private function
# which converts a mathematical number into its Romanian equivalent text.
sub number_to_ro {
    my ($self, $number, %opts);

    if (ref $_[0] eq __PACKAGE__) {
        ($self, $number) = @_;
    }
    else {
        ($number, %opts) = @_;
        $self = __PACKAGE__->new(%opts);
    }

    my $word_number = $self->_number_to_ro($number + 0);

    if (not $self->{diacritics}) {
        $word_number = _remove_diacritics($word_number);
    }

    # Return the text-number
    $word_number;
}

# This function it's an interface to a private function
# which converts a Romanian text-number into its mathematical value.
sub ro_to_number {
    my ($self, $text, %opts);

    if (ref $_[0] eq __PACKAGE__) {
        ($self, $text) = @_;
    }
    else {
        ($text, %opts) = @_;
        $self = __PACKAGE__->new(%opts);
    }

    (    # Decode the text unless it is already UTF-8
       $] >= 5.0080001 ? utf8::is_utf8($text) : do {
           require Encode;
           Encode::is_utf8($text);
         }
    )
      || do {
        require Encode;
        $text = Encode::decode_utf8($text);
      };

    # Return the number
    $self->_ro_to_number($text);
}

# This function removes the Romanian diacritics from a given text.
sub _remove_diacritics {
    my ($text) = @_;
    $text =~ tr{ăâșțî}{aasti};
    $text;
}

# This functions removes irrelevant characters from a text
sub _normalize_text {

    # Lowercase and remove the diacritics
    my $text = _remove_diacritics(lc(shift));

    # Replace irrelevant characters with a space
    $text =~ tr/a-z / /c;

    # Return the normalized text
    $text;
}

# This function adds together a list of numbers
sub _add_numbers {
    my (@nums) = @_;

    my $num = 0;
    while (defined(my $i = shift @nums)) {

        # When the current number is lower than the next number
        if (@nums and $i < $nums[0]) {
            my $n = shift @nums;

            # This is a special case, where: int(log(1000)/log(10)) == 2
            my $l = log($n) / log(10);
            if (length($l) == length(int($l))) {
                $l = sprintf('%.0f', $l);
            }

            # Factor (e.g.: 400 -> 4)
            my $f = int($i / (10**int(log($i) / log(10))));

            # When the next number is not really next to the current number
            # e.g.: $i == 400 and $n == 5000 # should produce 405_000 not 45_000
            if ((my $mod = length($n) % 3) != 0) {
                $f *= 10**(3 - $mod);
            }

            # Join the numbers and continue
            $num += 10**int($l) * $f + $n;
            next;
        }

        $num += $i;
    }

    $num;
}

# This function converts a Romanian
# text-number into a mathematical number.
sub _ro_to_number {
    my ($self, $text) = @_;

    # When no text has been provided
    if (not defined $text) {
        return;
    }

    # If a thousand separator is defined, remove it from text
    if (defined($self->{thousands_separator}) and length($self->{thousands_separator})) {
        $text =~ s/\Q$self->{thousands_separator}\E/ /g;
    }

    # Split the text into words
    my @words = split(' ', _normalize_text($text));

    my $dec_point = _normalize_text($self->{decimal_point});
    my $neg_sign  = _normalize_text($self->{negative_sign});

    my @nums;    # numbers
    my @decs;    # decimal numbers

    my $neg  = 0;    # bool -- true when the number is negative
    my $adec = 0;    # bool -- true after the decimal point

    my $amount = 0;  # int -- current number
    my $factor = 1;  # int -- multiplication factor

    if (@words) {

        # Check for negative numbers
        if ($words[0] eq $neg_sign) {
            $neg = 1;
            shift @words;
        }

        # Check for infinity and NaN
        if (@words == 1) {

            # Infinity
            my $inf = _normalize_text($self->{infinity});
            if ($words[0] eq $inf) {
                return $neg ? -9**9**9 : 9**9**9;
            }

            # Not a number
            my $nan = _normalize_text($self->{not_a_number});
            if ($words[0] eq $nan) {
                return -sin(9**9**9);
            }
        }
    }

    # Iterate over the @words
    while (
        @words and (

            # It's a small number (lower than 100)
            do {
                $factor = exists($WORDS{$words[0]}) ? 1 : $words[0] =~ s/zeci\z// ? 10 : 0;
                $factor && do { $amount = shift @words };
                $factor;
            }

            # It's a big number (e.g.: milion)
            or @words && exists($BIGWORDS{$words[0]}) && do {
                $factor = $BIGWORDS{shift @words};
            }

            # Ignore invalid words
            or do {
                shift @words;
                next;
            }
        )
      ) {

        # Take and multiply the current number
        my $num =
          exists($WORDS{$amount})
          ? $WORDS{$amount} * $factor
          : next;    # skip invalid words

        # Check for some word-joining tokens
        if (@words) {
            if ($words[0] eq 'si') {    # e.g.: patruzeci si doi
                shift @words;
                $num += $WORDS{shift @words};
            }

            if (@words) {
                {
                    if ($words[0] eq 'de') {    # e.g.: o suta de mii
                        shift @words;
                    }

                    if (exists $BIGWORDS{$words[0]}) {
                        $num *= $BIGWORDS{shift @words};
                    }

                    if (@words && $words[0] eq 'de') {
                        redo;
                    }
                }
            }
        }

        # If we are after the decimal point, store the
        # numbers in @decs, otherwise store them in @nums.
        $adec ? push(@decs, $num) : push(@nums, $num);

        # Check for the decimal point
        if (@words and $words[0] eq $dec_point) {
            $adec = 1;
            shift @words;
        }
    }

    # Return undef when no number has been converted
    @nums || return;

    # Add all the numbers together (if any)
    my $num = _add_numbers(@nums);

    # If the number contains decimals,
    # add them at the end of the number
    if (@decs) {

        # Special case -- check for leading zeros
        my $zeros = '';
        while (@decs and $decs[0] == 0) {
            $zeros .= shift(@decs);
        }

        $num .= '.' . $zeros . _add_numbers(@decs);
    }

    # Return the number
    $neg ? -$num : $num + 0;
}

# This function converts numbers
# into their Romanian equivalent text.
sub _number_to_ro {
    my ($self, $number) = @_;

    my @words;
    if (exists $DIGITS{$number}) {    # example: 8
        push @words, $DIGITS{$number};
    }
    elsif (lc($number) eq 'nan') {    # not a number (NaN)
        return $self->{not_a_number};
    }
    elsif ($number == 9**9**9) {      # number is infinit
        return $self->{infinity};
    }
    elsif ($number < 0) {             # example: -43
        push @words, $self->{negative_sign};
        push @words, $self->_number_to_ro(abs($number));
    }
    elsif ($number != int($number)) {    # example: 0.123 or 12.43
        my $l = length($number) - 2;

        if ((length($number) - length(int $number) - 1) < 1) {    # special case
            push @words, $self->_number_to_ro(sprintf('%.0f', $number));
        }
        else {
            push @words, $self->_number_to_ro(int $number);
            push @words, $self->{decimal_point};

            $number -= int $number;

            until ($number == int($number)) {
                $number *= 10;
                $number = sprintf('%.*f', --$l, $number);         # because of imprecise multiplication
                push @words, $DIGITS{0} if $number < 1;
            }
            push @words, $self->_number_to_ro(int $number);
        }
    }
    elsif ($number >= $BIGNUMS[0]{num}) {                         # i.e.: >= 100
        foreach my $i (0 .. $#BIGNUMS - 1) {
            my $j = $#BIGNUMS - $i;

            if ($number >= $BIGNUMS[$j - 1]{num} && $number <= $BIGNUMS[$j]{num}) {
                my $cat = int $number / $BIGNUMS[$j - 1]{num};
                $number -= $BIGNUMS[$j - 1]{num} * int($number / $BIGNUMS[$j - 1]{num});

                my @of = $cat <= 2 ? () : do {
                    my @w = exists $DIGITS{$cat} ? $DIGITS{$cat} : ($self->_number_to_ro($cat), 'de');
                    if (@w > 2) {
                        $w[-2] = 'două' if $w[-2] eq $DIGITS{2};
                    }
                    @w;
                };

                if ($cat >= 100 && $cat < 1_000) {
                    my $rest = $cat - 100 * int($cat / 100);
                    if (@of and $rest != 0 and exists $DIGITS{$rest}) {
                        splice @of, -1;    # remove 'de'
                    }
                }

                push @words,
                    $cat == 1 ? ($BIGNUMS[$j - 1]{fem} ? 'o' : 'un', $BIGNUMS[$j - 1]{sg})
                  : $cat == 2 ? ('două', $BIGNUMS[$j - 1]{pl})
                  :             (@of, $BIGNUMS[$j - 1]{pl});

                if ($number > 0) {
                    $words[-1] .= $self->{thousands_separator} if $BIGNUMS[$j]{num} > 1_000;
                    push @words, $self->_number_to_ro($number);
                }

                last;
            }
        }
    }
    elsif ($number > 19 && $number < 100) {    # example: 42
        my $cat = int $number / 10;
        push @words, ($cat == 2 ? 'două' : $cat == 6 ? 'șai' : $DIGITS{$cat}) . 'zeci',
          ($number % 10 != 0 ? ('și', $DIGITS{$number % 10}) : ());
    }
    else {                                     # doesn't look like a number
        return $self->{invalid_number};
    }

    return wantarray ? @words : @words ? join(' ', @words) : ();
}

=head1 AUTHOR

Daniel Șuteu, C<< <trizen at protonmail.com> >>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Lingua::RO::Numbers

=head1 REPOSITORY

L<https://github.com/trizen/Lingua-RO-Numbers>

=head1 REFERENCES

L<http://ro.wikipedia.org/wiki/Sistem_zecimal#Denumiri_ale_numerelor>

=head1 LICENSE AND COPYRIGHT

Copyright 2013-2018 Daniel Șuteu.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1;    # End of Lingua::RO::Numbers

__END__
