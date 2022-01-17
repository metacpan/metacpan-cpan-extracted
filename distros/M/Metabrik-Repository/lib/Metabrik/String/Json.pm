#
# $Id$
#
# string::json Brik
#
package Metabrik::String::Json;
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
         encode => [ qw($data_list|$data_hash) ],
         decode => [ qw($data) ],
         is_valid => [ qw($data) ],
      },
      require_modules => {
         'JSON::XS' => [ ],
      },
   };
}

sub encode {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('encode', $data) or return;
   $self->brik_help_run_invalid_arg('encode', $data, 'ARRAY', 'HASH')
      or return;

   $self->log->debug("encode: data[$data]");

   my $encoded = '';
   eval {
      my $j = JSON::XS->new;
      $j->relaxed(1);
      $j->utf8(1);
      $encoded = $j->encode($data);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("encode: unable to encode JSON: $@");
   }

   return $encoded;
}

sub decode {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('decode', $data) or return;

   $self->log->debug("decode: data[$data]");

   my $decoded = '';
   eval {
      my $j = JSON::XS->new;
      $j->relaxed(1);
      $j->utf8(1);
      $decoded = $j->decode($data);
   };
   if ($@) {
      chomp($@);
      return $self->log->error("decode: unable to decode JSON: $@");
   }

   return $decoded;
}

sub is_valid {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('is_valid', $data) or return;

   $self->log->debug("is_valid: data[$data]");

   eval {
      $self->decode($data);
   };
   if ($@) {
      return 0;
   }

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::String::Json - string::json Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
