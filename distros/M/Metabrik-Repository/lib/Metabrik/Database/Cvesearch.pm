#
# $Id: Cvesearch.pm,v 6bd6acfc81d5 2019/03/13 09:56:26 gomor $
#
# database::cvesearch Brik
#
package Metabrik::Database::Cvesearch;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision: 6bd6acfc81d5 $',
      tags => [ qw(unstable cve cpe vfeed circl) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         repo => [ qw(repo) ],
      },
      commands => {
         install => [ ],  # Inherited
         init_database => [ ],
         update_database => [ ],
         repopulate_database => [ ],
         cpe_search => [ qw(cpe) ],
         cve_search => [ qw(cve) ],
         dump_last => [ ],
      },
      require_modules => {
         'Metabrik::Devel::Git' => [ ],
         'Metabrik::String::Json' => [ ],
         'Metabrik::String::Xml' => [ ],
      },
      require_binaries => {
         python3 => [ ],
         pip3 => [ ],
      },
      need_packages => {
         ubuntu => [ qw(python3 python3-pip mongodb redis-server) ],
         debian => [ qw(python3 python3-pip mongodb redis-server) ],
         kali => [ qw(python3 python3-pip mongodb redis-server) ],
      },
   };
}

#
# https://github.com/cve-search/cve-search
#

sub brik_use_properties {
   my $self = shift;

   my $global_datadir = defined($self->global) && $self->global->datadir
      || defined($ENV{HOME}) && $ENV{HOME}."/metabrik"
      || '/tmp/metabrik';
   my $repo = $global_datadir."/devel-git/cve-search";

   return {
      attributes_default => {
         repo => $repo,
      },
   };
}

sub install {
   my $self = shift;

   $self->SUPER::install(@_) or return;

   my $url = 'https://github.com/cve-search/cve-search';

   my $dg = Metabrik::Devel::Git->new_from_brik_init($self) or return;

   my $repo = $self->repo;
   if (-d $repo) {
      $repo = $dg->update($url) or return;
   }
   else {
      $repo = $dg->clone($url) or return;
   }

   $self->sudo_execute('pip3 install -r '.$repo.'/requirements.txt') or return;

   return 1;
}

sub init_database {
   my $self = shift;

   my $repo = $self->repo;

   for my $this (
      'sbin/db_mgmt.py -p', 'sbin/db_mgmt_cpe_dictionary.py', 'sbin/db_updater.py -c'
   ) {
      my $cmd = $repo.'/'.$this;
      $self->log->verbose("init_database: cmd [$cmd]");
      $self->execute($cmd);
   }

   return 1;
}

sub update_database {
   my $self = shift;

   my $repo = $self->repo;

   for my $this ('sbin/db_updater.py -v') {
      my $cmd = $repo.'/'.$this;
      $self->execute($cmd);
   }

   return 1;
}

sub repopulate_database {
   my $self = shift;

   my $repo = $self->repo;

   for my $this ('sbin/db_updater.py -v -f') {
      my $cmd = $repo.'/'.$this;
      $self->execute($cmd);
   }

   return 1;
}

#
# run database::cvesearch cpe_search cisco:ios:12.4
#
sub cpe_search {
   my $self = shift;
   my ($cpe) = @_;

   $self->brik_help_run_undef_arg('cpe_search', $cpe) or return;

   my $repo = $self->repo;

   my $cmd = $repo.'/bin/search.py -o json -p '.$cpe;

   my $json = $self->capture($cmd) or return;
   if (@$json <= 0 || (@$json == 1 && $json->[0] eq 'undef')) {
      return $self->log->error("search_cpe: invalid response: ".join('', @$json));
   }

   my $sj = Metabrik::String::Json->new_from_brik_init($self) or return;

   my @results = ();
   for my $this (@$json) {
      my $r = $sj->decode($this) or next;
      push @results, $r;
   }

   return \@results;
}

#
# run database::cvesearch cve_search CVE-2010-3333
#
sub cve_search {
   my $self = shift;
   my ($cve) = @_;

   $self->brik_help_run_undef_arg('cve_search', $cve) or return;

   if ($cve !~ m{^(cve|can)\-\d+\-\d+$}i) {
      return $self->log->error("search_cve: invalid CVE format [$cve]");
   }

   my $repo = $self->repo;

   my $cmd = $repo.'/bin/search.py -o json -c '.$cve;

   my $json = $self->capture($cmd) or return;
   if (@$json <= 0 || (@$json == 1 && $json->[0] eq 'undef')) {
      return $self->log->error("search_cve: invalid response: ".join('', @$json));
   }

   my $sj = Metabrik::String::Json->new_from_brik_init($self) or return;

   my @results = ();
   for my $this (@$json) {
      my $r = $sj->decode($this) or next;
      push @results, $r;
   }

   return \@results;
}

sub dump_last {
   my $self = shift;

   my $repo = $self->repo;

   my $cmd = $repo.'/bin/dump_last.py -f atom';

   my $xml = $self->capture($cmd) or return;
   if (@$xml <= 0 || (@$xml == 1 && $xml->[0] eq 'undef')) {
      return $self->log->error("last_entries: invalid response: ".join('', @$xml));
   }

   $xml = join('', @$xml);

   my $sx = Metabrik::String::Xml->new_from_brik_init($self) or return;

   my $decoded = $sx->decode($xml) or next;
   my $h = $decoded->{entry};

   my @results = ();
   for my $k (keys %$h) {
      my $title = $h->{$k}{title};
      my ($cve) = $title =~ m{^\s*(CVE\-\d+\-\d+)\s+}i;
      $h->{$k}{cve} = $cve;

      my $href = $h->{$k}{link}{href};
      $h->{$k}{link} = $href;

      push @results, $h->{$k};
   }

   return \@results;
}

1;

__END__

=head1 NAME

Metabrik::Database::Cvesearch - database::cvesearch Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
