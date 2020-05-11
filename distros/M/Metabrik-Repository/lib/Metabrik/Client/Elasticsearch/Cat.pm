#
# $Id$
#
# client::elasticsearch::cat Brik
#
package Metabrik::Client::Elasticsearch::Cat;
use strict;
use warnings;

#
# DOC: Search::Elasticsearch::Client::6_0::Direct::Cat
#

use base qw(Metabrik::Client::Elasticsearch);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
      },
      attributes_default => {
      },
      commands => {
         show_nodes => [ ],
         show_tasks => [ ],
         show_shards => [ qw(indices|OPTIONAL) ],
         show_recovery => [ qw(indices|OPTIONAL) ],
         show_allocation => [ ],
         loop_show_allocation => [ qw(interval|OPTIONAL) ],
         show_health => [ ],
         loop_show_health => [ qw(interval|OPTIONAL) ],
         pending_tasks => [ ],
      },
   };
}

sub brik_init {
   my $self = shift;

   $self->open or return 0;

   return $self->SUPER::brik_init;
}

sub show_nodes {
   my $self = shift;

   my $r = $self->_es->cat->nodes;

   return [ split(/\n/, $r) ];
}

sub show_tasks {
   my $self = shift;

   my $r = $self->_es->cat->tasks;

   return [ split(/\n/, $r) ];
}

sub show_shards {
   my $self = shift;
   my ($indices) = @_;

   my %args = ();
   if (defined($indices)) {
      $args{index} = $indices;
   }

   my $r = $self->_es->cat->shards(%args);

   return [ split(/\n/, $r) ];
}

sub show_recovery {
   my $self = shift;
   my ($indices) = @_;

   my %args = ();
   if (defined($indices)) {
      $args{index} = $indices;
   }

   my $r = $self->_es->cat->recovery(%args);

   return [ split(/\n/, $r) ];
}

sub show_allocation {
   my $self = shift;

   my %args = ();

   my $r = $self->_es->cat->allocation(%args);

   return [ split(/\n/, $r) ];
}

sub loop_show_allocation {
   my $self = shift;
   my ($interval) = @_;

   $interval ||= 60;

   while (1) {
      my %lines = ();
      for my $line (@{$self->show_allocation}) {
         my @t = split(/\s+/, $line);
         $lines{$t[-1]} = $line;
      }
      for (sort { $a cmp $b } keys %lines) {
         print $lines{$_}."\n";
      }
      print "--\n";
      sleep($interval);
   }

   return 1;
}

sub show_health {
   my $self = shift;

   my %args = ();

   my $r = $self->_es->cat->health(%args);

   return [ split(/\n/, $r) ];
}

sub loop_show_health {
   my $self = shift;
   my ($interval) = @_;

   $interval ||= 60;

   while (1) {
      my $lines = $self->show_health;
      for my $line (@$lines) {
         print "$line\n";
      }
      sleep($interval);
   }

   return 1;
}

sub pending_tasks {
   my $self = shift;

   return $self->_es->cat->pending_tasks;
}

1;

__END__

=head1 NAME

Metabrik::Client::Elasticsearch::Cat - client::elasticsearch::cat Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
