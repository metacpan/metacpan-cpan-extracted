package Faker::Plugin::SoftwareName;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin';

# VERSION

our $VERSION = '1.19';

# METHODS

sub execute {
  my ($self, $data) = @_;

  return $self->faker->random->select(data_for_software_name());
}

sub data_for_software_name {
  state $software_name = [
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
    'Keylex',
  ]
}

1;



=head1 NAME

Faker::Plugin::SoftwareName - Software Name

=cut

=head1 ABSTRACT

Software Name for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::SoftwareName;

  my $plugin = Faker::Plugin::SoftwareName->new;

  # bless(..., "Faker::Plugin::SoftwareName")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for software name.

=encoding utf8

=cut

=head1 INHERITS

This package inherits behaviors from:

L<Faker::Plugin>

=cut

=head1 METHODS

This package provides the following methods:

=cut

=head2 execute

  execute(HashRef $data) (Str)

The execute method returns a returns a random fake software name.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::SoftwareName;

  my $plugin = Faker::Plugin::SoftwareName->new;

  # bless(..., "Faker::Plugin::SoftwareName")

  # my $result = $plugin->execute;

  # "Job";

  # my $result = $plugin->execute;

  # "Zamit";

  # my $result = $plugin->execute;

  # "Stronghold";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::SoftwareName;

  my $plugin = Faker::Plugin::SoftwareName->new;

  # bless(..., "Faker::Plugin::SoftwareName")

=back

=cut

=head1 AUTHORS

Awncorp, C<awncorp@cpan.org>

=cut

=head1 LICENSE

Copyright (C) 2000, Al Newkirk.

This program is free software, you can redistribute it and/or modify it under
the terms of the Apache license version 2.0.

=cut