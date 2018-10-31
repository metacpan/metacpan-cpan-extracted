#
# $Id: Cluster.pm,v 07f83089ef07 2018/09/17 10:14:06 gomor $
#
# client::elasticsearch::cluster Brik
#
package Metabrik::Client::Elasticsearch::Cluster;
use strict;
use warnings;

#
# DOC: Search::Elasticsearch::Client::6_0::Direct::Cluster
#

use base qw(Metabrik::Client::Elasticsearch);

sub brik_properties {
   return {
      revision => '$Revision: 07f83089ef07 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
      },
      attributes_default => {
      },
      commands => {
         show => [ ],
         list => [ ],
         health => [ qw(indices|OPTIONAL) ],
         stats => [ qw(nodes|OPTIONAL) ],
         remote_info => [ ],
         pending_tasks => [ ],
         get_settings => [ ],
         put_settings => [ qw(settings) ],
         exclude => [ qw(node) ],
         include => [ qw(node) ],
      },
   };
}

sub brik_init {
   my $self = shift;

   $self->open or return 0;

   return $self->SUPER::brik_init;
}

sub show {
   my $self = shift;

   return $self->SUPER::show_nodes();
}

sub list {
   my $self = shift;

   my $show = $self->show or return;

   my @nodes = ();
   for (@$show) {
      chomp;
      my @t = split(/\s+/);
      push @nodes, $t[-1];
   }

   return \@nodes;
}

sub health {
   my $self = shift;
   my ($indices) = @_;

   my %args = ();
   if (defined($indices)) {
      $self->brik_help_run_invalid_arg('health', $indices, 'ARRAY', 'SCALAR') or return;
      $args{index} = $indices;
   }

   return $self->_es->cluster->health(%args);
}

sub stats {
   my $self = shift;
   my ($nodes) = @_;

   my %args = ();
   if (defined($nodes)) {
      $self->brik_help_run_invalid_arg('stats', $nodes, 'ARRAY', 'SCALAR') or return;
      $args{node_id} = $nodes;
   }

   return $self->_es->cluster->stats(%args);
}

sub remote_info {
   my $self = shift;

   return $self->_es->cluster->remote_info;
}

sub pending_tasks {
   my $self = shift;

   return $self->_es->cluster->pending_tasks;
}

sub get_settings {
   my $self = shift;

   return $self->_es->cluster->get_settings;
}

sub put_settings {
   my $self = shift;
   my ($settings) = @_;

   $self->brik_help_run_undef_arg('put_settings', $settings) or return;
   $self->brik_help_run_invalid_arg('put', $settings, 'HASH') or return;

   return $self->_es->cluster->put_settings(body => $settings);
}

sub exclude {
   my $self = shift;
   my ($node) = @_;

   $self->brik_help_run_undef_arg('exclude', $node) or return;

   my $settings = {
      transient => {
         'cluster.routing.allocation.exclude._name' => $node,
      },
   };

   return $self->put_settings($settings);
}

sub include {
   my $self = shift;
   my ($node) = @_;

   $self->brik_help_run_undef_arg('include', $node) or return;

   my $settings = {
      transient => {
         'cluster.routing.allocation.include._name' => $node,
      },
   };

   return $self->put_settings($settings);
}

1;

__END__

=head1 NAME

Metabrik::Client::Elasticsearch::Cluster - client::elasticsearch::cluster Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
