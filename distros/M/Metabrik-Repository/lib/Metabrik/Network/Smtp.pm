#
# $Id: Smtp.pm,v 6bd6acfc81d5 2019/03/13 09:56:26 gomor $
#
# network::smtp Brik
#
package Metabrik::Network::Smtp;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: 6bd6acfc81d5 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         server => [ qw(server) ],
         port => [ qw(port) ],
         hello => [ qw(domain) ],
         username => [ qw(username) ],
         password => [ qw(password) ],
         auth_mechanism => [ qw(none|GSSAPI) ],
         _smtp => [ qw(INTERNAL) ],
      },
      attributes_default => {
         server => 'localhost',
         port => 25,
         auth_mechanism => 'none',
      },
      commands => {
         open => [ qw(server|OPTIONAL port|OPTIONAL username|OPTIONAL password|OPTIONAL) ],
         close => [ ],
      },
      need_packages => {
         ubuntu => [ qw(libgssapi-perl) ],
         debian => [ qw(libgssapi-perl) ],
         kali => [ qw(libgssapi-perl) ],
         freebsd => [ qw(p5-GSSAPI) ],
      },
      require_modules => {
         'Authen::SASL' => [ qw(Perl) ],
         'Authen::SASL::Perl::GSSAPI' => [ ],
         'Net::SMTP' => [ ],
      },
   };
}

sub open {
   my $self = shift;
   my ($server, $port, $username, $password) = @_;

   $server ||= $self->server;
   $port ||= $self->port;
   $self->brik_help_run_undef_arg('open', $server) or return;
   $self->brik_help_run_undef_arg('open', $port) or return;

   $username ||= $self->username;
   $password ||= $self->password;
   if (!defined($username)) {
      $username = '';
   }
   if (!defined($password)) {
      $password = '';
   }
   my $auth_mechanism = $self->auth_mechanism;

   my @args = (
      $server,
      Port => $port,
   );

   my $hello = $self->hello;
   if (defined($hello)) {
      push @args, ( Hello => $hello );
   }

   my $smtp;
   eval {
      $smtp = Net::SMTP->new(@args);
   };
   if (! defined($smtp) || $@) {
      chomp($@);
      return $self->log->error("open: Net::SMTP new failed for server [$server] port [$port] with [$!]: [$@]");
   }

   if ($auth_mechanism ne 'none') {
      my $sasl = Authen::SASL->new(
          mechanism => $auth_mechanism,
          callback => {
            pass => $password,
            user => $username,
         }
      );

      $smtp->starttls();

      my $r = $smtp->auth($sasl);
      $self->log->info("open: auth: returned [$r]");
   }

   #$self->log->info(Data::Dumper::Dumper($smtp));

   return $self->_smtp($smtp);
}

sub close {
   my $self = shift;

   my $smtp = $self->_smtp;
   if (defined($smtp)) {
      $smtp->quit;
      $self->_smtp(undef);
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::Network::Smtp - network::smtp Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
