#
# $Id: Rest.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# server::rest Brik
#
package Metabrik::Server::Rest;
use strict;
use warnings;

use base qw(Metabrik::Server::Http);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable api) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         hostname => [ qw(listen_hostname) ],
         port => [ qw(listen_port) ],
         output_mode => [ qw(json|xml) ],
      },
      attributes_default => {
         hostname => 'localhost',
         port => 8888,
         output_mode => 'json',
      },
      commands => {
         start => [ qw(get_handlers post_handlers|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::String::Json' => [ ],
         'Metabrik::String::Xml' => [ ],
      },
   };
}

sub start {
   my $self = shift;
   my ($get_handlers, $post_handlers) = @_;

   my $hostname = $self->hostname;
   my $port = $self->port;
   my $root = $self->datadir;
   $post_handlers ||= [];
   my $output_mode = $self->output_mode;
   $self->brik_help_run_undef_arg('start', $hostname) or return;
   $self->brik_help_run_undef_arg('start', $port) or return;
   $self->brik_help_run_undef_arg('start', $root) or return;
   $self->brik_help_run_undef_arg('start', $get_handlers) or return;

   my $http = HTTP::Server::Brick->new(
      port => $port,
      host => $hostname,
      timeout => defined($self->global) && $self->global->rtimeout || 3,
   );

   $http->mount('/' => { path => $root });

   my $se;
   if ($self->output_mode eq 'json') {
      $se = Metabrik::String::Json->new_from_brik_init($self) or return;
   }
   elsif ($self->output_mode eq 'xml') {
      $se = Metabrik::String::Xml->new_from_brik_init($self) or return;
   }
   else {
      return $self->log->error("start: output_mode not supported [$output_mode]");
   }

   for my $get (@$get_handlers) {
      $http->mount($get->{url} => {
         handler => sub {
            my ($req, $res) = @_;
            my $hash = &{$get->{sub}}($req, $res) || {
               error => 1,
               error_string => 'undef'
            };
            $res->add_content($se->encode($hash));
            $res->header('Content-Type' => 'application/'.$output_mode);
            return 1;
         },
         wildcard => 1,
      });
   }

   for my $post (@$post_handlers) {
   }

   return $self->_http($http)->start;
}

1;

__END__

=head1 NAME

Metabrik::Server::Rest - server::rest Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
