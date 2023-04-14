package Faker::Plugin::UserPassword;

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

  my $random = $self->faker->random;

  return $random->collect($random->range(12,20), 'character');
}

1;



=head1 NAME

Faker::Plugin::UserPassword - User Password

=cut

=head1 ABSTRACT

User Password for Faker

=cut

=head1 VERSION

1.19

=cut

=head1 SYNOPSIS

  package main;

  use Faker::Plugin::UserPassword;

  my $plugin = Faker::Plugin::UserPassword->new;

  # bless(..., "Faker::Plugin::UserPassword")

=cut

=head1 DESCRIPTION

This package provides methods for generating fake data for user password.

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

The execute method returns a returns a random fake user password.

I<Since C<1.10>>

=over 4

=item execute example 1

  package main;

  use Faker::Plugin::UserPassword;

  my $plugin = Faker::Plugin::UserPassword->new;

  # bless(..., "Faker::Plugin::UserPassword")

  # my $result = $plugin->execute;

  # "48R+a}[Lb?&0725";

  # my $result = $plugin->execute;

  # ",0w\$h4155>*0M";

  # my $result = $plugin->execute;

  # ")P2^'q695a}8GX";

=back

=cut

=head2 new

  new(HashRef $data) (Plugin)

The new method returns a new instance of the class.

I<Since C<1.10>>

=over 4

=item new example 1

  package main;

  use Faker::Plugin::UserPassword;

  my $plugin = Faker::Plugin::UserPassword->new;

  # bless(..., "Faker::Plugin::UserPassword")

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