#
# $Id: Hash.pm,v 6bd6acfc81d5 2019/03/13 09:56:26 gomor $
#
# string::hash Brik
#
package Metabrik::String::Hash;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: 6bd6acfc81d5 $',
      tags => [ qw(unstable sha sha1 sha256 sha512 md5 md5sum sum) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         sha1 => [ qw(data) ],
         sha256 => [ qw(data) ],
         sha512 => [ qw(data) ],
         md5 => [ qw(data) ],
      },
      require_modules => {
         'Crypt::Digest' => [ ],
      },
   };
}

sub _hash {
   my $self = shift;
   my ($function, $data) = @_;

   $self->brik_help_run_undef_arg($function, $data) or return;

   eval("use Crypt::Digest qw(digest_data_hex);");
   if ($@) {
      chomp($@);
      return $self->log->error("$function: unable to load function: $@");
   }

   return Crypt::Digest::digest_data_hex(uc($function), $data);
}

sub sha1 {
   my $self = shift;
   my ($data) = @_;

   return $self->_hash('sha1', $data);
}

sub sha256 {
   my $self = shift;
   my ($data) = @_;

   return $self->_hash('sha256', $data);
}

sub sha512 {
   my $self = shift;
   my ($data) = @_;

   return $self->_hash('sha512', $data);
}

sub md5 {
   my $self = shift;
   my ($data) = @_;

   return $self->_hash('md5', $data);
}

1;

__END__

=head1 NAME

Metabrik::File::Hash - file::hash Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
