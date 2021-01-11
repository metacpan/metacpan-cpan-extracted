package Measure::Everything::Adapter;

# ABSTRACT: Tell Measure::Everything where to send the stats
our $VERSION = '1.003'; # VERSION

use strict;
use warnings;
use Module::Runtime qw(use_module);

sub set {
    my ($self, $adapter, @args) = @_;

    my $module_name;
    if ( $adapter =~ s/^\+// ) {
        $module_name = $adapter;
    } else {
        $module_name = 'Measure::Everything::Adapter::'.$adapter;
    }

    $Measure::Everything::global_stats = use_module($module_name)->new(@args);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Measure::Everything::Adapter - Tell Measure::Everything where to send the stats

=head1 VERSION

version 1.003

=head1 SYNOPSIS

  # generic syntax
  use Measure::Everything::Adapter;
  Measure::Everything::Adapter->set('SomeAdapter', config => 'value' );

  # write InfluxDB lines to a file
  use Measure::Everything::Adapter;
  Measure::Everything::Adapter->set('InfluxDB::File', file => '/var/stats/influx.stats' );

=head1 DESCRIPTION

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
