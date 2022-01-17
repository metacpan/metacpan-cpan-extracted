#
# $Id$
#
# system::freebsd::iocage Brik
#
package Metabrik::System::Freebsd::Iocage;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         release => [ qw(version) ],
      },
      attributes_default => {
         release => '10.2-RELEASE',
      },
      commands => {
         install => [ ],  # Inherited
         list => [ ],
         list_template => [ ],
         show => [ ],
         fetch => [ ],
         update => [ ],  # Alias to fetch
         create => [ qw(tag interface|OPTIONAL ipv4_address|OPTIONAL ipv6_address|OPTIONAL) ],
         start => [ qw(tag) ],
         stop => [ qw(tag) ],
         restart => [ qw(tag) ],
         destroy => [ qw(tag) ],
         delete => [ qw(tag) ],  # Alias to destroy
         execute => [ qw(tag command) ],
         console => [ qw(tag) ],
         set_template => [ qw(tag) ],
         unset_template => [ qw(tag) ],
         clone => [ qw(template tag interface ipv4_address ipv6_address|OPTIONAL) ],
         get_all_properties => [ qw(tag) ],
         get_property => [ qw(tag property) ],
         set_property => [ qw(tag property value) ],
         backup => [ qw(tag|$tag_list) ],
         restore => [ qw(tag) ],
         tag_to_uuid => [ qw(tag) ],
         get_snapshots => [ qw(tag|OPTIONAL) ],
         snaplist => [ qw(tag|OPTIONAL) ],  # alias
         delete_snapshot => [ qw(tag snapshot) ],
         snapremove => [ qw(tag snapshot) ],  # alias
      },
      require_binaries => {
         iocage => [ ],
      },
      need_packages => {
         freebsd => [ qw(iocage) ],
      },
   };
}

#
# https://iocage.readthedocs.org/en/latest/basic-use.html
#
sub install {
   my $self = shift;

   my $release = $self->release;

   # We have to run it as root the first time, so it is initiated correctly
   my $cmd = "iocage fetch release=$release";

   $self->sudo_system($cmd) or return;

   return $self->SUPER::install(@_);
}

sub list {
   my $self = shift;
   my ($arg) = @_;

   $arg ||= '';
   my $cmd = "iocage list $arg";
   my $lines = $self->capture($cmd) or return;

   my $header = 0;
   my @jails = ();
   for (@$lines) {
      if (! $header) {
         $header++;
         next;
      }

      if (/non iocage jails currently active/) {
         last;
      }

      my @toks = split(/\s+/, $_);
      my ($ip, $interface) = split(/,/, $toks[5]);
      $ip ||= '';
      $interface ||= '';
      push @jails, {
         jid => $toks[0],
         uuid => $toks[1],
         boot => $toks[2],
         state => $toks[3],
         tag => $toks[4],
         ip => $ip,
         interface => $interface,
      };
   }

   return \@jails;
}

sub list_template {
   my $self = shift;

   return $self->list('-t');
}

sub show {
   my $self = shift;

   my $cmd = "iocage list";

   return $self->system($cmd);
}

sub fetch {
   my $self = shift;

   my $cmd = "iocage fetch";

   return $self->sudo_system($cmd);
}

sub update {
   my $self = shift;

   return $self->fetch(@_);
}

sub create {
   my $self = shift;
   my ($tag, $interface, $ipv4_address, $ipv6_address) = @_;

   $self->brik_help_run_undef_arg('create', $tag) or return;

   my $cmd = "iocage create tag=$tag";

   if (defined($interface) && defined($ipv4_address)) {
      $cmd .= " ip4_addr=\"$interface|$ipv4_address\"";
   }

   if (defined($interface) && defined($ipv6_address)) {
      $cmd .= " ip6_addr=\"$interface|$ipv6_address\"";
   }

   return $self->sudo_system($cmd);
}

sub start {
   my $self = shift;
   my ($tag) = @_;

   $self->brik_help_run_undef_arg('start', $tag) or return;

   my $cmd = "iocage start $tag";

   return $self->sudo_system($cmd);
}

sub stop {
   my $self = shift;
   my ($tag) = @_;

   $self->brik_help_run_undef_arg('stop', $tag) or return;

   my $cmd = "iocage stop $tag";

   return $self->sudo_system($cmd);
}

sub restart {
   my $self = shift;
   my ($tag) = @_;

   $self->brik_help_run_undef_arg('restart', $tag) or return;

   my $cmd = "iocage restart $tag";

   return $self->sudo_system($cmd);
}

sub destroy {
   my $self = shift;
   my ($tag) = @_;

   $self->brik_help_run_undef_arg('destroy', $tag) or return;

   my $cmd = "iocage destroy $tag";

   return $self->sudo_system($cmd);
}

sub delete {
   my $self = shift;

   return $self->destroy(@_);
}

sub execute {
   my $self = shift;
   my ($tag, $command) = @_;

   $self->brik_help_run_undef_arg('execute', $tag) or return;
   $self->brik_help_run_undef_arg('execute', $command) or return;

   my $cmd = "iocage exec $tag $command";

   return $self->sudo_execute($cmd);
}

sub console {
   my $self = shift;
   my ($tag) = @_;

   return $self->execute($tag, "/bin/csh");
   #my $cmd = "iocage chroot $tag /bin/csh";

   #return $self->sudo_system($cmd);
}

#
# https://iocage.readthedocs.org/en/latest/templates.html
#
sub set_template {
   my $self = shift;
   my ($tag) = @_;

   $self->brik_help_run_undef_arg('set_template', $tag) or return;

   my $cmd = "iocage set template=yes $tag";

   return $self->sudo_system($cmd);
}

sub unset_template {
   my $self = shift;
   my ($tag) = @_;

   $self->brik_help_run_undef_arg('unset_template', $tag) or return;

   my $cmd = "iocage set template=no $tag";

   return $self->sudo_system($cmd);
}

sub clone {
   my $self = shift;
   my ($template, $tag, $interface, $ipv4_address, $ipv6_address) = @_;

   $self->brik_help_run_undef_arg('clone', $template) or return;
   $self->brik_help_run_undef_arg('clone', $tag) or return;
   $self->brik_help_run_undef_arg('clone', $interface) or return;
   $self->brik_help_run_undef_arg('clone', $ipv4_address) or return;

   my $cmd = "iocage clone $template tag=$tag ip4_addr=\"$interface|$ipv4_address\"";

   if (defined($ipv6_address)) {
      $cmd .= " ip6_addr=\"$interface|$ipv6_address\"";
   }

   return $self->sudo_system($cmd);
}

sub get_all_properties {
   my $self = shift;
   my ($tag) = @_;

   $self->brik_help_run_undef_arg('get_all_properties', $tag) or return;

   my $cmd = "iocage get all $tag";
   my $r = $self->sudo_capture($cmd) or return;

   return $r;
}

sub get_property {
   my $self = shift;
   my ($tag, $property) = @_;

   $self->brik_help_run_undef_arg('get_property', $tag) or return;
   $self->brik_help_run_undef_arg('get_property', $property) or return;

   my $cmd = "iocage get $property $tag";
   my $r = $self->sudo_capture($cmd) or return;
   chomp($r);

   return $r;
}

sub set_property {
   my $self = shift;
   my ($tag, $property, $value) = @_;

   $self->brik_help_run_undef_arg('set_property', $tag) or return;
   $self->brik_help_run_undef_arg('set_property', $property) or return;
   $self->brik_help_run_undef_arg('set_property', $value) or return;

   my $cmd = "iocage set $property=\"$value\" $tag";

   return $self->sudo_system($cmd);
}

sub backup {
   my $self = shift;
   my ($tag) = @_;

   $self->brik_help_run_undef_arg('backup', $tag) or return;
   my $ref = $self->brik_help_run_invalid_arg('backup', $tag, 'ARRAY', 'SCALAR')
      or return;

   if ($ref eq 'ARRAY') {
      for my $tag (@$tag) {
         my $cmd = "iocage snapshot \"$tag\"";
         $self->sudo_system($cmd);
      }
      return 1;
   }

   my $cmd = "iocage snapshot \"$tag\"";

   return $self->sudo_system($cmd);
}

sub restore {
   my $self = shift;
   my ($tag) = @_;

   $self->brik_help_run_undef_arg('restore', $tag) or return;

   my $cmd = "iocage rollback \"$tag\"";

   return $self->sudo_system($cmd);
}

sub tag_to_uuid {
   my $self = shift;
   my ($tag) = @_;

   $self->brik_help_run_undef_arg('tag_to_uuid', $tag) or return;

   my $list = $self->list or return;
   for my $this (@$list) {
      if ($this->{tag} eq $tag) {
         return $this->{uuid};
      }
   }

   return 'undef';
}

sub get_snapshots {
   my $self = shift;
   my ($tag) = @_;

   # If no tag is given, we will do it for all running iocages
   my @tags;
   if (! defined($tag)) {
      my $list = $self->list or return;
      for my $this (@$list) {
         push @tags, $this->{tag};
      }
   }
   else {
      push @tags, $tag;
   }

   my @snapshots = ();
   for my $tag (@tags) {
      my $cmd = "iocage snaplist $tag";
      my $lines = $self->sudo_capture($cmd) or return;

      # NAME                                  CREATED                RSIZE   USED
      # ioc-2016-12-06_16:22:47               Tue Dec  6 16:22 2016  96K    8K

      my $header = 0;
      for (@$lines) {
         if (! $header) { # Skip first line, it is a header
            $header++;
            next;
         }

         if (/^(ioc\-\S+)\s+(\S+\s+\S+\s+\S+\s+\S+\s+\S+)\s+(\S+)\s+(\S+)$/) {
            push @snapshots, {
               tag => $tag,
               name => $1,
               created => $2,
               rsize => $3,
               used => $4,
            };
         }
      }
   }

   return \@snapshots;
}

# alias
sub snaplist {
   my $self = shift;

   return $self->get_snapshots(@_);
}

sub delete_snapshot {
   my $self = shift;
   my ($tag, $snapshot) = @_;

   $self->brik_help_run_undef_arg('delete_snapshot', $tag) or return;
   $self->brik_help_run_undef_arg('delete_snapshot', $snapshot) or return;

   my $cmd = "iocage snapremove $tag\@$snapshot";
   return $self->sudo_system($cmd);
}

# alias
sub snapremove {
   my $self = shift;

   return $self->snapremove(@_);
}

1;

__END__

=head1 NAME

Metabrik::System::Freebsd::Iocage - system::freebsd::iocage Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
