package Measure::Everything::Adapter::Test;

# ABSTRACT: Test Adapter: for testing...
our $VERSION = '1.003'; # VERSION

use strict;
use warnings;

use base qw(Measure::Everything::Adapter::Base);

sub init {
    my $self = shift;
    $self->{_stats} = [];
}

sub write {
    my $self = shift;

    push(@{$self->{_stats}}, [@_]);
}


sub get_stats {
    my $self = shift;

    return $self->{_stats};
}


sub reset {
    my $self = shift;

    $self->{_stats} = [];
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Measure::Everything::Adapter::Test - Test Adapter: for testing...

=head1 VERSION

version 1.003

=head1 SYNOPSIS

    Measure::Everything::Adapter->set( 'Test' );

=head1 DESCRIPTION

Collect stats in an in-memory array. Useful when you want to test if things are measured.

=head1 METHODS

=head2 get_stats

  my $stats = $stats->get_stats;

Returns all the stats collected in the raw format (i.e. as an array).

=head2 reset

  $stats->reset;

Flushes all stats collected so far, starts from a clean slate.

=head1 AUTHOR

Thomas Klausner <domm@plix.at>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 - 2021 by Thomas Klausner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
