#
# $Id$
#
# client::splunk Brik
#
package Metabrik::Client::Splunk;
use strict;
use warnings;

use base qw(Metabrik::Api::Splunk);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable rest) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         uri => [ qw(uri) ],  # Inherited
         username => [ qw(username) ],  # Inherited
         password => [ qw(password) ],  # Inherited
         ssl_verify => [ qw(0|1) ], # Inherited
         output_mode => [ qw(json|xml|csv) ],
         count => [ qw(number) ],
         offset => [ qw(number) ],
      },
      attributes_default => {
         uri => 'https://localhost:8089',
         username => 'admin',
         ssl_verify => 0,
         output_mode => 'json',
         count => 1000,
         offset => 0,
      },
      commands => {
         search => [ qw(string) ],
         is_job_done => [ qw(sid) ],
         get_results => [ qw(sid) ],
      },
   };
}

#
# Example:
# run client::splunk search "index=main"
#
sub search {
   my $self = shift;
   my ($search) = @_;

   $self->brik_help_run_undef_arg('search', $search) or return;

   my $r = $self->search_jobs({ search => "search $search" }) or return;

   if (! exists($r->{sid})) {
      return $self->log->error("search: sid not found in response");
   }

   return $r->{sid};
}

sub is_job_done {
   my $self = shift;
   my ($sid) = @_;

   $self->brik_help_run_undef_arg('is_job_done', $sid) or return;

   my $r = $self->search_jobs_sid($sid);
   if (! defined($r)) {
      return;
   }
   elsif ($r == 0) {
      return 0;
   }

   if (exists($r->{content})
   &&  exists($r->{content}{'s:dict'})
   &&  exists($r->{content}{'s:dict'}{'s:key'})
   &&  exists($r->{content}{'s:dict'}{'s:key'}{dispatchState})
   &&  exists($r->{content}{'s:dict'}{'s:key'}{dispatchState}{content})) {
      my $status = $r->{content}{'s:dict'}{'s:key'}{dispatchState}{content};
      return $status eq 'DONE';
   }

   return $self->log->error("is_job_done: invalid response");
}

sub get_results {
   my $self = shift;
   my ($sid, $count, $offset) = @_;

   $count ||= $self->count;
   $offset ||= $self->offset;
   $self->brik_help_run_undef_arg('get_results', $sid) or return;

   my $output_mode = $self->output_mode;
   if ($output_mode ne 'xml'
   &&  $output_mode ne 'json'
   &&  $output_mode ne 'csv') {
      return $self->log->error("get_results: output_mode not supported [$output_mode]");
   }

   my $r = $self->search_jobs_sid_results($sid, $count, $offset);
   if (! defined($r)) {
      return;
   }

   # No results from this search
   if (! length($r)) {
      return [];
   }

   return $r;
}

1;

__END__

=head1 NAME

Metabrik::Client::Splunk - client::splunk Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
