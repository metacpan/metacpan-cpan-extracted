package Pod::Weaver::PluginBundle::DBIO::Heritage;
# ABSTRACT: Pod::Weaver configuration for DBIO heritage distributions
our $VERSION = '0.900001';
use strict;
use warnings;


use parent 'Pod::Weaver::PluginBundle::DBIO';

sub mvp_bundle_config {
  my ($class, $args) = @_;
  $args->{payload}{heritage} = 1;
  return Pod::Weaver::PluginBundle::DBIO::mvp_bundle_config($class, $args);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Pod::Weaver::PluginBundle::DBIO::Heritage - Pod::Weaver configuration for DBIO heritage distributions

=head1 VERSION

version 0.900001

=head1 SYNOPSIS

  [PodWeaver]
  config_plugin = @DBIO::Heritage

=head1 DESCRIPTION

Variant of L<Pod::Weaver::PluginBundle::DBIO> for distributions derived
from DBIx::Class code. Identical in structure but adds the DBIx::Class
copyright attribution to the generated B<COPYRIGHT AND LICENSE> section.

Used automatically by L<Dist::Zilla::PluginBundle::DBIO> when C<heritage = 1>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
