# For Emacs: -*- mode:cperl; eval: (folding-mode 1); coding:utf-8; -*-

package Lingua::ENG::Num2Word;
# ABSTRACT: Number 2 word conversion for ENG.

use 5.16.0;
use utf8;
use warnings;

# {{{ use block

use base qw(Exporter);
use Carp;

use vars qw(
            @EXPORT_OK
            $VERSION

            $MODE

            %INPUT_GROUP_DELIMITER
            %INPUT_DECIMAL_DELIMITER
            %OUTPUT_BLOCK_DELIMITER
            %OUTPUT_GROUP_DELIMITER
            %OUTPUT_NUMBER_DELIMITER
            %OUTPUT_DECIMAL_DELIMITER

            %NUMBER_NAMES
            %SIGN_NAMES

            $TRUE
            $FALSE
            $SIGN_POSITIVE
            $SIGN_NEGATIVE
);

# }}}
# {{{ var block
our $VERSION = '0.2603270';

BEGIN {

    # Exporter Stuff
    @EXPORT_OK = qw(American British num2eng_cardinal num2eng_ordinal);

    # Constants
    $TRUE = 1;
    $FALSE = 0;
    $SIGN_POSITIVE = 1;
    $SIGN_NEGATIVE = -1;

    # Default Mode
    $MODE = "American";

    # Delimiters
    %OUTPUT_NUMBER_DELIMITER = (
        'American'   =>      ' ',
        'British'    =>      ' '
    );

    %OUTPUT_GROUP_DELIMITER = (
        'American'      =>      ' ',
        'British'       =>      ' '
    );

    %OUTPUT_BLOCK_DELIMITER = (
        'American'      =>      ', ',
        'British'       =>      ', '
    );

    %OUTPUT_DECIMAL_DELIMITER = (
        'American'      =>      'point ',
        'British'       =>      'point '
    );

    %INPUT_GROUP_DELIMITER = (
        'American'      =>      ',',
        'British'       =>      '.'
    );

    %INPUT_DECIMAL_DELIMITER = (
        'American'      =>      '.',
        'British'       =>      ','
    );

    # Low-Level Names
    %SIGN_NAMES = (
        'American'      =>      {
            $SIGN_POSITIVE  =>      '',
            $SIGN_NEGATIVE  =>      'Negative'
        },
        'British'       =>      {
            $SIGN_POSITIVE  =>      '',
            $SIGN_NEGATIVE  =>      'Negative'
        }
    );

    %NUMBER_NAMES = (
        'American'      =>      {
            0       =>      'zero',
            1       =>      'one',
            2       =>      'two',
            3       =>      'three',
            4       =>      'four',
            5       =>      'five',
            6       =>      'six',
            7       =>      'seven',
            8       =>      'eight',
            9       =>      'nine',
            10      =>      'ten',
            11      =>      'eleven',
            12      =>      'twelve',
            13      =>      'thirteen',
            14      =>      'fourteen',
            15      =>      'fifteen',
            16      =>      'sixteen',
            17      =>      'seventeen',
            18      =>      'eighteen',
            19      =>      'nineteen',
            20      =>      'twenty',
            30      =>      'thirty',
            40      =>      'forty',
            50      =>      'fifty',
            60      =>      'sixty',
            70      =>      'seventy',
            80      =>      'eighty',
            90      =>      'ninety',
            10**2   =>      'hundred',
            10**3   =>      'thousand',
            10**6   =>      'million',
            10**9   =>      'billion',
            10**12  =>      'trillion',
            10**15  =>      'quadrillion',
            10**18  =>      'quintillion',
            10**21  =>      'sextillion',
            10**24  =>      'septillion',
            10**27  =>      'octillion',
            10**30  =>      'nonillion',
            10**33  =>      'decillion',
            10**36  =>      'undecillion',
            10**39  =>      'duodecillion',
            10**42  =>      'tredecillion',
            10**45  =>      'quattuordecillion',
            10**48  =>      'quindecillion',
            10**51  =>      'sexdecillion',
            10**54  =>      'septendecillion',
            10**57  =>      'octodecillion',
            10**60  =>      'novemdecillion',
            10**63  =>      'vigintillion'
        },
        'British'       =>      {
            0       =>      'zero',
            1       =>      'one',
            2       =>      'two',
            3       =>      'three',
            4       =>      'four',
            5       =>      'five',
            6       =>      'six',
            7       =>      'seven',
            8       =>      'eight',
            9       =>      'nine',
            10      =>      'ten',
            11      =>      'eleven',
            12      =>      'twelve',
            13      =>      'thirteen',
            14      =>      'fourteen',
            15      =>      'fifteen',
            16      =>      'sixteen',
            17      =>      'seventeen',
            18      =>      'eighteen',
            19      =>      'nineteen',
            20      =>      'twenty',
            30      =>      'thirty',
            40      =>      'forty',
            50      =>      'fifty',
            60      =>      'sixty',
            70      =>      'seventy',
            80      =>      'eighty',
            90      =>      'ninety',
            10**2   =>      'hundred',
            10**3   =>      'thousand',
            10**6   =>      'million',
            10**9   =>      'milliard',
            10**12  =>      'billion',
            10**15  =>      'billiard',
            10**18  =>      'trillion',
            10**21  =>      'trilliard',
            10**24  =>      'quadrillion',
            10**27  =>      'quadrilliard',
            10**30  =>      'quintillion',
            10**33  =>      'quintilliard',
            10**36  =>      'sextillion',
            10**39  =>      'sextilliard',
            10**42  =>      'septillion',
            10**45  =>      'septilliard',
            10**48  =>      'octillion',
            10**51  =>      'octilliard',
            10**54  =>      'nonillion',
            10**57  =>      'nonilliard',
            10**60  =>      'decillion',
            10**63  =>      'decilliard'
        }
    );
}

# }}}

# Exporter Routines
# {{{ import

sub import {
    my $module = shift;
    my @args   = @_;

    # Separate mode tags from export requests
    my @exports;
    my $mode_set = 0;
    for my $arg (@args) {
        if ($arg eq 'American' || $arg eq 'British') {
            $MODE     = $arg;
            $mode_set = 1;
        }
        elsif ($arg) {
            push @exports, $arg;
        }
    }

    # Default to American if no mode was specified
    $MODE //= 'American';

    # Delegate function exports to Exporter
    if (@exports) {
        $module->export_to_level(1, $module, @exports);
    }

    return;
}

# }}}

# Math Routines
# {{{ pow10Block

sub pow10Block {
    my ($number) = @_;
    if ($number) {
        return (int(pow10($number) / 3) * 3);
    }
    else {
        return 0;
    }
}

# }}}
# {{{ pow10

sub pow10 {
    my ($number) = @_;
    return (length $number) - 1;
}

# }}}

# Numeric String Parsing Routines
# {{{ string_to_number

sub string_to_number {
    my $numberString = shift // return '';

    # Strip out delimiters
    $numberString =~ s/\Q$INPUT_GROUP_DELIMITER{$MODE}\E//g;

    my $sign = $SIGN_POSITIVE;
    if ($numberString =~ /^-/) {
        $numberString =~ s/^-//;
        $sign = $SIGN_NEGATIVE;
    }

    if (length($numberString)>1) { ### VSM 0.02 - Solve zero case
        $numberString =~ s/^0+//g;
    }

    my $number = '';
    my $decimal = '';
    if ($numberString =~ /(^.+)\Q$INPUT_DECIMAL_DELIMITER{$MODE}\E(.+$)/) {
        ($number, $decimal) = ($1, $2);
    }
    else {
        $number = $numberString;
    }

    if ($number =~ /\D/) {
        return ();
    }
    if ($decimal && ($decimal =~ /\D/)) {
        return ();
    }

    return ($number, $decimal, $sign);
}

# }}}
# {{{ parse_number

sub parse_number {
    my $number = shift;

    if (! defined $number) { # VSM 0.02 - Number zero is not a valid condition
        return { '0' => $NUMBER_NAMES{$MODE}{0} };
    }

    my %names;
    my $powerOfTen = pow10Block($number);
    while ($powerOfTen > 0) {
        my $factor     = int($number / 10**$powerOfTen);
        my $component  = $factor * 10**$powerOfTen;
        my $magnitude  = $NUMBER_NAMES{$MODE}{10**$powerOfTen};
        my $factorName = &parse_number_low($factor);

        $names{$component}{'factor'}    = $factorName;
        $names{$component}{'magnitude'} = $magnitude;

        $number -= $component;
        $powerOfTen = pow10Block($number);
    }

    if (defined $number) { # VSM 0.02 - Number zero is not a valid condition
        $names{'1'}{'factor'} = &parse_number_low($number);
        $names{'1'}{'magnitude'} = '';
    }

    return \%names;
}

# }}}
# {{{ parse_number_low

sub parse_number_low {
    my $number = shift;

    my @names = ();

    if ($number >= 100) {
        my $hundreds = int($number / 10**2);
        push @names, [ $NUMBER_NAMES{$MODE}{$hundreds}, $NUMBER_NAMES{$MODE}{10**2} ];
        $number -= $hundreds * 10**2;
    }

    if ($number >= 20) {
        my $tens = int($number / 10**1) * 10**1;
        my $ones = $number - $tens;

        if ($ones) {
            push @names, [ $NUMBER_NAMES{$MODE}{$tens} , $NUMBER_NAMES{$MODE}{$ones} ];
        }
        else {
            push @names, [ $NUMBER_NAMES{$MODE}{$tens} ];
        }
    }
    else {
        push @names, [ $NUMBER_NAMES{$MODE}{$number} ];
    }

    return \@names;
}

# }}}

# Class Methods
# {{{ new

sub new {
    my ($class, @initializer) = @_;

    if (! defined $class || ! $class) {
        return ();
    }

    my $self = {};
    bless $self, $class;

    if (@initializer) {
        $self->parse(@initializer);
    }

    return $self;
}

# }}}
# {{{ do_get_string

sub do_get_string {
    my ($self, $block) = @_;

    if (! defined $self || ! $self) {
        return '';
    }

    if (! defined $block || ! $block) {
        return '';
    }

    my @blockStrings;
    my $number = $self->{'string_data'}{$block};
    for my $component( sort {$b <=> $a } keys %{$number} ) {
        my $magnitude = $$number{$component}{'magnitude'};
        my $factor    = $$number{$component}{'factor'};

        my @strings;
        map { push @strings, join($OUTPUT_NUMBER_DELIMITER{$MODE}, @{$_}) } @{$factor};

        my $string = join($OUTPUT_GROUP_DELIMITER{$MODE}, @strings) . ' ' . $magnitude;
        push @blockStrings, $string;
    }

    my $blockString = join($OUTPUT_BLOCK_DELIMITER{$MODE}, @blockStrings);
    $blockString =~ s{(?<=.),?\s?Zero}{}xmsig;

    return $blockString;
}

# }}}
# {{{ parse

sub parse {
    my ($self, $numberString) = @_;

    if ( $numberString && $numberString =~ m{\A\d+\.?\d*?e\+\d+\z}xms ) {
      croak q{You shouldn't use scientific notation};
    }

    croak 'You should specify a number from interval [0, 10^66)'
        if    !defined $numberString
           || $numberString !~ m{\A\d+\z}xms
           || $numberString < 0
           || $numberString >= 10 ** 66;

    if (! defined $self || ! $self) {
        return $FALSE;
    }

    my ($number, $decimal, $sign) = &string_to_number($numberString);

    $self->{'numeric_data'}{'number'}  = $number;
    $self->{'numeric_data'}{'decimal'} = $decimal;
    $self->{'numeric_data'}{'sign'}    = $sign;

    if (defined $number && length($number)>0) { # VSM 0.02 - Number zero is not a valid condition
        $self->{'string_data'}{'number'} = &parse_number($number);
        $self->{'string_data'}{'sign'} = $SIGN_NAMES{$MODE}{$sign};
    }

    if (defined $decimal && $decimal) {
        $self->{'string_data'}{'decimal'} = &parse_number($decimal);
    }

    return $TRUE;
}

# }}}
# {{{ get_string

sub get_string {
    my ($self) = @_;

    if (! defined $self || ! $self) {
        return '';
    }

    my @strings;
    push @strings, $self->do_get_string('number');

    if ($self->{'string_data'}{'decimal'}) {
        push @strings, $self->do_get_string('decimal');
    }

    my $string = join($OUTPUT_DECIMAL_DELIMITER{$MODE}, @strings);
    if ($self->{'string_data'}{'sign'}) {
        $string = $self->{'string_data'}{'sign'} . " $string";
    }

    $string =~ s/\s+$//;

    return $string;
}

# }}}


# {{{ _cardinal_to_ordinal       convert cardinal last-word to ordinal

my %ORDINAL_IRREGULAR = (
    one    => 'first',
    two    => 'second',
    three  => 'third',
    five   => 'fifth',
    eight  => 'eighth',
    nine   => 'ninth',
    twelve => 'twelfth',
);

sub _cardinal_to_ordinal {
    my ($cardinal) = @_;

    return $cardinal if !defined $cardinal || $cardinal eq '';

    # Split on last space to isolate the final word (which may be hyphenated)
    my $prefix    = '';
    my $last_word = $cardinal;
    if ($cardinal =~ m{\A(?<prefix>.+)\s(?<last>\S+)\z}xms) {
        $prefix    = "$+{prefix} ";
        $last_word = $+{last};
    }

    # The last word may be hyphenated (e.g. "twenty one")
    # Actually this module uses spaces, not hyphens, but handle both
    my $hyph_prefix = '';
    my $final       = $last_word;
    if ($last_word =~ m{\A(?<hp>.+-)(?<fin>[^-]+)\z}xms) {
        $hyph_prefix = $+{hp};
        $final       = $+{fin};
    }

    my $ordinal_final;
    if (exists $ORDINAL_IRREGULAR{$final}) {
        $ordinal_final = $ORDINAL_IRREGULAR{$final};
    }
    elsif ($final =~ s{y\z}{ieth}xms) {
        # twenty -> twentieth, thirty -> thirtieth, etc.
        $ordinal_final = $final;
    }
    else {
        $ordinal_final = $final . 'th';
    }

    return $prefix . $hyph_prefix . $ordinal_final;
}

# }}}
# {{{ num2eng_ordinal            number to English ordinal string

sub num2eng_cardinal {
    my $number = shift;
    my $obj = Lingua::ENG::Num2Word->new($number);
    return $obj->get_string;
}

sub num2eng_ordinal {
    my ($number) = @_;

    my $obj = Lingua::ENG::Num2Word->new($number);
    my $cardinal = $obj->get_string;

    return _cardinal_to_ordinal($cardinal);
}

# }}}
# {{{ capabilities              declare supported features

sub capabilities {
    return {
        cardinal => 1,
        ordinal  => 1,
    };
}

# }}}
1;

__END__

=head1 NAME

Lingua::ENG::Num2Word - Converts numeric values into their English string equivalents.

=head1 VERSION

version 0.2603270

=head1 SYNOPSIS

        ## EXAMPLE 1

        use Lingua::ENG::Num2Word qw(American);

        $n = new Lingua::ENG::Num2Word(313721.23);
        if (defined $n) {
                $s = $n->get_string;
                print "$s\n";
        }

        ## EXAMPLE 2

        use Lingua::ENG::Num2Word;

        $n = new Lingua::ENG::Num2Word;
        $n->parse(-1281);
        print "N = " . $n->get_string . "\n";

        ## EXAMPLE 3 - Ordinal numbers

        use Lingua::ENG::Num2Word qw(American num2eng_ordinal);

        print num2eng_ordinal(1),   "\n";   # first
        print num2eng_ordinal(21),  "\n";   # twenty first
        print num2eng_ordinal(100), "\n";   # one hundredth

=head1 REQUIRES

Perl 5, Exporter, Carp

=head1 DESCRIPTION

Number 2 word conversion for ENG.

Lingua::ENG::Num2Word converts arbitrary numbers into human-oriented
English text. Limited support is included for parsing standardly
formatted numbers (i.e. '3,213.23'). But no attempt has been made to
handle any complex formats. Support for multiple variants of English
are supported. Currently only "American" formatting is supported.

To use the class, an instance is generated. The instance is then loaded
with a number. This can occur either during construction of the instance
or later, via a call to the B<parse> method. The number is then analyzed
and parsed into the english text equivalent.

The instance, now initialized, can be converted into a string, via the
B<get_string> method. This method takes the parsed data and converts
it from a data structure into a formatted string. Elements of the string's
formatting can be tweaked between calls to the B<get_string> function.
While such changes are unlikely, this has been done simply to provide
maximum flexibility.

=head1 EXPORTABLE FUNCTIONS

=over 4

=item num2eng_ordinal($number)

Converts a non-negative integer to its English ordinal form.
Handles irregular ordinals (first, second, third, fifth, eighth, ninth,
twelfth) and regular suffixing (fourth, sixth, twentieth, etc.).

    num2eng_ordinal(1)   # 'first'
    num2eng_ordinal(5)   # 'fifth'
    num2eng_ordinal(21)  # 'twenty first'
    num2eng_ordinal(100) # 'one hundredth'

=back

=head1 METHODS

=head2 Creation

=over 4

=item new Lingua::ENG::Num2Word $numberString

Creates, optionally initializes, and returns a new instance.

=back

=head1 INTERNAL FUNCTIONS

=over

=item _cardinal_to_ordinal

=item capabilities

=item do_get_string

=item logn

=item log10

=item parse_number

=item parse_number_low

=item pow10

=item pow10Block

=item string_to_number

=back

=head2 Initialization

=over 4

=item $number->parse $numberString

Parses a number and (re)initializes an instance.
Only a number from interval [0, 10^66) can be converted.

=back

=head2 Output

=over 4

=item $number->get_string

Returns a formatted string based on the most recent B<parse>.

=back

=head1 CLASS VARIABLES

=over 4

=item $Lingua::ENG::Num2Word::VERSION

The version of this class.

=item $Lingua::ENG::Num2Word::MODE

The current locale mode. Currently only B<American> is supported.

=item %Lingua::ENG::Num2Word::INPUT_GROUP_DELIMITER

The delimiter which separates number groups.
B<Example:> "1B<,>321B<,>323" uses the comma 'B<,>' as the group delimiter.

=item %Lingua::ENG::Num2Word::INPUT_DECIMAL_DELIMITER

The delimiter which separates the main number from its decimal part.
B<Example:> "132B<.>2" uses the period 'B<.>' as the decimal delimiter.

=item %Lingua::ENG::Num2Word::OUTPUT_BLOCK_DELIMITER

A character used at output time to convert the number into a string.
B<Example:> One Thousand, Two-Hundred and Twenty-Two point Four.
Uses the space character ' ' as the block delimiter.

=item %Lingua::ENG::Num2Word::OUTPUT_GROUP_DELIMITER

A character used at output time to convert the number into a string.
B<Example:> One ThousandB<,> Two-Hundred and Twenty-Two point Four.
Uses the comma 'B<,>' character as the group delimiter.

=item %Lingua::ENG::Num2Word::OUTPUT_NUMBER_DELIMITER

A character used at output time to convert the number into a string.
B<Example:> One Thousand, TwoB<->Hundred and TwentyB<->Two point Four.
Uses the dash 'B<->' character as the number delimiter.

=item %Lingua::ENG::Num2Word::OUTPUT_DECIMAL_DELIMITER

A character used at output time to convert the number into a string.
B<Example:> One Thousand, Two-Hundred and Twenty-Two B<point> Four.
Uses the 'point' string as the decimal delimiter.

=item %Lingua::ENG::Num2Word::NUMBER_NAMES

A list of names for numbers.

=item %Lingua::ENG::Num2Word::SIGN_NAMES

A list of names for positive and negative signs.

=item $Lingua::ENG::Num2Word::SIGN_POSITIVE

A constant indicating the current number is positive.

=item $Lingua::ENG::Num2Word::SIGN_NEGATIVE

A constant indicating the current number is negative.

=back

=head1 DIAGNOSTICS

=over 4

=item Error: Lingua::ENG::Num2Word does not support tag: '$tag'.

(F) The module has been invoked with an invalid locale.

=item Error: bad number format: '$number'.

(F) The number specified is not in a valid numeric format.

=item Error: bad number format: '.$number'.

(F) The decimal portion of number specified is not in a valid numeric format.

=back

=head1 AUTHORS

 initial coding:
   Stephen Pandich E<lt>pandich@yahoo.comE<gt>
 specification, maintenance:
   Richard C. Jelinek E<lt>rj@petamem.comE<gt>
 maintenance, coding (2025-present):
   PetaMem AI Coding Agents

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as the Artistic License 2.0 or the BSD 2-Clause
License. See the LICENSE file in the distribution for details.

=cut
