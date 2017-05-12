package Digital;
BEGIN {
  $Digital::AUTHORITY = 'cpan:GETTY';
}
# ABSTRACT: Handling conversion of digital values towards physical units
$Digital::VERSION = '0.002';
use strict;
use warnings;
use Package::Stash;
use Module::Runtime qw( use_module );

our %inputs;

sub register_input {
  my ( undef, $input, $input_class ) = @_;
  unless (defined $input_class) {
    $input_class = $input;
    $input = lc($input_class);
    $input =~ s!::!_!g;
    $input =~ s!^digitalx_!!g;
  }
  $inputs{$input} = $input_class;
}

sub input {
  my ( $class, $input, @args ) = @_;
  my $input_class = $inputs{$input};
  return $input_class->input(@args);
}

sub import {
  my ( $class, @args ) = @_;
  my ( $caller ) = caller;
  my $stash = Package::Stash->new($caller);
  my @classes;
  for (@args) { unless (/^-/) {
    push @classes, 'DigitalX::'.$_;
  } }
  for (@classes) {
    use_module($_);
  }
  $stash->add_symbol('&input', sub { return $class->input(@_) });
}

1;

__END__

=pod

=head1 NAME

Digital - Handling conversion of digital values towards physical units

=head1 VERSION

version 0.002

=head1 SYNOPSIS

Preparing L<Digital::Driver> class:

  package DigitalX::MyDriver;

  use Digital::Driver;

  to K => sub { ( ( $_ * 4.88 ) - 25 ) / 10 };
  overload_to C => sub { $_ - 273.15 }, 'K';
  to F => sub { ( $_ * ( 9 / 5 ) ) - 459.67 }, 'K';

  1;

Using driver class:

  use Digital qw( MyDriver );

  my $digi = input( mydriver => 613 );
  my $kelvin = $digi->K;  # 296.644
  my $celsius = $digi->C; #  23.494
  my $celsius = $digi+0;  # because of overload falls back to C

=head1 DESCRIPTION

=head1 SUPPORT

IRC

  Join #hardware on irc.perl.org. Highlight Getty for fast reaction :).

Repository

  https://github.com/homehivelab/p5-digital
  Pull request and additional contributors are welcome

Issue Tracker

  https://github.com/homehivelab/p5-digital/issues

=head1 AUTHOR

Torsten Raudssus <torsten@raudss.us>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
