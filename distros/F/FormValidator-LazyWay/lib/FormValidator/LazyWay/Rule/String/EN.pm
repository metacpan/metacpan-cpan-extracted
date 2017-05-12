package FormValidator::LazyWay::Rule::String::EN;

use strict;
use warnings;

sub length {
    'minimun $_[min] letters and maximum $_[max] letters',
}

sub string {
    'error',
}

sub ascii {
    'alphabet, number, simbol ',
}

sub nonsymbol_ascii {
    'alphabet, number',
}

sub alphabet {
    'alphabet',
}

sub number {
    'number',
}

1;

=head1 NAME

FormValidator::LazyWay::Rule::String::EN - Messages of String Rule

=head1 METHOD

=head2 length

=head2 string

=head2 ascii

=head2 nonsymbol_ascii

=head2 alphabet

=head2 number

=cut

