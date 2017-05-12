package Dist::Zooky::Role::DistIni;
$Dist::Zooky::Role::DistIni::VERSION = '0.22';
# ABSTRACT: role for DistIni plugins

use strict;
use warnings;
use Moose::Role;

with 'Dist::Zilla::Role::TextTemplate';

has 'type' => (
  is => 'ro',
  isa => 'Str',
  required => 1,
);

has 'metadata' => (
  is => 'ro',
  isa => 'HashRef',
  required => 1,
);

requires 'content';

no Moose::Role;

qq[Gotta role];

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zooky::Role::DistIni - role for DistIni plugins

=head1 VERSION

version 0.22

=head1 AUTHOR

Chris Williams <chris@bingosnet.co.uk>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Chris Williams.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
