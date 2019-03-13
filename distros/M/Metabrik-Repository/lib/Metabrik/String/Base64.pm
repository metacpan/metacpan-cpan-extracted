#
# $Id: Base64.pm,v 6bd6acfc81d5 2019/03/13 09:56:26 gomor $
#
# string::base64 Brik
#
package Metabrik::String::Base64;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: 6bd6acfc81d5 $',
      tags => [ qw(unstable encode decode) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         encode => [ qw($data) ],
         decode => [ qw($data) ],
      },
      require_modules => {
         'MIME::Base64' => [ ],
      },
   };
}

sub encode {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('encode', $data) or return;

   my $encoded = MIME::Base64::encode_base64($data, '');
   chomp($encoded);

   return $encoded;
}

sub decode {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('decode', $data) or return;

   my $decoded = MIME::Base64::decode_base64($data);
   chomp($decoded);

   return $decoded;
}

1;

__END__

=head1 NAME

Metabrik::String::Base64 - string::base64 Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
