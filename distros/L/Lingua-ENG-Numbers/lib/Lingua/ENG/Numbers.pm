# For Emacs: -*- mode:cperl; mode:folding; coding:utf-8; -*-

package Lingua::ENG::Numbers;
# ABSTRACT: Number 2 word conversion for ENG.

# {{{ use block

use 5.10.1;
use strict;
use warnings;
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
# {{{ variables declaration

our $VERSION = 0.1106;

BEGIN {

    # Exporter Stuff
    @EXPORT_OK = qw(American British);

    # Constants
    $TRUE = 1;
    $FALSE = 0;
    $SIGN_POSITIVE = 1;
    $SIGN_NEGATIVE = -1;

    # Default Mode
    $MODE = "American";

    # Delimiters
    %OUTPUT_NUMBER_DELIMITER
        = (
           'American'   =>      '-',
           'British'    =>      '-'
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
                        0       =>      'Zero',
                        1       =>      'One',
                        2       =>      'Two',
                        3       =>      'Three',
                        4       =>      'Four',
                        5       =>      'Five',
                        6       =>      'Six',
                        7       =>      'Seven',
                        8       =>      'Eight',
                        9       =>      'Nine',
                        10      =>      'Ten',
                        11      =>      'Eleven',
                        12      =>      'Twelve',
                        13      =>      'Thirteen',
                        14      =>      'Fourteen',
                        15      =>      'Fifteen',
                        16      =>      'Sixteen',
                        17      =>      'Seventeen',
                        18      =>      'Eighteen',
                        19      =>      'Nineteen',
                        20      =>      'Twenty',
                        30      =>      'Thirty',
                        40      =>      'Fourty',
                        50      =>      'Fifty',
                        60      =>      'Sixty',
                        70      =>      'Seventy',
                        80      =>      'Eighty',
                        90      =>      'Ninety',
                        10**2   =>      'Hundred',
                        10**3   =>      'Thousand',
                        10**6   =>      'Million',
                        10**9   =>      'Billion',
                        10**12  =>      'Trillion',
                        10**15  =>      'Quadrillion',
                        10**18  =>      'Quintillion',
                        10**21  =>      'Sextillion',
                        10**24  =>      'Septillion',
                        10**27  =>      'Octillion',
                        10**30  =>      'Nonillian',
                        10**33  =>      'Decillion',
                        10**36  =>      'Undecillion',
                        10**39  =>      'Duodecillion',
                        10**42  =>      'Tredecillion',
                        10**45  =>      'Quattuordecillion',
                        10**48  =>      'Quindecillion',
                        10**51  =>      'Sexdecillion',
                        10**54  =>      'Septendecillion',
                        10**57  =>      'Octodecillion',
                        10**60  =>      'Novemdecillion',
                        10**63  =>      'Vigintillion'
                },
                'British'       =>      {
                        0       =>      'Zero',
                        1       =>      'One',
                        2       =>      'Two',
                        3       =>      'Three',
                        4       =>      'Four',
                        5       =>      'Five',
                        6       =>      'Six',
                        7       =>      'Seven',
                        8       =>      'Eight',
                        9       =>      'Nine',
                        10      =>      'Ten',
                        11      =>      'Eleven',
                        12      =>      'Twelve',
                        13      =>      'Thirteen',
                        14      =>      'Fourteen',
                        15      =>      'Fifteen',
                        16      =>      'Sixteen',
                        17      =>      'Seventeen',
                        18      =>      'Eighteen',
                        19      =>      'Nineteen',
                        20      =>      'Twenty',
                        30      =>      'Thirty',
                        40      =>      'Fourty',
                        50      =>      'Fifty',
                        60      =>      'Sixty',
                        70      =>      'Seventy',
                        80      =>      'Eighty',
                        90      =>      'Ninety',
                        10**2   =>      'Hundred',
                        10**3   =>      'Thousand',
                        10**6   =>      'Million',
                        10**9   =>      'Milliard',
                        10**12  =>      'Billion',
                        10**15  =>      'Billiard',
                        10**18  =>      'Trillion',
                        10**21  =>      'Trilliard',
                        10**24  =>      'Quadrillion',
                        10**27  =>      'Quadrilliard',
                        10**30  =>      'Quintillion',
                        10**33  =>      'Quintilliard',
                        10**36  =>      'Sextillion',
                        10**39  =>      'Sextilliard',
                        10**42  =>      'Septillion',
                        10**45  =>      'Septilliard',
                        10**48  =>      'Octillion',
                        10**51  =>      'Octilliard',
                        10**54  =>      'Nonillian',
                        10**57  =>      'Nonilliard',
                        10**60  =>      'Decillion',
                        10**63  =>      'Decilliard'
                }
        );
}

# }}}

# Exporter Routines
# {{{ import

sub import {
    my $module = shift;
    my $tag    = shift // 'American';
    if (($tag eq 'American') || ($tag eq 'British')) {
        $MODE = $tag;
    }
    else {
        croak "Error: $module does not support tag: '$tag'.\n"
            if ($tag);
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
    my ($number) = @_;

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
    my ($number) = @_;
    my @names;

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
    $blockString =~ s{(?<=.),?\s?Zero}{}xmsg;

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

1;

__END__

=head1 NAME

Lingua::ENG::Numbers - Converts numeric values into their English string equivalents.

=head1 VERSION

version 0.1106

=head1 SYNOPSIS

        ## EXAMPLE 1

        use Lingua::ENG::Numbers qw(American);

        $n = new Lingua::ENG::Numbers(313721.23);
        if (defined $n) {
                $s = $n->get_string;
                print "$s\n";
        }


        ## EXAMPLE 2

        use Lingua::ENG::Numbers;

        $n = new Lingua::ENG::Numbers;
        $n->parse(-1281);
        print "N = " . $n->get_string . "\n";



=head1 REQUIRES

Perl 5, Exporter, Carp


=head1 DESCRIPTION

Number 2 word conversion for ENG.

Lingua::ENG::Numbers converts arbitrary numbers into human-oriented
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
maximum flexability.


=head1 METHODS

=head2 Creation

=over 4

=item new Lingua::ENG::Numbers $numberString

Creates, optionally initializes, and returns a new instance.

=back

=head1 INTERNAL FUNCTIONS

=over

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

=item $Lingua::ENG::Numbers::VERSION

The version of this class.

=item $Lingua::ENG::Numbers::MODE

The current locale mode. Currently only B<American> is supported.

=item %Lingua::ENG::Numbers::INPUT_GROUP_DELIMITER

The delimiter which seperates number groups.
B<Example:> "1B<,>321B<,>323" uses the comma 'B<,>' as the group delimiter.

=item %Lingua::ENG::Numbers::INPUT_DECIMAL_DELIMITER

The delimiter which seperates the main number from its decimal part.
B<Example:> "132B<.>2" uses the period 'B<.>' as the decimal delimiter.

=item %Lingua::ENG::Numbers::OUTPUT_BLOCK_DELIMITER

A character used at output time to convert the number into a string.
B<Example:> One Thousand, Two-Hundred and Twenty-Two point Four.
Uses the space character ' ' as the block delimiter.

=item %Lingua::ENG::Numbers::OUTPUT_GROUP_DELIMITER

A character used at output time to convert the number into a string.
B<Example:> One ThousandB<,> Two-Hundred and Twenty-Two point Four.
Uses the comma 'B<,>' character as the group delimiter.

=item %Lingua::ENG::Numbers::OUTPUT_NUMBER_DELIMITER

A character used at output time to convert the number into a string.
B<Example:> One Thousand, TwoB<->Hundred and TwentyB<->Two point Four.
Uses the dash 'B<->' character as the number delimiter.

=item %Lingua::ENG::Numbers::OUTPUT_DECIMAL_DELIMITER

A character used at output time to convert the number into a string.
B<Example:> One Thousand, Two-Hundred and Twenty-Two B<point> Four.
Uses the 'point' string as the decimal delimiter.

=item %Lingua::ENG::Numbers::NUMBER_NAMES

A list of names for numbers.

=item %Lingua::ENG::Numbers::SIGN_NAMES

A list of names for positive and negative signs.

=item $Lingua::ENG::Numbers::SIGN_POSITIVE

A constant indicating the the current number is positive.

=item $Lingua::ENG::Numbers::SIGN_NEGATIVE

A constant indicating the the current number is negative.

=back


=head1 DIAGNOSTICS

=over 4

=item Error: Lingua::ENG::Numbers does not support tag: '$tag'.

(F) The module has been invoked with an invalid locale.

=item Error: bad number format: '$number'.

(F) The number specified is not in a valid numeric format.

=item Error: bad number format: '.$number'.

(F) The decimal portion of number specified is not in a valid numeric format.

=back


=head1 AUTHOR

Stephen Pandich, pandich@yahoo.com

Maintenance
PetaMem s.r.o. <info@petamem.com>
