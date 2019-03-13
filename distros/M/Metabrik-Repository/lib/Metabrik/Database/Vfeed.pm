#
# $Id: Vfeed.pm,v 6bd6acfc81d5 2019/03/13 09:56:26 gomor $
#
# database::vfeed Brik
#
package Metabrik::Database::Vfeed;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: 6bd6acfc81d5 $',
      tags => [ qw(unstable cve) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         db => [ qw(vfeed.db) ],
      },
      attributes_default => {
         db => 'vfeed.db',
      },
      commands => {
         db_version => [ ],
         update => [ ],
         cve => [ qw(cve_id) ],
      },
      require_modules => {
         'Data::Dumper' => [ ],
         'vFeed::DB' => [ ],
         'vFeed::Log' => [ ],
         'Metabrik::Client::Www' => [ ],
         'Metabrik::File::Compress' => [ ],
      },
   };
}

sub db_version {
   my $self = shift;

   my $db = $self->db;
   my $datadir = $self->datadir;

   my $log = vFeed::Log->new;
   my $vfeed = vFeed::DB->new(
      log => $log,
      file => $datadir.'/'.$db,
   );

   $vfeed->init;

   return $vfeed->db_version;
}

sub cve {
   my $self = shift;
   my ($id) = @_;

   $self->brik_help_run_undef_arg('cve', $id) or return;

   my $db = $self->db;
   my $datadir = $self->datadir;

   my $log = vFeed::Log->new;
   my $vfeed = vFeed::DB->new(
      log => $log,
      file => $datadir.'/'.$db,
   );

   $vfeed->init;

   my $cve = $vfeed->get_cve($id);
   my $cpe = $vfeed->get_cpe($id);
   my $cwe = $vfeed->get_cwe($id);

   return {
      cve => $cve,
      cpe => $cpe,
      cwe => $cwe,
   };
}

sub update {
   my $self = shift;

   my $db = $self->db;
   my $datadir = $self->datadir;
   my $url = 'http://www.toolswatch.org/vfeed/vfeed.db.tgz';

   my $cw = Metabrik::Client::Www->new_from_brik_init($self) or return;
   my $files = $cw->mirror($url, 'vfeed.db.tgz', $datadir);
   if (@$files) { # An update was found
      $self->log->info("update: a new version was found");
      my $fc = Metabrik::File::Compress->new_from_brik_init($self) or return;
      $fc->uncompress($files->[0], $db, $datadir) or return;
   }

   return $self->db_version;
}

1;

__END__

=head1 NAME

Metabrik::Database::Vfeed - database::vfeed Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
