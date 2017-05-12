package Faker::Role::Random;

use Faker::Role;
use Faker::Function qw(confess);

our $VERSION = '0.12'; # VERSION

method random_between
(
    Maybe[INTEGER] $from,
    Maybe[INTEGER] $to
) {
    my $max = 2147483647;

    $from = 0    if !$from || $from > $max;
    $to   = $max if !$to   || $to   > $max;

    return $from + int rand($to - $from);
}

method random_digit () {
    return int rand(10);
}

method random_digit_not_zero () {
    return 1 + int rand(8);
}

method random_float
(
    Maybe[INTEGER] $place,
    Maybe[INTEGER] $min,
    Maybe[INTEGER] $max
) {
    my $min = shift // 0;
    my $max = shift // $self->random_number;
    my $tmp; $tmp = $min and $min = $max and $max = $tmp if $min > $max;

    $place //= $self->random_digit;

    return sprintf "%.${place}f", $min + rand() * ($max - $min);
}

method random_item (ARRAY|HASH $items) {
    return $self->random_array_item($items) if 'ARRAY' eq ref $items;
    return $self->random_hash_item($items)  if 'HASH'  eq ref $items;
    return undef;
}

method random_array_item (ARRAY $items) {
    return $items->[$self->random_between(0, $#{$items})];
}

method random_hash_item (HASH $items) {
    return $items->{$self->random_item([keys %$items])};
}

method random_letter {
    return chr $self->random_between(97, 122);
}

method random_number
(
    Maybe[INTEGER] $from,
    Maybe[INTEGER] $to
) {
    $to   //= 0;
    $from //= $self->random_digit;

    return $self->random_between($from, $to) if $to;
    return int rand 10 ** $from - 1;
}

1;
