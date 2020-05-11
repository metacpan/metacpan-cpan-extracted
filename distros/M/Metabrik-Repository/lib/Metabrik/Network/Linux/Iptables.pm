#
# $Id$
#
# network::linux::iptables Brik
#
package Metabrik::Network::Linux::Iptables;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable fw firewall filter block filtering nat) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         device => [ qw(device) ],
         table => [ qw(nat|filter|mangle|$name) ],
         chain => [ qw(INPUT|OUTPUT|FORWARD|PREROUTING|POSTROUTING|MASQUERADE|DNAT|$name) ],
         target => [ qw(ACCEPT|REJECT|DROP|RETURN|REDIRECT|$name) ],
         protocol => [ qw(udp|tcp|all) ],
         source => [ qw(source) ],
         destination => [ qw(destination) ],
         test_only => [ qw(0|1) ],
         input => [ qw(file) ],
         output => [ qw(file) ],
      },
      attributes_default => {
         table => 'filter',
         chain => 'INPUT',
         target => 'REJECT',
         protocol => '',
         source => '',
         destination => '',
         test_only => 0,
         input => 'current.txt',
         output => 'current.txt',
      },
      commands => {
         install => [ ], # Inherited
         command => [ qw(command) ],
         show_nat => [ ],
         show_filter => [ ],
         save => [ qw(file table|OPTIONAL) ],
         save_nat => [ qw(file) ],
         save_filter => [ qw(file) ],
         restore => [ qw(file table|OPTIONAL) ],
         restore_nat => [ qw(file) ],
         restore_filter => [ qw(file) ],
         flush => [ qw(table|$table_list chain) ],
         flush_nat => [ qw(chain|OPTIONAL) ],
         flush_nat_prerouting => [ ],
         flush_nat_input => [ ],
         flush_nat_output => [ ],
         flush_nat_postrouting => [ ],
         flush_filter => [ qw(chain|OPTIONAL) ],
         flush_filter_input => [ ],
         flush_filter_forward => [ ],
         flush_filter_output => [ ],
         set_policy => [ qw(table target) ],
         set_policy_input => [ qw(target) ],
         set_policy_output => [ qw(target) ],
         set_policy_forward => [ qw(target) ],
         add => [ qw(table chain target rule) ],
         add_nat => [ qw(chain target rule) ],
         add_nat_output => [ qw(target rule) ],
         add_nat_output_return => [ qw(rule) ],
         add_nat_output_redirect => [ qw(rule) ],
         add_nat_output_dnat => [ qw(rule) ],
         add_nat_postrouting => [ qw(target rule) ],
         add_nat_postrouting_masquerade => [ qw(rule) ],
         add_nat_postrouting_dnat => [ qw(rule) ],
         add_filter => [ qw(chain target rule) ],
         add_filter_output => [ qw(target rule) ],
         add_filter_output_accept => [ qw(rule) ],
         add_filter_output_reject => [ qw(rule) ],
         del => [ qw(table chain target rule) ],
         del_nat => [ qw(chain target rule) ],
         del_nat_output => [ qw(target rule) ],
         del_nat_output_return => [ qw(rule) ],
         del_nat_output_redirect => [ qw(rule) ],
         del_nat_output_dnat => [ qw(rule) ],
         check => [ qw(table chain target rule) ],
         check_nat => [ qw(chain target rule) ],
         check_nat_output => [ qw(target rule) ],
         check_nat_output_return => [ qw(rule) ],
         check_nat_output_redirect => [ qw(rule) ],
         check_nat_output_dnat => [ qw(rule) ],
         start_redirect_target_to => [ qw(host_port dest_host_port protocol|OPTIONAL) ],
         start_redirect_target_tcp_to => [ qw(host_port dest_host_port) ],
         start_redirect_target_udp_to => [ qw(host_port dest_host_port) ],
         stop_redirect_target_to => [ qw(host_port dest_host_port protocol|OPTIONAL) ],
         stop_redirect_target_tcp_to => [ qw(host_port dest_host_port) ],
         stop_redirect_target_udp_to => [ qw(host_port dest_host_port) ],
      },
      require_modules => {
         'Metabrik::File::Text' => [ ],
      },
      require_binaries => {
         iptables => [ ],
      },
      need_packages => {
         ubuntu => [ qw(iptables) ],
         debian => [ qw(iptables) ],
         kali => [ qw(iptables) ],
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

sub command {
   my $self = shift;
   my ($command) = @_;

   $self->brik_help_run_undef_arg('command', $command) or return;

   my $cmd = "iptables $command";

   $self->log->verbose("command: cmd[$cmd]");

   if ($self->test_only) {
      return 1;
   }

   $self->ignore_error(0);

   my $r = $self->sudo_execute($cmd) or return;
   if ($r == 256) {
      return 0;
   }

   return 1;
}

sub show_nat {
   my $self = shift;

   my $cmd = '-S -t nat';

   return $self->command($cmd);
}

sub show_filter {
   my $self = shift;

   my $cmd = '-S -t filter';

   return $self->command($cmd);
}

sub save {
   my $self = shift;
   my ($output, $table) = @_;

   $output ||= $self->output;
   $self->brik_help_run_undef_arg('save', $output) or return;

   my $datadir = $self->datadir;
   # If it does not start with a /, we put it in datadir
   if ($output !~ m{^/}) {
      $output = $datadir.'/'.$output;
   }

   my $cmd = 'iptables-save -c';
   if (defined($table)) {
      $cmd = "iptables-save -c -t $table";
   }

   $self->log->verbose("save: cmd[$cmd]");

   if ($self->test_only) {
      return 1;
   }

   my $preve = $self->ignore_error;
   my $prevc = $self->capture_stderr;
   $self->ignore_error(0);
   $self->capture_stderr(0);
   my $r = $self->sudo_capture($cmd);
   if (! defined($r)) {
      $self->ignore_error($preve);
      $self->ignore_error($prevc);
      return;
   }
   $self->ignore_error($preve);
   $self->ignore_error($prevc);

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;
   $ft->append(0);
   $ft->overwrite(1);
   $ft->write($r, $output) or return;

   return $output;
}

sub save_nat {
   my $self = shift;
   my ($output) = @_;

   $output ||= $self->output;
   $self->brik_help_run_undef_arg('save_nat', $output) or return;

   return $self->save($output, 'nat');
}

sub save_filter {
   my $self = shift;
   my ($output) = @_;

   $output ||= $self->output;
   $self->brik_help_run_undef_arg('save_filter', $output) or return;

   return $self->save($output, 'filter');
}

sub restore {
   my $self = shift;
   my ($input, $table) = @_;

   $input ||= $self->input;
   $self->brik_help_run_undef_arg('restore', $input) or return;

   my $datadir = $self->datadir;
   if ($input !~ m{^/}) {
      $input = $datadir.'/'.$input;
   }
   $self->brik_help_run_file_not_found('restore', $input) or return;

   my $cmd = "cat \"$input\" | iptables-restore -c";
   if (defined($table)) {
      $cmd = "iptables-restore -c -T $table < \"$input\"";
   }

   $self->log->verbose("restore: cmd[$cmd]");

   if ($self->test_only) {
      return 1;
   }

   my $preve = $self->ignore_error;
   my $prevc = $self->capture_stderr;
   $self->ignore_error(0);
   $self->capture_stderr(0);
   my $r = $self->sudo_capture($cmd);
   if (! defined($r)) {
      $self->ignore_error($preve);
      $self->ignore_error($prevc);
      return;
   }
   $self->ignore_error($preve);
   $self->ignore_error($prevc);

   return $input;
}

sub restore_nat {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   $self->brik_help_run_undef_arg('restore_nat', $input) or return;

   my $datadir = $self->datadir;
   if ($input !~ m{^/}) {
      $input = $datadir.'/'.$input;
   }
   $self->brik_help_run_file_not_found('restore_nat', $input) or return;

   return $self->restore($input, 'nat');
}

sub restore_filter {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   $self->brik_help_run_undef_arg('restore_filter', $input) or return;

   my $datadir = $self->datadir;
   if ($input !~ m{^/}) {
      $input = $datadir.'/'.$input;
   }
   $self->brik_help_run_file_not_found('restore_filter', $input) or return;

   return $self->restore($input, 'filter');
}

sub flush {
   my $self = shift;
   my ($table, $chain) = @_;

   if (! defined($table)) {
      $table = [ qw(nat filter) ];
   }
   my $ref = $self->brik_help_run_invalid_arg('flush', $table, 'ARRAY', 'SCALAR')
      or return;

   my $cmd = "-t $table -F";

   if ($ref eq 'ARRAY') {
      for my $this (@$table) {
         $self->flush($this, $chain);
      }
      return 1;
   }
   else {
      if (defined($chain)) {
         $cmd = "-t $table -F $chain";
      }
   }

   return $self->command($cmd);
}

sub flush_nat {
   my $self = shift;
   my ($chain) = @_;

   return $self->flush('nat', $chain);
}

sub flush_nat_prerouting {
   my $self = shift;

   return $self->flush_nat('PREROUTING');
}

sub flush_nat_input {
   my $self = shift;

   return $self->flush_nat('INPUT');
}

sub flush_nat_output {
   my $self = shift;

   return $self->flush_nat('OUTPUT');
}

sub flush_nat_postrouting {
   my $self = shift;

   return $self->flush_nat('POSTROUTING');
}

sub flush_filter {
   my $self = shift;
   my ($chain) = @_;

   return $self->flush('filter', $chain);
}

sub flush_filter_input {
   my $self = shift;

   return $self->flush_filter('INPUT');
}

sub flush_filter_forward {
   my $self = shift;

   return $self->flush_filter('FORWARD');
}

sub flush_filter_output {
   my $self = shift;

   return $self->flush_filter('OUTPUT');
}

sub set_policy {
   my $self = shift;
   my ($table, $target) = @_;

   $self->brik_help_run_undef_arg('set_policy', $table) or return;
   $self->brik_help_run_undef_arg('set_policy', $target) or return;

   my $cmd = "-P $table $target";

   return $self->command($cmd);
}

sub set_policy_input {
   my $self = shift;
   my ($target) = @_;

   $self->brik_help_run_undef_arg('set_policy_input', $target) or return;

   return $self->set_policy('input', $target);
}

sub set_policy_output {
   my $self = shift;
   my ($target) = @_;

   $self->brik_help_run_undef_arg('set_policy_output', $target) or return;

   return $self->set_policy('output', $target);
}

sub set_policy_forward {
   my $self = shift;
   my ($target) = @_;

   $self->brik_help_run_undef_arg('set_policy_forward', $target) or return;

   return $self->set_policy('forward', $target);
}

sub _action {
   my $self = shift;
   my ($action, $table, $chain, $target, $rule) = @_;

   my $source = $rule->{source} || $self->source;
   my $destination = $rule->{destination} || $self->destination;
   my $protocol = $rule->{protocol} || $self->protocol;
   my $dport = $rule->{dest_port} || '';
   my $sport = $rule->{src_port} || '';
   my $to_ports = $rule->{to_ports} || '';
   my $state = $rule->{state} || '';
   my $uid = $rule->{uid} || '';
   my $to_destination = $rule->{to_destination} || '';
   my $custom = $rule->{custom} || '';

   my $cmd = "-t $table $action $chain -j $target";
   if (length($source)) {
      $cmd .= " -s $source";
   }
   if (length($destination)) {
      $cmd .= " -d $destination";
   }
   if (length($protocol)) {
      $cmd .= " -p $protocol";
   }
   if (length($dport)) {
      $cmd .= " --dport $dport";
   }
   if (length($sport)) {
      $cmd .= " --sport $dport";
   }
   if (length($to_ports)) {
      $cmd .= " --to-ports $to_ports";
   }
   if (length($state)) {
      $cmd .= " -m state --state $state";
   }
   if (length($uid)) {
      $cmd .= " -m owner --uid $uid";
   }
   if (length($to_destination)) {
      $cmd .= " --to-destination $to_destination";
   }
   if (length($custom)) {
      $cmd .= " $custom";
   }

   return $cmd;
}

sub add {
   my $self = shift;
   my ($table, $chain, $target, $rule) = @_;

   $table ||= $self->table;
   $chain ||= $self->chain;
   $target ||= $self->target;
   $self->brik_help_run_undef_arg('add', $table) or return;
   $self->brik_help_run_undef_arg('add', $chain) or return;
   $self->brik_help_run_undef_arg('add', $target) or return;
   $self->brik_help_run_undef_arg('add', $rule) or return;
   $self->brik_help_run_invalid_arg('add', $rule, 'HASH') or return;

   my $cmd = $self->_action('-A', $table, $chain, $target, $rule);

   return $self->command($cmd);
}

sub add_nat {
   my $self = shift;
   my ($chain, $target, $rule) = @_;

   $chain ||= $self->chain;
   $target ||= $self->target;
   $self->brik_help_run_undef_arg('add_nat', $chain) or return;
   $self->brik_help_run_undef_arg('add_nat', $target) or return;
   $self->brik_help_run_undef_arg('add_nat', $rule) or return;
   $self->brik_help_run_invalid_arg('add_nat', $rule, 'HASH') or return;

   return $self->add('nat', $chain, $target, $rule);
}

sub add_nat_output {
   my $self = shift;
   my ($target, $rule) = @_;

   $target ||= $self->target;
   $self->brik_help_run_undef_arg('add_nat_output', $target) or return;
   $self->brik_help_run_undef_arg('add_nat_output', $rule) or return;
   $self->brik_help_run_invalid_arg('add_nat_output', $rule, 'HASH') or return;

   return $self->add_nat('OUTPUT', $target, $rule);
}

sub add_nat_output_return {
   my $self = shift;
   my ($rule) = @_;

   $self->brik_help_run_undef_arg('add_nat_output_return', $rule) or return;
   $self->brik_help_run_invalid_arg('add_nat_output_return', $rule, 'HASH') or return;

   return $self->add_nat_output('RETURN', $rule);
}

sub add_nat_output_redirect {
   my $self = shift;
   my ($rule) = @_;

   $self->brik_help_run_undef_arg('add_nat_output_redirect', $rule) or return;
   $self->brik_help_run_invalid_arg('add_nat_output_redirect', $rule, 'HASH') or return;

   return $self->add_nat_output('REDIRECT', $rule);
}

sub add_nat_output_dnat {
   my $self = shift;
   my ($rule) = @_;

   $self->brik_help_run_undef_arg('add_nat_output_dnat', $rule) or return;
   $self->brik_help_run_invalid_arg('add_nat_output_dnat', $rule, 'HASH') or return;

   return $self->add_nat_output('DNAT', $rule);
}

sub add_nat_postrouting {
   my $self = shift;
   my ($target, $rule) = @_;

   $target ||= $self->target;
   $self->brik_help_run_undef_arg('add_nat_postrouting', $target) or return;
   $self->brik_help_run_undef_arg('add_nat_postrouting', $rule) or return;
   $self->brik_help_run_invalid_arg('add_nat_postrouting', $rule, 'HASH') or return;

   return $self->add_nat('POSTROUTING', $target, $rule);
}

# Example: iptables -A POSTROUTING -t nat -j MASQUERADE -s 192.168.1.0/24
sub add_nat_postrouting_masquerade {
   my $self = shift;
   my ($rule) = @_;

   $self->brik_help_run_undef_arg('add_nat_postrouting_masquerade', $rule) or return;
   $self->brik_help_run_invalid_arg('add_nat_postrouting_masquerade', $rule, 'HASH') or return;

   return $self->add_nat_postrouting('MASQUERADE', $rule);
}

sub add_nat_postrouting_dnat {
   my $self = shift;
   my ($rule) = @_;

   $self->brik_help_run_undef_arg('add_nat_postrouting_dnat', $rule) or return;
   $self->brik_help_run_invalid_arg('add_nat_postrouting_dnat', $rule, 'HASH') or return;

   return $self->add_nat_postrouting('DNAT', $rule);
}

sub add_filter {
   my $self = shift;
   my ($chain, $target, $rule) = @_;

   $chain ||= $self->chain;
   $target ||= $self->target;
   $self->brik_help_run_undef_arg('add_filter', $chain) or return;
   $self->brik_help_run_undef_arg('add_filter', $target) or return;
   $self->brik_help_run_undef_arg('add_filter', $rule) or return;
   $self->brik_help_run_invalid_arg('add_filter', $rule, 'HASH') or return;

   return $self->add('filter', $chain, $target, $rule);
}

sub add_filter_output {
   my $self = shift;
   my ($target, $rule) = @_;

   $target ||= $self->target;
   $self->brik_help_run_undef_arg('add_filter_output', $target) or return;
   $self->brik_help_run_undef_arg('add_filter_output', $rule) or return;
   $self->brik_help_run_invalid_arg('add_filter_output', $rule, 'HASH') or return;

   return $self->add_filter('OUTPUT', $target, $rule);
}

sub add_filter_output_accept {
   my $self = shift;
   my ($rule) = @_;

   $self->brik_help_run_undef_arg('add_filter_output_accept', $rule) or return;
   $self->brik_help_run_invalid_arg('add_filter_output_accept', $rule, 'HASH') or return;

   return $self->add_filter_output('ACCEPT', $rule);
}

sub add_filter_output_reject {
   my $self = shift;
   my ($rule) = @_;

   $self->brik_help_run_undef_arg('add_filter_output_reject', $rule) or return;
   $self->brik_help_run_invalid_arg('add_filter_output_reject', $rule, 'HASH') or return;

   return $self->add_filter_output('REJECT', $rule);
}

sub del {
   my $self = shift;
   my ($table, $chain, $target, $rule) = @_;

   $table ||= $self->table;
   $chain ||= $self->chain;
   $target ||= $self->target;
   $self->brik_help_run_undef_arg('del', $table) or return;
   $self->brik_help_run_undef_arg('del', $chain) or return;
   $self->brik_help_run_undef_arg('del', $target) or return;
   $self->brik_help_run_undef_arg('del', $rule) or return;
   $self->brik_help_run_invalid_arg('del', $rule, 'HASH') or return;

   my $cmd = $self->_action('-D', $table, $chain, $target, $rule);

   return $self->command($cmd);
}

sub del_nat {
   my $self = shift;
   my ($chain, $target, $rule) = @_;

   $chain ||= $self->chain;
   $target ||= $self->target;
   $self->brik_help_run_undef_arg('del_nat', $chain) or return;
   $self->brik_help_run_undef_arg('del_nat', $target) or return;
   $self->brik_help_run_undef_arg('del_nat', $rule) or return;
   $self->brik_help_run_invalid_arg('del_nat', $rule, 'HASH') or return;

   return $self->del('nat', $chain, $target, $rule);
}

sub del_nat_output {
   my $self = shift;
   my ($target, $rule) = @_;

   $target ||= $self->target;
   $self->brik_help_run_undef_arg('del_nat_output', $target) or return;
   $self->brik_help_run_undef_arg('del_nat_output', $rule) or return;
   $self->brik_help_run_invalid_arg('del_nat_output', $rule, 'HASH') or return;

   return $self->del_nat('OUTPUT', $target, $rule);
}

sub del_nat_output_return {
   my $self = shift;
   my ($rule) = @_;

   $self->brik_help_run_undef_arg('del_nat_output_return', $rule) or return;
   $self->brik_help_run_invalid_arg('del_nat_output_return', $rule, 'HASH') or return;

   return $self->del_nat_output('RETURN', $rule);
}

sub del_nat_output_redirect {
   my $self = shift;
   my ($rule) = @_;

   $self->brik_help_run_undef_arg('del_nat_output_return', $rule) or return;
   $self->brik_help_run_invalid_arg('del_nat_output_return', $rule, 'HASH') or return;

   return $self->del_nat_output('REDIRECT', $rule);
}

sub del_nat_output_dnat {
   my $self = shift;
   my ($rule) = @_;

   $self->brik_help_run_undef_arg('del_nat_output_return', $rule) or return;
   $self->brik_help_run_invalid_arg('del_nat_output_return', $rule, 'HASH') or return;

   return $self->del_nat_output('DNAT', $rule);
}

sub check {
   my $self = shift;
   my ($table, $chain, $target, $rule) = @_;

   $table ||= $self->table;
   $chain ||= $self->chain;
   $target ||= $self->target;
   $self->brik_help_run_undef_arg('check', $table) or return;
   $self->brik_help_run_undef_arg('check', $chain) or return;
   $self->brik_help_run_undef_arg('check', $target) or return;
   $self->brik_help_run_undef_arg('check', $rule) or return;
   $self->brik_help_run_invalid_arg('check', $rule, 'HASH') or return;

   my $cmd = $self->_action('-C', $table, $chain, $target, $rule);

   return $self->command($cmd);
}

sub check_nat {
   my $self = shift;
   my ($chain, $target, $rule) = @_;

   $chain ||= $self->chain;
   $target ||= $self->target;
   $self->brik_help_run_undef_arg('check_nat', $chain) or return;
   $self->brik_help_run_undef_arg('check_nat', $target) or return;
   $self->brik_help_run_undef_arg('check_nat', $rule) or return;
   $self->brik_help_run_invalid_arg('check_nat', $rule, 'HASH') or return;

   return $self->check('nat', $chain, $target, $rule);
}

sub check_nat_output {
   my $self = shift;
   my ($target, $rule) = @_;

   $target ||= $self->target;
   $self->brik_help_run_undef_arg('check_nat_output', $target) or return;
   $self->brik_help_run_undef_arg('check_nat_output', $rule) or return;
   $self->brik_help_run_invalid_arg('check_nat_output', $rule, 'HASH') or return;

   return $self->check_nat('OUTPUT', $target, $rule);
}

sub check_nat_output_return {
   my $self = shift;
   my ($rule) = @_;

   $self->brik_help_run_undef_arg('check_nat_output_return', $rule) or return;
   $self->brik_help_run_invalid_arg('check_nat_output_return', $rule, 'HASH') or return;

   return $self->check_nat_output('RETURN', $rule);
}

sub check_nat_output_redirect {
   my $self = shift;
   my ($rule) = @_;

   $self->brik_help_run_undef_arg('check_nat_output_return', $rule) or return;
   $self->brik_help_run_invalid_arg('check_nat_output_return', $rule, 'HASH') or return;

   return $self->check_nat_output('REDIRECT', $rule);
}

sub check_nat_output_dnat {
   my $self = shift;
   my ($rule) = @_;

   $self->brik_help_run_undef_arg('check_nat_output_return', $rule) or return;
   $self->brik_help_run_invalid_arg('check_nat_output_return', $rule, 'HASH') or return;

   return $self->check_nat_output('DNAT', $rule);
}

sub _redirect_target_to {
   my $self = shift;
   my ($action, $target_host_port, $dest_host_port, $protocol) = @_;

   if ($target_host_port =~ m{^\d+$}) {
      $target_host_port = ":$target_host_port";
   }
   if ($dest_host_port =~ m{^\d+$}) {
      $dest_host_port = ":$dest_host_port";
   }

   my ($target_host, $target_port) = split(/:/, $target_host_port);
   $target_host ||= '';
   $target_port ||= '';

   my ($dest_host, $dest_port) = split(/:/, $dest_host_port);
   $dest_host ||= '';
   $dest_port ||= '';

   my $method_return = '';
   my $method_dnat = '';
   if ($action eq 'start') {
      $method_return = 'add_nat_output_return';
      $method_dnat = 'add_nat_output_dnat';
   }
   else {
      $method_return = 'del_nat_output_return';
      $method_dnat = 'del_nat_output_dnat';
   }

   # Add only if it does not exist yet
   if ($action eq 'start' && ! $self->check_nat_output_return({ state => 'ESTABLISHED' })) {
      $self->$method_return({ state => 'ESTABLISHED' }) or return;
   }

   # Use only specified protocol
   if ($protocol) {
      my $rule = {
         destination => $target_host,
         dest_port => $target_port,
         to_destination => "$dest_host:$dest_port",
         protocol => $protocol,
      };
      if ($action eq 'start' && ! $self->check_nat_output_dnat($rule)) {
         $self->$method_dnat($rule) or return;
      }
      elsif ($action eq 'stop') {
         $self->$method_dnat($rule) or return;
      }
   }
   # Or use both tcp and udp
   else {
      my $rule_tcp = {
         destination => $target_host,
         dest_port => $target_port,
         to_destination => "$dest_host:$dest_port",
         protocol => 'tcp',
      };
      my $rule_udp = {
         destination => $target_host,
         dest_port => $target_port,
         to_destination => "$dest_host:$dest_port",
         protocol => 'udp',
      };
      if ($action eq 'start' && ! $self->check_nat_output_dnat($rule_tcp)) {
         $self->$method_dnat($rule_tcp) or return;
      }
      elsif ($action eq 'stop') {
         $self->$method_dnat($rule_tcp) or return;
      }
      if ($action eq 'start' && ! $self->check_nat_output_dnat($rule_udp)) {
         $self->$method_dnat($rule_udp) or return;
      }
      elsif ($action eq 'stop') {
         $self->$method_dnat($rule_udp) or return;
      }
   }

   return 1;
}

sub start_redirect_target_to {
   my $self = shift;
   my ($target_host_port, $dest_host_port, $protocol) = @_;

   $self->brik_help_run_undef_arg('start_redirect_target_to', $target_host_port) or return;
   $self->brik_help_run_undef_arg('start_redirect_target_to', $dest_host_port) or return;

   return $self->_redirect_target_to('start', $target_host_port, $dest_host_port, $protocol);
}

sub start_redirect_target_tcp_to {
   my $self = shift;
   my ($target_host_port, $dest_host_port) = @_;

   $self->brik_help_run_undef_arg('start_redirect_target_tcp_to', $target_host_port) or return;
   $self->brik_help_run_undef_arg('start_redirect_target_tcp_to', $dest_host_port) or return;

   return $self->start_redirect_target_to($target_host_port, $dest_host_port, 'tcp');
}

sub start_redirect_target_udp_to {
   my $self = shift;
   my ($target_host_port, $dest_host_port) = @_;

   $self->brik_help_run_undef_arg('start_redirect_target_udp_to', $target_host_port) or return;
   $self->brik_help_run_undef_arg('start_redirect_target_udp_to', $dest_host_port) or return;

   return $self->start_redirect_target_to($target_host_port, $dest_host_port, 'udp');
}

sub stop_redirect_target_to {
   my $self = shift;
   my ($target_host_port, $dest_host_port, $protocol) = @_;

   $self->brik_help_run_undef_arg('stop_redirect_target_to', $target_host_port) or return;
   $self->brik_help_run_undef_arg('stop_redirect_target_to', $dest_host_port) or return;

   return $self->_redirect_target_to('stop', $target_host_port, $dest_host_port, $protocol);
}

1;

__END__

=head1 NAME

Metabrik::Network::Linux::Iptables - network::linux::iptables Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
