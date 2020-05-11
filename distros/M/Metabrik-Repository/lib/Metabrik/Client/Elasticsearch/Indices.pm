#
# $Id$
#
# client::elasticsearch::indices Brik
#
package Metabrik::Client::Elasticsearch::Indices;
use strict;
use warnings;

#
# DOC: Search::Elasticsearch::Client::6_0::Direct::Indices
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
         show => [ qw(indices|OPTIONAL) ],
         list => [ qw(indices|OPTIONAL) ],
         get_settings => [ qw(indices|OPTIONAL) ],
         put_settings => [ qw(settings indices|OPTIONAL) ],
         set_indices_readonly => [ qw(indices) ],
         clear_indices_readonly => [ qw(indices) ],
         move_indices_to_node => [ qw(indices node) ],
         reset_indices_node => [ qw(indices node) ],
         move_indices_to_rack => [ qw(indices rack) ],
         reset_indices_rack => [ qw(indices) ],
         remove_indices_replicas => [ qw(indices) ],
         forcemerge_indices => [ qw(indices) ],
         check_forcemerge_indices => [ qw(indices) ],
         shrink_index => [ qw(index size rack|OPTIONAL) ],
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
   my ($indices) = @_;

   return $self->SUPER::show_indices($indices);
}

sub list {
   my $self = shift;
   my ($indices) = @_;

   return $self->SUPER::list_indices($indices);
}

sub get_settings {
   my $self = shift;
   my ($indices) = @_;

   my %args = ();
   if (defined($indices)) {
      $args{index} = $indices;
   }

   return $self->_es->indices->get_settings(%args);
}

sub put_settings {
   my $self = shift;
   my ($settings, $indices) = @_;

   $self->brik_help_run_undef_arg('put_settings', $settings) or return;
   $self->brik_help_run_invalid_arg('put', $settings, 'HASH') or return;

   return $self->_es->indices->put_settings(body => $settings);
}

sub set_indices_readonly {
   my $self = shift;
   my ($indices) = @_;

   $self->brik_help_run_undef_arg('set_indices_readonly', $indices) or return;

   my $settings = {
      'index.blocks.write' => 'true',
   };

   my %args = (
      index => $indices,
      body => $settings,
   );

   return $self->_es->indices->put_settings(%args);
}

sub clear_indices_readonly {
   my $self = shift;
   my ($indices) = @_;

   $self->brik_help_run_undef_arg('clear_indices_readonly', $indices)
      or return;

   my $settings = {
      'index.blocks.write' => undef,
   };

   my %args = (
      index => $indices,
      body => $settings,
   );

   return $self->_es->indices->put_settings(%args);
}

sub move_indices_to_node {
   my $self = shift;
   my ($indices, $node) = @_;

   $self->brik_help_run_undef_arg('move_indices_to_node', $indices) or return;
   $self->brik_help_run_undef_arg('move_indices_to_node', $node) or return;

   my $settings = {
      'index.routing.allocation.require._name' => $node,
   };

   my %args = (
      index => $indices,
      body => $settings,
   );

   return $self->_es->indices->put_settings(%args);
}

sub reset_indices_node {
   my $self = shift;
   my ($indices) = @_;

   $self->brik_help_run_undef_arg('reset_indices_node', $indices) or return;

   my $settings = {
      'index.routing.allocation.require._name' => undef,
   };

   my %args = (
      index => $indices,
      body => $settings,
   );

   return $self->_es->indices->put_settings(%args);
}

#
# POST /logs_2014-09-30/_settings
# {
#   "index.routing.allocation.include.box_type" : "medium"
# }
#
sub move_indices_to_rack {
   my $self = shift;
   my ($indices, $rack) = @_;

   $self->brik_help_run_undef_arg('move_indices_to_rack', $indices) or return;
   $self->brik_help_run_undef_arg('move_indices_to_rack', $rack) or return;

   my $settings = {
      #'index.routing.allocation.include.node.attr.rack' => $rack,
      'index.routing.allocation.require.rack' => $rack,
   };

   my %args = (
      index => $indices,
      body => $settings,
   );

   return $self->_es->indices->put_settings(%args);
}

sub reset_indices_rack {
   my $self = shift;
   my ($indices) = @_;

   $self->brik_help_run_undef_arg('reset_indices_to_rack', $indices) or return;

   my $settings = {
      'index.routing.allocation.include.node.attr.rack' => undef,
   };

   my %args = (
      index => $indices,
      body => $settings,
   );

   return $self->_es->indices->put_settings(%args);
}

#
# set number of replicas to 0
#
sub remove_indices_replicas {
   my $self = shift;
   my ($indices) = @_;

   $self->brik_help_run_undef_arg('remove_indices_replicas', $indices)
      or return;

   my $settings = {
      'index.number_of_replicas' => 0,
   };

   my %args = (
      index => $indices,
      body => $settings,
   );

   return $self->_es->indices->put_settings(%args);
}

#
# WARNING: do that only on read-only indices.
#
# http://www.elastic.co/guide/en/elasticsearch/reference/current/indices-forcemerge.html
#
sub forcemerge_indices {
   my $self = shift;
   my ($indices) = @_;

   $self->brik_help_run_undef_arg('forcemerge_indices', $indices)
      or return;

   # Add optional argument: "index.codec": "best_compression"

   my %args = (
      index => $indices,
      max_num_segments => 1,
      #wait_for_merge => 'false', # argument doesn't exist in ES.
   );

   return $self->_es->indices->forcemerge(%args);
}

sub check_forcemerge_indices {
   my $self = shift;
   my ($indices) = @_;

   $self->brik_help_run_undef_arg('forcemerge_indices', $indices)
      or return;

   my %args = (
      index => $indices,
      max_num_segments => undef,
   );

   return $self->_es->indices->forcemerge(%args);
}

#
# https://www.elastic.co/guide/en/elasticsearch/guide/current/retiring-data.html#optimize-indices
# sub optimize {}
#
# 1. Remove replicas
# 2. forcemerge to one segment
# 3. Put back replicas settings
#

sub shrink_index {
   my $self = shift;
   my ($index, $size, $rack) = @_;

   $self->brik_help_run_undef_arg('shrink_index', $index) or return;
   $self->brik_help_run_undef_arg('shrink_index', $size) or return;

   my $target = "$index.shrink";

   my $body = {
      settings => {
         'index.number_of_shards' => $size,
      },
      #aliases => {
      #},
   };

   if (defined($rack)) {
      $body->{settings}{'index.routing.allocation.require.rack'} = $rack;
   }

   my %args = (
      index => $index,
      target => $target,
      body => $body,
      #copy_settings => 'true',  # Does not work yet.
   );

   my $r = $self->_es->indices->shrink(%args);

   #if (defined($rack)) {
      #sleep(5);  # Wait for Shrink to start, then move to rack if given
      #$self->move_indices_to_rack($target, $rack);
   #}

   return $r;
}

1;

__END__

=head1 NAME

Metabrik::Client::Elasticsearch::Indices - client::elasticsearch::indices Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
