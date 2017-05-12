#
# $Id: Dump.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# string::dump Brik
#
package Metabrik::String::Dump;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable encode decode) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         use_identation => [ qw(0|1) ],
         use_base64 => [ qw(0|1) ],
         strip_crlf => [ qw(0|1) ],
      },
      attributes_default => {
         use_identation => 1,
         use_base64 => 0,
         strip_crlf => 0,
      },
      commands => {
         encode => [ qw($data) ],
         decode => [ qw($data) ],
      },
      require_modules => {
         'Data::Dump' => [ ],
      },
   };
}

sub encode {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('encode', $data) or return;

   if (! $self->use_identation) {
      $Data::Dump::INDENT = "";    # No indentation shorten length
   }
   if (! $self->use_base64) {
      $Data::Dump::TRY_BASE64 = 0; # Never encode in base64
   }

   my $encoded = Data::Dump::dump($data);

   if ($self->strip_crlf) {
      $encoded =~ s{\n}{}g;
   }

   return $encoded;
}

sub decode {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('decode', $data) or return;

   my $decoded = eval($data);

   return $decoded;
}

1;

__END__

=head1 NAME

Metabrik::String::Dump - string::dump Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
