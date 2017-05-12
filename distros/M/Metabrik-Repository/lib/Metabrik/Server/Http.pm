#
# $Id: Http.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# server::http Brik
#
package Metabrik::Server::Http;
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
         datadir => [ qw(datadir) ],
         hostname => [ qw(listen_hostname) ],
         port => [ qw(listen_port) ],
         _http => [ qw(INTERNAL) ],
      },
      attributes_default => {
         hostname => 'localhost',
         port => 8888,
      },
      commands => {
         start => [ qw(listen_hostname|OPTIONAL listen_port|OPTIONAL datadir|OPTIONAL) ],
      },
      require_modules => {
         'HTTP::Server::Brick' => [ ],
      },
   };
}

sub start {
   my $self = shift;
   my ($hostname, $port, $root) = @_;

   $hostname ||= $self->hostname;
   $port ||= $self->port;
   $root ||= $self->datadir;

   my $http = HTTP::Server::Brick->new(
      port => $port,
      host => $hostname,
      timeout => $self->global->rtimeout,
   );

   $http->mount('/' => { path => $root });

   return $self->_http($http)->start;
}

1;

__END__

=head1 NAME

Metabrik::Server::Http - server::http Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
