#
# $Id$
#
# client::mongodb Brik
#
package Metabrik::Client::Mongodb;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         host => [ qw(host) ],
         port => [ qw(port) ],
         client => [ qw(INTERNAL) ],
         database => [ qw(database) ],
         collection => [ qw(collection) ],
      },
      attributes_default => {
         host => 'localhost',
         port => 27017,
      },
      commands => {
         connect => [ qw(host|OPTIONAL port|OPTIONAL) ],
         list_database_names => [ ],
         list_database_collection_names => [ qw(database) ],
         get_database => [ qw(database) ],
         get_database_collection => [ qw(database collection) ],
         get_database_collection_find_all => [ qw(database collection) ],
      },
      require_modules => {
         MongoDB => [ ],
      },
   };
}

#
# Some search examples:
# https://metacpan.org/pod/distribution/MongoDB/lib/MongoDB/Examples.pod
#

sub connect {
   my $self = shift;
   my ($host, $port) = @_;

   $host ||= $self->host;
   $port ||= $self->port;

   my $client = MongoDB::MongoClient->new(
      host => "mongodb://$host:$port",
   );

   return $self->client($client);
}

sub list_database_names {
   my $self = shift;

   my $client = $self->client;
   $self->brik_help_run_undef_arg('connect', $client) or return;

   return [ $client->database_names ];
}

sub list_database_collection_names {
   my $self = shift;
   my ($database) = @_;

   my $client = $self->client;
   $self->brik_help_run_undef_arg('connect', $client) or return;
   $self->brik_help_run_undef_arg('list_database_collection_names', $database) or return;

   my $db = $self->get_database($database) or return;

   return [ $db->collection_names ];
}

sub get_database {
   my $self = shift;
   my ($database) = @_;

   my $client = $self->client;
   $self->brik_help_run_undef_arg('connect', $client) or return;
   $self->brik_help_run_undef_arg('get_database', $database) or return;

   return $client->get_database($database);
}

sub get_database_collection {
   my $self = shift;
   my ($database, $collection) = @_;

   my $client = $self->client;
   $self->brik_help_run_undef_arg('connect', $client) or return;
   $self->brik_help_run_undef_arg('get_database_collection', $database) or return;
   $self->brik_help_run_undef_arg('get_database_collection', $collection) or return;

   my $db = $self->get_database($database) or return;

   return $db->get_collection($collection);
}

sub get_database_collection_find_all {
   my $self = shift;
   my ($database, $collection) = @_;

   my $client = $self->client;
   $self->brik_help_run_undef_arg('connect', $client) or return;
   $self->brik_help_run_undef_arg('get_database_collection', $database) or return;
   $self->brik_help_run_undef_arg('get_database_collection', $collection) or return;

   my $coll = $self->get_database_collection($database, $collection) or return;

   return [ $coll->find()->all() ];
}

1;

__END__

=head1 NAME

Metabrik::Client::Mongodb - client::mongodb Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
