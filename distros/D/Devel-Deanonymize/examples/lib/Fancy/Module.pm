package Fancy::Module;
use strict;
use warnings FATAL => 'all';
use experimental 'signatures';

use base 'Exporter';
our @EXPORT = qw(is_it_the_number is_the_sum_the_number);

my $anon = sub($number) {
    if ($number != 42) {
        my $sub_sub = sub($num) {
            return "No, it's not";
        };
        &{$sub_sub}($number);
    }
};

sub is_it_the_number($number) {
    if ($number == 42) {
        return "It is the number";
    }
    else {
        &{$anon}($number);
    }
}

sub is_the_sum_the_number($number1, $number2) {
    # extra complicated check
    if ($number1 > 42 or $number2 > 42) {
        return "No, its not";
    }
    elsif (($number2 == 42 or $number1 == 42) and ($number1 + $number2 == 0)) {
        return "It is the number";
    }
    elsif ($number1 + $number2 == 42) {
        return "It is the number"
    }
    else {
        &{$anon}($number1 + $number2);
    }

}

__END__