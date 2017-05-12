#
# $Id: Splunk.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# api::splunk Brik
#
package Metabrik::Api::Splunk;
use strict;
use warnings;

use base qw(Metabrik::Client::Rest);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
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
         count => 1000,  # 0 means return everything
         offset => 0,  # 0 means return everything
      },
      commands => {
         get => [ qw(path) ],
         reset_user_agent => [ ],  # Inherited
         apps_local => [ ],
         search_jobs => [ qw(search) ],
         search_jobs_sid => [ qw(sid) ],
         search_jobs_sid_results => [ qw(sid count|OPTIONAL offset|OPTIONAL) ],
         licenser_groups => [ ],
         data_lookup_table_files_acl => [ qw(app csv_file perm|OPTIONAL) ],
         cluster_config => [ ],
         cluster_config_config => [ ],
         deployment_client => [ ],
         deployment_client_config => [ ],
         search_data_lookuptablefiles => [ qw(username|OPTIONAL) ],
      },
   };
}

#
# API reference: 
# http://docs.splunk.com/Documentation/Splunk/latest/RESTREF/RESTlist
#

sub get {
   my $self = shift;
   my ($path, $count) = @_;

   $count ||= $self->count;
   $self->brik_help_run_undef_arg('get', $path) or return;

   my $uri = $self->uri;

   my $resp = $self->SUPER::get($uri.$path.'?count='.$count) or return;

   my $content = $self->content('xml') or return;
   my $code = $self->code or return;

   $self->log->verbose("get: returned code [$code]");

   return $content;
}

sub apps_local {
   my $self = shift;

   return $self->get('/services/apps/local');
}

#
# run api::splunk search_jobs "{ search => 'search index=main' }" https://localhost:8089
#
sub search_jobs {
   my $self = shift;
   my ($post) = @_;

   $self->brik_help_run_undef_arg('search_jobs', $post) or return;
   $self->brik_help_run_invalid_arg('search_jobs', $post, 'HASH') or return;

   my $uri = $self->uri;

   my $resp = $self->post($post, $uri.'/services/search/jobs') or return;

   my $code = $self->code;

   $self->log->verbose("search_jobs: returned code [$code]");
   $self->debug && $self->log->debug("search_jobs: content [".$resp->{content}."]");

   if ($code == 201) {  # Job created
      return $self->content('xml');
   }

   return $self->log->error("search_jobs: failed with code [$code]");
}

sub search_jobs_sid {
   my $self = shift;
   my ($sid) = @_;

   $self->brik_help_run_undef_arg('search_jobs_sid', $sid) or return;

   my $uri = $self->uri;

   my $resp = $self->SUPER::get($uri.'/services/search/jobs/'.$sid) or return;

   my $code = $self->code;

   $self->log->verbose("search_jobs_sid: returned code [$code]");
   $self->debug && $self->log->debug("search_jobs_sid: content [".$resp->{content}."]");

   if ($code == 404) {
      return 0;
   }
   elsif ($code == 200) {
      return $self->content('xml');
   }

   return $self->log->error("search_jobs_sid: failed with code [$code]");
}

#
# http://docs.splunk.com/Documentation/Splunk/latest/RESTREF/RESTsearch#search.2Fjobs.2F.7Bsearch_id.7D.2Fresults
#
sub search_jobs_sid_results {
   my $self = shift;
   my ($sid, $count, $offset) = @_;

   $count ||= $self->count;
   $offset ||= $self->offset;
   $self->brik_help_run_undef_arg('search_jobs_sid_results', $sid) or return;

   my $uri = $self->uri;
   my $output_mode = $self->output_mode;

   my $resp = $self->SUPER::get(
      $uri.'/services/search/jobs/'.$sid.
      '/results/?output_mode='.$output_mode."&offset=$offset&count=$count"
   ) or return;

   my $code = $self->code;

   $self->log->verbose("search_jobs_sid_results: returned code [$code]");
   $self->debug && $self->log->debug("search_jobs_sid_results: content [".$resp->{content}."]");

   if ($code == 200) {  # Job finished
      return $self->content($output_mode);
   }
   elsif ($code == 204) {  # Job not finished
      return $self->log->error("search_jobs_sid_results: job not done");
   }

   return $self->log->error("search_jobs_sid_results: failed with code [$code]");
}

#
# http://docs.splunk.com/Documentation/Splunk/6.1.3/RESTAPI/RESTlicense
#
sub licenser_groups {
   my $self = shift;

   return $self->get('/services/licenser/groups');
}

#
# curl -k -u admin https://localhost:8089/servicesNS/admin/$APP/data/lookup-table-files/$FILE.csv/acl -d owner=nobody -d sharing=global
#
# http://docs.splunk.com/Documentation/Splunk/6.1.3/RESTAPI/RESTknowledge
#
sub data_lookup_table_files_acl {
   my $self = shift;
   my ($app, $csv_file, $perm) = @_;

   $perm ||= { owner => 'nobody', sharing => 'global' };
   $self->brik_help_run_undef_arg('data_lookup_table_files_acl', $app) or return;
   $self->brik_help_run_undef_arg('data_lookup_table_files_acl', $csv_file) or return;

   my $uri = $self->uri;
   my $username = $self->username;

   if ($csv_file !~ m{\.csv$}) {
      return $self->log->error("data_lookup_table_files_acl: csv file [$csv_file] must ends with .csv extension");
   }

   my $resp = $self->post(
      $perm, $uri.'/servicesNS/'.$username.'/'.$app.'/data/lookup-table-files/'.$csv_file.'/acl'
   ) or return;

   my $code = $self->code;

   $self->log->verbose("data_lookup_table_files_acl: returned code [$code]");
   $self->debug && $self->log->debug("data_lookup_table_files_acl: content [".$resp->{content}."]");

   return $self->content('xml');
}

sub cluser_config {
   my $self = shift;

   return $self->get('/services/cluster/config');
}

sub cluser_config_config {
   my $self = shift;

   return $self->get('/services/cluster/config/config');
}

sub deployment_client {
   my $self = shift;

   return $self->get('/services/deployment/client');
}

sub deployment_client_config {
   my $self = shift;

   return $self->get('/services/deployment/client/config');
}

sub search_data_lookuptablefiles {
   my $self = shift;
   my ($username) = @_;

   $username ||= $self->username;

   return $self->get('/servicesNS/'.$username.'/search/data/lookup-table-files');
}

1;

__END__

=head1 NAME

Metabrik::Api::Splunk - api::splunk Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
