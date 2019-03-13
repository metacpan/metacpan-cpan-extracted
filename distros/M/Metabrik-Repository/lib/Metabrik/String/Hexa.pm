#
# $Id: Hexa.pm,v 6bd6acfc81d5 2019/03/13 09:56:26 gomor $
#
# string::hexa Brik
#
package Metabrik::String::Hexa;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: 6bd6acfc81d5 $',
      tags => [ qw(unstable encode decode hex) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         with_x => [ ],
      },
      attributes_default => {
         with_x => 1,
      },
      commands => {
         encode => [ qw($data) ],
         decode => [ qw($data) ],
         is_hexa => [ qw($data) ],
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

   my $encoded = unpack('H*', $data);

   if ($self->with_x) {
      $encoded =~ s/(..)/\\x$1/g;
   }

   return $encoded;
}

sub decode {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('decode', $data) or return;

   # Keep only hex-compliant characters
   $data =~ s/[^a-fA-F0-9]//g;

   my $decoded = pack('H*', $data);

   return $decoded;
}

sub is_hexa {
   my $self = shift;
   my ($data) = @_;

   my $this = lc($data);
   $this =~ s/\\x//g;

   if ($this =~ /^[a-f0-9]+$/) {
      return 1;
   }

   return 0;
}

1;

__END__

=head1 NAME

Metabrik::String::Hexa - string::hexa Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
