#
# This file is part of Memory-Stats
#
# This software is copyright (c) 2014 by celogeek <me@celogeek.com>.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
package Memory::Stats;

# ABSTRACT: Memory Usage Consumption of your process

use strict;
use warnings;
our $VERSION = '0.04';    # VERSION
use Proc::ProcessTable;
use Carp qw/croak/;
use Moo;

my $pt = Proc::ProcessTable->new;

has '_memory_usage' => ( is => 'rw', default => sub { [] } );

sub _get_current_memory_usage {
    my ($info) = grep { $_->pid eq $$ } @{ $pt->table };
    my $memory_usage;
    return -1 if !defined eval { $memory_usage = $info->rss };
    return $memory_usage;
}

sub start {
    my $self = shift;
    $self->_memory_usage( [ [ "start", _get_current_memory_usage() ] ] );
    return;
}

sub checkpoint {
    my $self = shift;
    my $title = shift // 'checkpoint';
    croak "Please start first !"
        if !scalar @{ $self->_memory_usage }
        || $self->_memory_usage->[-1][0] eq 'stop';
    push @{ $self->_memory_usage }, [ $title, _get_current_memory_usage() ];
    return;
}

sub stop {
    my $self = shift;
    croak "Please start first !"
        if !scalar @{ $self->_memory_usage }
        || $self->_memory_usage->[-1][0] eq 'stop';
    push @{ $self->_memory_usage }, [ 'stop', _get_current_memory_usage() ];
    return;
}

sub delta_usage {
    my $self              = shift;
    my $last_memory_usage = $self->_memory_usage->[-1][1]
        or return;
    return ( _get_current_memory_usage() - $last_memory_usage );
}

sub usage {
    my $self = shift;
    croak "Please start and stop before !"
        if scalar @{ $self->_memory_usage } < 2
        || $self->_memory_usage->[-1][0] ne 'stop';
    return $self->_memory_usage->[-1][1] - $self->_memory_usage->[0][1];

}

sub report {
    my $self = shift;
    print "--- Memory Usage ---\n";
    my $prev;
    for my $row ( @{ $self->_memory_usage } ) {
        if ($prev) {
            printf(
                "%s: %d - delta: %d - total: %d\n",
                @$row,
                $row->[1] - $prev,
                $row->[1] - $self->_memory_usage->[0][1]
            );
        }
        else {
            printf( "%s: %d\n", @$row );
        }
        $prev = $row->[1];
    }
    print "--- Memory Usage ---\n";
    return;
}

1;

__END__

=pod

=head1 NAME

Memory::Stats - Memory Usage Consumption of your process

=head1 VERSION

version 0.04

=head1 DESCRIPTION

This module give you the memory usage (resident RSS), of a part of your process. It use L<Proc::ProcessTable> and should work on all platforms supported by this module.

You can check this link to for explanation: L<http://blog.celogeek.com/201312/394/perl-universal-way-to-get-memory-usage-of-a-process/>

=head1 SYNOPSIS

  use Memory::Stats;

  my $stats = Memory::Stats->new;

  $stats->start;
  # do something
  $stats->checkpoint("before my big method");
  # big method
  $stats->checkpoint("after my big method");
  $stats->stop;
  $stats->report;

=head1 METHODS

=head2 start

Start recording memory usage.

 $mu->start;

=head2 checkpoint

Mark a step in the recording.

  $mu->checkpoint('title of the checkpoint');

You need to start first.

=head2 stop

Stop the recording.

 $mu->stop;

You need to start first.

=head2 delta_usage

Get the current delta memory usage since the last checkpoint

  $mu->delta_usage

=head2 usage

Get the total memory usage (difference between stop and start)

 $mu->usage

You need to start and stop first.

=head2 report

Dump all the recording.

 $mu->report;

It will display all memory checkpoint, with delta. You can call it at any times.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/celogeek/perl-memory-stats/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

celogeek <me@celogeek.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by celogeek <me@celogeek.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
