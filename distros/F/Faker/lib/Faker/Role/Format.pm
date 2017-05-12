package Faker::Role::Format;

use Faker::Role;
use Faker::Function qw(confess);

with 'Faker::Role::Random';

our $VERSION = '0.12'; # VERSION

method format_lex_markers (STRING $string) {
    $string =~ s/\?/$self->random_letter/eg;

    return $string;
}

method format_line_markers (STRING $string) {
    $string =~ s/\\n/\n/g;

    return $string;
}

method format_number_markers (STRING $string = '###') {
    $string =~ s/\#/$self->random_digit/eg;
    $string =~ s/\%/$self->random_digit_not_zero/eg;

    return $string;
}

1;
