#
# $Id$
#
# client::dns Brik
#
package Metabrik::Client::Dns;
use strict;
use warnings;

use base qw(Metabrik::Network::Dns);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         get_local_resolver => [ qw(file|OPTIONAL) ],
         a_lookup => [ qw(host|$host_list nameserver|$nameserver_list|OPTIONAL port|OPTIONAL) ],
         aaaa_lookup => [ qw(host|$host_list nameserver|$nameserver_list|OPTIONAL port|OPTIONAL) ],
         ptr_lookup => [ qw(ip_address|$ip_address_list nameserver|$nameserver_list|OPTIONAL port|OPTIONAL) ],
         mx_lookup => [ qw(host|$host_list nameserver|$nameserver_list|OPTIONAL port|OPTIONAL) ],
         ns_lookup => [  qw(host|$host_list nameserver|$nameserver_list|OPTIONAL port|OPTIONAL) ],
         cname_lookup => [  qw(host|$host_list nameserver|$nameserver_list|OPTIONAL port|OPTIONAL) ],
         soa_lookup => [  qw(host|$host_list nameserver|$nameserver_list|OPTIONAL port|OPTIONAL) ],
         srv_lookup => [  qw(host|$host_list nameserver|$nameserver_list|OPTIONAL port|OPTIONAL) ],
         txt_lookup => [  qw(host|$host_list nameserver|$nameserver_list|OPTIONAL port|OPTIONAL) ],
      },
      attributes => {
         nameserver => [ qw(ip_address|$ip_address_list) ],
         timeout => [ qw(0|1) ],
         rtimeout => [ qw(timeout) ],
         return_list => [ qw(0|1) ],
         port => [ qw(port) ],
         use_recursion => [ qw(0|1) ],
      },
      attributes_default => {
         timeout => 0,
         rtimeout => 2,
         return_list => 1,
         port => 53,
         use_recursion => 1,
      },
      require_modules => {
         'Metabrik::File::Text' => [ ],
      },
   };
}

sub brik_init {
   my $self = shift;

   my $ns = $self->get_local_resolver;
   if (defined($ns)) {
      $self->nameserver($ns);
   }

   return $self->SUPER::brik_init(@_);
}

sub get_local_resolver {
   my $self = shift;
   my ($file) = @_;

   $file ||= "/etc/resolv.conf";

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;
   $ft->as_array(1);
   $ft->strip_crlf(1);

   my @nameservers = ();
   if (-f $file) {
      my $lines = $ft->read($file) or return;
      for (@$lines) {
         if (/^\s*nameserver\s+/) {
            my @toks = split(/\s+/);
            push @nameservers, $toks[1];
         }
      }

      $self->log->verbose("brik_init: using resolve.conf DNS: [@nameservers]");
   }

   my $google_ns = [ qw(8.8.8.8 8.8.4.4) ];
   if (@nameservers > 0) {
      $self->nameserver(\@nameservers);
   }
   else {
      $self->nameserver($google_ns);
   }

   return @nameservers > 0 ? \@nameservers : $google_ns;
}

sub a_lookup {
   my $self = shift;
   my ($host, $nameserver, $port) = @_;

   $nameserver ||= $self->nameserver;
   $port ||= $self->port || 53;
   $self->brik_help_run_undef_arg('a_lookup', $host) or return;
   my $ref = $self->brik_help_run_invalid_arg('a_lookup', $host, 'ARRAY', 'SCALAR')
      or return;

   if ($ref eq 'ARRAY') {
      my %res = ();
      for my $this (@$host) {
         my $r = $self->a_lookup($this, $nameserver, $port) or next;
         $res{$this} = $r;
      }

      return \%res;
   }
   else {
      my $list = $self->lookup($host, 'A', $nameserver, $port) or return;

      my @res = ();
      for (@$list) {
         if (defined($_->{address})) {
            push @res, $_->{address};
         }
      }

      return $self->return_list ? \@res : ($res[0] || 'undef');
   }

   return; # Error
}

sub aaaa_lookup {
   my $self = shift;
   my ($host, $nameserver, $port) = @_;

   $nameserver ||= $self->nameserver;
   $port ||= $self->port || 53;
   $self->brik_help_run_undef_arg('aaaa_lookup', $host) or return;
   my $ref = $self->brik_help_run_invalid_arg('aaaa_lookup', $host, 'ARRAY', 'SCALAR')
      or return;

   if ($ref eq 'ARRAY') {
      my %res = ();
      for my $this (@$host) {
         my $r = $self->aaaa_lookup($this, $nameserver, $port) or next;
         $res{$this} = $r;
      }

      return \%res;
   }
   else {
      my $list = $self->lookup($host, 'AAAA', $nameserver, $port) or return;

      my @res = ();
      for (@$list) {
         if (defined($_->{address})) {
            push @res, $_->{address};
         }
      }

      return $self->return_list ? \@res : ($res[0] || 'undef');
   }

   return; # Error
}

sub ptr_lookup {
   my $self = shift;
   my ($host, $nameserver, $port) = @_;

   $nameserver ||= $self->nameserver;
   $port ||= $self->port || 53;
   $self->brik_help_run_undef_arg('ptr_lookup', $host) or return;
   my $ref = $self->brik_help_run_invalid_arg('ptr_lookup', $host, 'ARRAY', 'SCALAR')
      or return;

   if ($ref eq 'ARRAY') {
      my %res = ();
      for my $this (@$host) {
         my $r = $self->ptr_lookup($this, $nameserver, $port) or next;
         $res{$this} = $r;
      }

      return \%res;
   }
   else {
      my $list = $self->lookup($host, 'PTR', $nameserver, $port) or return;

      my @res = ();
      for (@$list) {
         if (defined($_->{ptrdname})) {
            push @res, $_->{ptrdname};
         }
      }

      return $self->return_list ? \@res : ($res[0] || 'undef');
   }

   return; # Error
}

sub mx_lookup {
   my $self = shift;
   my ($host, $nameserver, $port) = @_;

   $nameserver ||= $self->nameserver;
   $port ||= $self->port || 53;
   $self->brik_help_run_undef_arg('mx_lookup', $host) or return;
   my $ref = $self->brik_help_run_invalid_arg('mx_lookup', $host, 'ARRAY', 'SCALAR')
      or return;

   if ($ref eq 'ARRAY') {
      my %res = ();
      for my $this (@$host) {
         my $r = $self->mx_lookup($this, $nameserver, $port) or next;
         $res{$this} = $r;
      }

      return \%res;
   }
   else {
      my $list = $self->lookup($host, 'MX', $nameserver, $port) or return;

      my @res = ();
      for (@$list) {
         if (defined($_->{exchange})) {
            push @res, $_->{exchange};
         }
      }

      return $self->return_list ? \@res : ($res[0] || 'undef');
   }

   return; # Error
}

sub ns_lookup {
   my $self = shift;
   my ($host, $nameserver, $port) = @_;

   $nameserver ||= $self->nameserver;
   $port ||= $self->port || 53;
   $self->brik_help_run_undef_arg('ns_lookup', $host) or return;
   my $ref = $self->brik_help_run_invalid_arg('ns_lookup', $host, 'ARRAY', 'SCALAR')
      or return;

   if ($ref eq 'ARRAY') {
      my %res = ();
      for my $this (@$host) {
         my $r = $self->ns_lookup($this, $nameserver, $port) or next;
         $res{$this} = $r;
      }

      return \%res;
   }
   else {
      my $list = $self->lookup($host, 'NS', $nameserver, $port) or return;

      my @res = ();
      for (@$list) {
         if (defined($_->{nsdname})) {
            push @res, $_->{nsdname};
         }
      }

      return $self->return_list ? \@res : ($res[0] || 'undef');
   }

   return; # Error
}

sub soa_lookup {
   my $self = shift;
   my ($host, $nameserver, $port) = @_;

   $nameserver ||= $self->nameserver;
   $port ||= $self->port || 53;
   $self->brik_help_run_undef_arg('soa_lookup', $host) or return;
   my $ref = $self->brik_help_run_invalid_arg('soa_lookup', $host, 'ARRAY', 'SCALAR')
      or return;

   if ($ref eq 'ARRAY') {
      my %res = ();
      for my $this (@$host) {
         my $r = $self->soa_lookup($this, $nameserver, $port) or next;
         $res{$this} = $r;
      }

      return \%res;
   }
   else {
      my $list = $self->lookup($host, 'SOA', $nameserver, $port) or return;

      my @res = ();
      for (@$list) {
         if (defined($_->{rdatastr})) {
            push @res, $_->{rdatastr};
         }
      }

      return $self->return_list ? \@res : ($res[0] || 'undef');
   }

   return; # Error
}

sub txt_lookup {
   my $self = shift;
   my ($host, $nameserver, $port) = @_;

   $nameserver ||= $self->nameserver;
   $port ||= $self->port || 53;
   $self->brik_help_run_undef_arg('txt_lookup', $host) or return;
   my $ref = $self->brik_help_run_invalid_arg('txt_lookup', $host, 'ARRAY', 'SCALAR')
      or return;

   if ($ref eq 'ARRAY') {
      my %res = ();
      for my $this (@$host) {
         my $r = $self->txt_lookup($this, $nameserver, $port) or next;
         $res{$this} = $r;
      }

      return \%res;
   }
   else {
      my $list = $self->lookup($host, 'TXT', $nameserver, $port) or return;

      my @res = ();
      for (@$list) {
         if (defined($_->{rdatastr})) {
            push @res, $_->{rdatastr};
         }
      }

      return $self->return_list ? \@res : ($res[0] || 'undef');
   }

   return; # Error
}

sub srv_lookup {
   my $self = shift;
   my ($host, $nameserver, $port) = @_;

   $nameserver ||= $self->nameserver;
   $port ||= $self->port || 53;
   $self->brik_help_run_undef_arg('srv_lookup', $host) or return;
   my $ref = $self->brik_help_run_invalid_arg('srv_lookup', $host, 'ARRAY', 'SCALAR')
      or return;

   if ($ref eq 'ARRAY') {
      my %res = ();
      for my $this (@$host) {
         my $r = $self->srv_lookup($this, $nameserver, $port) or next;
         $res{$this} = $r;
      }

      return \%res;
   }
   else {
      my $list = $self->lookup($host, 'SRV', $nameserver, $port) or return;

      my @res = ();
      for (@$list) {
         if (defined($_->{target})) {
            push @res, $_->{target};
         }
      }

      return $self->return_list ? \@res : ($res[0] || 'undef');
   }

   return; # Error
}

sub cname_lookup {
   my $self = shift;
   my ($host, $nameserver, $port) = @_;

   $nameserver ||= $self->nameserver;
   $port ||= $self->port || 53;
   $self->brik_help_run_undef_arg('cname_lookup', $host) or return;
   my $ref = $self->brik_help_run_invalid_arg('cname_lookup', $host, 'ARRAY', 'SCALAR')
      or return;

   if ($ref eq 'ARRAY') {
      my %res = ();
      for my $this (@$host) {
         my $r = $self->cname_lookup($this, $nameserver, $port) or next;
         $res{$this} = $r;
      }

      return \%res;
   }
   else {
      my $list = $self->lookup($host, 'CNAME', $nameserver, $port) or return;

      my @res = ();
      for (@$list) {
         if (defined($_->{cname})) {
            push @res, $_->{cname};
         }
      }

      return $self->return_list ? \@res : ($res[0] || 'undef');
   }

   return; # Error
}

1;

__END__

=head1 NAME

Metabrik::Client::Dns - client::dns Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
