#
# $Id: Threatlist.pm,v 6bd6acfc81d5 2019/03/13 09:56:26 gomor $
#
# lookup::threatlist Brik
#
package Metabrik::Lookup::Threatlist;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: 6bd6acfc81d5 $',
      tags => [ qw(unstable ipv4 ipv6 ip threat) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
      },
      commands => {
         update => [ ],
         from_ipv4 => [ qw(ipv4_address) ],
      },
      require_modules => {
         'Metabrik::Client::Www' => [ ],
         'Metabrik::File::Compress' => [ ],
         'Metabrik::File::Text' => [ ],
         'Metabrik::Network::Address' => [ ],
      },
   };
}

sub update {
   my $self = shift;

   my $datadir = $self->datadir;

   my %mirror = (
      'iblocklist-tgbankumtwtrzllndbmb.gz' => 'http://list.iblocklist.com/?list=logmein',
      'iblocklist-nzldzlpkgrcncdomnttb.gz' => 'http://list.iblocklist.com/?list=nzldzlpkgrcncdomnttb',
      'iblocklist-xoebmbyexwuiogmbyprb.gz' => 'http://list.iblocklist.com/?list=bt_proxy',
      'iblocklist-zfucwtjkfwkalytktyiw.gz' => 'http://list.iblocklist.com/?list=zfucwtjkfwkalytktyiw',
      'iblocklist-llvtlsjyoyiczbkjsxpf.gz' => 'http://list.iblocklist.com/?list=bt_spyware',
      'iblocklist-togdoptykrlolpddwbvz.gz' => 'http://list.iblocklist.com/?list=tor',
      'iblocklist-ghlzqtqxnzctvvajwwag.gz' => 'http://list.iblocklist.com/?list=ghlzqtqxnzctvvajwwag',
      'sans-block.txt' => 'http://isc.sans.edu/block.txt',
      'malwaredomains-domains.txt' => 'http://mirror1.malwaredomains.com/files/domains.txt',
      'emergingthreats-compromised-ips.txt.gz' => 'http://rules.emergingthreats.net/blockrules/compromised-ips.txt',
      'emergingthreats-emerging-Block-IPs.txt.gz' => 'http://rules.emergingthreats.net/fwrules/emerging-Block-IPs.txt',
      'phishtank-verified_online.csv.gz' => 'http://data.phishtank.com/data/online-valid.csv.gz',
      'abusech-palevotracker.txt.gz' => 'https://palevotracker.abuse.ch/blocklists.php?download=ipblocklist',
      'abusech-spyeyetracker.txt.gz' => 'https://spyeyetracker.abuse.ch/blocklist.php?download=ipblocklist',
      'abusech-zeustracker-badips.txt.gz' => 'https://zeustracker.abuse.ch/blocklist.php?download=badips',
      'abusech-zeustracker.txt.gz' => 'https://zeustracker.abuse.ch/blocklist.php?download=ipblocklist',
      'iana-tlds-alpha-by-domain.txt' => 'http://data.iana.org/TLD/tlds-alpha-by-domain.txt',
      'publicsuffix-effective_tld_names.dat.gz' => 'https://publicsuffix.org/list/effective_tld_names.dat',
   );

   # IP Threatlist:
   # "abusech-palevotracker.txt",  # Palevo C&C
   # "abusech-zeustracker-badips.txt", # Zeus IPs
   # "abusech-zeustracker.txt", # Zeus IPs
   # "emergingthreats-compromised-ips.txt", # Compromised IPs
   # "emergingthreats-emerging-Block-IPs.txt", # Raw IPs from Spamhaus, DShield and Abuse.ch
   # "iblocklist-ghlzqtqxnzctvvajwwag", # Various exploiters, scanner, spammers IPs
   # "iblocklist-llvtlsjyoyiczbkjsxpf", # Various evil IPs (?)
   # "iblocklist-xoebmbyexwuiogmbyprb", # Proxy and TOR IPs
   # "sans-block.txt", # IP ranges to block for abuse reasons

   # Owner lists
   # "iblocklist-nzldzlpkgrcncdomnttb", # ThePirateBay
   # "iblocklist-togdoptykrlolpddwbvz", # TOR IPs
   # "iblocklist-tgbankumtwtrzllndbmb", # LogMeIn IPs
   # "iblocklist-zfucwtjkfwkalytktyiw", # RapidShare IPs
   # "phishtank-verified_online.csv", # URLs hosting phishings
   # "malwaredomains-domains.txt", # Malware domains

   # Other lists
   # "top-1m.csv",
   # "iana-tlds-alpha-by-domain.txt",
   # "publicsuffix-effective_tld_names.dat",

   my $cw = Metabrik::Client::Www->new_from_brik_init($self) or return;
   $cw->user_agent("Metabrik-Lookup-Threatlist-mirror/1.00");
   $cw->datadir($datadir);

   my $fc = Metabrik::File::Compress->new_from_brik_init($self) or return;
   $fc->datadir($datadir);

   my @updated = ();
   for my $f (keys %mirror) {
      my $files = $cw->mirror($mirror{$f}, $f) or next;
      for my $file (@$files) {
         my $outfile = $file;
         if ($file =~ /\.gz$/) {
            ($outfile = $file) =~ s/\.gz$//;
            $fc->uncompress($file, $outfile) or next;
         }
         elsif ($file =~ /\.zip$/) {
            ($outfile = $file) =~ s/\.zip$//;
            $fc->uncompress($file, $outfile) or next;
         }
         push @updated, $outfile;
      }
   }

   return \@updated;
}

sub from_ipv4 {
   my $self = shift;
   my ($ipv4) = @_;

   $self->brik_help_run_undef_arg('from_ipv4', $ipv4) or return;

   my $na = Metabrik::Network::Address->new_from_brik_init($self) or return;
   if (! $na->is_ipv4($ipv4)) {
      return $self->log->error("from_ipv4: not a valid IPv4 address [$ipv4]");
   }

   # Keep only the IP part
   ($ipv4) = $ipv4 =~ m{^(\d+\.\d+\.\d+\.\d+)/?.*$};

   # One IP per line format
   my $lists_a = {
      "abusech-palevotracker.txt" => 'Abuse.ch - Palevo C&C',
      "abusech-zeustracker-badips.txt" => 'Abuse.ch - Zeus bad IPs',
      "abusech-zeustracker.txt" => 'Abuse.ch - Zeus IPs',
      "emergingthreats-compromised-ips.txt" => 'EmergingThreats - Compromised IPs',
      "emergingthreats-emerging-Block-IPs.txt" => 'EmergingThreats - Spamhaus, DShield and Abuse.ch',
   };

   # CSV-like format
   my $lists_b = {
      "iblocklist-ghlzqtqxnzctvvajwwag" => 'iblocklist - Exploiters, scanner and spammers',
      "iblocklist-llvtlsjyoyiczbkjsxpf" => 'iblocklist - Malicious IPs',
      "iblocklist-xoebmbyexwuiogmbyprb" => 'iblocklist - Proxy and TOR',
   };

   # Custom format
   my $lists_c = {
      "sans-block.txt" => 'SANS - Malicious IPs',
   };

   my $datadir = $self->datadir;

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;
   $ft->as_array(1);
   $ft->strip_crlf(1);

   my $level = $self->log->level;
   $self->log->level(1);

   my %threats = ();
   for my $file (keys %$lists_a) {
      my $data = $ft->read($datadir.'/'.$file) or next;
      for (@$data) {
         next if (/^\s*#/);
         next if (/^\s*$/);
         if ($na->is_ipv4_subnet($_) && $na->match($ipv4, $_)) {
            $threats{$lists_a->{$file}}++;
         }
         elsif ($na->is_ipv4($_) && /^$ipv4$/) {
            $threats{$lists_a->{$file}}++;
         }
      }
   }

   for my $file (keys %$lists_b) {
      my $data = $ft->read($datadir.'/'.$file) or next;
      for (@$data) {
         next if (/^\s*#/);
         next if (/^\s*$/);
         my @toks = split(/\s*:\s*/);
         next unless (defined($toks[0]) && defined($toks[1]));
         my $type = $toks[0];  # Exploit scanner, WebExploit, ...
         my ($start, $end) = $toks[1] =~ m{^\s*(\d+\.\d+\.\d+\.\d+)\s*-\s*(\d+\.\d+\.\d+\.\d+)\s*$};
         next unless (defined($start) && defined($end));
         next unless ($na->is_ipv4($start) && $na->is_ipv4($end));
         my $subnet = $na->range_to_cidr($start, $end) or next;
         for my $this (@$subnet) {
            if ($na->match($ipv4, $this)) {
               $threats{$lists_b->{$file}}++;
            }
         }
      }
   }

   for my $file (keys %$lists_c) {
      my $data = $ft->read($datadir.'/'.$file) or next;
      for (@$data) {
         next if (/^\s*#/);
         next if (/^\s*$/);
         my @toks = split(/\s+/);
         my $start = $toks[0];
         my $end = $toks[1];
         next unless (defined($start) && defined($end));
         next unless ($na->is_ipv4($start) && $na->is_ipv4($end));
         my $subnet = $na->range_to_cidr($start, $end) or next;
         for my $this (@$subnet) {
            if ($na->match($ipv4, $this)) {
               $threats{$lists_c->{$file}}++;
            }
         }
      }
   }

   $self->log->level($level);

   return [ keys %threats ];
}

1;

__END__

=head1 NAME

Metabrik::Lookup::Threatlist - lookup::threatlist Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
