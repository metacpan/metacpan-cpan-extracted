#
# $Id: Ripe.pm,v a173ffd4dd67 2017/10/23 08:23:32 gomor $
#
# database::ripe Brik
#
package Metabrik::Database::Ripe;
use strict;
use warnings;

# API RIPE search : http://rest.db.ripe.net/search?query-string=193.6.223.152/24
# https://github.com/RIPE-NCC/whois/wiki/WHOIS-REST-API

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: a173ffd4dd67 $',
      tags => [ qw(unstable netname country as) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         input => [ qw(ripe.db) ],
         _read => [ qw(INTERNAL) ],
      },
      attributes_default => {
         input => 'ripe.db',
      },
      commands => {
         update => [ ],
         next_record => [ qw(file.ripe|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::Client::Www' => [ ],
         'Metabrik::File::Compress' => [ ],
         'Metabrik::File::Read' => [ ],
         'Metabrik::File::Text' => [ ],
      },
   };
}

sub update {
   my $self = shift;

   my @urls = qw(
      ftp://ftp.apnic.net/apnic/whois/apnic.db.inetnum.gz
      ftp://ftp.apnic.net/apnic/whois/apnic.db.inet6num.gz
      ftp://ftp.ripe.net/ripe/dbase/ripe.db.gz
      ftp://ftp.afrinic.net/dbase/afrinic.db.gz
      http://ftp.apnic.net/apnic/dbase/data/jpnic.db.gz
      http://ftp.apnic.net/apnic/dbase/data/krnic.db.gz
      http://ftp.apnic.net/apnic/dbase/data/twnic.in.gz
      http://ftp.apnic.net/apnic/dbase/data/twnic.pn.gz
      ftp://ftp.arin.net/pub/rr/arin.db
   );

   my $datadir = $self->datadir;

   my $cw = Metabrik::Client::Www->new_from_brik_init($self) or return;

   my @fetched = ();
   for my $url (@urls) {
      $self->log->verbose("update: fetching url [$url]");

      (my $filename = $url) =~ s/^.*\/(.*?)$/$1/;
      (my $unzipped = $filename) =~ s/\.gz$//;

      my $output = $datadir."/$filename";
      my $r = $cw->mirror($url, $filename, $datadir);
      if (! defined($r)) {
         $self->log->warning("update: can't fetch url [$url]");
         next;
      }
      elsif (@$r == 0) { # Already up to date
         next;
      }

      my $files = [];
      if ($filename =~ m{.gz$}) {
         $self->log->verbose("update: uncompressing file to [$unzipped]");

         my $fc = Metabrik::File::Compress->new_from_brik_init($self) or return;
         $files = $fc->uncompress($output, $unzipped, $datadir);
         if (! defined($files)) {
            $self->log->warning("update: can't uncompress file [$output]");
            next;
         }
      }
      else {
         push @fetched, $output;
      }

      push @fetched, @$files;
   }

   return \@fetched;
}

sub next_record {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->datadir.'/'.$self->input;
   $self->brik_help_run_file_not_found('next_record', $input) or return;

   my $fr = $self->_read;
   if (! defined($fr)) {
      $fr = Metabrik::File::Read->new_from_brik_init($self) or return;
      $fr->encoding('ascii');
      $fr->input($input);
      $fr->as_array(1);
      $fr->open
         or return $self->log->error("next_record: file::read open failed");
      $self->_read($fr);
   }

   my $lines = $fr->read_until_blank_line;
   if (@$lines == 0) {
      # If nothing has been read and eof reached, we return undef.
      # Otherwise, we return an empty object.
      if ($fr->eof) {
         $fr->close;
         $self->_read(undef);
         return;
      }
      else {
         return {};
      }
   }

   my %record = ();
   for my $line (@$lines) {
      next if ($line =~ /^\s*#/);

      $line =~ s/^\s*//;
      $line =~ s/\s*$//;

      my ($key, $val);
      if ($line =~ /^(.*?)\s*:\s*(.*)$/) {
         $key = $1;
         $val = $2;
      }
      next unless defined($val);

      push @{$record{raw}}, $line;

      $self->log->debug("next_record: key [$key] val[$val]");

      if (! exists($record{$key})) {
         $record{$key} = $val;
      }
      else {
         $record{$key} .= "\n$val";
      }

      # Remove DUMMY data, it is kept in {raw} anyway
      delete $record{'remarks'};
      delete $record{'admin-c'};
      delete $record{'tech-c'};
      delete $record{'changed'};
   }

   return \%record;
}

1;

__END__

=head1 NAME

Metabrik::Database::Ripe - database::ripe Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
