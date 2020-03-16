package Faker::Process;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Role;

requires 'plugin';
requires 'throw';

method format_lex_markers(Str $string) {
  $string =~ s/\?/$self->random_letter/eg;

  return $string;
}

method format_line_markers(Str $string) {
  $string =~ s/\\n/\n/g;

  return $string;
}

method format_number_markers(Str $string = '###') {
  $string =~ s/\#/$self->random_digit/eg;
  $string =~ s/\%/$self->random_digit_not_zero/eg;

  return $string;
}

method parse_format(Str $string = '') {
  $string =~ s/\{\{\s?([#\.\w]+)\s?\}\}/$self->process_format($1)/eg;

  return $string;
}

method process(Tuple[Str, Str] $lookup, Maybe[HashRef[Int]] $options) {
  my $string;

  $string = $self->process_lookup($lookup);

  if ($options->{all_markers}) {
    $string = $self->process_markers($string);
  }
  if ($options->{lex_markers}) {
    $string = $self->format_lex_markers($string);
  }
  if ($options->{line_markers}) {
    $string = $self->format_line_markers($string);
  }
  if ($options->{number_markers}) {
    $string = $self->format_number_markers($string);
  }

  return $string;
}

method process_format(Str $token) {
  my ($source, $content) = split /[#\.]/, $token;

  my $plugin = $self->plugin($source, faker => $self);

  return $plugin->$content if $plugin->can($content);

  return $self->process_lookup([$source, $content]);
}

method process_lookup(Tuple[Str, Str] $lookup) {
  my ($source, $datatype) = @$lookup;

  my @samples = (
    $datatype,
    "data_for_${datatype}",
    "format_for_${datatype}"
  );

  my $plugin = $self->plugin($source, faker => $self);

  for my $sample (@samples) {
    $plugin->can($sample) or next;

    my $content = $plugin->$sample;
    my $format = $content->[rand @$content];

    $format = join ' ', @$format if ref $format eq 'ARRAY';

    return $self->parse_format($format);
  }

  $plugin = $self->plugin("${source}_${datatype}", faker => $self);

  return $plugin->execute;
}

method process_markers(Str $string = '') {
  my @markers = qw(
    lex_markers
    line_markers
    number_markers
  );

  for my $marker (@markers) {
    my $filter = "format_${marker}";

    $string = $self->$filter($string);
  }

  return $string;
}

method random_between(Maybe[Int] $from, Maybe[Int] $to) {
  my $max = 2147483647;

  $from = 0 if !$from || $from > $max;
  $to = $max if !$to || $to > $max;

  return $from + int rand($to - $from);
}

method random_digit() {

  return int rand(10);
}

method random_digit_not_zero() {

  return 1 + int rand(8);
}

method random_float(Maybe[Int] $place, Maybe[Int] $min, Maybe[Int] $max) {
  my $min = shift // 0;
  my $max = shift // $self->random_number;
  my $tmp; $tmp = $min and $min = $max and $max = $tmp if $min > $max;

  $place //= $self->random_digit;

  return sprintf "%.${place}f", $min + rand() * ($max - $min);
}

method random_item(ArrayRef | HashRef $items) {
  return $self->random_array_item($items) if 'ARRAY' eq ref $items;

  return $self->random_hash_item($items) if 'HASH'  eq ref $items;

  return undef;
}

method random_array_item(ArrayRef $items) {

  return $items->[$self->random_between(0, $#{$items})];
}

method random_hash_item(HashRef $items) {

  return $items->{$self->random_item([keys %$items])};
}

method random_letter() {

  return chr $self->random_between(97, 122);
}

method random_number(Maybe[Int] $from, Maybe[Int] $to) {
  $to //= 0;
  $from //= $self->random_digit;

  return $self->random_between($from, $to) if $to;

  return int rand 10 ** $from - 1;
}

1;
