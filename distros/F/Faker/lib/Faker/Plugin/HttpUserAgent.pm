package Faker::Plugin::HttpUserAgent;

use 5.018;

use strict;
use warnings;

use Venus::Class 'base';

base 'Faker::Plugin';

use POSIX 'strftime';

# VERSION

our $VERSION = '1.19';

# METHODS

sub execute {
  my ($self, $data) = @_;

  my $faker = $self->faker;
  my $random = $faker->random;
  my $class = 'Mozilla';
  my $version = join '.', $random->range(5, 9), $random->range(0, 9);
  my $product = join '/', $class, $version;
  my $this_year = strftime '%Y', localtime;
  my $rand_year = $random->select([($this_year-20)..$this_year]);
  my $rand_month = sprintf('%.2d', $random->range(1, 12));
  my $rand_day = sprintf('%.2d', $random->range(1, 28));
  my $engine = join '/', 'Gecko', join('', $rand_year, $rand_month, $rand_day);
  my $platform = $random->select([
    ['Macintosh', ['Mac OS ##.#', 'Max OS X ##.#'], ['Chrome', 'Safari']],
    ['Windows', ['Windows ##.#', 'Windows NT ##.#'], ['Chrome', 'Edge', 'Firefox']],
    ['X11', ['Linux x86', 'Linux x86_64'], ['Chrome', 'Firefox']],
  ]);
  my $locale = $random->select([
    'cs-CZ',
    'da-DK',
    'de-DE',
    'en-GB',
    'en-US',
    'es-ES',
    'ja-JP',
    'nb-NO',
    'pl-PL',
    'pt-BR',
    'sv-SE',
    'tr-TR',
    'zh-CN',
    'zh-TW',
  ]);
  my $software = join ':', 'rv', $faker->software_version;
  my $os_name = $platform->[0];
  my $os_desc = $self->process_markers(
    $self->process_format($random->select($platform->[1]))
  );
  my $comment = sprintf('(%s)', join('; ', $os_name, 'U', $os_desc, $software));
  my $client = $random->select($platform->[2]);
  my $client_version = $faker->software_version;
  my $user_agent = "$product $comment $engine $os_name $client/$client_version";

  return $user_agent;
}

1;



=head1 NAME

Faker::Plugin::HttpUserAgent - HTTP User-Agent

=cut

=head1 ABSTRACT

HTTP User-Agent for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::HttpUserAgent;

  my $plugin = Faker::Plugin::HttpUserAgent->new;

  # bless(..., "Faker::Plugin::HttpUserAgent")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for HTTP user-agents.

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

The execute method returns a returns a random fake HTTP user-agent.

I<Since C<1.17>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::HttpUserAgent;

  my $plugin = Faker::Plugin::HttpUserAgent->new;

  # bless(..., "Faker::Plugin::HttpUserAgent")

  # my $result = $plugin->execute;

  # "Mozilla/6.1 (Windows; U; Windows NT 07.6; rv:0.4.5) ... Windows Firefox/4.4.3";

  # my $result = $plugin->execute;

  # "Mozilla/5.8 (Macintosh; U; Mac OS 58.2; rv:0.02) ... Macintosh Safari/0.5";

  # my $result = $plugin->execute;

  # "Mozilla/9.9 (Macintosh; U; Mac OS 58.9; rv:1.25) ... Macintosh Safari/0.6";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.17>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::HttpUserAgent;

  my $plugin = Faker::Plugin::HttpUserAgent->new;

  # bless(..., "Faker::Plugin::HttpUserAgent")

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