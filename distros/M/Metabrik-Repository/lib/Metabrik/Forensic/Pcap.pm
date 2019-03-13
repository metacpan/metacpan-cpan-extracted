#
# $Id: Pcap.pm,v 6bd6acfc81d5 2019/03/13 09:56:26 gomor $
#
# forensic::pcap Brik
#
package Metabrik::Forensic::Pcap;
use strict;
use warnings;

use base qw(Metabrik::Client::Elasticsearch::Query);

sub brik_properties {
   return {
      revision => '$Revision: 6bd6acfc81d5 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         nodes => [ qw(node_list) ], # Inherited
         index => [ qw(index) ],     # Inherited
         type => [ qw(type) ],       # Inherited
      },
      attributes_default => {
         index => 'forensicpcap-*',
         type => 'pcap',
      },
      commands => {
         create_client => [ ],  # Inherited
         reset_client => [ ],  # Inherited
         query => [ qw(query index|OPTIONAL type|OPTIONAL) ], # Inherited
         from_json_file => [ qw(json_file index|OPTIONAL type|OPTIONAL) ], # Inherited
         from_dump_file => [ qw(dump_file index|OPTIONAL type|OPTIONAL) ], # Inherited
         pcap_to_elasticsearch => [ qw(file filter|OPTIONAL) ],
         show_sessions => [ qw(ip_address port protocol) ],
      },
      require_modules => {
         'Metabrik::File::Pcap' => [ ],
         'Metabrik::Time::Universal' => [ ],
      },
      require_binaries => {
      },
      optional_binaries => {
      },
      need_packages => {
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
      },
   };
}

sub brik_preinit {
   my $self = shift;

   # Do your preinit here, return 0 on error.

   return $self->SUPER::brik_preinit;
}

sub brik_init {
   my $self = shift;

   # Do your init here, return 0 on error.

   return $self->SUPER::brik_init;
}

sub pcap_to_elasticsearch {
   my $self = shift;
   my ($file, $filter) = @_;

   $filter ||= '';
   $self->brik_help_run_undef_arg('pcap_to_elasticsearch', $file) or return;
   $self->brik_help_run_file_not_found('pcap_to_elasticsearch', $file) or return;

   my $fp = Metabrik::File::Pcap->new_from_brik_init($self) or return;
   $fp->open($file, 'read', $filter) or return;

   my $tu = Metabrik::Time::Universal->new_from_brik_init($self) or return;
   my $today = $tu->today;

   my $index = "forensicpcap-$today";
   my $type = "pcap";

   $self->create_client or return;

   my $count_before = 0;
   if ($self->is_index_exists($index)) {
      $count_before = $self->count($index, $type);
      if (! defined($count_before)) {
         return;
      }
      $self->log->info("pcap_to_elasticsearch: current index [$index] count is ".
         "[$count_before]");
   }

   $self->open_bulk_mode($index, $type) or return;

   $self->log->info("pcap_to_elasticsearch: importing file [$file] to index ".
      "[$index] with type [$type]");

   my $print_re = qr/^[[:print:]]{5,}/;

   my $read = 0;
   my $imported = 0;
   while (1) {
      my $h = $fp->read_next(10); # We read 10 by 10
      if (! defined($h)) {
         $self->log->error("pcap_to_elasticsearch: unable to read frame, skipping");
         next;
      }

      last if @$h == 0; # Eof

      $read += @$h;

      for my $this (@$h) {
         my $simple = $fp->from_read($this);
         if (! defined($simple)) {
            $self->log->error("pcap_to_elasticsearch: unable to parse frame, skipping");
            next;
         }

         my $timestamp = $simple->timestamp;

         my $new = {
            '@version' => 1,
            '@timestamp' => $tu->timestamp_to_tz_time($timestamp),
         };
         my $skip_payload = 0;
         for my $layer (reverse $simple->layers) {
            my $this_layer = $layer->layer;

            my $class = ref($layer);
            my %h = map { $_ => $layer->[$layer->cgGetIndice($_)] }
               @{$class->cgGetAttributes};

            # The first we loop, we are using the last layer where we 
            # want to keep the payload. For all others, we remove it.
            if ($skip_payload) {
               delete $h{payload};
            }
            else {
               $skip_payload = 1;
            }
            # We convert IPv4 and TCP options to hex
            if ($layer->layer eq 'TCP') {
               $h{options} = CORE::unpack('H*', $h{options});
               # If payload does not seem printable, we encode in hex
               if (defined($h{payload}) && $h{payload} !~ $print_re) {
                  $h{payload} = CORE::unpack('H*', $h{payload});
               }
               #print "payload[".$h{payload}."]\n" if defined($h{payload});
            }
            if ($layer->layer eq 'UDP') {
               # If payload does not seem printable, we encode in hex
               if (defined($h{payload}) && $h{payload} !~ $print_re) {
                  $h{payload} = CORE::unpack('H*', $h{payload});
               }
               #print "payload[".$h{payload}."]\n" if defined($h{payload});
            }
            elsif ($layer->layer eq 'IPv4') {
               $h{options} = CORE::unpack('H*', $h{options});
            }
            delete $h{raw};
            delete $h{nextLayer};
            delete $h{noFixLen};

            $new->{$this_layer} = \%h;
         }

         my $r = $self->index_bulk($new);
         if (! defined($r)) {
            $self->log->error("pcap_to_elasticsearch: bulk index failed for index ".
               "[$index] at read [$read], skipping chunk");
            next;
         }

         $imported++;
      }
   }

   $self->bulk_flush;

   $self->refresh_index($index);

   my $count_current = $self->count($index, $type) or return;
   $self->log->info("pcap_to_elasticsearch: after index [$index] count is ".
      "[$count_current]");

   my $skipped = 0;
   my $complete = (($count_current - $count_before) == $read) ? 1 : 0;
   if ($complete) {  # If complete, import has been retried, and everything is now ok.
      $imported = $read;
   }
   else {
      $skipped = $read - ($count_current - $count_before);
   }

   if (! $complete) {
      $self->log->warning("pcap_to_elasticsearch: import incomplete");
   }
   else {
      $self->log->info("pcap_to_elasticsearch: successfully imported [$read] frames");
   }

   return 1;
}

sub show_sessions {
   my $self = shift;
   my ($ip_address, $port, $protocol) = @_;

   $protocol ||= 'tcp';
   $self->brik_help_run_undef_arg('show_sessions', $ip_address) or return;
   $self->brik_help_run_undef_arg('show_sessions', $port) or return;

   $protocol = lc($protocol);
   if ($protocol ne 'tcp' && $protocol ne 'udp') {
      return $self->log->error("show_sessions: protocol must be tcp or udp");
   }

   #
   # TCP query
   #
   # (TCP.flags:16 OR TCP.flags:24)
   # AND (IPv4.src:$ip OR IPv4.dst:$ip)
   # AND (TCP.dst:$port OR TCP.src:$port)
   #
   my @should1 = ();
   my @should2 = (
      { term => { 'IPv4.src' => $ip_address } },
      { term => { 'IPv4.dst' => $ip_address } },
   );
   my @should3 = ();

   if ($protocol eq 'tcp') {
      push @should1, { term => { 'TCP.flags' => 16 } };
      push @should1, { term => { 'TCP.flags' => 24 } };
      push @should3, { term => { 'TCP.dst' => $port } };
      push @should3, { term => { 'TCP.src' => $port } };
   }
   else {
      push @should3, { term => { 'UDP.dst' => $port } };
      push @should3, { term => { 'UDP.src' => $port } };
   }

   # IPv4.dst:37.247.10.18 OR IPv4.src:37.247.10.18

   my $q = {
      size => 1000,
      sort => [
         { '_uid' => { order => "asc" } },
         { '@timestamp' => { order => "asc" } },
      ],
      query => {
         bool => {
            must => [
               { bool => { should => \@should1, }, },
               { bool => { should => \@should2, }, },
               { bool => { should => \@should3, }, },
            ],
         }
      },
   };

   my $r = $self->query($q) or return;
   my $hits = $self->get_query_result_hits($r) or return;

   use Data::Dumper;

   for my $this (@$hits) {
      #print Dumper($this)."\n"; last;
      $this = $this->{_source};
      my $timestamp = $this->{'@timestamp'};
      my $ip_src = $this->{IPv4}{src};
      my $ip_dst = $this->{IPv4}{dst};
      my $src = $this->{TCP}{src} || $this->{UDP}{src};
      my $dst = $this->{TCP}{dst} || $this->{UDP}{dst};
      my $payload = $this->{TCP}{payload} || $this->{UDP}{payload} || '';

      print "$timestamp: [$ip_src]:$src > [$ip_dst]:$dst [$payload]\n";
   }

   return 1;
}

sub brik_fini {
   my $self = shift;

   # Do your fini here, return 0 on error.

   return $self->SUPER::brik_fini;
}

1;

__END__

=head1 NAME

Metabrik::Forensic::Pcap - forensic::pcap Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
