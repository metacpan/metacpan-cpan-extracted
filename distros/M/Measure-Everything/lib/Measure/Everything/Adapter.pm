package Measure::Everything::Adapter;
use strict;
use warnings;
use Module::Runtime qw(use_module);

# ABSTRACT: Tell Measure::Everything where to send the stats

sub set {
    my ($self, $adapter, @args) = @_;

    $Measure::Everything::global_stats = use_module('Measure::Everything::Adapter::'.$adapter)->new(@args);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Measure::Everything::Adapter - Tell Measure::Everything where to send the stats

=head1 VERSION

version 1.001

=head1 SYNOPSIS

  # generic syntax
  use Measure::Everything::Adapter;
  Measure::Everything::Adapter->set('SomeAdapter', config => 'value' );

  # write InfluxDB lines to a file
  use Measure::Everything::Adapter;
  Measure::Everything::Adapter->set('InfluxDB::File', file => '/var/stats/influx.stats' );

=head1 DESCRIPTION

=head1 AUTHOR

Thomas Klausner <domm@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
