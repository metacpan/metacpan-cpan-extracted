package Faker::Plugin::Software;

use 5.014;

use strict;
use warnings;

use registry;
use routines;

use Data::Object::Class;
use Data::Object::ClassHas;

extends 'Data::Object::Plugin';

our $VERSION = '1.04'; # VERSION

# ATTRIBUTES

has 'faker' => (
  is => 'ro',
  isa => 'ConsumerOf["Faker::Maker"]',
  req => 1,
);

# METHODS

method data_for_name() {
  [
    'Redhold',
    'Treeflex',
    'Trippledex',
    'Kanlam',
    'Bigtax',
    'Daltfresh',
    'Toughjoyfax',
    'Mat lam tam',
    'Otcom',
    'Tres-zap',
    'Y-solowarm',
    'Tresom',
    'Voltsillam',
    'Biodex',
    'Greenlam',
    'Viva',
    'Matsoft',
    'Temp',
    'Zoolab',
    'Subin',
    'Rank',
    'Job',
    'Stringtough',
    'Tin',
    'It',
    'Home ing',
    'Zamit',
    'Sonsing',
    'Konklab',
    'Alpha',
    'Latlux',
    'Voyatouch',
    'Alphazap',
    'Holdlamis',
    'Zaam-dox',
    'Sub-ex',
    'Quo lux',
    'Bamity',
    'Ventosanzap',
    'Lotstring',
    'Hatity',
    'Tempsoft',
    'Overhold',
    'Fixflex',
    'Konklux',
    'Zontrax',
    'Tampflex',
    'Span',
    'Namfix',
    'Transcof',
    'Stim',
    'Fix san',
    'Sonair',
    'Stronghold',
    'Fintone',
    'Y-find',
    'Opela',
    'Lotlux',
    'Ronstring',
    'Zathin',
    'Duobam',
    'Keylex'
  ]
}

method data_for_semver() {
  [
    '0.#.#',
    '#.#.#',
    '#.##.##'
  ]
}

method data_for_version() {
  [
    '#.##',
    '#.#',
    '#.#.#',
    '0.##',
    '0.#.#'
  ]
}

method format_for_author() {
  [
    '{{person.name}}',
    '{{company.name}}'
  ]
}

1;
