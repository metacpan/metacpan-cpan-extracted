#
# $Id: Service.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# system::service Brik
#
package Metabrik::System::Service;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable daemon) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         get_system_service => [ ],
         status => [ qw(service_name) ],
         start => [ qw(service_name) ],
         stop => [ qw(service_name) ],
         restart => [ qw(service_name) ],
         my_os => [ ],
         enable => [ qw(service_name) ],
         disable => [ qw(service_name) ],
      },
      require_modules => {
         'Metabrik::System::Os' => [ ],
         'Metabrik::System::Debian::Service' => [ ],
         'Metabrik::System::Ubuntu::Service' => [ ],
         'Metabrik::System::Centos::Service' => [ ],
      },
      require_binaries => {
         service => [ ],
      },
   };
}

sub get_system_service {
   my $self = shift;

   my $os = $self->my_os;

   my $ss;
   if ($os eq 'ubuntu') {
      $ss = Metabrik::System::Ubuntu::Service->new_from_brik_init($self) or return;
   }
   elsif ($os eq 'debian') {
      $ss = Metabrik::System::Debian::Service->new_from_brik_init($self) or return;
   }
   elsif ($os eq 'centos') {
      $ss = Metabrik::System::Centos::Service->new_from_brik_init($self) or return;
   }
   else {
      $ss = $self;
   }

   return $ss;
}

sub status {
   my $self = shift;
   my ($name) = @_;

   if (defined($name)) {
      return $self->execute("service \"$name\" status");
   }
   elsif (! exists($self->brik_properties->{need_services})) {
      return $self->log->error($self->brik_help_run('status'));
   }
   else {
      my $os = $self->my_os;
      if (exists($self->brik_properties->{need_services}{$os})) {
         my $need_services = $self->brik_properties->{need_services}{$os};
         for my $service (@$need_services) {
            $self->execute("service \"$service\" status");
         }
      }
      else {
         return $self->log->error("status: don't know how to do that for OS [$os]");
      }
   }

   return 1;
}

sub start {
   my $self = shift;
   my ($name) = @_;

   if (defined($name)) {
      return $self->sudo_execute("service \"$name\" start");
   }
   elsif (! exists($self->brik_properties->{need_services})) {
      return $self->log->error($self->brik_help_run('start'));
   }
   else {
      my $os = $self->my_os;
      if (exists($self->brik_properties->{need_services}{$os})) {
         my $need_services = $self->brik_properties->{need_services}{$os};
         for my $service (@$need_services) {
            $self->sudo_execute("service \"$service\" start");
         }
      }
      else {
         return $self->log->error("start: don't know how to do that for OS [$os]");
      }
   }

   return 1;
}

sub stop {
   my $self = shift;
   my ($name) = @_;

   if (defined($name)) {
      return $self->sudo_execute("service \"$name\" stop");
   }
   elsif (! exists($self->brik_properties->{need_services})) {
      return $self->log->error($self->brik_help_run('stop'));
   }
   else {
      my $os = $self->my_os;
      if (exists($self->brik_properties->{need_services}{$os})) {
         my $need_services = $self->brik_properties->{need_services}{$os};
         for my $service (@$need_services) {
            $self->sudo_execute("service \"$service\" stop");
         }
      }
      else {
         return $self->log->error("stop: don't know how to do that for OS [$os]");
      }
   }

   return 1;
}

sub restart {
   my $self = shift;
   my ($name) = @_;

   if (defined($name)) {
      $self->stop($name) or return;
      sleep(1);
      return $self->start($name);
   }
   elsif (! exists($self->brik_properties->{need_services})) {
      return $self->log->error($self->brik_help_run('restart'));
   }
   else {
      my $os = $self->my_os;
      if (exists($self->brik_properties->{need_services}{$os})) {
         my $need_services = $self->brik_properties->{need_services}{$os};
         for my $service (@$need_services) {
            $self->stop($name) or next;
            sleep(1);
            $self->start($name);
         }
      }
      else {
         return $self->log->error("restart: don't know how to do that for OS [$os]");
      }
   }

   return 1;
}

sub my_os {
   my $self = shift;

   my $so = Metabrik::System::Os->new_from_brik_init($self) or return;
   return $so->my;
}

sub disable {
   my $self = shift;
   my ($service_name) = @_;

   $self->brik_help_run_undef_arg('disable', $service_name) or return;

   my $ss = $self->get_system_service or return;
   return $ss->disable($service_name);
}

sub enable {
   my $self = shift;
   my ($service_name) = @_;

   $self->brik_help_run_undef_arg('enable', $service_name) or return;

   my $ss = $self->get_system_service or return;
   return $ss->enable($service_name);
}

1;

__END__

=head1 NAME

Metabrik::System::Service - system::service Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
