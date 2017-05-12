#
# $Id: Smtp.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# audit::smtp Brik
#
package Metabrik::Audit::Smtp;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         hostname => [ qw(hostname) ],
         port => [ qw(integer) ],
         domainname => [ qw(domainname) ],
         _smtp => [ qw(INTERNAL) ],
      },
      attributes_default => {
         port => 25,
      },
      commands => {
         connect => [ qw(hostname|OPTIONAL port|OPTIONAL domainname|OPTIONAL) ],
         banner => [ ],
         quit => [ ],
         open_auth_login => [ ],
         open_relay => [ ],
         all => [ ],
      },
      require_modules => {
         'Net::SMTP' => [],
         'Net::Cmd' => [ qw(CMD_INFO CMD_OK CMD_MORE CMD_REJECT CMD_ERROR CMD_PENDING) ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         hostname => $self->global->hostname,
      },
   };
}

sub connect {
   my $self = shift;
   my ($hostname, $port, $domainname) = @_;

   $hostname ||= $self->hostname;
   $port ||= $self->port;
   $domainname ||= $self->domainname;
   $self->brik_help_run_undef_arg('connect', $hostname) or return;
   $self->brik_help_run_undef_arg('connect', $port) or return;
   $self->brik_help_run_undef_arg('connect', $domainname) or return;

   my $timeout = $self->global->ctimeout;

   my $smtp = Net::SMTP->new(
      $hostname,
      Port    => $port,
      Hello   => $domainname,
      Timeout => $timeout,
      Debug   => $self->log->level,
   ) or return $self->log->error("connect: $!");

   $self->_smtp($smtp);

   return $smtp;
}

sub quit {
   my $self = shift;

   my $smtp = $self->_smtp;
   $self->brik_help_run_undef_arg('connect', $smtp) or return;

   $self->_smtp(undef);

   return $smtp->quit;
}

sub banner {
   my $self = shift;

   my $smtp = $self->_smtp;
   $self->brik_help_run_undef_arg('connect', $smtp) or return;

   chomp(my $banner = $smtp->banner);

   # XXX: move to identify::smtp
   #if ($banner =~ /rblsmtpd/i) {
      #$log->debug("smtpRbl=1");
      #$result->rbl(1);
   #}
   #else {
      #$log->debug("smtpRbl=0");
      #$result->rbl(0);
   #}

   return $banner;
}

sub open_auth_login {
   my $self = shift;

   my $smtp = $self->_smtp;
   $self->brik_help_run_undef_arg('connect', $smtp) or return;

   my $smtp_feature_auth_login = 0;
   my $smtp_open_auth_login = 0;

   my $msg = $smtp->message;
   if ($msg =~ /AUTH LOGIN/i) {
      $smtp_feature_auth_login = 1;

      my $ok = $smtp->command("AUTH LOGIN")->response;
      if ($ok == Net::Cmd::CMD_MORE()) {
         $ok = $smtp->command("YWRtaW4=")->response; # Send login 'admin'
         if ($ok == Net::Cmd::CMD_MORE()) {
            $ok = $smtp->command("YWRtaW4=")->response; # Send password 'admin'
            if ($ok == Net::Cmd::CMD_OK()) {
               $smtp_open_auth_login = 1;
            }
         }
      }
   }
   else {
      $self->log->info("AUTH LOGIN not supported by target");
   }

   return {
      smtp_feature_auth_login => $smtp_feature_auth_login,
      smtp_open_auth_login => $smtp_open_auth_login,
   };
}

sub open_relay {
   my $self = shift;

   my $smtp = $self->_smtp;
   $self->brik_help_run_undef_arg('connect', $smtp) or return;

   my $smtp_open_relay = 0;
   my $smtp_to_reject = 0;
   my $smtp_to_error = 0;
   my $smtp_from_reject = 0;
   my $smtp_from_error = 0;

   my $ok = $smtp->mail('audit@example.com');
   if ($ok) {
      $ok = $smtp->to('audit@example.com');
      if ($ok) {
         $smtp_open_relay = 1;
      }
      else {
         my $status = $smtp->status;
         if ($status == Net::Cmd::CMD_REJECT()) {
            $smtp_to_reject = 1;
         }
         elsif ($status == Net::Cmd::CMD_ERROR()) {
            $smtp_to_error = 1;
         }
         else {
            chomp(my $msg = $smtp->message);
            $self->log->debug("open_relay: MSG[$msg]");
         }
      }
   }
   else {
      my $status = $smtp->status;
      if ($status == Net::Cmd::CMD_REJECT()) {
         $smtp_from_reject = 1;
      }
      elsif ($status == Net::Cmd::CMD_ERROR()) {
         $smtp_from_error = 1;
      }
      else {
         chomp(my $msg = $smtp->message);
         $self->log->debug("open_relay: MSG[$msg]");
      }
   }

   return {
      smtp_open_relay => $smtp_open_relay,
      smtp_to_reject => $smtp_to_reject,
      smtp_to_error => $smtp_to_error,
      smtp_from_reject => $smtp_from_reject,
      smtp_from_error => $smtp_from_error,
   };
}

sub all {
   my $self = shift;

   my $hash = {};

   my $check_001 = $self->open_auth_login;
   for (keys %$check_001) { $hash->{$_} = $check_001->{$_} }

   my $check_002 = $self->open_relay;
   for (keys %$check_002) { $hash->{$_} = $check_002->{$_} }

   return $hash;
}

1;

__END__

=head1 NAME

Metabrik::Audit::Smtp - audit::smtp Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
