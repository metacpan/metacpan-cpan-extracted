#
# $Id: Sinfp3.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# network::sinfp3 Brik
#
package Metabrik::Network::Sinfp3;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable sinfp osfp fingerprint fingerprinting) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         db => [ qw(sinfp3_db) ],
         target => [ qw(target_host) ],
         port => [ qw(tcp_port) ],
         device => [ qw(device) ],
         threshold => [ qw(percent) ],
         best_score_only => [ qw(0|1) ],
         _global => [ qw(INTERNAL) ],
         _update_url => [ qw(INTERNAL) ],
      },
      attributes_default => {
         port => 80,
         db => 'sinfp3.db',
         threshold => 80,
         best_score_only => 0,
         _update_url => 'https://www.metabrik.org/wp-content/files/sinfp/sinfp3-latest.db',
      },
      commands => {
         update => [ ],
         active_ipv4 => [ qw(target_host|OPTIONAL target_port|OPTIONAL) ],
         active_ipv6 => [ qw(target_host|OPTIONAL target_port|OPTIONAL) ],
         export_active_db => [ qw(sinfp3_db|OPTIONAL) ],
         save_active_ipv4_fingerprint => [ qw(target_host|OPTIONAL target_port|OPTIONAL) ],
         save_active_ipv6_fingerprint => [ qw(target_host|OPTIONAL target_port|OPTIONAL) ],
         active_ipv4_from_pcap => [ qw(pcap_file) ],
         active_ipv6_from_pcap => [ qw(pcap_file) ],
         to_signature_from_tcp_options => [ qw(options) ],
         to_signature_from_tcp_window_and_options => [ qw(window options) ],
         active_ipv4_from_tcp_window_and_options => [ qw(window options) ],
         active_ipv4_from_tcp_options => [ qw(options) ],
         active_ipv4_from_signature => [ qw(signature) ],
         get_os_list_from_result => [ qw(result) ],
      },
      require_modules => {
         'File::Copy' => [ qw(move) ],
         'Net::SinFP3' => [ ],
         'Net::SinFP3::Ext::S' => [ ],
         'Net::SinFP3::Log::Console' => [ ],
         'Net::SinFP3::Log::Null' => [ ],
         'Net::SinFP3::Global' => [ ],
         'Net::SinFP3::Input::IpPort' => [ ],
         'Net::SinFP3::Input::Pcap' => [ ],
         'Net::SinFP3::Input::Signature' => [ ],
         'Net::SinFP3::DB::SinFP3' => [ ],
         'Net::SinFP3::Mode::Active' => [ ],
         'Net::SinFP3::Search::Active' => [ ],
         'Net::SinFP3::Search::Null' => [ ],
         'Net::SinFP3::Output::Console' => [ ],
         'Net::SinFP3::Output::Pcap' => [ ],
         'Net::SinFP3::Output::Simple' => [ ],
         'Metabrik::Client::Www' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         device => defined($self->global) && $self->global->device || 'eth0',
      },
   };
}

sub brik_init {
   my $self = shift;

   my $datadir = $self->datadir;
   my $file = $datadir.'/'.$self->db;
   my $threshold = $self->threshold;
   my $best_score_only = $self->best_score_only;

   if (! -f $file) {
      $self->update or return;
   }

   my $log = Net::SinFP3::Log::Null->new(
      level => $self->log->level,
   ) or return $self->log->error('brik_init: log::null failed');
   $log->init;

   my $global = Net::SinFP3::Global->new(
      log => $log,
      ipv6 => 0,
      dnsReverse => 0,
      threshold => $threshold,
      bestScore => $best_score_only,
   ) or return $self->log->error('brik_init: global failed');

   my $db = Net::SinFP3::DB::SinFP3->new(
      global => $global,
      file => $file,
   ) or return $self->log->error('brik_init: db::sinfp3 failed');
   $db->init;
   $global->db($db);

   $self->_global($global);

   return $self->SUPER::brik_init(@_);
}

sub update {
   my $self = shift;

   my $db = $self->db;
   my $datadir = $self->datadir;

   my $url = $self->_update_url;

   my $cw = Metabrik::Client::Www->new_from_brik_init($self) or return;
   my $files = $cw->mirror($url, $db, $datadir) or return;
   if (@$files > 0) {
      $self->log->info("update: $db updated");
   }

   return "$datadir/$db";
}

sub active_ipv4 {
   my $self = shift;
   my ($target, $port) = @_;

   $target ||= $self->target;
   $port ||= $self->port;
   $self->brik_help_run_must_be_root('active_ipv4') or return;
   $self->brik_help_run_undef_arg('active_ipv4', $target) or return;
   $self->brik_help_run_undef_arg('active_ipv4', $port) or return;

   my $device = $self->device;
   my $threshold = $self->threshold;

   my $datadir = $self->datadir;
   my $file = $datadir.'/'.$self->db;
   $self->brik_help_run_file_not_found('active_ipv4', $file) or return;

   my $log = Net::SinFP3::Log::Console->new(
      level => $self->log->level,
   );

   my $global = Net::SinFP3::Global->new(
      log => $log,
      target => $target,
      port => $port,
      ipv6 => 0,
      dnsReverse => 0,
      worker => 'single',
      device => $device,
      threshold => $threshold,
   ) or return $self->log->error("active: global failed");

   my $input = Net::SinFP3::Input::IpPort->new(
      global => $global,
   );

   my $db = Net::SinFP3::DB::SinFP3->new(
      global => $global,
      file => $file,
   );

   my $mode = Net::SinFP3::Mode::Active->new(
      global => $global,
      doP1 => 1,
      doP2 => 1,
      doP3 => 1,
   );

   my $search = Net::SinFP3::Search::Active->new(
      global => $global,
   );

   my $output = Net::SinFP3::Output::Simple->new(
      global => $global,
   );

   my $sinfp3 = Net::SinFP3->new(
      global => $global,
      input => [ $input ],
      db => [ $db ],
      mode => [ $mode ],
      search => [ $search ],
      output => [ $output ],
   );

   my $ret = $sinfp3->run;

   my @result = $global->result;

   $db->post;
   $log->post;

   return \@result;

   # I was quite mad at this time.
   #$global->mode($mode);
   #$mode->init;
   #$mode->run;
   #$db->init;
   #$db->run;
   #$global->db($db);
   #$global->search($search);
   #$search->init;
   #my $result = $search->run;

   #return $result;
}

sub export_active_db {
   my $self = shift;
   my ($db) = @_;

   $db ||= $self->db;
   $self->brik_help_run_undef_arg('export_active_db', $db) or return;
   $self->brik_help_run_file_not_found('export_active_db', $db) or return;

   return 1;
}

sub save_active_ipv4_fingerprint {
   my $self = shift;
   my ($target_host, $target_port) = @_;

   $target_host ||= $self->target;
   $target_port ||= $self->port;
   my $device = $self->device;
   $self->brik_help_run_undef_arg('save_active_ipv4_fingerprint', $target_host) or return;
   $self->brik_help_run_undef_arg('save_active_ipv4_fingerprint', $target_port) or return;

   my $datadir = $self->datadir;
   my $file = $datadir.'/'.$self->db;
   $self->brik_help_run_file_not_found('save_active_ipv4_fingerprint', $file) or return;

   my $threshold = $self->threshold;

   my $log = Net::SinFP3::Log::Console->new(
      level => $self->log->level,
   );

   my $global = Net::SinFP3::Global->new(
      log => $log,
      target => $target_host,
      port => $target_port,
      ipv6 => 0,
      dnsReverse => 0,
      device => $device,
      threshold => $threshold,
   ) or return $self->log->error("save_active_ipv4_fingerprint: global failed");

   my $input = Net::SinFP3::Input::IpPort->new(
      global => $global,
   );

   my $db = Net::SinFP3::DB::SinFP3->new(
      global => $global,
   );

   my $mode = Net::SinFP3::Mode::Active->new(
      global => $global,
      doP1 => 1,
      doP2 => 1,
      doP3 => 1,
   );

   my $search = Net::SinFP3::Search::Active->new(
      global => $global,
   );

   my $output = Net::SinFP3::Output::Pcap->new(
      global => $global,
      anonymize => 1,
   );

   my $sinfp3 = Net::SinFP3->new(
      global => $global,
      input => [ $input ],
      db => [ $db ],
      mode => [ $mode ],
      search => [ $search ],
      output => [ $output ],
   );

   my $ret = $sinfp3->run;

   $log->post;

   my $pcap = 'sinfp4-127.0.0.1-'.$target_port.'.pcap';
   if (-f $pcap) {
      File::Copy::move($pcap, $datadir);
   }

   return $datadir."/$pcap";
}

sub save_active_ipv6_fingerprint {
   my $self = shift;
   my ($target_host, $target_port) = @_;

   $target_host ||= $self->target;
   $target_port ||= $self->port;
   my $device = $self->device;
   $self->brik_help_run_undef_arg('save_active_ipv6_fingerprint', $target_host) or return;
   $self->brik_help_run_undef_arg('save_active_ipv6_fingerprint', $target_port) or return;

   my $datadir = $self->datadir;
   my $file = $datadir.'/'.$self->db;
   $self->brik_help_run_file_not_found('save_active_ipv6_fingerprint', $file) or return;

   my $threshold = $self->threshold;

   my $log = Net::SinFP3::Log::Console->new(
      level => $self->log->level,
   );

   my $global = Net::SinFP3::Global->new(
      log => $log,
      target => $target_host,
      port => $target_port,
      ipv6 => 1,
      dnsReverse => 0,
      device => $device,
      threshold => $threshold,
   ) or return $self->log->error("save_active_ipv6_fingerprint: global failed");

   my $input = Net::SinFP3::Input::IpPort->new(
      global => $global,
   );

   my $db = Net::SinFP3::DB::SinFP3->new(
      global => $global,
      file => $file,
   );

   my $mode = Net::SinFP3::Mode::Active->new(
      global => $global,
      doP1 => 1,
      doP2 => 1,
      doP3 => 1,
   );

   my $search = Net::SinFP3::Search::Active->new(
      global => $global,
   );

   my $output = Net::SinFP3::Output::Pcap->new(
      global => $global,
      anonymize => 1,
   );

   my $sinfp3 = Net::SinFP3->new(
      global => $global,
      input => [ $input ],
      db => [ $db ],
      mode => [ $mode ],
      search => [ $search ],
      output => [ $output ],
   );

   my $ret = $sinfp3->run;

   $log->post;

   my $pcap = 'sinfp6-::1-'.$target_port.'.pcap';
   if (-f $pcap) {
      File::Copy::move($pcap, $datadir);
   }

   return $datadir."/$pcap";
}

sub active_ipv4_from_pcap {
   my $self = shift;
   my ($pcap_file) = @_;

   my $device = $self->device;
   $self->brik_help_run_undef_arg('active_ipv4_from_pcap', $pcap_file) or return;
   $self->brik_help_run_file_not_found('active_ipv4_from_pcap', $pcap_file) or return;

   my $datadir = $self->datadir;
   my $file = $datadir.'/'.$self->db;
   $self->brik_help_run_file_not_found('active_ipv4_from_pcap', $file) or return;

   my $threshold = $self->threshold;

   my $log = Net::SinFP3::Log::Console->new(
      level => $self->log->level,
   );

   my $global = Net::SinFP3::Global->new(
      log => $log,
      ipv6 => 0,
      dnsReverse => 0,
      device => $device,
      threshold => $threshold,
   ) or return $self->log->error("active_ipv4_from_pcap: global failed");

   my $input = Net::SinFP3::Input::Pcap->new(
      global => $global,
      file => $pcap_file,
      count => 10,
   );

   my $db = Net::SinFP3::DB::SinFP3->new(
      global => $global,
      file => $file,
   );

   my $mode = Net::SinFP3::Mode::Active->new(
      global => $global,
      doP1 => 1,
      doP2 => 1,
      doP3 => 1,
   );

   my $search = Net::SinFP3::Search::Active->new(
      global => $global,
   );

   my $output = Net::SinFP3::Output::Console->new(
      global => $global,
   );

   my $sinfp3 = Net::SinFP3->new(
      global => $global,
      input => [ $input ],
      db => [ $db ],
      mode => [ $mode ],
      search => [ $search ],
      output => [ $output ],
   );

   my $ret = $sinfp3->run;

   $log->post;

   return $ret;
}

sub active_ipv6_from_pcap {
   my $self = shift;
   my ($pcap_file) = @_;

   my $device = $self->device;
   $self->brik_help_run_undef_arg('active_ipv6_from_pcap', $pcap_file) or return;
   $self->brik_help_run_file_not_found('active_ipv6_from_pcap', $pcap_file) or return;

   my $datadir = $self->datadir;
   my $file = $datadir.'/'.$self->db;
   $self->brik_help_run_file_not_found('active_ipv6_from_pcap', $file) or return;

   my $threshold = $self->threshold;

   my $log = Net::SinFP3::Log::Console->new(
      level => $self->log->level,
   );

   my $global = Net::SinFP3::Global->new(
      log => $log,
      ipv6 => 1,
      dnsReverse => 0,
      device => $device,
      threshold => $threshold,
   ) or return $self->log->error("active_ipv6_from_pcap: global failed");

   my $input = Net::SinFP3::Input::Pcap->new(
      global => $global,
      file => $pcap_file,
      count => 10,
   );

   my $db = Net::SinFP3::DB::SinFP3->new(
      global => $global,
      file => $file,
   );

   my $mode = Net::SinFP3::Mode::Active->new(
      global => $global,
      doP1 => 1,
      doP2 => 1,
      doP3 => 1,
   );

   my $search = Net::SinFP3::Search::Active->new(
      global => $global,
   );

   my $output = Net::SinFP3::Output::Console->new(
      global => $global,
   );

   my $sinfp3 = Net::SinFP3->new(
      global => $global,
      input => [ $input ],
      db => [ $db ],
      mode => [ $mode ],
      search => [ $search ],
      output => [ $output ],
   );

   my $ret = $sinfp3->run;

   $log->post;

   return $ret;
}

sub _parse_result {
   my $self = shift;
   my ($result) = @_;

   my @final = ();
   for my $r (@$result) {
      my $h = {
         id_signature => $r->idSignature,
         ip_version => $r->ipVersion,
         system_class => $r->systemClass,
         vendor => $r->vendor,
         os => $r->os,
         os_version => $r->osVersion,
         os_version_family => $r->osVersionFamily,
         match_type => $r->matchType,
         match_score => $r->matchScore,
         match_mask => $r->matchMask,
      };
      for ($r->osVersionChildrenList) {
         push @{$h->{os_version_children}}, $_;
      }
      push @final, $h;
   }

   return \@final;
}

sub _analyze_options {
   my $self = shift;
   my ($opts) = @_;

   # Rewrite timestamp values, if > 0 overwrite with ffff,
   # for each timestamp. Same with WScale value
   my $mss;
   my $wscale;
   if ($opts =~ m/^(.*080a)(.{8})(.{8})(.*)/) {
      my $head = $1;
      my $a    = $2;
      my $b    = $3;
      my $tail = $4;
      # Some systems put timestamp values to 00. We keep it for
      # fingerprint matching. If there is no DEAD, it is not a 
      # reply to a SinFP3 probe, we strip this value.
      if ($a !~ /00000000/ && $a !~ /44454144/) {
         $a = "........";
      }
      if ($b !~ /00000000/ && $b !~ /44454144/) {
         $b = "........";
      }
      $opts = $head.$a.$b.$tail;
   }
   # Move MSS value in its own field
   if ($opts =~ /0204(....)/) {
      if ($1) {
         $mss = sprintf("%d", hex($1));
         $opts =~ s/0204..../0204ffff/;
      }
   }
   # Move WScale value in its own field
   if ($opts =~ /0303(..)/) {
      if ($1) {
         $wscale = sprintf("%d", hex($1));
         $opts =~ s/0303../0303ff/;
      }
   }

   # We completely ignore payload from original SinFP3 code.
   # If we want it, we have to pad $opts with it.
   #$opts .= unpack('H*', $p->reply->ref->{TCP}->payload)
      #if $p->reply->ref->{TCP}->payload;

   $opts ||= '0';
   $mss ||= '0';
   $wscale ||= '0';

   my $opt_len = $opts ? length($opts) / 2 : 0;

   return [ $opts, $mss, $wscale, $opt_len ];
}

sub to_signature_from_tcp_window_and_options {
   my $self = shift;
   my ($window, $options) = @_;

   $self->brik_help_run_undef_arg('to_signature_from_tcp_window_and_options', $window)
      or return;
   $self->brik_help_run_undef_arg('to_signature_from_tcp_window_and_options', $options)
      or return;

   #
   # Example:
   # S2: B11113 F0x12 W65535 O0204ffff010303ff0402080affffffff44454144 M1460 S6 L20
   #
   # Convert TCP options, extract MSS and Scale values
   my $a = $self->_analyze_options($options);
   my $tcp_options = $a->[0];
   my $tcp_mss = $a->[1];
   my $tcp_scale = $a->[2];
   my $opt_len = $a->[3];

   return {
      B => '.....',  # We completly ignore IP header.
      F => '0x12',   # We consider it is a SYN|ACK
      W => $window,
      O => $tcp_options,
      M => $tcp_mss,
      S => $tcp_scale,
      L => $opt_len,
   };
}

sub to_signature_from_tcp_options {
   my $self = shift;
   my ($options) = @_;

   $self->brik_help_run_undef_arg('to_signature_from_tcp_options', $options) or return;

   #
   # Example:
   # S2: B11113 F0x12 W65535 O0204ffff010303ff0402080affffffff44454144 M1460 S6 L20
   #
   # Convert TCP options, extract MSS and Scale values
   my $a = $self->_analyze_options($options);
   my $tcp_options = $a->[0];
   my $tcp_mss = $a->[1];
   my $tcp_scale = $a->[2];
   my $opt_len = $a->[3];

   return {
      B => '.....',  # We completely ignore IP header.
      F => '0x12',   # We consider it is a SYN|ACK
      W => '\\d+',   # We completely ignore TCP window size.
      O => $tcp_options,
      M => $tcp_mss,
      S => $tcp_scale,
      L => $opt_len,
   };
}

sub active_ipv4_from_tcp_window_and_options {
   my $self = shift;
   my ($window, $options) = @_;

   $self->brik_help_run_undef_arg('active_ipv4_from_tcp_window_and_options', $window)
      or return;
   $self->brik_help_run_undef_arg('active_ipv4_from_tcp_window_and_options', $options)
      or return;

   my $global = $self->_global;

   my $mode = Net::SinFP3::Mode::Active->new(
      global => $global,
      doP1 => 1,
      doP2 => 1,
      doP3 => 1,
   ) or return $self->log->error('active_ipv4_from_tcp_window_and_options: mode::active failed');
   $mode->init;
   $global->mode($mode);

   my $s = $self->to_signature_from_tcp_window_and_options($window, $options) or return;
   my $s2 = Net::SinFP3::Ext::S->new(
      B => 'B'.$s->{B},
      F => 'F'.$s->{F},
      W => 'W'.$s->{W},
      O => 'O'.$s->{O},
      M => 'M'.$s->{M},
      S => 'S'.$s->{S},
      L => 'L'.$s->{L},
   );
   if (! defined($s2)) {
      return $self->log->error('active_ipv4_from_tcp_window_and_options: ext::s failed');
   }

   my $search = Net::SinFP3::Search::Active->new(
      global => $global,
      #s1 => $s1,
      s2 => $s2,  # We only use S2 here. Be sure to have enough TCP options in your reply.
      #s3 => $s3,
   );
   $search->init;
   $global->search($search);

   my $r = $search->search;

   return $self->_parse_result($r);
}

sub active_ipv4_from_tcp_options {
   my $self = shift;
   my ($options) = @_;

   $self->brik_help_run_undef_arg('active_ipv4_from_tcp_options', $options) or return;

   my $global = $self->_global;

   my $mode = Net::SinFP3::Mode::Active->new(
      global => $global,
      doP1 => 1,
      doP2 => 1,
      doP3 => 1,
   ) or return $self->log->error('active_ipv4_from_tcp_options: mode::active failed');
   $mode->init;
   $global->mode($mode);

   my $s = $self->to_signature_from_tcp_options($options) or return;
   my $s2 = Net::SinFP3::Ext::S->new( 
      B => 'B'.$s->{B},
      F => 'F'.$s->{F},
      W => 'W'.$s->{W},
      O => 'O'.$s->{O},
      M => 'M'.$s->{M},
      S => 'S'.$s->{S},
      L => 'L'.$s->{L},
   );
   if (! defined($s2)) {
      return $self->log->error('active_ipv4_from_tcp_options: ext::s failed');
   }

   my $search = Net::SinFP3::Search::Active->new(
      global => $global,
      #s1 => $s1,
      s2 => $s2,  # We only use S2 here. Be sure to have enough TCP options in your reply.
      #s3 => $s3,
   );
   $search->init;
   $global->search($search);

   my $r = $search->search;

   return $self->_parse_result($r);
}

sub active_ipv4_from_signature {
   my $self = shift;
   my ($signature) = @_;

   $self->brik_help_run_undef_arg('active_ipv4_from_signature', $signature) or return;
   $self->brik_help_run_invalid_arg('active_ipv4_from_signature', $signature, 'HASH') or return;

   my $global = $self->_global;

   my $mode = Net::SinFP3::Mode::Active->new(
      global => $global,
      doP1 => 1,
      doP2 => 1,
      doP3 => 1,
   ) or return $self->log->error('active_ipv4_from_signature: mode::active failed');
   $mode->init;
   $global->mode($mode);

   my $s2 = Net::SinFP3::Ext::S->new( 
      B => 'B'.$signature->{B},
      F => 'F'.$signature->{F},
      W => 'W'.$signature->{W},
      O => 'O'.$signature->{O},
      M => 'M'.$signature->{M},
      S => 'S'.$signature->{S},
      L => 'L'.$signature->{L},
   );
   if (! defined($s2)) {
      return $self->log->error('active_ipv4_from_signature: ext::s failed');
   }

   my $search = Net::SinFP3::Search::Active->new(
      global => $global,
      #s1 => $s1,
      s2 => $s2,  # We only use S2 here. Be sure to have enough TCP options in your reply.
      #s3 => $s3,
   );
   $search->init;
   $global->search($search);

   my $r = $search->search;

   return $self->_parse_result($r);
}

sub get_os_list_from_result {
   my $self = shift;
   my ($result) = @_;

   $self->brik_help_run_undef_arg('get_os_list_from_result', $result) or return;
   $self->brik_help_run_invalid_arg('get_os_list_from_result', $result, 'ARRAY') or return;
   $self->brik_help_run_empty_array_arg('get_os_list_from_result', $result) or return;

   my %os_list = map { $_->{os} => 1 } @$result;

   return [ sort { $a cmp $b } keys %os_list ];
}

sub brik_fini {
   my $self = shift;

   my $global = $self->_global;
   if (defined($global)) {
      my $search = $global->search;
      my $mode = $global->mode;
      my $db = $global->db;
      my $log = $global->log;

      if (defined($search)) {
         $search->post;
      }
      if (defined($mode)) {
         $mode->post;
      }
      if (defined($db)) {
         $db->post;
      }
      if (defined($log)) {
         $log->post;
      }
      $global->search(undef);
      $global->mode(undef);
      $global->db(undef);
      $global->log(undef);
      $self->_global(undef);

      return 1;
   }

   return 0;
}

1;

__END__

=head1 NAME

Metabrik::Network::Sinfp3 - network::sinfp3 Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
