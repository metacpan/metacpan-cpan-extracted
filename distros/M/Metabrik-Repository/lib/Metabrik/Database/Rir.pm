#
# $Id: Rir.pm,v 6bd6acfc81d5 2019/03/13 09:56:26 gomor $
#
# database::rir Brik
#
package Metabrik::Database::Rir;
use strict;
use warnings;

# Some history:
# http://www.apnic.net/about-APNIC/organization/history-of-apnic/history-of-the-regional-internet-registries

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: 6bd6acfc81d5 $',
      tags => [ qw(unstable as country subnet) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         input => [ qw(input.rir) ],
         _read => [ qw(INTERNAL) ],
      },
      attributes_default => {
         input => 'input.rir',
      },
      commands => {
         update => [ ],
         next_record => [ qw(input|OPTIONAL) ],
         ip_to_asn => [ qw(ipv4_address) ],
      },
      require_modules => {
         'Metabrik::Client::Www' => [ ],
         'Metabrik::File::Read' => [ ],
         'Metabrik::Network::Address' => [ ],
      },
   };
}

sub update {
   my $self = shift;

   my @urls = qw(
      ftp://ftp.arin.net/pub/stats/arin/delegated-arin-extended-latest
      ftp://ftp.ripe.net/ripe/stats/delegated-ripencc-extended-latest
      ftp://ftp.afrinic.net/pub/stats/afrinic/delegated-afrinic-extended-latest
      ftp://ftp.apnic.net/pub/stats/apnic/delegated-apnic-extended-latest
      ftp://ftp.lacnic.net/pub/stats/lacnic/delegated-lacnic-extended-latest
   );

   my $datadir = $self->datadir;

   my $cw = Metabrik::Client::Www->new_from_brik_init($self) or return;

   my @fetched = ();
   for my $url (@urls) {
      $self->log->verbose("update: fetching url [$url]");

      (my $filename = $url) =~ s/^.*\/(.*?)$/$1/;

      my $output = $datadir.'/'.$filename;
      my $r = $cw->mirror($url, $filename, $datadir);
      if (! defined($r)) {
         $self->log->warning("update: can't fetch url [$url]");
         next;
      }
      if (@$r == 0) { # Nothing new
         next;
      }
      push @fetched, $output;
   }

   return \@fetched;
}

sub next_record {
   my $self = shift;
   my ($input) = @_;

   my $fr = $self->_read;
   if (! defined($fr)) {
      $input ||= $self->datadir.'/'.$self->input;
      $self->brik_help_run_file_not_found('next_record', $input) or return;

      $fr = Metabrik::File::Read->new_from_brik_init($self) or return;
      $fr->encoding('ascii');
      $fr->input($input);
      $fr->as_array(0);
      $fr->open or return;
      $self->_read($fr);
   }

   my $na = Metabrik::Network::Address->new_from_brik_init($self) or return;

   # 2|afrinic|20150119|4180|00000000|20150119|00000
   # afrinic|*|asn|*|1146|summary
   # afrinic|*|ipv4|*|2586|summary
   # afrinic|*|ipv6|*|448|summary
   # afrinic|ZA|asn|1228|1|19910301|allocated
   # arin|US|ipv4|13.128.0.0|524288|19860425|assigned|efe0f73dfd0d72364bf64f417b803f18

   my $line;
   while ($line = $fr->read_line) {
      next if $line =~ /^\s*#/;  # Skip comments

      chomp($line);

      $self->log->debug("next_record: line[$line]");

      my @t = split(/\|/, $line);

      my $cc = $t[1];
      if (! defined($cc)) {
         $self->log->verbose("next_record: skipping line [$line]");
         next;
      }
      next if ($cc eq '*');

      my $type = $t[2];
      if (! defined($type)) {
         $self->log->verbose("next_record: skipping line [$line]");
         next;
      }
      next if ($type ne 'asn' && $type ne 'ipv4' && $type ne 'ipv6');

      my $source = $t[0];
      my $value = $t[3];
      my $count = $t[4];
      my $date = $t[5];
      my $status = $t[6];

      if ($date !~ /^\d{8}$/ && $date ne '') {
         $self->log->warning("next_record: invalid date [$date] for line [$line]");
         $date = '1970-01-01';
      }
      else {
         $date =~ s/^(\d{4})(\d{2})(\d{2})$/$1-$2-$3/;
      }

      my $from = 'undef';
      my $to = 'undef';
      my $subnet = 'undef';
      if ($type eq 'ipv4') {
         $from = $value;
         my $integer = $na->ipv4_to_integer($from);
         if (! defined($integer)) {
            $self->log->warning("next_record: unable to convert IPv4 [$from]");
            next;
         }
         $to = $na->integer_to_ipv4($integer + $count - 1);
         if (! defined($to)) {
            $self->log->warning("next_record: unable to convert integer [".$integer + $count."]");
            next;
         }
         $subnet = $na->range_to_cidr($from, $to);
         if (! defined($subnet)) {
            $self->log->warning("next_record: unable to get subnet with [$from] [$to]");
            next;
         }
         $subnet = join('|', @$subnet);
      }

      my $h = {
         raw => $line,
         source => uc($source),
         cc => uc($cc),
         type => $type,
         value => $value,
         count => $count,
         date => $date,
         status => $status,
         subnet => $subnet,
         from => $value,
         to => $to,
      };

      return $h;
   }

   return;
}

sub ip_to_asn {
   my $self = shift;
   my ($ip) = @_;

   return $self;
}

1;

__END__

=head1 NAME

Metabrik::Database::Rir - database::rir Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
