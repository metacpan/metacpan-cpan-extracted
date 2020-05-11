#
# $Id$
#
# client::elasticsearch Brik
#
package Metabrik::Client::Elasticsearch;
use strict;
use warnings;

use base qw(Metabrik::Client::Rest);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable es es) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         nodes => [ qw(node_list) ],
         cxn_pool => [ qw(Sniff|Static|Static::NoPing) ],
         date => [ qw(date) ],
         index => [ qw(index) ],
         type => [ qw(type) ],
         from => [ qw(number) ],
         size => [ qw(count) ],
         max => [ qw(count) ],
         max_flush_count => [ qw(count) ],
         max_flush_size => [ qw(count) ],
         rtimeout => [ qw(seconds) ],
         sniff_rtimeout => [ qw(seconds) ],
         try => [ qw(count) ],
         use_bulk_autoflush => [ qw(0|1) ],
         use_indexing_optimizations => [ qw(0|1) ],
         use_ignore_id => [ qw(0|1) ],
         use_type => [ qw(0|1) ],
         csv_header => [ qw(fields) ],
         csv_encoded_fields => [ qw(fields) ],
         csv_object_fields => [ qw(fields) ],
         encoding => [ qw(utf8|ascii) ],
         _es => [ qw(INTERNAL) ],
         _bulk => [ qw(INTERNAL) ],
         _scroll => [ qw(INTERNAL) ],
      },
      attributes_default => {
         nodes => [ qw(http://localhost:9200) ],
         cxn_pool => 'Sniff',
         from => 0,
         size => 10,
         max => 0,
         index => '*',
         type => '*',
         rtimeout => 60,
         sniff_rtimeout => 3,
         try => 3,
         max_flush_count => 1_000,
         max_flush_size => 1_000_000,
         use_bulk_autoflush => 1,
         use_indexing_optimizations => 0,
         use_ignore_id => 0,
         use_type => 1,
         encoding => 'utf8',
      },
      commands => {
         open => [ qw(nodes_list|OPTIONAL cxn_pool|OPTIONAL) ],
         open_bulk_mode => [ qw(index|OPTIONAL type|OPTIONAL) ],
         open_scroll_scan_mode => [ qw(index|OPTIONAL size|OPTIONAL) ],
         open_scroll => [ qw(index|OPTIONAL size|OPTIONAL type|OPTIONAL query|OPTIONAL) ],
         close_scroll => [ ],
         total_scroll => [ ],
         next_scroll => [ qw(count|OPTIONAL) ],
         reindex => [ qw(index_source index_destination type_destination|OPTIONAL) ],
         get_reindex_tasks => [ ],
         cancel_reindex_task => [ qw(id) ],
         get_taskid => [ qw(id) ],
         show_reindex_progress => [ ],
         loop_show_reindex_progress => [ qw(seconds|OPTIONAL) ],
         index_document => [ qw(document index|OPTIONAL type|OPTIONAL hash|OPTIONAL id|OPTIONAL) ],
         index_bulk => [ qw(document index|OPTIONAL type|OPTIONAL hash|OPTIONAL id|OPTIONAL) ],
         index_bulk_from_list => [ qw(document_list index|OPTIONAL type|OPTIONAL hash|OPTIONAL) ],
         clean_deleted_from_index => [ qw(index) ],
         update_document => [ qw(document id index|OPTIONAL type|OPTIONAL hash|OPTIONAL) ],
         update_document_bulk => [ qw(document index|OPTIONAL type|OPTIONAL hash|OPTIONAL id|OPTIONAL) ],
         bulk_flush => [ qw(index|OPTIONAL) ],
         query => [ qw($query_hash index|OPTIONAL type|OPTIONAL hash|OPTIONAL) ],
         count => [ qw(index|OPTIONAL type|OPTIONAL) ],
         get_from_id => [ qw(id index|OPTIONAL type|OPTIONAL) ],
         www_search => [ qw(query index|OPTIONAL type|OPTIONAL) ],
         delete_index => [ qw(index|indices_list) ],
         update_alias => [ qw(new_index alias) ],
         delete_document => [ qw(index type id) ],
         delete_by_query => [ qw($query_hash index type proceed|OPTIONAL) ],
         show_indices => [ qw(string_filter|OPTIONAL) ],
         show_nodes => [ ],
         show_health => [ ],
         show_recovery => [ ],
         show_allocation => [ ],
         list_indices => [ qw(regex|OPTIONAL) ],
         get_indices => [ qw(string_filter|OPTIONAL) ],
         get_index => [ qw(index|indices_list) ],
         get_index_stats => [ qw(index) ],
         list_index_types => [ qw(index) ],
         list_index_fields => [ qw(index) ],
         list_indices_version => [ qw(index|indices_list) ],
         open_index => [ qw(index|indices_list) ],
         close_index => [ qw(index|indices_list) ],
         get_aliases => [ qw(index) ],
         put_alias => [ qw(index alias) ],
         delete_alias => [ qw(index alias) ],
         is_mapping_exists => [ qw(index mapping) ],
         get_mappings => [ qw(index type|OPTIONAL) ],
         create_index => [ qw(index shards|OPTIONAL) ],
         create_index_with_mappings => [ qw(index mappings) ],
         info => [ qw(nodes_list|OPTIONAL) ],
         version => [ qw(nodes_list|OPTIONAL) ],
         get_templates => [ ],
         list_templates => [ ],
         get_template => [ qw(name) ],
         put_mapping => [ qw(index type mapping) ],
         put_mapping_from_json_file => [ qw(index type file) ],
         update_mapping_from_json_file => [ qw(file index type) ],
         put_template => [ qw(name template) ],
         put_template_from_json_file => [ qw(file name|OPTIONAL) ],
         update_template_from_json_file => [ qw(file name|OPTIONAL) ],
         get_settings => [ qw(index|indices_list|OPTIONAL name|names_list|OPTIONAL) ],
         put_settings => [ qw(settings_hash index|indices_list|OPTIONAL) ],
         set_index_readonly => [ qw(index|indices_list boolean|OPTIONAL) ],
         reset_index_readonly => [ qw(index|indices_list|OPTIONAL) ],
         list_index_readonly => [ ],
         set_index_number_of_replicas => [ qw(index|indices_list number) ],
         set_index_refresh_interval => [ qw(index|indices_list number) ],
         get_index_settings => [ qw(index|indices_list) ],
         get_index_readonly => [ qw(index|indices_list) ],
         get_index_number_of_replicas => [ qw(index|indices) ],
         get_index_refresh_interval => [ qw(index|indices_list) ],
         get_index_number_of_shards => [ qw(index|indices_list) ],
         delete_template => [ qw(name) ],
         is_index_exists => [ qw(index) ],
         is_type_exists => [ qw(index type) ],
         is_document_exists => [ qw(index type document) ],
         parse_error_string => [ qw(string) ],
         refresh_index => [ qw(index) ],
         export_as => [ qw(format index size|OPTIONAL callback|OPTIONAL) ],
         export_as_csv => [ qw(index size|OPTIONAL callback|OPTIONAL) ],
         export_as_json => [ qw(index size|OPTIONAL callback|OPTIONAL) ],
         import_from => [ qw(format input index|OPTIONAL type|OPTIONAL hash|OPTIONAL callback|OPTIONAL) ],
         import_from_csv => [ qw(input index|OPTIONAL type|OPTIONAL hash|OPTIONAL callback|OPTIONAL) ],
         import_from_json => [ qw(input index|OPTIONAL type|OPTIONAL hash|OPTIONAL callback|OPTIONAL) ],
         import_from_csv_worker => [ qw(input_csv index|OPTIONAL type|OPTIONAL hash|OPTIONAL callback|OPTIONAL) ],
         get_stats_process => [ ],
         get_process => [ ],
         get_cluster_state => [ ],
         get_cluster_health => [ ],
         get_cluster_settings => [ ],
         put_cluster_settings => [ qw(settings) ],
         count_green_indices => [ ],
         count_yellow_indices => [ ],
         count_red_indices => [ ],
         list_green_indices => [ ],
         list_yellow_indices => [ ],
         list_red_indices => [ ],
         count_indices => [ ],
         list_indices_status => [ ],
         count_shards => [ ],
         count_size => [ qw(string_filter|OPTIONAL) ],
         count_total_size => [ qw(string_filter|OPTIONAL) ],
         count_count => [ ],
         list_datatypes => [ ],
         get_hits_total => [ qw(results) ],
         disable_shard_allocation => [ ],
         enable_shard_allocation => [ ],
         flush_synced => [ ],
         create_snapshot_repository => [ qw(body repository_name|OPTIONAL) ],
         create_shared_fs_snapshot_repository => [ qw(location
            repository_name|OPTIONAL) ],
         get_snapshot_repositories => [ ],
         get_snapshot_status => [ ],
         delete_snapshot_repository => [ qw(repository_name) ],
         create_snapshot => [ qw(snapshot_name|OPTIONAL repository_name|OPTIONAL 
            body|OPTIONAL) ],
         create_snapshot_for_indices => [ qw(indices snapshot_name|OPTIONAL
            repository_name|OPTIONAL) ],
         is_snapshot_finished => [ ],
         get_snapshot_state => [ ],
         get_snapshot => [ qw(snapshot_name|OPTIONAL repository_name|OPTIONAL) ],
         delete_snapshot => [ qw(snapshot_name repository_name) ],
         restore_snapshot => [ qw(snapshot_name repository_name body|OPTIONAL) ],
         restore_snapshot_for_indices => [ qw(indices snapshot_name repository_name) ],
      },
      require_modules => {
         'Metabrik::String::Json' => [ ],
         'Metabrik::File::Csv' => [ ],
         'Metabrik::File::Json' => [ ],
         'Metabrik::File::Dump' => [ ],
         'Metabrik::Format::Number' => [ ],
         'Metabrik::Worker::Parallel' => [ ],
         'Search::Elasticsearch' => [ ],
      },
   };
}

sub brik_preinit {
   my $self = shift;

   eval("use Search::Elasticsearch;");
   if ($Search::Elasticsearch::VERSION < 5) {
      $self->log->error("brik_preinit: please upgrade Search::Elasticsearch module ".
         "with: run perl::module install Search::Elasticsearch");
   }

   return $self->SUPER::brik_preinit;
}

sub open {
   my $self = shift;
   my ($nodes, $cxn_pool) = @_;

   $nodes ||= $self->nodes;
   $cxn_pool ||= $self->cxn_pool;
   $self->brik_help_run_undef_arg('open', $nodes) or return;
   $self->brik_help_run_undef_arg('open', $cxn_pool) or return;
   $self->brik_help_run_invalid_arg('open', $nodes, 'ARRAY') or return;
   $self->brik_help_run_empty_array_arg('open', $nodes) or return;

   for my $node (@$nodes) {
      if ($node !~ m{https?://}) {
         return $self->log->error("open: invalid node[$node], must start with http(s)");
      }
   }

   my $timeout = $self->rtimeout;

   my $nodes_str = join('|', @$nodes);
   $self->log->debug("open: using nodes [$nodes_str]");

   #
   # Timeout description here:
   #
   # Search::Elasticsearch::Role::Cxn
   #

   my $es = Search::Elasticsearch->new(
      nodes => $nodes,
      cxn_pool => $cxn_pool,
      timeout => $timeout,
      max_retries => $self->try,
      retry_on_timeout => 1,
      sniff_timeout => $self->sniff_rtimeout, # seconds, default 1
      request_timeout => 60,  # seconds, default 30
      ping_timeout => 5,  # seconds, default 2
      dead_timeout => 120,  # seconds, detault 60
      max_dead_timeout => 3600,  # seconds, default 3600
      sniff_request_timeout => 15, # seconds, default 2
      #trace_to => 'Stderr',  # For debug purposes
   );
   if (! defined($es)) {
      return $self->log->error("open: failed");
   }

   $self->_es($es);

   return $nodes;
}

#
# Search::Elasticsearch::Client::5_0::Bulk
#
sub open_bulk_mode {
   my $self = shift;
   my ($index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;
   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('open_bulk_mode', $index) or return;
   $self->brik_help_run_undef_arg('open_bulk_mode', $type) or return;

   my %args = (
      index => $index,
      on_error => sub {
         #my ($action, $response, $i) = @_;

         #print Data::Dumper::Dumper($action)."\n";
         #print Data::Dumper::Dumper($response)."\n";
         #print Data::Dumper::Dumper($i)."\n";
         print Data::Dumper::Dumper(\@_)."\n";
      },
   );

   if ($self->use_type) {
      $args{type} = $type;
   }

   if ($self->use_bulk_autoflush) {
      my $max_count = $self->max_flush_count || 1_000;
      my $max_size = $self->max_flush_size || 1_000_000;

      $args{max_count} = $max_count;
      $args{max_size} = $max_size;
      $args{max_time} = 0;

      $self->log->info("open_bulk_mode: opening with max_flush_count [$max_count] and ".
         "max_flush_size [$max_size]");
   }
   else {
      $args{max_count} = 0;
      $args{max_size} = 0;
      $args{max_time} = 0;
      $args{on_error} = undef;
      #$args{on_success} = sub {
         #my ($action, $response, $i) = @_;
      #};

      $self->log->info("open_bulk_mode: opening without automatic flushing");
   }

   my $bulk;
   eval {
      $bulk = $es->bulk_helper(%args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("open_bulk_mode: failed: [$@]");
   }

   $self->_bulk($bulk);

   return $self->nodes;
}

sub open_scroll_scan_mode {
   my $self = shift;
   my ($index, $size) = @_;

   my $version = $self->version or return;
   if ($version ge "5.0.0") {
      return $self->log->error("open_scroll_scan_mode: Command not supported for ES version ".
         "$version, try open_scroll Command instead");
   }

   $index ||= $self->index;
   $size ||= $self->size;
   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('open_scroll_scan_mode', $index) or return;
   $self->brik_help_run_undef_arg('open_scroll_scan_mode', $size) or return;

   my $scroll;
   eval {
      $scroll = $es->scroll_helper(
         index => $index,
         search_type => 'scan',
         size => $size,
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("open_scroll_scan_mode: failed: $@");
   }

   $self->_scroll($scroll);

   return $self->nodes;
}

#
# Search::Elasticsearch::Client::5_0::Scroll
#
sub open_scroll {
   my $self = shift;
   my ($index, $size, $type, $query) = @_;

   my $version = $self->version or return;
   if ($version lt "5.0.0") {
      return $self->log->error("open_scroll: Command not supported for ES version ".
         "$version, try open_scroll_scan_mode Command instead");
   }

   $query ||= { query => { match_all => {} } };
   $index ||= $self->index;
   $type ||= $self->type;
   $size ||= $self->size;
   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('open_scroll', $index) or return;
   $self->brik_help_run_undef_arg('open_scroll', $size) or return;

   my $timeout = $self->rtimeout;

   my %args = (
      scroll => "${timeout}s",
      scroll_in_qs => 1,  # By default (0), pass scroll_id in request body. When 1, pass 
                          # it in query string.
      index => $index,
      size => $size,
      body => $query,
   );
   if ($self->use_type) {
      if ($type ne '*') {
         $args{type} = $type;
      }
   }

   #
   # https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-scroll.html
   #
   my $scroll;
   eval {
      $scroll = $es->scroll_helper(%args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("open_scroll: failed: $@");
   }

   $self->_scroll($scroll);

   $self->log->verbose("open_scroll: opened with size [$size] and timeout [${timeout}s]");

   return $self->nodes;
}

#
# Search::Elasticsearch::Client::5_0::Scroll
#
sub close_scroll {
   my $self = shift;

   my $scroll = $self->_scroll;
   if (! defined($scroll)) {
      return 1;
   }

   $scroll->finish;
   $self->_scroll(undef);

   return 1;
}

sub total_scroll {
   my $self = shift;

   my $scroll = $self->_scroll;
   $self->brik_help_run_undef_arg('open_scroll', $scroll) or return;

   my $total;
   eval {
      $total = $scroll->total;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("total_scroll: failed with: [$@]");
   }

   return $total;
}

sub next_scroll {
   my $self = shift;
   my ($count) = @_;

   $count ||= 1;

   my $scroll = $self->_scroll;
   $self->brik_help_run_undef_arg('open_scroll', $scroll) or return;

   my $next;
   eval {
      if ($count > 1) {
         my @docs = $scroll->next($count);
         if (@docs > 0) {
            $next = \@docs;
         }
      }
      else {
         $next = $scroll->next;
      }
   };
   if ($@) {
      chomp($@);
      return $self->log->error("next_scroll: failed with: [$@]");
   }

   return $next;
}

#
# Search::Elasticsearch::Client::5_0::Direct
#
sub index_document {
   my $self = shift;
   my ($doc, $index, $type, $hash, $id) = @_;

   $index ||= $self->index;
   $type ||= $self->type;
   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('index_document', $doc) or return;
   $self->brik_help_run_invalid_arg('index_document', $doc, 'HASH') or return;
   $self->brik_help_set_undef_arg('index', $index) or return;
   $self->brik_help_set_undef_arg('type', $type) or return;

   my %args = (
      index => $index,
      body => $doc,
   );
   if (defined($id)) {
      $args{id} = $id;
   }

   if ($self->use_type) {
      $args{type} = $type;
   }

   if (defined($hash)) {
      $self->brik_help_run_invalid_arg('index_document', $hash, 'HASH')
         or return;
      my $this_hash = { %$hash };
      if (defined($hash->{routing}) && defined($doc->{$hash->{routing}})) {
         $this_hash->{routing} = $doc->{$hash->{routing}};
      }
      %args = ( %args, %$this_hash );
   }

   my $r;
   eval {
      $r = $es->index(%args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("index_document: index failed for ".
         "index [$index]: [$@]");
   }

   return $r;
}

#
# https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-reindex.html
#
sub reindex {
   my $self = shift;
   my ($index, $new, $type) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('reindex', $index) or return;
   $self->brik_help_run_undef_arg('reindex', $new) or return;

   my %args = (
      body => {
         conflicts => 'proceed',
         source => { index => $index },
         dest => { index => $new },
      },
      wait_for_completion => 'false',  # Immediately return the task.
   );

   # Change the type for destination doc
   if ($self->use_type) {
      if (defined($type)) {
         $args{body}{dest}{type} = $type;
      }
   }

   my $r;
   eval {
      $r = $es->reindex(%args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("reindex: reindex failed for index [$index]: [$@]");
   }

   return $r;
}

#
# List reindex tasks
#
# curl -X GET "localhost:9200/_tasks?detailed=true&actions=*reindex" | jq .
#
# Cancel reindex task
#
# curl -X POST "localhost:9200/_tasks/7VelPnOxQm21HtuJNFUAvQ:120914725/_cancel" | jq .
#

#
# Search::Elasticsearch::Client::6_0::Direct::Tasks
#
sub get_reindex_tasks {
   my $self = shift;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my $t = $es->tasks;

   my $list = $t->list;
   my $nodes = $list->{nodes};
   if (! defined($nodes)) {
      return $self->log->error("get_reindex_tasks: no nodes found");
   }

   my %tasks = ();
   for my $node (keys %$nodes) {
      for my $id (keys %{$nodes->{$node}}) {
         my $tasks = $nodes->{$node}{tasks};
         for my $task (keys %$tasks) {
            my $action = $tasks->{$task}{action};
            if ($action eq 'indices:data/write/reindex' && !exists($tasks{$task})) {
               $tasks{$task} = $tasks->{$task};
            }
         }
      }
   }

   return \%tasks;
}

sub cancel_reindex_task {
   my $self = shift;
   my ($id) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('cancel_reindex_task', $id) or return;

   my $t = $es->tasks;

   return $t->cancel(task_id => $id);
}

sub get_taskid {
   my $self = shift;
   my ($id) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('get_taskid', $id) or return;

   my $t = $es->tasks;

   return $t->get(task_id => $id);
}

sub show_reindex_progress {
   my $self = shift;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my $tasks = $self->get_reindex_tasks or return;
   if (! keys %$tasks) {
      $self->log->info("show_reindex_progress: no reindex task in progress");
      return 0;
   }

   for my $id (keys %$tasks) {
      my $task = $self->get_taskid($id) or next;

      my $status = $task->{task}{status};
      my $desc = $task->{task}{description};
      my $total = $status->{total};
      my $created = $status->{created};
      my $deleted = $status->{deleted};
      my $updated = $status->{updated};

      my $perc = ($created + $deleted + $updated) / $total * 100;

      printf("> Task [%s]: %.02f%%\n", $desc, $perc);
      print "created[$created] deleted[$deleted] updated[$updated] total[$total]\n";
   }

   return 1;
}

sub loop_show_reindex_progress {
   my $self = shift;
   my ($sec) = @_;

   $sec ||= 60;
   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   while (1) {
      $self->show_reindex_progress or return;
      sleep($sec);
   }

   return 1;
}

sub reindex_with_mapping_from_json_file {
   my $self = shift;
   my ($index, $new, $file) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('reindex_with_mapping_from_json_file', $index)
      or return;
   $self->brik_help_run_undef_arg('reindex_with_mapping_from_json_file', $new) or return;
   $self->brik_help_run_undef_arg('reindex_with_mapping_from_json_file', $file) or return;
   $self->brik_help_run_file_not_found('reindex_with_mapping_from_json_file', $file)
      or return;

   my $fj = Metabrik::File::Json->new_from_brik_init($self) or return;
   my $json = $fj->read($file) or return;

   return $self->reindex($index, $new, $json);
}

#
# Search::Elasticsearch::Client::5_0::Direct
#
# To execute this Command using routing requires to use the correct field
# value directly in $hash->{routing}. We cannot "guess" it from arguments,
# this would be a little bit complicated to do in an efficient way.
#
sub update_document {
   my $self = shift;
   my ($doc, $id, $index, $type, $hash) = @_;

   $index ||= $self->index;
   $type ||= $self->type;
   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('update_document', $doc) or return;
   $self->brik_help_run_invalid_arg('update_document', $doc, 'HASH') or return;
   $self->brik_help_run_undef_arg('update_document', $id) or return;
   $self->brik_help_set_undef_arg('index', $index) or return;
   $self->brik_help_set_undef_arg('type', $type) or return;

   my %args = (
      id => $id,
      index => $index,
      body => { doc => $doc },
   );

   if ($self->use_type) {
      $args{type} = $type;
   }

   if (defined($hash)) {
      $self->brik_help_run_invalid_arg('update_document', $hash, 'HASH')
         or return;
      %args = ( %args, %$hash );
   }

   my $r;
   eval {
      $r = $es->update(%args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("update_document: index failed for index [$index]: [$@]");
   }

   return $r;
}

#
# Search::Elasticsearch::Client::5_0::Bulk
#
sub index_bulk {
   my $self = shift;
   my ($doc, $index, $type, $hash, $id) = @_;

   my $bulk = $self->_bulk;
   $index ||= $self->index;
   $type ||= $self->type;
   $self->brik_help_run_undef_arg('open_bulk_mode', $bulk) or return;
   $self->brik_help_run_undef_arg('index_bulk', $doc) or return;
   $self->brik_help_set_undef_arg('index', $index) or return;
   $self->brik_help_set_undef_arg('type', $type) or return;

   my %args = (
      source => $doc,
   );
   if (defined($id)) {
      $args{id} = $id;
   }

   if (defined($hash)) {
      $self->brik_help_run_invalid_arg('index_bulk', $hash, 'HASH') or return;
      my $this_hash = { %$hash };
      if (defined($hash->{routing}) && defined($doc->{$hash->{routing}})) {
         $this_hash->{routing} = $doc->{$hash->{routing}};
      }
      %args = ( %args, %$this_hash );
   }

   my $r;
   eval {
      $r = $bulk->add_action(index => \%args);
   };
   if ($@) {
      chomp($@);
      my $p = $self->parse_error_string($@);
      if (defined($p) && exists($p->{class})) {
         my $class = $p->{class};
         my $code = $p->{code};
         my $node = $p->{node};
         return $self->log->error("index_bulk: failed for index [$index] with error ".
            "[$class] code [$code] for node [$node]");
      }
      else {
         return $self->log->error("index_bulk: index failed for index [$index]: [$@]");
      }
   }

   return $r;
}

#
# Allows to index multiple docs at one time
# $bulk->index({ source => $doc1 }, { source => $doc2 }, ...);
#
sub index_bulk_from_list {
   my $self = shift;
   my ($list, $index, $type, $hash) = @_;

   my $bulk = $self->_bulk;
   $index ||= $self->index;
   $type ||= $self->type;
   $self->brik_help_run_undef_arg('open_bulk_mode', $bulk) or return;
   $self->brik_help_run_undef_arg('index_bulk_from_list', $list) or return;
   $self->brik_help_run_invalid_arg('index_bulk_from_list', $list, 'ARRAY')
      or return;
   $self->brik_help_run_empty_array_arg('index_bulk_from_list', $list)
      or return;
   $self->brik_help_set_undef_arg('index', $index) or return;
   $self->brik_help_set_undef_arg('type', $type) or return;

   if (defined($hash)) {
      $self->brik_help_run_invalid_arg('index_bulk_from_list', $hash, 'HASH')
         or return;
   }

   my @args = ();
   for my $doc (@$list) {
      my %args = (
         source => $doc,
      );
      if (defined($hash)) {
         my $this_hash = { %$hash };
         if (defined($hash->{routing}) && defined($doc->{$hash->{routing}})) {
            $this_hash->{routing} = $doc->{$hash->{routing}};
         }
         %args = ( %args, %$this_hash );
      }
      push @args, \%args;
   }

   my $r;
   eval {
      $r = $bulk->index(@args);
   };
   if ($@) {
      chomp($@);
      my $p = $self->parse_error_string($@);
      if (defined($p) && exists($p->{class})) {
         my $class = $p->{class};
         my $code = $p->{code};
         my $node = $p->{node};
         return $self->log->error("index_bulk: failed for index [$index] with error ".
            "[$class] code [$code] for node [$node]");
      }
      else {
         return $self->log->error("index_bulk: index failed for index [$index]: [$@]");
      }
   }

   return $r;
}

#
# https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-forcemerge.html
#
sub clean_deleted_from_index {
   my $self = shift;
   my ($index) = @_;

   $self->brik_help_run_undef_arg('clean_deleted_from_index', $index) or return;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my $indices = $self->_es->indices;

   my $r;
   eval {
      $r = $indices->forcemerge(
         index => $index,
         only_expunge_deletes => 'true',
      );
   };
   if ($@) {
      chomp($@);
      my $p = $self->parse_error_string($@);
      if (defined($p) && exists($p->{class})) {
         my $class = $p->{class};
         my $code = $p->{code};
         my $node = $p->{node};
         return $self->log->error("clean_deleted_from_index: failed for index ".
            "[$index] with error [$class] code [$code] for node [$node]");
      }
      else {
         return $self->log->error("clean_deleted_from_index: index failed for ".
            "index [$index]: [$@]");
      }
   }

   return $r;
}

#
# To execute this Command using routing requires to use the correct field
# value directly in $hash->{routing}. We cannot "guess" it from arguments,
# this would be a little bit complicated to do in an efficient way.
#
sub update_document_bulk {
   my $self = shift;
   my ($doc, $index, $type, $hash, $id) = @_;

   my $bulk = $self->_bulk;
   $index ||= $self->index;
   $type ||= $self->type;
   $self->brik_help_run_undef_arg('open_bulk_mode', $bulk) or return;
   $self->brik_help_run_undef_arg('update_document_bulk', $doc) or return;
   $self->brik_help_set_undef_arg('index', $index) or return;
   $self->brik_help_set_undef_arg('type', $type) or return;

   my %args = (
      index => $index,
      doc => $doc,
   );

   if ($self->use_type) {
      $args{type} = $type;
   }

   if (defined($id)) {
      $args{id} = $id;
   }

   if (defined($hash)) {
      $self->brik_help_run_invalid_arg('update_document_bulk', $hash, 'HASH')
         or return;
      %args = ( %args, %$hash );
   }

   my $r;
   eval {
      $r = $bulk->update(\%args);
   };
   if ($@) {
      chomp($@);
      my $p = $self->parse_error_string($@);
      if (defined($p) && exists($p->{class})) {
         my $class = $p->{class};
         my $code = $p->{code};
         my $node = $p->{node};
         return $self->log->error("update_document_bulk: failed for index [$index] ".
            "with error [$class] code [$code] for node [$node]");
      }
      else {
         return $self->log->error("update_document_bulk: index failed for ".
            "index [$index]: [$@]");
      }
   }

   return $r;
}

#
# We may have to call refresh_index after a bulk_flush, so we give an additional 
# optional Argument for given index.
#
sub bulk_flush {
   my $self = shift;
   my ($index) = @_;

   my $bulk = $self->_bulk;
   $self->brik_help_run_undef_arg('open_bulk_mode', $bulk) or return;

   my $try = $self->try;

RETRY:

   my $r;
   eval {
      $r = $bulk->flush;
   };
   if ($@) {
      chomp($@);
      if (--$try == 0) {
         my $p = $self->parse_error_string($@);
         if (defined($p) && exists($p->{class})) {
            my $class = $p->{class};
            my $code = $p->{code};
            my $node = $p->{node};
            return $self->log->error("bulk_flush: failed after [$try] tries with error ".
               "[$class] code [$code] for node [$node]");
         }
         else {
            return $self->log->error("bulk_flush: failed after [$try]: [$@]");
         }
      }
      $self->log->warning("bulk_flush: sleeping 10 seconds before retry cause error ".
               "[$@]");
      sleep 10;
      goto RETRY;
   }

   if (defined($index)) {
      $self->refresh_index($index);
   }

   return $r;
}

#
# Search::Elasticsearch::Client::2_0::Direct
# Search::Elasticsearch::Client::5_0::Direct
#
sub count {
   my $self = shift;
   my ($index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;
   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my %args = ();
   if (defined($index) && $index ne '*') {
      $args{index} = $index;
   }
   if ($self->use_type) {
      if (defined($type) && $type ne '*') {
         $args{type} = $type;
      }
   }

   #$args{body} = {
      #query => {
         #match => { title => 'Elasticsearch clients' },
      #},
   #}

   my $r;
   my $version = $self->version or return;
   if ($version ge "5.0.0") {
      eval {
         $r = $es->count(%args);
      };
   }
   else {
      eval {
         my %this_args = (
            index => $index,
            search_type => 'count',
            body => {
               query => {
                  match_all => {},
               },
            },
         );
         if ($self->use_type) {
            $this_args{type} = $type;
         }
         $r = $es->search(%args);
      };
   }
   if ($@) {
      chomp($@);
      return $self->log->error("count: count failed for index [$index]: [$@]");
   }

   if ($version ge "5.0.0") {
      if (exists($r->{count})) {
         return $r->{count};
      }
   }
   elsif (exists($r->{hits}) && exists($r->{hits}{total})) {
      return $r->{hits}{total};
   }

   return $self->log->error("count: nothing found");
}

#
# https://www.elastic.co/guide/en/elasticsearch/reference/current/full-text-queries.html
# https://www.elastic.co/guide/en/elasticsearch/reference/current/search-request-body.html
#
# Example: my $q = { query => { term => { ip => "192.168.57.19" } } }
#
# To perform a query using routing requires to use the correct field
# value directly in $hash->{routing}. We cannot "guess" it from $q,
# this would be a little bit complicated to do in an efficient way.
#
sub query {
   my $self = shift;
   my ($query, $index, $type, $hash) = @_;

   $index ||= $self->index;
   $type ||= $self->type;
   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('query', $query) or return;
   $self->brik_help_set_undef_arg('index', $index) or return;
   $self->brik_help_set_undef_arg('type', $type) or return;
   $self->brik_help_run_invalid_arg('query', $query, 'HASH') or return;

   my $timeout = $self->rtimeout;

   my %args = (
      index => $index,
      body => $query,
   );

   if (defined($hash)) {
      $self->brik_help_run_invalid_arg('query', $hash, 'HASH') or return;
      %args = ( %args, %$hash );
   }

   if ($self->use_type) {
      if ($type ne '*') {
         $args{type} = $type;
      }
   }

   my $r;
   eval {
      $r = $es->search(%args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("query: failed for index [$index]: [$@]");
   }

   return $r;
}

sub get_from_id {
   my $self = shift;
   my ($id, $index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;
   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('get_from_id', $id) or return;
   $self->brik_help_set_undef_arg('index', $index) or return;
   $self->brik_help_set_undef_arg('type', $type) or return;

   my $r;
   eval {
      my %this_args = (
         index => $index,
         id => $id,
      );
      if ($self->use_type) {
         $this_args{type} = $type;
      }
      $r = $es->get(%this_args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("get_from_id: get failed for index [$index]: [$@]");
   }

   return $r;
}

#
# https://www.elastic.co/guide/en/elasticsearch/reference/current/search-uri-request.html
#
sub www_search {
   my $self = shift;
   my ($query, $index, $type) = @_;

   $index ||= $self->index;
   $type ||= $self->type;
   $self->brik_help_run_undef_arg('www_search', $query) or return;
   $self->brik_help_set_undef_arg('index', $index) or return;
   $self->brik_help_set_undef_arg('type', $type) or return;

   my $from = $self->from;
   my $size = $self->size;

   my $sj = Metabrik::String::Json->new_from_brik_init($self) or return;

   my $nodes = $self->nodes;
   for my $node (@$nodes) {
      # http://localhost:9200/INDEX/TYPE/_search/?size=SIZE&q=QUERY
      my $url = "$node/$index";
      if ($self->use_type) {
         if ($type ne '*') {
            $url .= "/$type";
         }
      }
      $url .= "/_search/?from=$from&size=$size&q=".$query;

      my $get = $self->SUPER::get($url) or next;
      my $body = $get->{content};

      my $decoded = $sj->decode($body) or next;

      return $decoded;
   }

   return;
}

#
# Search::Elasticsearch::Client::2_0::Direct::Indices
#
sub delete_index {
   my $self = shift;
   my ($index) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('delete_index', $index) or return;
   $self->brik_help_run_invalid_arg('delete_index', $index, 'ARRAY', 'SCALAR') or return;

   my %args = (
      index => $index,
   );

   my $r;
   eval {
      $r = $es->indices->delete(%args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("delete_index: delete failed for index [$index]: [$@]");
   }

   return $r;
}

#
# Search::Elasticsearch::Client::2_0::Direct::Indices
#
# To execute this Command using routing requires to use the correct field
# value directly in $hash->{routing}. We cannot "guess" it from arguments,
# this would be a little bit complicated to do in an efficient way.
#
sub delete_document {
   my $self = shift;
   my ($index, $type, $id, $hash) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('delete_document', $index) or return;
   $self->brik_help_run_undef_arg('delete_document', $type) or return;
   $self->brik_help_run_undef_arg('delete_document', $id) or return;

   my %args = (
      index => $index,
      id => $id,
   );

   if ($self->use_type) {
      $args{type} = $type;
   }

   if (defined($hash)) {
      $self->brik_help_run_invalid_arg('delete_document', $hash, 'HASH')
         or return;
      %args = ( %args, %$hash );
   }

   my $r;
   eval {
      $r = $es->delete(%args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("delete_document: delete failed for index [$index]: [$@]");
   }

   return $r;
}

#
# https://www.elastic.co/guide/en/elasticsearch/reference/current/docs-delete-by-query.html
#
# Example: my $q = { query => { term => { ip => "192.168.57.19" } } }
#
sub delete_by_query {
   my $self = shift;
   my ($query, $index, $type, $proceed) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('delete_by_query', $query) or return;
   $self->brik_help_run_undef_arg('delete_by_query', $index) or return;
   $self->brik_help_run_undef_arg('delete_by_query', $type) or return;
   $self->brik_help_run_invalid_arg('delete_by_query', $query, 'HASH') or return;

   my $timeout = $self->rtimeout;

   my %args = (
      index => $index,
      body => $query,
   );

   if ($self->use_type) {
      $args{type} = $type;
   }

   if (defined($proceed) && $proceed) {
      $args{conflicts} = 'proceed';
   }

   my $r;
   eval {
      $r = $es->delete_by_query(%args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("delete_by_query: failed for index [$index]: [$@]");
   }

   # This may fail, we ignore it.
   $self->refresh_index($index);

   return $r;
}

#
# Search::Elasticsearch::Client::2_0::Direct::Cat
#
# https://www.elastic.co/guide/en/elasticsearch/reference/current/cat-indices.html
#
sub show_indices {
   my $self = shift;
   my ($string) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my $r;
   eval {
      $r = $es->cat->indices;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("show_indices: failed: [$@]");
   }

   my @lines = split(/\n/, $r);

   if (@lines == 0) {
      $self->log->warning("show_indices: nothing returned, no index?");
   }

   my @filtered = ();
   if (defined($string)) {
      for (@lines) {
         if (m{$string}) {
            push @filtered, $_;
         }
      }
      @lines = @filtered;
   }

   return \@lines;
}

#
# Search::Elasticsearch::Client::2_0::Direct::Cat
#
sub show_nodes {
   my $self = shift;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my $r;
   eval {
      $r = $es->cat->nodes;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("show_nodes: failed: [$@]");
   }

   my @lines = split(/\n/, $r);

   if (@lines == 0) {
      $self->log->warning("show_nodes: nothing returned, no nodes?");
   }

   return \@lines;
}

#
# Search::Elasticsearch::Client::2_0::Direct::Cat
#
sub show_health {
   my $self = shift;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my $r;
   eval {
      $r = $es->cat->health;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("show_health: failed: [$@]");
   }

   my @lines = split(/\n/, $r);

   if (@lines == 0) {
      $self->log->warning("show_health: nothing returned, no recovery?");
   }

   return \@lines;
}

#
# Search::Elasticsearch::Client::2_0::Direct::Cat
#
sub show_recovery {
   my $self = shift;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my $r;
   eval {
      $r = $es->cat->recovery;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("show_recovery: failed: [$@]");
   }

   my @lines = split(/\n/, $r);

   if (@lines == 0) {
      $self->log->warning("show_recovery: nothing returned, no index?");
   }

   return \@lines;
}

#
# curl -s 'localhost:9200/_cat/allocation?v'
#
sub show_allocation {
   my $self = shift;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my $r;
   eval {
      $r = $es->cat->allocation;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("show_allocation: failed: [$@]");
   }

   my @lines = split(/\n/, $r);

   if (@lines == 0) {
      $self->log->warning("show_allocation: nothing returned, no index?");
   }

   return \@lines;
}

sub list_indices {
   my $self = shift;
   my ($regex) = @_;

   my $get = $self->get_indices or return;

   my @indices = ();
   for (@$get) {
      if (defined($regex)) {
         if ($_->{index} =~ m{$regex}) {
            push @indices, $_->{index};
         }
      }
      else {
         push @indices, $_->{index};
      }
   }

   return [ sort { $a cmp $b } @indices ];
}

sub get_indices {
   my $self = shift;
   my ($string) = @_;

   my $lines = $self->show_indices($string) or return;
   if (@$lines == 0) {
      $self->log->warning("get_indices: no index found");
      return [];
   }

   #
   # Format depends on ElasticSearch version. We try to detect the format.
   #
   # 5.0.0:
   # "yellow open www-2016-08-14 BmNE9RaBRSCKqB5Oe8yZcw 5 1  146 0 251.8kb 251.8kb"
   #
   my @indices = ();
   for (@$lines) {
      my @t = split(/\s+/);
      if (@t == 10) {  # Version 5.0.0
         my $color = $t[0];
         my $state = $t[1];
         my $index = $t[2];
         my $id = $t[3];
         my $shards = $t[4];
         my $replicas = $t[5];
         my $count = $t[6];
         my $count2 = $t[7];
         my $total_size = $t[8];
         my $size = $t[9];
         push @indices, {
            color => $color,
            state => $state,
            index => $index,
            id => $id,
            shards => $shards,
            replicas => $replicas,
            count => $count,
            total_size => $total_size,
            size => $size,
         };
      }
      elsif (@t == 9) {
         my $index = $t[2];
         push @indices, {
            index => $index,
         };
      }
      elsif (@t == 8) {
         my $index = $t[1];
         push @indices, {
            index => $index,
         };
      }
   }

   return \@indices;
}

#
# Search::Elasticsearch::Client::5_0::Direct::Indices
#
sub get_index {
   my $self = shift;
   my ($index) = @_;
 
   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('get_index', $index) or return;
   $self->brik_help_run_invalid_arg('get_index', $index, 'ARRAY', 'SCALAR') or return;

   my %args = (
      index => $index,
   );

   my $r;
   eval {
      $r = $es->indices->get(%args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("get_index: get failed for index [$index]: [$@]");
   }

   return $r;
}

sub get_index_stats {
   my $self = shift;
   my ($index) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('get_index', $index) or return;

   my %args = (
      index => $index,
   );

   my $r;
   eval {
      $r = $es->indices->stats(%args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("get_index_stats: get failed for index [$index]: ".
         "[$@]");
   }

   return $r->{indices}{$index};
}

sub list_index_types {
   my $self = shift;
   my ($index) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('list_index_types', $index) or return;
   $self->brik_help_run_invalid_arg('list_index_types', $index, 'SCALAR') or return;

   my $r = $self->get_mappings($index) or return;
   if (keys %$r > 1) {
      return $self->log->error("list_index_types: multiple indices found, choose one");
   }

   my @types = ();
   for my $this_index (keys %$r) {
      my $mappings = $r->{$this_index}{mappings};
      push @types, keys %$mappings;
   }

   my %uniq = map { $_ => 1 } @types;

   return [ sort { $a cmp $b } keys %uniq ];
}

#
# By default, if you provide only one index and no type,
# all types will be merged (including _default_)
# If you specify one type (other than _default_), _default_ will be merged to it.
#
sub list_index_fields {
   my $self = shift;
   my ($index, $type) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('list_index_fields', $index) or return;
   $self->brik_help_run_invalid_arg('list_index_fields', $index, 'SCALAR') or return;

   my $r;
   if (defined($type)) {
      $r = $self->get_mappings($index, $type) or return;
      if (keys %$r > 1) {
         return $self->log->error("list_index_fields: multiple indices found, ".
            "choose one");
      }
      # _default_ mapping may not exists.
      if ($self->is_mapping_exists($index, '_default_')) {
         my $r2 = $self->get_mappings($index, '_default_');
         # Merge
         for my $this_index (keys %$r2) {
            my $default = $r2->{$this_index}{mappings}{'_default_'};
            $r->{$this_index}{mappings}{_default_} = $default;
         }
      }
   }
   else {
      $r = $self->get_mappings($index) or return;
      if (keys %$r > 1) {
         return $self->log->error("list_index_fields: multiple indices found, ".
            "choose one");
      }
   }

   my @fields = ();
   for my $this_index (keys %$r) {
      my $mappings = $r->{$this_index}{mappings};
      for my $this_type (keys %$mappings) {
         my $properties = $mappings->{$this_type}{properties};
         push @fields, keys %$properties;
      }
   }

   my %uniq = map { $_ => 1 } @fields;

   return [ sort { $a cmp $b } keys %uniq ];
}

sub list_indices_version {
   my $self = shift;
   my ($index) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('list_indices_version', $index) or return;
   $self->brik_help_run_invalid_arg('list_indices_version', $index, 'ARRAY', 'SCALAR')
      or return;

   my $r = $self->get_index($index) or return;

   my @list = ();
   for my $this (keys %$r) {
      my $name = $this;
      my $version = $r->{$this}{settings}{index}{version}{created};
      push @list, {
         index => $name,
         version => $version,
      };
   }

   return \@list;
}

sub open_index {
   my $self = shift;
   my ($index) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('open_index', $index) or return;
   $self->brik_help_run_invalid_arg('open_index', $index, 'ARRAY', 'SCALAR') or return;

   my $r;
   eval {
      $r = $es->indices->open(
         index => $index,
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("open_index: failed: [$@]");
   }

   return $r;
}

sub close_index {
   my $self = shift;
   my ($index) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('close_index', $index) or return;
   $self->brik_help_run_invalid_arg('close_index', $index, 'ARRAY', 'SCALAR') or return;

   my $r;
   eval {
      $r = $es->indices->close(
         index => $index,
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("close_index: failed: [$@]");
   }

   return $r;
}

#
# Search::Elasticsearch::Client::5_0::Direct::Indices
#
sub get_aliases {
   my $self = shift;
   my ($index) = @_;

   $index ||= $self->index;
   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   #
   # [DEPRECATION] [types removal] The parameter include_type_name should be
   # explicitly specified in get indices requests to prepare for 7.0. In 7.0
   # include_type_name will default to 'false', which means responses will
   # omit the type name in mapping definitions. - In request: {body => undef,
   # ignore => [],method => "GET",path => "/*",qs => {},serialize => "std"}
   #

   my %args = (
      index => $index,
      params => { include_type_name => 'false' },
   );

   my $r;
   eval {
      $r = $es->indices->get(%args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("get_aliases: get_aliases failed: [$@]");
   }

   my %aliases = ();
   for my $this (keys %$r) {
      $aliases{$this} = $r->{$this}{aliases};
   }

   return \%aliases;
}

#
# Search::Elasticsearch::Client::5_0::Direct::Indices
#
sub put_alias {
   my $self = shift;
   my ($index, $alias) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('put_alias', $index) or return;
   $self->brik_help_run_undef_arg('put_alias', $alias) or return;

   my %args = (
      index => $index,
      name => $alias,
   );

   my $r;
   eval {
      $r = $es->indices->put_alias(%args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("put_alias: put_alias failed: [$@]");
   }

   return $r;
}

#
# Search::Elasticsearch::Client::5_0::Direct::Indices
#
sub delete_alias {
   my $self = shift;
   my ($index, $alias) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('delete_alias', $index) or return;
   $self->brik_help_run_undef_arg('delete_alias', $alias) or return;

   my %args = (
      index => $index,
      name => $alias,
   );

   my $r;
   eval {
      $r = $es->indices->delete_alias(%args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("delete_alias: delete_alias failed: [$@]");
   }

   return $r;
}

sub update_alias {
   my $self = shift;
   my ($new_index, $alias) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('update_alias', $new_index) or return;
   $self->brik_help_run_undef_arg('update_alias', $alias) or return;

   # Search for previous index with that alias, if any.
   my $prev_index;
   my $aliases = $self->get_aliases or return;
   while (my ($k, $v) = each %$aliases) {
      for my $this (keys %$v) {
         if ($this eq $alias) {
            $prev_index = $k;
            last;
         }
      }
      last if $prev_index;
   }

   # Delete previous alias if it exists.
   if (defined($prev_index)) {
      $self->delete_alias($prev_index, $alias) or return;
   }

   return $self->put_alias($new_index, $alias);
}

sub is_mapping_exists {
   my $self = shift;
   my ($index, $mapping) = @_;

   $self->brik_help_run_undef_arg('is_mapping_exists', $index) or return;
   $self->brik_help_run_undef_arg('is_mapping_exists', $mapping) or return;

   if (! $self->is_index_exists($index)) {
      return 0;
   }

   my $all = $self->get_mappings($index) or return;
   for my $this_index (keys %$all) {
      my $mappings = $all->{$this_index}{mappings};
      for my $this_mapping (keys %$mappings) {
         if ($this_mapping eq $mapping) {
            return 1;
         }
      }
   }

   return 0;
}

#
# Search::Elasticsearch::Client::2_0::Direct::Indices
#
sub get_mappings {
   my $self = shift;
   my ($index, $type) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('get_mappings', $index) or return;
   $self->brik_help_run_invalid_arg('get_mappings', $index, 'ARRAY', 'SCALAR') or return;

   my %args = (
      index => $index,
      params => { include_type_name => 'false' },
   );

   if ($self->use_type) {
      $args{type} = $type;
   }

   my $r;
   eval {
      $r = $es->indices->get_mapping(%args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("get_mappings: get_mapping failed for index [$index]: ".
         "[$@]");
   }

   return $r;
}

#
# Search::Elasticsearch::Client::2_0::Direct::Indices
#
sub create_index {
   my $self = shift;
   my ($index, $shards) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('create_index', $index) or return;

   my %args = (
      index => $index,
   );

   if (defined($shards)) {
      $args{body}{settings}{index}{number_of_shards} = $shards;
   }

   my $r;
   eval {
      $r = $es->indices->create(%args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("create_index: create failed ".
         "for index [$index]: [$@]");
   }
   
   return $r;
}

#
# https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-put-mapping.html
#
sub create_index_with_mappings {
   my $self = shift;
   my ($index, $mappings) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('create_index_with_mappings', $index) or return;
   $self->brik_help_run_undef_arg('create_index_with_mappings', $mappings) or return;
   $self->brik_help_run_invalid_arg('create_index_with_mappings', $mappings, 'HASH')
      or return;

   my $r;
   eval {
      $r = $es->indices->create(
         index => $index,
         body => {
            mappings => $mappings,
         },
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("create_index_with_mappings: create failed for ".
         "index [$index]: [$@]");
   }

   return $r;
}

# GET http://localhost:9200/
sub info {
   my $self = shift;
   my ($nodes) = @_;

   $nodes ||= $self->nodes;
   $self->brik_help_run_undef_arg('info', $nodes) or return;
   $self->brik_help_run_invalid_arg('info', $nodes, 'ARRAY') or return;
   $self->brik_help_run_empty_array_arg('info', $nodes) or return;

   my $first = $nodes->[0];

   $self->get($first) or return;

   return $self->content;
}

sub version {
   my $self = shift;
   my ($nodes) = @_;

   $nodes ||= $self->nodes;
   $self->brik_help_run_undef_arg('version', $nodes) or return;
   $self->brik_help_run_invalid_arg('version', $nodes, 'ARRAY') or return;
   $self->brik_help_run_empty_array_arg('version', $nodes) or return;

   my $first = $nodes->[0];

   $self->get($first) or return;
   my $content = $self->content or return;

   return $content->{version}{number};
}

#
# Search::Elasticsearch::Client::2_0::Direct::Indices
#
sub get_templates {
   my $self = shift;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my $r;
   eval {
      $r = $es->indices->get_template;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("get_templates: failed: [$@]");
   }

   return $r;
}

sub list_templates {
   my $self = shift;

   my $content = $self->get_templates or return;

   return [ sort { $a cmp $b } keys %$content ];
}

#
# http://www.elastic.co/guide/en/elasticsearch/reference/current/indices-templates.html
#
sub get_template {
   my $self = shift;
   my ($template) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('get_template', $template) or return;

   my $r;
   eval {
      $r = $es->indices->get_template(
         name => $template,
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("get_template: template failed for name [$template]: [$@]");
   }

   return $r;
}

sub put_mapping {
   my $self = shift;
   my ($index, $type, $mapping) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('put_mapping', $index) or return;
   $self->brik_help_run_undef_arg('put_mapping', $type) or return;
   $self->brik_help_run_undef_arg('put_mapping', $mapping) or return;
   $self->brik_help_run_invalid_arg('put_mapping', $mapping, 'HASH')
      or return;

   my $r;
   eval {
      my %this_args = (
         index => $index,
         body => $mapping,
      );
      if ($self->use_type) {
         $this_args{type} = $type;
      }
      $r = $es->indices->put_mapping(%this_args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("put_mapping: mapping failed ".
         "for index [$index]: [$@]");
   }

   return $r;
}

#
# http://www.elastic.co/guide/en/elasticsearch/reference/current/indices-templates.html
#
sub put_template {
   my $self = shift;
   my ($name, $template) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('put_template', $name) or return;
   $self->brik_help_run_undef_arg('put_template', $template) or return;
   $self->brik_help_run_invalid_arg('put_template', $template, 'HASH')
      or return;

   my $r;
   eval {
      $r = $es->indices->put_template(
         name => $name,
         body => $template,
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("put_template: template failed ".
         "for name [$name]: [$@]");
   }

   return $r;
}

sub put_mapping_from_json_file {
   my $self = shift;
   my ($index, $type, $json_file) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('put_mapping_from_json_file', $index)
      or return;
   $self->brik_help_run_undef_arg('put_mapping_from_json_file', $type)
      or return;
   $self->brik_help_run_undef_arg('put_mapping_from_json_file', $json_file)
      or return;
   $self->brik_help_run_file_not_found('put_mapping_from_json_file',
      $json_file) or return;

   my $fj = Metabrik::File::Json->new_from_brik_init($self) or return;
   my $data = $fj->read($json_file) or return;

   if (! exists($data->{mappings})) {
      return $self->log->error("put_mapping_from_json_file: no mapping ".
         "data found");
   }

   return $self->put_mapping($index, $type, $data->{mappings});
}

sub update_mapping_from_json_file {
   my $self = shift;
   my ($json_file, $index, $type) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('update_mapping_from_json_file',
      $json_file) or return;
   $self->brik_help_run_file_not_found('update_mapping_from_json_file',
      $json_file) or return;
   $self->brik_help_run_undef_arg('update_mapping_from_json_file',
      $type) or return;
   $self->brik_help_run_undef_arg('update_mapping_from_json_file',
      $index) or return;

   my $fj = Metabrik::File::Json->new_from_brik_init($self) or return;
   my $data = $fj->read($json_file) or return;

   if (! exists($data->{mappings})) {
      return $self->log->error("update_mapping_from_json_file: ".
         "no data found");
   }

   my $mappings = $data->{mappings};

   return $self->put_mapping($index, $type, $mappings);
}

sub put_template_from_json_file {
   my $self = shift;
   my ($json_file, $name) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('put_template_from_json_file', $json_file)
      or return;
   $self->brik_help_run_file_not_found('put_template_from_json_file',
      $json_file) or return;

   my $fj = Metabrik::File::Json->new_from_brik_init($self) or return;
   my $data = $fj->read($json_file) or return;

   if (!defined($name)) {
      ($name) = $json_file =~ m{([^/]+)\.json$};
   }

   if (! defined($name)) {
      return $self->log->error("put_template_from_json_file: no template ".
         "name found");
   }

   return $self->put_template($name, $data);
}

sub update_template_from_json_file {
   my $self = shift;
   my ($json_file, $name) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('update_template_from_json_file',
      $json_file) or return;
   $self->brik_help_run_file_not_found('update_template_from_json_file',
      $json_file) or return;

   my $fj = Metabrik::File::Json->new_from_brik_init($self) or return;
   my $data = $fj->read($json_file) or return;

   if (!defined($name)) {
      ($name) = $json_file =~ m{([^/]+)\.json$};
   }

   if (! defined($name)) {
      return $self->log->error("put_template_from_json_file: no template ".
         "name found");
   }

   # We ignore errors, template may not exist.
   $self->delete_template($name);

   return $self->put_template($name, $data);
}

#
# http://www.elastic.co/guide/en/elasticsearch/reference/current/indices-get-settings.html
# Search::Elasticsearch::Client::2_0::Direct::Indices
#
sub get_settings {
   my $self = shift;
   my ($indices, $names) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my %args = ();
   if (defined($indices)) {
      $self->brik_help_run_undef_arg('get_settings', $indices) or return;
      my $ref = $self->brik_help_run_invalid_arg('get_settings', $indices, 'ARRAY', 'SCALAR')
         or return;
      $args{index} = $indices;
   }
   if (defined($names)) {
      $self->brik_help_run_file_not_found('get_settings', $names) or return;
      my $ref = $self->brik_help_run_invalid_arg('get_settings', $names, 'ARRAY', 'SCALAR')
         or return;
      $args{name} = $names;
   }

   my $r;
   eval {
      $r = $es->indices->get_settings(%args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("get_settings: failed: [$@]");
   }

   return $r;
}

#
# http://www.elastic.co/guide/en/elasticsearch/reference/current/indices-get-settings.html
# Search::Elasticsearch::Client::2_0::Direct::Indices
#
# Example:
#
# run client::elasticsearch put_settings "{ index => { refresh_interval => -1 } }"
#
# XXX: should be renamed to put_index_settings
#
sub put_settings {
   my $self = shift;
   my ($settings, $indices) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('put_settings', $settings) or return;
   $self->brik_help_run_invalid_arg('put_settings', $settings, 'HASH') or return;

   my %args = (
      body => $settings,
   );
   if (defined($indices)) {
      $self->brik_help_run_undef_arg('put_settings', $indices) or return;
      my $ref = $self->brik_help_run_invalid_arg('put_settings', $indices, 'ARRAY', 'SCALAR')
         or return;
      $args{index} = $indices;
   }

   my $r;
   eval {
      $r = $es->indices->put_settings(%args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("put_settings: failed: [$@]");
   }

   return $r;
}

sub set_index_readonly {
   my $self = shift;
   my ($indices, $bool) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('set_index_readonly', $indices) or return;
   $self->brik_help_run_invalid_arg('set_index_readonly', $indices, 'ARRAY', 'SCALAR')
      or return;

   if (! defined($bool)) {
      $bool = 'true';
   }
   else {
      $bool = $bool ? 'true' : 'false';
   }

   my $settings = {
      'blocks.read_only' => $bool,
      'blocks.read_only_allow_delete' => 'true',
   };

   return $self->put_settings($settings, $indices);
}

#
# curl -XPUT -H "Content-Type: application/json" http://localhost:9200/_all/_settings -d '{"index.blocks.read_only_allow_delete": null}'
# PUT synscan-2018-05/_settings
# {
#  "index": {
#    "blocks":{
#      "read_only":"false",
#      "read_only_allow_delete":"true"
#    }
#  }
#}
#
#
# If it fails with the following error:
#
# [2018-09-12T13:38:40,012][INFO ][logstash.outputs.elasticsearch] retrying failed action with response code: 403 ({"type"=>"cluster_block_exception", "reason"=>"blocked by: [FORBIDDEN/12/index read-only / allow delete (api)];"})
#
# Use Kibana dev console and copy/paste both requests:
#
# PUT _all/_settings
# {
#    "index": {
#       "blocks": {
#          "read_only_allow_delete": "false"
#       }
#    }
# }
#
sub reset_index_readonly {
   my $self = shift;
   my ($indices) = @_;

   $indices ||= '*';
   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_invalid_arg('reset_index_readonly', $indices,
      'ARRAY', 'SCALAR') or return;

   my $settings = {
      blocks => {
         read_only_allow_delete => 'false',
      },
   };

   # Settings on '*' indices should be enough to reset for everyone.
   my $r = $self->put_settings($settings, $indices);
   #$self->log->info(Data::Dumper::Dumper($r));

   return 1;
}

sub list_index_readonly {
   my $self = shift;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my $list = $self->list_indices or return;

   my @indices = ();
   for my $this (@$list) {
      my $ro = $self->get_index_readonly($this) or next;
      if (defined($ro->{index}{provided_name})) {
         push @indices, $ro->{index}{provided_name};
      }
   }

   return \@indices;
}

sub set_index_number_of_replicas {
   my $self = shift;
   my ($indices, $number) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('set_index_number_of_replicas', $indices) or return;
   $self->brik_help_run_invalid_arg('set_index_number_of_replicas', $indices, 'ARRAY', 'SCALAR')
      or return;

   my $settings = { number_of_replicas => $number };

   return $self->put_settings($settings, $indices);
}

sub set_index_refresh_interval {
   my $self = shift;
   my ($indices, $number) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('set_index_refresh_interval', $indices) or return;
   $self->brik_help_run_invalid_arg('set_index_refresh_interval', $indices, 'ARRAY', 'SCALAR')
      or return;

   # If there is a meaningful value not postfixed with a unity,
   # we default to add a `s' for a number of seconds.
   if ($number =~ /^\d+$/ && $number > 0) {
      $number .= 's';
   }

   my $settings = { refresh_interval => $number };

   return $self->put_settings($settings, $indices);
}

sub get_index_settings {
   my $self = shift;
   my ($indices) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('get_index_settings', $indices) or return;
   $self->brik_help_run_invalid_arg('get_index_settings', $indices, 'ARRAY', 'SCALAR')
      or return;

   my $settings = $self->get_settings($indices);

   my %indices = ();
   for (keys %$settings) {
      $indices{$_} = $settings->{$_}{settings};
   }

   return \%indices;
}

sub get_index_readonly {
   my $self = shift;
   my ($indices) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('get_index_readonly', $indices) or return;
   $self->brik_help_run_invalid_arg('get_index_readonly', $indices, 'ARRAY', 'SCALAR')
      or return;

   my $settings = $self->get_settings($indices);

   my %indices = ();
   for (keys %$settings) {
      #$indices{$_} = $settings->{$_}{settings}{index}{'blocks_write'};
      $indices{$_} = $settings->{$_}{settings};
   }

   return \%indices;
}

sub get_index_number_of_replicas {
   my $self = shift;
   my ($indices) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('get_index_number_of_replicas', $indices) or return;
   $self->brik_help_run_invalid_arg('get_index_number_of_replicas', $indices, 'ARRAY', 'SCALAR')
      or return;

   my $settings = $self->get_settings($indices);

   my %indices = ();
   for (keys %$settings) {
      $indices{$_} = $settings->{$_}{settings}{index}{number_of_replicas};
   }

   return \%indices;
}

sub get_index_refresh_interval {
   my $self = shift;
   my ($indices, $number) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('get_index_refresh_interval', $indices) or return;
   $self->brik_help_run_invalid_arg('get_index_refresh_interval', $indices, 'ARRAY', 'SCALAR')
      or return;

   my $settings = $self->get_settings($indices);

   my %indices = ();
   for (keys %$settings) {
      $indices{$_} = $settings->{$_}{settings}{index}{refresh_interval};
   }

   return \%indices;
}

sub get_index_number_of_shards {
   my $self = shift;
   my ($indices, $number) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('get_index_number_of_shards', $indices) or return;
   $self->brik_help_run_invalid_arg('get_index_number_of_shards', $indices, 'ARRAY', 'SCALAR')
      or return;

   my $settings = $self->get_settings($indices);

   my %indices = ();
   for (keys %$settings) {
      $indices{$_} = $settings->{$_}{settings}{index}{number_of_shards};
   }

   return \%indices;
}

#
# http://www.elastic.co/guide/en/elasticsearch/reference/current/indices-templates.html
#
sub delete_template {
   my $self = shift;
   my ($name) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('delete_template', $name) or return;

   my $r;
   eval {
      $r = $es->indices->delete_template(
         name => $name,
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("delete_template: failed for name [$name]: [$@]");
   }

   return $r;
}

#
# Return a boolean to state for index existence
#
sub is_index_exists {
   my $self = shift;
   my ($index) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('is_index_exists', $index) or return;

   my $r;
   eval {
      $r = $es->indices->exists(
         index => $index,
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("is_index_exists: failed for index [$index]: [$@]");
   }

   return $r ? 1 : 0;
}

#
# Return a boolean to state for index with type existence
#
sub is_type_exists {
   my $self = shift;
   my ($index, $type) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('is_type_exists', $index) or return;
   $self->brik_help_run_undef_arg('is_type_exists', $type) or return;

   my $r;
   eval {
      my %this_args = (
         index => $index,
      );
      if ($self->use_type) {
         $this_args{type} = $type;
      }
      $r = $es->indices->exists_type(%this_args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("is_type_exists: failed for index [$index] and ".
         "type [$type]: [$@]");
   }

   return $r ? 1 : 0;
}

#
# Return a boolean to state for document existence
#
sub is_document_exists {
   my $self = shift;
   my ($index, $type, $document) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('is_document_exists', $index) or return;
   $self->brik_help_run_undef_arg('is_document_exists', $type) or return;
   $self->brik_help_run_undef_arg('is_document_exists', $document) or return;
   $self->brik_help_run_invalid_arg('is_document_exists', $document, 'HASH') or return;

   my $r;
   eval {
      my %this_args = (
         index => $index,
         %$document,
      );
      if ($self->use_type) {
         $this_args{type} = $type;
      }
      $r = $es->exists(%this_args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("is_document_exists: failed for index [$index] and ".
         "type [$type]: [$@]");
   }

   return $r ? 1 : 0;
}

sub parse_error_string {
   my $self = shift;
   my ($string) = @_;

   $self->brik_help_run_undef_arg('parse_error_string', $string) or return;

   # [Timeout] ** [http://X.Y.Z.1:9200]-[599] Timed out while waiting for socket to become ready for reading, called from sub Search::Elasticsearch::Role::Client::Direct::__ANON__ at /usr/local/lib/perl5/site_perl/Metabrik/Client/Elasticsearch.pm line 1466. With vars: {'status_code' => 599,'request' => {'body' => undef,'qs' => {},'ignore' => [],'serialize' => 'std','path' => '/index-thing/_refresh','method' => 'POST'}}

   my ($class, $node, $code, $message, $dump) = $string =~
      m{^\[([^]]+)\] \*\* \[([^]]+)\]\-\[(\d+)\] (.+)\. With vars: (.+)$};

   if (defined($dump) && length($dump)) {
      my $sd = Metabrik::String::Dump->new_from_brik_init($self) or return;
      $dump = $sd->decode($dump);
   }

   # Sanity check
   if (defined($node) && $node =~ m{^http} && $code =~ m{^\d+$}
   &&  defined($dump) && ref($dump) eq 'HASH') {
      return {
         class => $class,
         node => $node,
         code => $code,
         message => $message,
         dump => $dump,
      };
   }

   # Were not able to decode, we return as-is.
   return {
      message => $string,
   };
}

#
# Refresh an index to receive latest additions
#
# Search::Elasticsearch::Client::5_0::Direct::Indices
# https://www.elastic.co/guide/en/elasticsearch/reference/current/indices-refresh.html
#
sub refresh_index {
   my $self = shift;
   my ($index) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('refresh_index', $index) or return;

   my $try = $self->try;

RETRY:

   my $r;
   eval {
      $r = $es->indices->refresh(
         index => $index,
      );
   };
   if ($@) {
      if (--$try == 0) {
         chomp($@);
         my $p = $self->parse_error_string($@);
         if (defined($p) && exists($p->{class})) {
            my $class = $p->{class};
            my $code = $p->{code};
            my $node = $p->{node};
            return $self->log->error("refresh_index: failed for index [$index] ".
               "after [$try] tries with error [$class] code [$code] for node [$node]");
         }
         else {
            return $self->log->error("refresh_index: failed for index [$index] ".
               "after [$try]: [$@]");
         }
      }
      sleep 60;
      goto RETRY;
   }

   return $r;
}

sub export_as {
   my $self = shift;
   my ($format, $index, $size, $cb) = @_;

   $size ||= 10_000;
   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('export_as', $format) or return;
   $self->brik_help_run_undef_arg('export_as', $index) or return;
   $self->brik_help_run_undef_arg('export_as', $size) or return;

   if ($format ne 'csv' && $format ne 'json') {
      return $self->log->error("export_as: unsupported export format ".
         "[$format]");
   }

   my $max = $self->max;
   my $datadir = $self->datadir;

   $self->log->debug("export_as: selecting scroll Command...");

   my $scroll;
   my $version = $self->version or return;
   if ($version lt "5.0.0") {
      $scroll = $self->open_scroll_scan_mode($index, $size) or return;
   }
   else {
      $scroll = $self->open_scroll($index, $size) or return;
   }

   $self->log->debug("export_as: selecting scroll Command...OK.");

   my $fd = Metabrik::File::Dump->new_from_brik_init($self) or return;

   my $out;
   my $csv_header;
   if ($format eq 'csv') {
      $out = Metabrik::File::Csv->new_from_brik_init($self) or return;
      $out->encoding($self->encoding);
      $out->separator(',');
      $out->escape('\\');
      $out->append(1);
      $out->first_line_is_header(0);
      $out->write_header(1);
      $out->use_quoting(1);
      if (defined($self->csv_header)) {
         my $sorted = [ sort { $a cmp $b } @{$self->csv_header} ];
         $out->header($sorted);
      }
      if (defined($self->csv_encoded_fields)) {
         $out->encoded_fields($self->csv_encoded_fields);
      }
      if (defined($self->csv_object_fields)) {
         $out->object_fields($self->csv_object_fields);
      }

      $csv_header = $out->header;
   }
   elsif ($format eq 'json') {
      $out = Metabrik::File::Json->new_from_brik_init($self) or return;
      $out->encoding($self->encoding);
   }

   my $total = $self->total_scroll;
   $self->log->info("export_as: total [$total] for index [$index]");

   my %types = ();
   my $read = 0;
   my $skipped = 0;
   my $exported = 0;
   my $start = time();
   my $done = $datadir."/$index.exported";
   my $start_time = time();
   my %chunk = ();
   while (my $next = $self->next_scroll(10000)) {
      for my $this (@$next) {
         $read++;

         if (defined($cb)) {
            $this = $cb->($this);
            if (! defined($this)) {
               $self->log->error("export_as: callback failed for index ".
                  "[$index] at read [$read], skipping single entry");
               $skipped++;
               next;
            }
         }

         my $id = $this->{_id};
         my $doc = $this->{_source};
         # Prepare for when types will be removed from ES
         my $type = $this->{_type} || '_doc';
         if (! exists($types{$type})) {
            if ($format eq 'csv') {
               # If not given, we guess the CSV fields to use.
               if (! defined($csv_header)) {
                  my $fields = $self->list_index_fields($index, $type)
                     or return;
                  $types{$type}{header} = [ '_id', @$fields ];
               }
               else {
                  $types{$type}{header} = [ '_id', @$csv_header ];
               }

               $types{$type}{output} = $datadir."/$index:$type.csv";
            }
            elsif ($format eq 'json') {
               $types{$type}{output} = $datadir."/$index:$type.json";
            }

            # Verify it has not been exported yet
            if (-f $done) {
               return $self->log->error("export_as: export already done ".
                  "for index [$index]");
            }

            $self->log->info("export_as: exporting to file [".
               $types{$type}{output}."] for type [$type], using ".
               "chunk size of [$size]");
         }

         my $h = { _id => $id };

         for my $k (keys %$doc) {
            $h->{$k} = $doc->{$k};
         }

         if ($format eq 'csv') {
            $out->header($types{$type}{header});
         }

         push @{$chunk{$type}}, $h;
         if (@{$chunk{$type}} > 999) {
            my $r = $out->write($chunk{$type}, $types{$type}{output});
            if (!defined($r)) {
               $self->log->warning("export_as: unable to process entry, ".
                  "skipping");
               $skipped++;
               next;
            }
            $chunk{$type} = [];
         }

         # Log a status sometimes.
         if (! (++$exported % 100_000)) {
            my $now = time();
            my $perc = sprintf("%.02f", $exported / $total * 100);
            $self->log->info("export_as: fetched [$exported/$total] ".
               "($perc%) elements in ".($now - $start)." second(s) ".
               "from index [$index]");
            $start = time();
         }

         # Limit export to specified maximum
         if ($max > 0 && $exported >= $max) {
            $self->log->info("export_as: max export reached [$exported] ".
               "for index [$index], stopping");
            last;
         }
      }
   }

   # Process remaining data waiting to be written and build output file list
   my %files = ();
   for my $type (keys %types) {
      if (@{$chunk{$type}} > 0) {
         $out->write($chunk{$type}, $types{$type}{output});
         $files{$types{$type}{output}}++;
      }
   }

   $self->close_scroll;

   my $stop_time = time();
   my $duration = $stop_time - $start_time;
   my $eps = $exported;
   if ($duration > 0) {
      $eps = $exported / $duration;
   }

   my $result = {
      read => $read,
      exported => $exported,
      skipped => $read - $exported,
      total_count => $total,
      complete => ($exported == $total) ? 1 : 0,
      duration => $duration,
      eps => $eps, 
      files => [ sort { $a cmp $b } keys %files ],
   };

   # Say the file has been processed, and put resulting stats.
   $fd->write($result, $done) or return;

   $self->log->info("export_as: done.");

   return $result;
}

sub export_as_csv {
   my $self = shift;
   my ($index, $size, $cb) = @_;

   $size ||= 10_000;
   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('export_as_csv', $index) or return;
   $self->brik_help_run_undef_arg('export_as_csv', $size) or return;

   return $self->export_as('csv', $index, $size, $cb);
}

sub export_as_json {
   my $self = shift;
   my ($index, $size, $cb) = @_;

   $size ||= 10_000;
   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('export_as_json', $index) or return;
   $self->brik_help_run_undef_arg('export_as_json', $size) or return;

   return $self->export_as('json', $index, $size, $cb);
}

#
# Optimization instructions:
# https://www.elastic.co/guide/en/elasticsearch/reference/master/tune-for-indexing-speed.html
#
sub import_from {
   my $self = shift;
   my ($format, $input, $index, $type, $hash, $cb) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('import_from', $format) or return;
   $self->brik_help_run_undef_arg('import_from', $input) or return;
   $self->brik_help_run_file_not_found('import_from', $input) or return;

   if ($format ne 'csv' && $format ne 'json') {
      return $self->log->error("import_from: unsupported export format ".
         "[$format]");
   }

   # If index and/or types are not defined, we try to get them from
   # input filename
   if (! defined($index) || ! defined($type)) {
      # Example: index-DATE:type.csv
      if ($input =~ m{^(.+):(.+)\.(?:csv|json)(?:.*)?$}) {
         my ($this_index, $this_type) = $input =~
            m{^(.+):(.+)\.(?:csv|json)(?:.*)?$};
         $index ||= $this_index;
         $type ||= $this_type;
      }
   }

   # Verify it has not been indexed yet
   my $done = "$input.imported";
   if (-f $done) {
      $self->log->info("import_from: import already done for file ".
         "[$input]");
      return 0;
   }

   # And default to Attributes if guess failed.
   $index ||= $self->index;
   $type ||= $self->type;
   $self->brik_help_set_undef_arg('index', $index) or return;
   $self->brik_help_set_undef_arg('type', $type) or return;

   if ($index eq '*') {
      return $self->log->error("import_from: cannot import to invalid ".
         "index [$index]");
   }
   if ($self->use_type) {
      if ($type eq '*') {
         return $self->log->error("import_from: cannot import to invalid ".
            "type [$type]");
      }
   }

   $self->log->debug("input [$input]");
   $self->log->debug("index [$index]");
   $self->log->debug("type [$type]");

   my $count_before = 0;
   if ($self->is_index_exists($index)) {
      $count_before = $self->count($index, $type);
      if (! defined($count_before)) {
         return;
      }
      $self->log->info("import_from: current index [$index] count is ".
         "[$count_before]");
   }

   my $max = $self->max;

   $self->open_bulk_mode($index, $type) or return;

   $self->log->info("import_from: importing file [$input] to index ".
      "[$index] with type [$type]");

   my $fd = Metabrik::File::Dump->new_from_brik_init($self) or return;

   my $out;
   if ($format eq 'csv') {
      $out = Metabrik::File::Csv->new_from_brik_init($self) or return;
      $out->encoding($self->encoding);
      $out->separator(',');
      $out->escape('\\');
      $out->first_line_is_header(1);
      $out->encoded_fields($self->csv_encoded_fields);
      $out->object_fields($self->csv_object_fields);
   }
   elsif ($format eq 'json') {
      $out = Metabrik::File::Json->new_from_brik_init($self) or return;
      $out->encoding($self->encoding);
   }

   my $refresh_interval;
   my $number_of_replicas;
   my $start = time();
   my $speed_settings = {};
   my $imported = 0;
   my $first = 1;
   my $read = 0;
   my $skipped_chunks = 0;
   my $start_time = time();
   while (my $this = $out->read_next($input)) {
      $read++;

      my $h = {};
      my $id = $self->use_ignore_id ? undef : $this->{_id};
      delete $this->{_id};
      for my $k (keys %$this) {
         my $value = $this->{$k};
         # We keep only fields when they have a value.
         # No need to index data that is empty.
         if (defined($value) && length($value)) {
            $h->{$k} = $value;
         }
      }

      if (defined($cb)) {
         $h = $cb->($h);
         if (! defined($h)) {
            $self->log->error("import_from: callback failed for ".
               "index [$index] at read [$read], skipping single entry");
            $skipped_chunks++;
            next;
         }
      }

      # Set routing based on the provided field name, if any.
      my $this_hash;
      if (defined($hash) && defined($hash->{routing})
      &&  defined($h->{$hash->{routing}})) {
         $this_hash = { %$hash };  # Make a copy to avoid overwriting
                                   # user provided value.
         $this_hash->{routing} = $h->{$hash->{routing}};
      }

      #$self->log->info(Data::Dumper::Dumper($h));

      my $r;
      eval {
         $r = $self->index_bulk($h, $index, $type, $this_hash, $id);
      };
      if ($@) {
         chomp($@);
         $self->log->warning("import_from: error [$@]");
      }
      if (! defined($r)) {
         $self->log->error("import_from: bulk processing failed for ".
            "index [$index] at read [$read], skipping chunk");
         $skipped_chunks++;
         next;
      }

      # Gather index settings, and set values for speed.
      # We don't do it earlier, cause we need index to be created,
      # and it should have been done from index_bulk Command.
      if ($first && $self->is_index_exists($index)) {
         # Save current values so we can restore them at the end of Command.
         # We ignore errors here, this is non-blocking for indexing.
         $refresh_interval = $self->get_index_refresh_interval($index);
         $refresh_interval = $refresh_interval->{$index};
         $number_of_replicas = $self->get_index_number_of_replicas($index);
         $number_of_replicas = $number_of_replicas->{$index};
         if ($self->use_indexing_optimizations) {
            $self->set_index_number_of_replicas($index, 0);
         }
         $self->set_index_refresh_interval($index, -1);
         $first = 0;
      }

      # Log a status sometimes.
      if (! (++$imported % 100_000)) {
         my $now = time();
         $self->log->info("import_from: imported [$imported] entries in ".
            ($now - $start)." second(s) to index [$index]");
         $start = time();
      }

      # Limit import to specified maximum
      if ($max > 0 && $imported >= $max) {
         $self->log->info("import_from: max import reached [$imported] for ".
            "index [$index], stopping");
         last;
      }
   }

   $self->bulk_flush;

   my $stop_time = time();
   my $duration = $stop_time - $start_time;
   my $eps = sprintf("%.02f", $imported / ($duration || 1)); # Avoid divide by zero error.

   $self->refresh_index($index);

   my $count_current = $self->count($index, $type) or return;
   $self->log->info("import_from: after index [$index] count is [$count_current] ".
      "at EPS [$eps]");

   my $skipped = 0;
   my $complete = (($count_current - $count_before) == $read) ? 1 : 0;
   if ($complete) {  # If complete, import has been retried, and everything is now ok.
      $imported = $read;
   }
   else {
      $skipped = $read - ($count_current - $count_before);
   }

   my $result = {
      read => $read,
      imported => $imported,
      skipped => $skipped,
      previous_count => $count_before,
      current_count => $count_current,
      complete => $complete,
      duration => $duration,
      eps => $eps,
   };

   # Say the file has been processed, and put resulting stats.
   $fd->write($result, $done) or return;

   # Restore previous settings, if any
   if (defined($refresh_interval)) {
      $self->set_index_refresh_interval($index, $refresh_interval);
   }
   if (defined($number_of_replicas) && $self->use_indexing_optimizations) {
      $self->set_index_number_of_replicas($index, $number_of_replicas);
   }

   return $result;
}

sub import_from_csv {
   my $self = shift;
   my ($input, $index, $type, $hash, $cb) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('import_from_csv', $input) or return;
   $self->brik_help_run_file_not_found('import_from_csv', $input)
      or return;

   return $self->import_from('csv', $input, $index, $type, $hash, $cb);
}

sub import_from_json {
   my $self = shift;
   my ($input, $index, $type, $hash, $cb) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('import_from_json', $input) or return;
   $self->brik_help_run_file_not_found('import_from_json', $input)
      or return;

   return $self->import_from('json', $input, $index, $type, $hash, $cb);
}

#
# Same as import_from_csv Command but in worker mode for speed.
#
sub import_from_csv_worker {
   my $self = shift;
   my ($input_csv, $index, $type, $hash, $cb) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('import_from_csv_worker', $input_csv)
      or return;
   $self->brik_help_run_file_not_found('import_from_csv_worker', $input_csv)
      or return;

   # If index and/or types are not defined, we try to get them from input filename
   if (! defined($index) || ! defined($type)) {
      # Example: index-DATE:type.csv
      if ($input_csv =~ m{^(.+):(.+)\.csv(?:.*)?$}) {
         my ($this_index, $this_type) = $input_csv =~ m{^(.+):(.+)\.csv(?:.*)?$};
         $index ||= $this_index;
         $type ||= $this_type;
      }
   }

   # Verify it has not been indexed yet
   my $done = "$input_csv.imported";
   if (-f $done) {
      $self->log->info("import_from_csv_worker: import already done for ".
         "file [$input_csv]");
      return 0;
   }

   # And default to Attributes if guess failed.
   $index ||= $self->index;
   $type ||= $self->type;
   $self->brik_help_set_undef_arg('index', $index) or return;
   $self->brik_help_set_undef_arg('type', $type) or return;

   if ($index eq '*') {
      return $self->log->error("import_from_csv_worker: cannot import to invalid ".
         "index [$index]");
   }
   if ($self->use_type) {
      if ($type eq '*') {
         return $self->log->error("import_from_csv_worker: cannot import to ".
            "invalid type [$type]");
      }
   }

   $self->log->debug("input [$input_csv]");
   $self->log->debug("index [$index]");
   $self->log->debug("type [$type]");

   my $count_before = 0;
   if ($self->is_index_exists($index)) {
      $count_before = $self->count($index, $type);
      if (! defined($count_before)) {
         return;
      }
      $self->log->info("import_from_csv_worker: current index [$index] count is ".
         "[$count_before]");
   }

   my $max = $self->max;

   $self->open_bulk_mode($index, $type) or return;

   #my $batch = undef;
   my $batch = 10_000;

   $self->log->info("import_from_csv_worker: importing file [$input_csv] to ".
      "index [$index] with type [$type] and batch [$batch]");

   my $fd = Metabrik::File::Dump->new_from_brik_init($self) or return;

   my $fc = Metabrik::File::Csv->new_from_brik_init($self) or return;
   $fc->separator(',');
   $fc->escape('\\');
   $fc->first_line_is_header(1);
   $fc->encoded_fields($self->csv_encoded_fields);
   $fc->object_fields($self->csv_object_fields);

   my $wp = Metabrik::Worker::Parallel->new_from_brik_init($self) or return;
   $wp->pool_size(2);

   $wp->create_manager or return;

   my $refresh_interval;
   my $number_of_replicas;
   my $start = time();
   my $speed_settings = {};
   my $imported = 0;
   my $first = 1;
   my $read = 0;
   my $skipped_chunks = 0;
   my $start_time = time();
   while (my $list = $fc->read_next($input_csv, $batch)) {

      $wp->start(sub {
         my @list = ();
         for my $this (@$list) {
            $read++;

            my $h = {};
            my $id = $this->{_id};
            delete $this->{_id};
            for my $k (keys %$this) {
               my $value = $this->{$k};
               # We keep only fields when they have a value.
               # No need to index data that is empty.
               if (defined($value) && length($value)) {
                  $h->{$k} = $value;
               }
            }

            if (defined($cb)) {
               $h = $cb->($h);
               if (! defined($h)) {
                  $self->log->error("import_from_csv_worker: callback failed for ".
                     "index [$index] at read [$read], skipping single entry");
                  $skipped_chunks++;
                  next;
               }
            }

            push @list, $h;
         }

         my $r;
         eval {
            $r = $self->index_bulk_from_list(\@list, $index, $type, $hash);
         };
         if ($@) {
            chomp($@);
            $self->log->warning("import_from_csv_worker: error [$@]");
         }
         if (! defined($r)) {
            $self->log->error("import_from_csv_worker: bulk processing failed for ".
               "index [$index] at read [$read], skipping chunk");
            $skipped_chunks++;
            next;
         }

         # Log a status sometimes.
         if (! ($imported % 10_000)) {
            my $now = time();
            my $diff = sprintf("%.02f", $now - $start);
            my $eps = sprintf("%.02f", $imported / $diff);
            $self->log->info("import_from_csv_worker: imported [$imported] entries ".
               "in [$diff] second(s) to index [$index] at EPS [$eps]");
            $start = time();
         }

         exit(0);
      });

      # Gather index settings, and set values for speed.
      # We don't do it earlier, cause we need index to be created,
      # and it should have been done from index_bulk Command.
      if ($first && $self->is_index_exists($index)) {
         # Save current values so we can restore them at the end of Command.
         # We ignore errors here, this is non-blocking for indexing.
         $refresh_interval = $self->get_index_refresh_interval($index);
         $refresh_interval = $refresh_interval->{$index};
         $number_of_replicas = $self->get_index_number_of_replicas($index);
         $number_of_replicas = $number_of_replicas->{$index};
         if ($self->use_indexing_optimizations) {
            $self->set_index_number_of_replicas($index, 0);
         }
         $self->set_index_refresh_interval($index, -1);
         $first = 0;
      }

      # Log a status sometimes.
      #$imported += @$list;
      #if (! ($imported % 10_000)) {
         #my $now = time();
         #my $diff = sprintf("%.02f", $now - $start);
         #my $eps = sprintf("%.02f", 10_000 / $diff);
         #$self->log->info("import_from_csv_worker: imported [$imported] entries ".
            #"in [$diff] second(s) to index [$index] at EPS [$eps]");
         #$start = time();
      #}

      # Limit import to specified maximum
      if ($max > 0 && $imported >= $max) {
         $self->log->info("import_from_csv_worker: max import reached [$imported] for ".
            "index [$index], stopping");
         last;
      }

      last if (@$list < $batch);

      $imported += @$list;
   }

   $wp->stop;

   $self->bulk_flush;

   my $stop_time = time();
   my $duration = $stop_time - $start_time;
   my $eps = sprintf("%.02f", $imported / ($duration || 1)); # Avoid divide by zero error.

   $self->refresh_index($index);

   my $count_current = $self->count($index, $type) or return;
   $self->log->info("import_from_csv_worker: after index [$index] count ".
      "is [$count_current] at EPS [$eps]");

   my $skipped = 0;
   my $complete = (($count_current - $count_before) == $read) ? 1 : 0;
   if ($complete) {  # If complete, import has been retried, and everything is now ok.
      $imported = $read;
   }
   else {
      $skipped = $read - ($count_current - $count_before);
   }

   my $result = {
      read => $read,
      imported => $imported,
      skipped => $skipped,
      previous_count => $count_before,
      current_count => $count_current,
      complete => $complete,
      duration => $duration,
      eps => $eps,
   };

   # Say the file has been processed, and put resulting stats.
   $fd->write($result, $done) or return;

   # Restore previous settings, if any
   if (defined($refresh_interval)) {
      $self->set_index_refresh_interval($index, $refresh_interval);
   }
   if (defined($number_of_replicas) && $self->use_indexing_optimizations) {
      $self->set_index_number_of_replicas($index, $number_of_replicas);
   }

   return $result;
}

#
# http://localhost:9200/_nodes/stats/process?pretty
#
# Search::Elasticsearch::Client::2_0::Direct::Nodes
#
sub get_stats_process {
   my $self = shift;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my $r;
   eval {
      $r = $es->nodes->stats(
         metric => [ qw(process) ],
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("get_stats_process: failed: [$@]");
   }

   return $r;
}

#
# curl http://localhost:9200/_nodes/process?pretty
#
# Search::Elasticsearch::Client::2_0::Direct::Nodes
#
sub get_process {
   my $self = shift;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my $r;
   eval {
      $r = $es->nodes->info(
         metric => [ qw(process) ],
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("get_process: failed: [$@]");
   }

   return $r;
}

#
# Search::Elasticsearch::Client::2_0::Direct::Cluster
#
sub get_cluster_state {
   my $self = shift;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my $r;
   eval {
      $r = $es->cluster->state;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("get_cluster_state: failed: [$@]");
   }

   return $r;
}

#
# Search::Elasticsearch::Client::2_0::Direct::Cluster
#
sub get_cluster_health {
   my $self = shift;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my $r;
   eval {
      $r = $es->cluster->health;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("get_cluster_health: failed: [$@]");
   }

   return $r;
}

#
# Search::Elasticsearch::Client::2_0::Direct::Cluster
#
sub get_cluster_settings {
   my $self = shift;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my $r;
   eval {
      $r = $es->cluster->get_settings;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("get_cluster_settings: failed: [$@]");
   }

   return $r;
}

#
# Search::Elasticsearch::Client::2_0::Direct::Cluster
#
sub put_cluster_settings {
   my $self = shift;
   my ($settings) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('put_cluster_settings', $settings) or return;
   $self->brik_help_run_invalid_arg('put_cluster_settings', $settings, 'HASH') or return;

   my %args = (
      body => $settings,
   );

   my $r;
   eval {
      $r = $es->cluster->put_settings(%args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("put_cluster_settings: failed: [$@]");
   }

   return $r;
}

sub count_green_indices {
   my $self = shift;

   my $get = $self->show_indices or return;

   my $count = 0;
   for (@$get) {
      if (/^\s*green\s+/) {
         $count++;
      }
   }

   return $count;
}

sub count_yellow_indices {
   my $self = shift;

   my $get = $self->show_indices or return;

   my $count = 0;
   for (@$get) {
      if (/^\s*yellow\s+/) {
         $count++;
      }
   }

   return $count;
}

sub count_red_indices {
   my $self = shift;

   my $get = $self->show_indices or return;

   my $count = 0;
   for (@$get) {
      if (/^\s*red\s+/) {
         $count++;
      }
   }

   return $count;
}

sub count_indices {
   my $self = shift;

   my $get = $self->show_indices or return;

   return scalar @$get;
}

sub list_indices_status {
   my $self = shift;

   my $get = $self->show_indices or return;

   my $count_red = 0;
   my $count_yellow = 0;
   my $count_green = 0;
   for (@$get) {
      if (/^\s*red\s+/) {
         $count_red++;
      }
      elsif (/^\s*yellow\s+/) {
         $count_yellow++;
      }
      elsif (/^\s*green\s+/) {
         $count_green++;
      }
   }

   return {
      red => $count_red,
      yellow => $count_yellow,
      green => $count_green,
   };
}

sub count_shards {
   my $self = shift;

   my $indices = $self->get_indices or return;

   my $count = 0;
   for (@$indices) {
      $count += $_->{shards};
   }

   return $count;
}

sub count_size {
   my $self = shift;
   my ($string) = @_;

   my $indices = $self->get_indices($string) or return;

   my $fn = Metabrik::Format::Number->new_from_brik_init($self) or return;
   $fn->decimal_point(".");
   $fn->kibi_suffix("kb");
   $fn->mebi_suffix("mb");
   $fn->gibi_suffix("gb");
   $fn->kilo_suffix("KB");
   $fn->mega_suffix("MB");
   $fn->giga_suffix("GB");

   my $size = 0;
   for (@$indices) {
      $size += $fn->to_number($_->{size});
   }

   return $fn->from_number($size);
}

sub count_total_size {
   my $self = shift;
   my ($string) = @_;

   my $indices = $self->get_indices($string) or return;

   my $fn = Metabrik::Format::Number->new_from_brik_init($self) or return;
   $fn->decimal_point(".");
   $fn->kibi_suffix("kb");
   $fn->mebi_suffix("mb");
   $fn->gibi_suffix("gb");
   $fn->kilo_suffix("KB");
   $fn->mega_suffix("MB");
   $fn->giga_suffix("GB");

   my $size = 0;
   for (@$indices) {
      $size += $fn->to_number($_->{total_size});
   }

   return $fn->from_number($size);
}

sub count_count {
   my $self = shift;

   my $indices = $self->get_indices or return;

   my $fn = Metabrik::Format::Number->new_from_brik_init($self) or return;
   $fn->kilo_suffix('k');
   $fn->mega_suffix('m');
   $fn->giga_suffix('M');

   my $count = 0;
   for (@$indices) {
      $count += $_->{count};
   }

   return $fn->from_number($count);
}

sub list_green_indices {
   my $self = shift;

   my $get = $self->get_indices or return;

   my @indices = ();
   for (@$get) {
      if ($_->{color} eq 'green') {
         push @indices, $_->{index};
      }
   }

   return \@indices;
}

sub list_yellow_indices {
   my $self = shift;

   my $get = $self->get_indices or return;

   my @indices = ();
   for (@$get) {
      if ($_->{color} eq 'yellow') {
         push @indices, $_->{index};
      }
   }

   return \@indices;
}

sub list_red_indices {
   my $self = shift;

   my $get = $self->get_indices or return;

   my @indices = ();
   for (@$get) {
      if ($_->{color} eq 'red') {
         push @indices, $_->{index};
      }
   }

   return \@indices;
}

#
# https://www.elastic.co/guide/en/elasticsearch/reference/current/mapping-types.html
#
sub list_datatypes {
   my $self = shift;

   return {
      core => [ qw(string long integer short byte double float data boolean binary) ],
   };
}

#
# Return total hits for last www_search
#
sub get_hits_total {
   my $self = shift;
   my ($run) = @_;

   $self->brik_help_run_undef_arg('get_hits_total', $run) or return;

   if (ref($run) eq 'HASH') {
      if (exists($run->{hits}) && exists($run->{hits}{total})) {
         return $run->{hits}{total};
      }
   }

   return $self->log->error("get_hits_total: last Command not compatible");
}

sub disable_shard_allocation {
   my $self = shift;

   my $settings = {
      persistent => {
         'cluster.routing.allocation.enable' => 'none',
      }
   };

   return $self->put_cluster_settings($settings);
}

sub enable_shard_allocation {
   my $self = shift;

   my $settings = {
      persistent => { 
         'cluster.routing.allocation.enable' => 'all',
      }
   };

   return $self->put_cluster_settings($settings);
}

sub flush_synced {
   my $self = shift;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my $r;
   eval {
      $r = $es->indices->flush_synced;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("flush_synced: failed: [$@]");
   }

   return $r;
}

#
# https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-snapshots.html
#
# run client::elasticsearch create_snapshot_repository myrepo 
#      "{ type => 'fs', settings => { compress => 'true', location => '/path/' } }"
#
# You have to set path.repo in elasticsearch.yml like:
# path.repo: ["/home/gomor/es-backups"]
#
# Search::Elasticsearch::Client::2_0::Direct::Snapshot
#
sub create_snapshot_repository {
   my $self = shift;
   my ($body, $repository_name) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('create_snapshot_repository', $body) or return;

   $repository_name ||= 'repository';

   my %args = (
      repository => $repository_name,
      body => $body,
   );

   my $r;
   eval {
      $r = $es->snapshot->create_repository(%args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("create_snapshot_repository: failed: [$@]");
   }

   return $r;
}

sub create_shared_fs_snapshot_repository {
   my $self = shift;
   my ($location, $repository_name) = @_;

   $repository_name ||= 'repository';
   $self->brik_help_run_undef_arg('create_shared_fs_snapshot_repository', $location) or return;

   if ($location !~ m{^/}) {
      return $self->log->error("create_shared_fs_snapshot_repository: you have to give ".
         "a full directory path, this one is invalid [$location]");
   }

   my $body = {
      #type => 'fs',
      settings => {
         compress => 'true',
         location => $location,
      },
   };

   return $self->create_snapshot_repository($body, $repository_name);
}

#
# Search::Elasticsearch::Client::2_0::Direct::Snapshot
#
sub get_snapshot_repositories {
   my $self = shift;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my $r;
   eval {
      $r = $es->snapshot->get_repository;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("get_snapshot_repositories: failed: [$@]");
   }

   return $r;
}

#
# Search::Elasticsearch::Client::2_0::Direct::Snapshot
#
sub get_snapshot_status {
   my $self = shift;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   my $r;
   eval {
      $r = $es->snapshot->status;
   };
   if ($@) {
      chomp($@);
      return $self->log->error("get_snapshot_status: failed: [$@]");
   }

   return $r;
}

#
# Search::Elasticsearch::Client::5_0::Direct::Snapshot
#
sub create_snapshot {
   my $self = shift;
   my ($snapshot_name, $repository_name, $body) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   $snapshot_name ||= 'snapshot';
   $repository_name ||= 'repository';

   my %args = (
      repository => $repository_name,
      snapshot => $snapshot_name,
   );
   if (defined($body)) {
      $args{body} = $body;
   }

   my $r;
   eval {
      $r = $es->snapshot->create(%args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("create_snapshot: failed: [$@]");
   }

   return $r;
}

sub create_snapshot_for_indices {
   my $self = shift;
   my ($indices, $snapshot_name, $repository_name) = @_;

   $self->brik_help_run_undef_arg('create_snapshot_for_indices', $indices) or return;

   $snapshot_name ||= 'snapshot';
   $repository_name ||= 'repository';

   my $body = {
      indices => $indices,
   };

   return $self->create_snapshot($snapshot_name, $repository_name, $body);
}

sub is_snapshot_finished {
   my $self = shift;

   my $status = $self->get_snapshot_status or return;

   if (@{$status->{snapshots}} == 0) {
      return 1;
   }

   return 0;
}

sub get_snapshot_state {
   my $self = shift;

   if ($self->is_snapshot_finished) {
      return $self->log->info("get_snapshot_state: is already finished");
   }

   my $status = $self->get_snapshot_status or return;

   my @indices_done = ();
   my @indices_not_done = ();

   my $list = $status->{snapshots};
   for my $snapshot (@$list) {
      my $indices = $snapshot->{indices};
      for my $index (@$indices) {
         my $done = $index->{shards_stats}{done};
         if ($done) {
            push @indices_done, $index;
         }
         else {
            push @indices_not_done, $index;
         }
      }
   }

   return { done => \@indices_done, not_done => \@indices_not_done };
}

sub verify_snapshot_repository {
}

sub delete_snapshot_repository {
   my $self = shift;
   my ($repository_name) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('delete_snapshot_repository', $repository_name) or return;

   my $r;
   eval {
      $r = $es->snapshot->delete_repository(
         repository => $repository_name,
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("delete_snapshot_repository: failed: [$@]");
   }

   return $r;
}

sub get_snapshot {
   my $self = shift;
   my ($snapshot_name, $repository_name) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;

   $snapshot_name ||= 'snapshot';
   $repository_name ||= 'repository';

   my $r;
   eval {
      $r = $es->snapshot->get(
         repository => $repository_name,
         snapshot => $snapshot_name,
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("get_snapshot: failed: [$@]");
   }

   return $r;
}

#
# Search::Elasticsearch::Client::5_0::Direct::Snapshot
#
sub delete_snapshot {
   my $self = shift;
   my ($snapshot_name, $repository_name) = @_;

   my $es = $self->_es;
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('delete_snapshot', $snapshot_name) or return;
   $self->brik_help_run_undef_arg('delete_snapshot', $repository_name) or return;

   my $timeout = $self->rtimeout;

   my $r;
   eval {
      $r = $es->snapshot->delete(
         repository => $repository_name,
         snapshot => $snapshot_name,
         master_timeout => "${timeout}s",
      );
   };
   if ($@) {
      chomp($@);
      return $self->log->error("delete_snapshot: failed: [$@]");
   }

   return $r;
}

#
# https://www.elastic.co/guide/en/elasticsearch/reference/current/modules-snapshots.html
#
sub restore_snapshot {
   my $self = shift;
   my ($snapshot_name, $repository_name, $body) = @_;

   my $es = $self->_es;
   $snapshot_name ||= 'snapshot';
   $repository_name ||= 'repository';
   $self->brik_help_run_undef_arg('open', $es) or return;
   $self->brik_help_run_undef_arg('restore_snapshot', $snapshot_name) or return;
   $self->brik_help_run_undef_arg('restore_snapshot', $repository_name) or return;

   my %args = (
      repository => $repository_name,
      snapshot => $snapshot_name,
   );
   if (defined($body)) {
      $args{body} = $body;
   }

   my $r;
   eval {
      $r = $es->snapshot->restore(%args);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("restore_snapshot: failed: [$@]");
   }

   return $r;
}

sub restore_snapshot_for_indices {
   my $self = shift;
   my ($indices, $snapshot_name, $repository_name) = @_;

   $snapshot_name ||= 'snapshot';
   $repository_name ||= 'repository';
   $self->brik_help_run_undef_arg('restore_snapshot_for_indices', $indices) or return;
   $self->brik_help_run_undef_arg('restore_snapshot_for_indices', $snapshot_name) or return;
   $self->brik_help_run_undef_arg('restore_snapshot_for_indices', $repository_name) or return;

   my $body = {
      indices => $indices,
   };

   return $self->restore_snapshot($snapshot_name, $repository_name, $body);
}

# shard occupation
#
# curl -XGET "http://127.0.0.1:9200/_cat/shards?v
# Or https://www.elastic.co/guide/en/elasticsearch/reference/1.6/cluster-nodes-stats.html
#
# disk occuption:
# curl -XGET http://127.0.0.1:9200/_cat/nodes?h=ip,h,diskAvail,diskTotal
# 
#
# Who is master: curl -XGET http://127.0.0.1:9200/_cat/master?v
#

# Check memory lock

# curl -XGET 'localhost:9200/_nodes?filter_path=**.mlockall&pretty'
# {
#  "nodes" : {
#    "3XXX" : {
#      "process" : {
#        "mlockall" : true
#      }
#    }
#  }
# }

1;

__END__

=head1 NAME

Metabrik::Client::Elasticsearch - client::elasticsearch Brik

=head1 SYNOPSIS

   host:~> my $q = { term => { ip => "192.168.57.19" } }
   host:~> run client::elasticsearch open
   host:~> run client::elasticsearch query $q data-*

=head1 DESCRIPTION

Template to write a new Metabrik Brik.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
