package FlightRecorder::Plugin::Report;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

our $VERSION = '0.01'; # VERSION

# ATTRIBUTES

has 'flight_recorder' => (
  is => 'ro',
  isa => 'InstanceOf["FlightRecorder"]',
  req => 1,
);

has level => (
  is => 'ro',
  isa => 'Enum[qw(debug info warn error fatal)]',
  def => 'debug'
);

has logs => (
  is => 'ro',
  isa => 'ArrayRef[HashRef]',
  new => 1
);

fun new_logs($self) {

  $self->flight_recorder->logs
}

# METHODS

method format() {
  my @template;

  push @template, '{item_timestamp}';
  push @template, '[{item_context}]';
  push @template, '@{item_level}';
  push @template, '[{item_process}]';
  push @template, '{item_message}';

  return join ' ', @template;
}

method generate() {
  my $logs = $self->logs;
  my $level = $self->level;
  my $source = $self->flight_recorder;
  my $levels = $source->levels;

  my @lines;

  for my $item (@$logs) {
    if ($$levels{$item->{level}} >= $$levels{$level}) {
      push @lines, $self->logline($item);
    }
  }

  return join "\n", @lines;
}

method item_dump(HashRef $item) {
  require Data::Dumper;

  no warnings 'once';

  local $Data::Dumper::Indent = 2;
  local $Data::Dumper::Pair = ': ';
  local $Data::Dumper::Purity = 0;
  local $Data::Dumper::Quotekeys = 0;
  local $Data::Dumper::Deepcopy = 0;
  local $Data::Dumper::Deparse = 0;
  local $Data::Dumper::Sortkeys = 1;
  local $Data::Dumper::Terse = 1;
  local $Data::Dumper::Useqq = 0;

  return Data::Dumper::Dumper($item);
}

method item_file(HashRef $item) {

  return $item->{file};
}

method item_line(HashRef $item) {

  return $item->{line};
}

method item_name(HashRef $item) {

  return $item->{name};
}

method item_context(HashRef $item) {

  return $item->{context};
}

method item_process(HashRef $item) {

  return $item->{process};
}

method item_package(HashRef $item) {

  return $item->{package};
}

method item_report(HashRef $item) {
  my @info;

  my $file = $self->item_file($item);
  my $line = $self->item_line($item);

  push @info, "In $file at line #$line", "";

  push @info, $self->item_dump({
    context => $self->item_name($item),
    message => $self->item_message($item)
  });

  return join "\n", @info;
}

method item_version(HashRef $item) {

  return $item->{version} || 'no-version';
}

method item_subroutine(HashRef $item) {

  return $item->{subroutine} || 'no-subroutine';
}

method item_timestamp(HashRef $item) {
  my $time = $item->{timestamp};

  return scalar(localtime($time));
}

method item_message(HashRef $item) {

  return $item->{message};
}

method item_level(HashRef $item) {

  return $item->{level};
}

method logline(HashRef $item) {
  my $format = $self->format;
  my @tokens = $format =~ m/\{(\w+)\}/g;

  $format =~ s/\{$_\}/$self->token($_, $item)/ge for @tokens;

  return $format;
}

method output() {

  say $self->generate;
}

method token(Str $name, HashRef $item) {
  return $self->$name($item) if $self->can($name);

  return "{$name}";
}

1;
