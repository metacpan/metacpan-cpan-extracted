#
# $Id: Xml.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# string::xml Brik
#
package Metabrik::String::Xml;
use strict;
use warnings;

use base qw(Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable encode decode) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         install => [ ], # Inherited
         encode => [ qw($data_hash) ],
         decode => [ qw($data) ],
      },
      require_modules => {
         'XML::Simple' => [ ],
      },
      need_packages => {
         ubuntu => [ qw(libexpat1-dev libxml2-dev) ],
         debian => [ qw(libexpat1-dev libxml2-dev) ],
         freebsd => [ qw(expat libxml2) ],
      },
   };
}

sub encode {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('encode', $data) or return;
   $self->brik_help_run_invalid_arg('encode', $data, 'HASH') or return;

   my $xs = XML::Simple->new;

   $self->log->debug("encode: data[$data]");

   return $xs->XMLout($data);
}

sub decode {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('decode', $data) or return;

   my $xs = XML::Simple->new;

   $self->log->debug("decode: data[$data]");

   return $xs->XMLin($data);
}

1;

__END__

=head1 NAME

Metabrik::String::Xml - string::xml Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
