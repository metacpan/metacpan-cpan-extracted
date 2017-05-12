#
# $Id: Query.pm,v 84f8ea395fe8 2017/01/10 14:59:25 gomor $
#
# client::elasticsearch::query Brik
#
package Metabrik::Client::Elasticsearch::Query;
use strict;
use warnings;

use base qw(Metabrik::Client::Elasticsearch);

sub brik_properties {
   return {
      revision => '$Revision: 84f8ea395fe8 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         nodes => [ qw(node_list) ], # Inherited
         index => [ qw(index) ],     # Inherited
         type => [ qw(type) ],       # Inherited
         from => [ qw(number) ],     # Inherited
         size => [ qw(count) ],      # Inherited
         client => [ qw(INTERNAL) ],
      },
      attributes_default => {
         index => '*',
         type => '*',
      },
      commands => {
         create_client => [ ],
         reset_client => [ ],
         query => [ qw(query index|OPTIONAL type|OPTIONAL) ],
         get_query_result_total => [ qw($query_result|OPTIONAL) ],
         get_query_result_hits => [ qw($query_result|OPTIONAL) ],
         get_query_result_timed_out => [ qw($query_result|OPTIONAL) ],
         get_query_result_took => [ qw($query_result|OPTIONAL) ],
         term => [ qw(kv index|OPTIONAL type|OPTIONAL) ],
         unique_term => [ qw(unique kv index|OPTIONAL type|OPTIONAL) ],
         wildcard => [ qw(kv index|OPTIONAL type|OPTIONAL) ],
         range => [ qw(kv_from kv_to index|OPTIONAL type|OPTIONAL) ],
         top => [ qw(kv_count index|OPTIONAL type|OPTIONAL) ],
         top_match => [ qw(kv_count kv_match index|OPTIONAL type|OPTIONAL) ],
         match => [ qw(kv index|OPTIONAL type|OPTIONAL) ],
         match_phrase => [ qw(kv index|OPTIONAL type|OPTIONAL) ],
         from_json_file => [ qw(json_file index|OPTIONAL type|OPTIONAL) ],
      },
   };
}

sub create_client {
   my $self = shift;

   my $ce = $self->client;
   if (! defined($ce)) {
      $ce = $self->open or return;
      $self->client($ce);
   }

   return $ce;
}

sub reset_client {
   my $self = shift;

   my $ce = $self->client;
   if (defined($ce)) {
      $self->client(undef);
   }

   return 1;
}

sub get_query_result_total {
   my $self = shift;
   my ($query_result) = @_;

   my $run = $self->context->do('$RUN');
   $query_result ||= $run;
   $self->brik_help_run_undef_arg('get_query_result_total', $query_result) or return;
   $self->brik_help_run_invalid_arg('get_query_result_total', $query_result, 'HASH') or return;

   if (! exists($query_result->{hits})) {
      return $self->log->error("get_query_result_total: invalid query result, no hits found");
   }
   if (! exists($query_result->{hits}{total})) {
      return $self->log->error("get_query_result_total: invalid query result, no total found");
   }

   return $query_result->{hits}{total};
}

sub get_query_result_hits {
   my $self = shift;
   my ($query_result) = @_;

   my $run = $self->context->do('$RUN');
   $query_result ||= $run;
   $self->brik_help_run_undef_arg('get_query_result_hits', $query_result) or return;
   $self->brik_help_run_invalid_arg('get_query_result_hits', $query_result, 'HASH') or return;

   if (! exists($query_result->{hits})) {
      return $self->log->error("get_query_result_hits: invalid query result, no hits found");
   }
   if (! exists($query_result->{hits}{hits})) {
      return $self->log->error("get_query_result_hits: invalid query result, no hits in hits found");
   }

   return $query_result->{hits}{hits};
}

sub get_query_result_timed_out {
   my $self = shift;
   my ($query_result) = @_;

   my $run = $self->context->do('$RUN');
   $query_result ||= $run;
   $self->brik_help_run_undef_arg('get_query_result_timed_out', $query_result) or return;
   $self->brik_help_run_invalid_arg('get_query_result_timed_out', $query_result, 'HASH')
      or return;

   if (! exists($query_result->{timed_out})) {
      return $self->log->error("get_query_result_timed_out: invalid query result, ".
         "no timed_out found");
   }

   return $query_result->{timed_out} ? 1 : 0;
}

sub get_query_result_took {
   my $self = shift;
   my ($query_result) = @_;

   my $run = $self->context->do('$RUN');
   $query_result ||= $run;
   $self->brik_help_run_undef_arg('get_query_result_took', $query_result) or return;
   $self->brik_help_run_invalid_arg('get_query_result_took', $query_result, 'HASH')
      or return;

   if (! exists($query_result->{took})) {
      return $self->log->error("get_query_result_took: invalid query result, no took found");
   }

   return $query_result->{took};
}

sub query {
   my $self = shift;
   my ($q, $index, $type) = @_;

   $index ||= '*';
   $type ||= '*';
   $self->brik_help_run_undef_arg('query', $q) or return;

   my $ce = $self->create_client or return;

   my $r = $self->SUPER::query($q, $index, $type) or return;
   if (defined($r)) {
      if (exists($r->{hits}{total})) {
         return $r;
      }
      else {
         return $self->log->error("query: failed with [$r]");
      }
   }

   return $self->log->error("query: failed");
}

#
# run client::elasticsearch::query term domain=example.com index1-*,index2-*
#
sub term {
   my $self = shift;
   my ($kv, $index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;
   $self->brik_help_run_undef_arg('term', $kv) or return;
   $self->brik_help_set_undef_arg('term', $index) or return;
   $self->brik_help_set_undef_arg('term', $type) or return;

   if ($kv !~ /^\S+?=.+$/) {
      return $self->log->error("term: kv must be in the form 'key=value'");
   }
   my ($key, $value) = split('=', $kv);

   $self->debug && $self->log->debug("term: key[$key] value[$value]");

   # Optimized version on ES 5.0.0
   my $q = {
      query => {
         bool => {
            must => { term => { $key => $value } },
         },
      },
   };

   $self->log->verbose("term: keys [$key] value [$value] index [$index] type [$type]");

   return $self->query($q, $index, $type);
}

#
# run client::elasticsearch::query unique_term ip domain=example.com index1-*,index2-*
#
sub unique_term {
   my $self = shift;
   my ($unique, $kv, $index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;
   $self->brik_help_run_undef_arg('term', $unique) or return;
   $self->brik_help_run_undef_arg('term', $kv) or return;
   $self->brik_help_set_undef_arg('term', $index) or return;
   $self->brik_help_set_undef_arg('term', $type) or return;

   if ($kv !~ /^\S+?=.+$/) {
      return $self->log->error("unique_term: kv must be in the form 'key=value'");
   }
   my ($key, $value) = split('=', $kv);

   $self->debug && $self->log->debug("unique_term: key[$key] value[$value]");

   # Optimized version on ES 5.0.0
   my $q = {
      size => 0,
      query => {
         bool => {
            must => { term => { $key => $value } },
         },
      },
      aggs => {
         1 => {
            cardinality => {
               field => $unique,
            },
         },
      },
   };

   $self->log->verbose("unique_term: unique [$unique] keys [$key] value [$value] ".
      "index [$index] type [$type]");

   return $self->query($q, $index, $type);
}

#
# 
#
#sub unique_values {
#{
   #"size": 0,
   #"aggs": {
      #"1" : {
         #"terms" : { "field" : "ip" },
      #}
   #}
#}
#} 

sub wildcard {
   my $self = shift;
   my ($kv, $index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;
   $self->brik_help_run_undef_arg('wildcard', $kv) or return;
   $self->brik_help_set_undef_arg('wildcard', $index) or return;
   $self->brik_help_set_undef_arg('wildcard', $type) or return;

   if ($kv !~ /^\S+?=.+$/) {
      return $self->log->error("wildcard: kv must be in the form 'key=value'");
   }
   my ($key, $value) = split('=', $kv);

   my $q = {
      query => {
         #constant_score => {  # Does not like constant_score
            #filter => {
               wildcard => {
                  $key => $value,
               },
            #},
         #},
      },
   };

   $self->log->verbose("wildcard: keys [$key] value [$value] index [$index] type [$type]");

   return $self->query($q, $index, $type);
}

#
# run client::elasticsearch::query range ip_range.from=192.168.255.36 ip_range.to=192.168.255.36
#
sub range {
   my $self = shift;
   my ($kv_from, $kv_to, $index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;
   $self->brik_help_run_undef_arg('range', $kv_from) or return;
   $self->brik_help_run_undef_arg('range', $kv_to) or return;
   $self->brik_help_set_undef_arg('range', $index) or return;
   $self->brik_help_set_undef_arg('range', $type) or return;

   if ($kv_from !~ /^\S+?=.+$/) {
      return $self->log->error("range: kv_from [$kv_from] must be in the form 'key=value'");
   }
   if ($kv_to !~ /^\S+?=.+$/) {
      return $self->log->error("range: kv_to [$kv_to] must be in the form 'key=value'");
   }
   my ($key_from, $value_from) = split('=', $kv_from);
   my ($key_to, $value_to) = split('=', $kv_to);

   #
   # http://stackoverflow.com/questions/40519806/no-query-registered-for-filtered
   # https://www.elastic.co/guide/en/elasticsearch/reference/current/query-dsl-filtered-query.html
   # Compatible with ES 5.0
   #
   my $q = {
      query => {
         bool => {
            must => [
               { range => { $key_to => { gte => $value_to } } },
               { range => { $key_from => { lte => $value_from } } },
            ],
         },
      },
   };

   return $self->query($q, $index, $type);
}

#
# run client::elasticsearch::query top name=10 users-*
#
sub top {
   my $self = shift;
   my ($kv_count, $index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;
   $self->brik_help_run_undef_arg('top', $kv_count) or return;
   $self->brik_help_set_undef_arg('top', $index) or return;
   $self->brik_help_set_undef_arg('top', $type) or return;

   if ($kv_count !~ /^\S+=\d+$/) {
      return $self->log->error("top: kv_count [$kv_count] must be in the form 'key=value'");
   }
   my ($key_count, $value_count) = split('=', $kv_count);

   my $q = {
      aggs => {
         top_values => {
            terms => {
               field => $key_count,
               size => int($value_count),
               order => { _count => 'desc' },
            },
         },
      },
   };

   $self->log->verbose("top: key [$key_count] value [$value_count] index [$index] type [$type]");

   return $self->query($q, $index, $type);
}

sub match_phrase {
   my $self = shift;
   my ($kv, $index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;
   $self->brik_help_run_undef_arg('match_phrase', $kv) or return;
   $self->brik_help_set_undef_arg('match_phrase', $index) or return;
   $self->brik_help_set_undef_arg('match_phrase', $type) or return;

   if ($kv !~ /^\S+?=.+$/) {
      return $self->log->error("match_phrase: kv must be in the form 'key=value'");
   }
   my ($key, $value) = split('=', $kv);

   $self->debug && $self->log->debug("match_phrase: key[$key] value[$value]");

   my $q = {
      query => {
         match_phrase => {
            $key => $value,
         },
      },
   };

   return $self->query($q, $index, $type);
}

sub match {
   my $self = shift;
   my ($kv, $index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;
   $self->brik_help_run_undef_arg('match', $kv) or return;
   $self->brik_help_set_undef_arg('match', $index) or return;
   $self->brik_help_set_undef_arg('match', $type) or return;

   if ($kv !~ /^\S+?=.+$/) {
      return $self->log->error("match: kv must be in the form 'key=value'");
   }
   my ($key, $value) = split('=', $kv);

   $self->debug && $self->log->debug("match: key[$key] value[$value]");

   my $q = {
      query => {
         match => {
            $key => $value,
         },
      },
   };

   return $self->query($q, $index, $type);
}

#
# run client::elasticsearch::query top_match domain=10 host=*www*
#
sub top_match {
   my $self = shift;
   my ($kv_count, $kv_match, $index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;
   $self->brik_help_run_undef_arg('top_match', $kv_count) or return;
   $self->brik_help_run_undef_arg('top_match', $kv_match) or return;
   $self->brik_help_set_undef_arg('top_match', $index) or return;
   $self->brik_help_set_undef_arg('top_match', $type) or return;

   if ($kv_count !~ /^\S+?=.+$/) {
      return $self->log->error("top_match: kv_count [$kv_count] must be in the form 'key=value'");
   }
   if ($kv_match !~ /^\S+?=.+$/) {
      return $self->log->error("top_match: kv_match [$kv_match] must be in the form 'key=value'");
   }
   my ($key_count, $value_count) = split('=', $kv_count);
   my ($key_match, $value_match) = split('=', $kv_match);

   my $q = {
      query => {
         #constant_score => {   # Does not like constant_score
            #filter => {
               match => {
                  $key_match => $value_match,
               },
            #},
         #},
      },
      aggs => {
         top_values => {
            terms => {
               field => $key_count,
               size => int($value_count),
            },
         },
      },
   };

   return $self->query($q, $index, $type);
}

sub from_json_file {
   my $self = shift;
   my ($file, $index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;
   $self->brik_help_run_undef_arg('from_json_file', $file) or return;
   $self->brik_help_run_file_not_found('from_json_file', $file) or return;
   $self->brik_help_set_undef_arg('from_json_file', $index) or return;
   $self->brik_help_set_undef_arg('from_json_file', $type) or return;

   my $fj = Metabrik::File::Json->new_from_brik_init($self) or return;
   my $q = $fj->read($file) or return;

   return $self->query($q, $index, $type);
}

1;

__END__

=head1 NAME

Metabrik::Client::Elasticsearch::Query - client::elasticsearch::query Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
