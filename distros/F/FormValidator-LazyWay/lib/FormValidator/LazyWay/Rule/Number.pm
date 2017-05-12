package FormValidator::LazyWay::Rule::Number;

use strict;
use warnings;

sub range {
    my $num = shift;
    my $args = shift;

    return 0 if $num > $args->{max};
    return 0 if $num < $args->{min};

    return 1;
}
sub int {
    my $num = shift;
    return 1 if $num eq '0';
    return $num =~ /^[-+]?[1-9][0-9]*$/ ? 1 : 0 ;
}
sub uint {
    my $num = shift;
    return 1 if $num eq '0';
    return $num =~ /^[1-9][0-9]*$/ ? 1 : 0 ;
}

sub float {
    my $num = shift;
    return $num =~ /^[-+]?([1-9][0-9]*|0)(\.[0-9]+)?$/ ? 1 : 0 ;
}

sub ufloat {
    my $num = shift;
    return $num =~ /^([1-9][0-9]*|0)(\.[0-9]+)?$/ ? 1 : 0 ;
}

1;

=head1 NAME

FormValidator::LazyWay::Rule::Number - Number Rule

=head1 DESCRIPTION

=head1 METHOD

=head2 range

range

 Number#range :
    min : 3
    max : 10

=head2 int

integer

=head2 uint

unsigned integer

=head1 float

float

=head1 ufloat

unsigned float

=head1 AUTHOR

Tomohiro Teranishi <tomohiro.teranishi@gmail.com>

=cut
