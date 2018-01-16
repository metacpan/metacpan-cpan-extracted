#
# $Id: Aes.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# crypto::aes Brik
#
package Metabrik::Crypto::Aes;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         encrypt => [ qw($data) ],
         decrypt => [ qw($data) ],
      },
      #require_modules => {
         #'Crypt::CBC' => [ ],
         #'Crypt::OpenSSL::AES' => [ ],
      #},
      require_binaries => {
         'openssl' => [ ],
      },
   };
}

sub encrypt {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('encrypt', $data) or return;

   #my $key = 'key';

   #my $cipher = Crypt::CBC->new(
      #-key => $key,
      #-cipher => 'Crypt::OpenSSL::AES',
   #) or return $self->log->error("cipher: $!");

   #my $crypted = $cipher->encrypt_hex($data);

   # Will only return hex encoded data
   my $crypted = `echo "$data" | openssl enc -e -a -aes-128-cbc`;

   return $crypted;
}

sub decrypt {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('decrypt', $data) or return;

   #my $key = 'key';

   #my $cipher = Crypt::CBC->new(
      #-key => $key,
      #-cipher => 'Crypt::OpenSSL::AES',
   #) or return $self->log->error("cipher: $!");

   #my $decrypted = $cipher->decrypt_hex($data);

   $self->log->debug("echo \"$data\" | openssl enc -d -a -aes-128-cbc");

   # Will only return hex decoded data
   my $decrypted = `echo "$data" | openssl enc -d -a -aes-128-cbc`;

   return $decrypted;
}

1;

__END__

=head1 NAME

Metabrik::Crypto::Aes - crypto::aes Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
