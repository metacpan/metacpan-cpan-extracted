#
# $Id$
#
# string::ini Brik
#
package Metabrik::String::Ini;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable encode decode) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         encode => [ qw($data_hash) ],
         decode => [ qw($data) ],
      },
      require_modules => {
         'Config::Tiny' => [ ],
         'Storable' => [ qw(dclone) ],
      },
   };
}

sub encode {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('encode', $data) or return;
   $self->brik_help_run_invalid_arg('encode', $data, 'HASH') or return;

   my $copy = Storable::dclone($data);
   bless($copy, 'Config::Tiny');

   my ($config) = $copy->write_string;
   if (! defined($config)) {
      return $self->log->error("encode: write_string failed");
   }

   chomp($config);

   return $config;
}

sub decode {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('decode', $data) or return;

   my ($config) = Config::Tiny->read_string($data);

   return { %$config };
}

1;

__END__

=head1 NAME

Metabrik::String::Ini - string::ini Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
