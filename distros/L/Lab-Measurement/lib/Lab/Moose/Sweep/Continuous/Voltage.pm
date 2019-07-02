package Lab::Moose::Sweep::Continuous::Voltage;
$Lab::Moose::Sweep::Continuous::Voltage::VERSION = '3.682';
#ABSTRACT: Continuous sweep of voltage


use 5.010;
use Moose;
use Carp;
use Time::HiRes 'time';

extends 'Lab::Moose::Sweep::Continuous';

has filename_extension => ( is => 'ro', isa => 'Str', default => 'Voltage=' );

__PACKAGE__->meta->make_immutable();
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Lab::Moose::Sweep::Continuous::Voltage - Continuous sweep of voltage

=head1 VERSION

version 3.682

=head1 SYNOPSIS

 use Lab::Moose;

 # FIXME

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by the Lab::Measurement team; in detail:

  Copyright 2018       Simon Reinhardt


This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
