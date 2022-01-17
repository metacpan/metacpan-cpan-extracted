#
# $Id$
#
# client::elasticsearch::tasks Brik
#
package Metabrik::Client::Elasticsearch::Tasks;
use strict;
use warnings;

#
# DOC: Search::Elasticsearch::Client::6_0::Direct::Tasks
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
         list => [ ],
         get_taskid => [ qw(id) ],
         get_forcemerge => [ ],
         show_forcemerge_progress => [ ],
         loop_show_forcemerge_progress => [ qw(seconds|OPTIONAL) ],
      },
   };
}

sub brik_init {
   my $self = shift;

   $self->open or return 0;

   return $self->SUPER::brik_init;
}

sub list {
   my $self = shift;

   return $self->_es->tasks->list;
}

sub get_taskid {
   my $self = shift;
   my ($id) = @_;

   $self->brik_help_run_undef_arg('get_taskid', $id) or return;

   my $tasks = $self->_es->tasks;

   return $tasks->get(task_id => $id);
}

sub get_forcemerge {
   my $self = shift;

   my $list = $self->list or return;

   my $nodes = $list->{nodes};
   if (! defined($nodes)) {
      return $self->log->error("get_forcemerge: no nodes found");
   }

   my %tasks = ();
   for my $node (keys %$nodes) {
      for my $id (keys %{$nodes->{$node}}) {
         my $tasks = $nodes->{$node}{tasks};
         for my $task (keys %$tasks) {
            my $action = $tasks->{$task}{action};
            if ($action eq 'indices:admin/forcemerge'
            &&  !exists($tasks{$task})) {
               $tasks{$task} = $tasks->{$task};
            }
         }
      }
   }

   return \%tasks;
}

sub show_forcemerge_progress {
   my $self = shift;

   my $tasks = $self->get_forcemerge or return;
   if (! keys %$tasks) {
      $self->log->info("show_forcemerge_progress: no forcemerge task ".
         "in progress");
      return 0;
   }

   my $count = 1;
   for my $id (sort { $a cmp $b } keys %$tasks) {
      my $task = $self->get_taskid($id) or next;

      my $desc = $task->{task}{description};
      my $start_time = $task->{task}{start_time_in_millis};
      my $running_time = $task->{task}{running_time_in_nanos};

      print "Task ID [$id] count [".$count++."] is running...\n";
   }

   return 1;
}

sub loop_show_forcemerge_progress {
   my $self = shift;
   my ($sec) = @_;

   $sec ||= 60;
   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   while (1) {
      $self->show_forcemerge_progress or return;
      sleep($sec);
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Client::Elasticsearch::Tasks - client::elasticsearch::tasks Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
