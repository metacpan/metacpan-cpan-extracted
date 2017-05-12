#
# $Id: Indexer.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# server::logstash::indexer Brik
#
package Metabrik::Server::Logstash::Indexer;
use strict;
use warnings;

use base qw(Metabrik::Server::Logstash);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         conf_file => [ qw(file) ],
         log_file => [ qw(file) ],
         version => [ qw(2.4.0|5.0.0) ],
         no_output => [ qw(0|1) ],
         redis_host => [ qw(host) ],
         es_nodes => [ qw(node_list) ],
         binary => [ qw(binary_path) ],
      },
      attributes_default => {
         version => '5.0.0',
         no_output => 0,
         log_file => 'logstash.log',
         redis_host => '127.0.0.1',
         es_nodes => [ '127.0.0.1:9200' ],
      },
      commands => {
         install => [ ],
         get_binary => [ ],
         check_config => [ qw(conf_file) ],
         start => [ qw(conf_file|OPTIONAL) ],
         start_in_foreground => [ qw(conf_file|OPTIONAL) ],
         stop => [ ],
         generate_conf => [ qw(conf_file|OPTIONAL redis_host|OPTIONAL) ],
         status => [ ],
      },
   };
}

sub generate_conf {
   my $self = shift;
   my ($conf_file, $redis_host) = @_;

   my $es_nodes = $self->es_nodes;
   $self->brik_help_run_undef_arg('generate_conf', $es_nodes) or return;
   $self->brik_help_run_invalid_arg('generate_conf', $es_nodes, 'ARRAY') or return;

   $conf_file ||= $self->conf_file;
   $redis_host ||= $self->redis_host;

   my $es_hosts = '[ ';
   for my $this (@$es_nodes) {
      $es_hosts .= "\"$this\", ";
   }
   $es_hosts =~ s{, $}{ \]};

   my $conf =<<EOF
input {
   redis {
      host => "$redis_host"
      key => "logstash"
      data_type => "list"
      codec => json
   }
}

output {
   if "_grokparsefailure" in [tags] {
      null {}
   }
   if [type] == "example" {
      elasticsearch {
         hosts => $es_hosts
         index => "example-%{+YYYY-MM-dd}"
         document_type => "document"
         template_name => "example-*"
      }
   }
}
EOF
;

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;
   $ft->append(0);
   $ft->overwrite(1);

   $ft->write($conf, $conf_file) or return;

   return $conf_file;
}

1;

__END__

=head1 NAME

Metabrik::Server::Logstash::Indexer - server::logstash::indexer Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
