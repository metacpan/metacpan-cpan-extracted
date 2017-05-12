#
# $Id: Compress.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# string::gzip Brik
#
package Metabrik::String::Compress;
use strict;
use warnings;

use base qw(Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
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
      },
   };
}

sub gunzip {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('gunzip', $data) or return;

   $self->debug && $self->log->debug("gunzip: length[".length($data)."]");

   $self->debug && $self->log->debug("gunzip: starting");

   my $plain = Gzip::Faster::gunzip($data)
      or return $self->log->error("gunzip: error");

   $self->debug && $self->log->debug("gunzip: finished");

   $self->debug && $self->log->debug("gunzip: length[".length($plain)."]");

   return \$plain;
}

sub gzip {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('gzip', $data) or return;

   my $gzipped = Gzip::Faster::gzip($data)
      or return $self->log->error("gzip: error");

   return \$gzipped;
}

1;

__END__

=head1 NAME

Metabrik::String::Compress - string::compress Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
