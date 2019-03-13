#
# $Id: Compress.pm,v 6bd6acfc81d5 2019/03/13 09:56:26 gomor $
#
# string::gzip Brik
#
package Metabrik::String::Compress;
use strict;
use warnings;

use base qw(Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision: 6bd6acfc81d5 $',
      tags => [ qw(unstable gzip gunzip unzip uncompress) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         data => [ qw($data) ],
         memory_limit => [ qw(integer) ],
      },
      attributes_default => {
         memory_limit => '1_000_000_000', # XXX: to implement
      },
      commands => {
         install => [ ],  # Inherited
         gunzip => [ qw($data) ],
         gzip => [ qw($data) ],
      },
      require_modules => {
         'Gzip::Faster' => [ ],
      },
      need_packages => {
         ubuntu => [ qw(libz-dev) ],
         debian => [ qw(libz-dev) ],
         kali => [ qw(libz-dev) ],
      },
   };
}

sub gunzip {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('gunzip', $data) or return;

   if (! length($data)) {
      return $self->log->error("gunzip: empty data, nothing to decompress");
   }

   $self->log->debug("gunzip: length[".length($data)."]");

   $self->log->debug("gunzip: starting");

   my $plain = Gzip::Faster::gunzip($data);
   if (! defined($plain)) {
      return $self->log->error("gunzip: error");
   }

   $self->log->debug("gunzip: finished");

   $self->log->debug("gunzip: length[".length($plain)."]");

   return \$plain;
}

sub gzip {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('gzip', $data) or return;

   if (! length($data)) {
      return $self->log->error("gzip: empty data, nothing to compress");
   }

   my $gzipped = Gzip::Faster::gzip($data);
   if (! defined($gzipped)) {
      return $self->log->error("gzip: error");
   }

   return \$gzipped;
}

1;

__END__

=head1 NAME

Metabrik::String::Compress - string::compress Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
