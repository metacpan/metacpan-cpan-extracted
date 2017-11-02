#
# $Id: Javascript.pm,v 6af3d9cda2c3 2017/03/04 16:01:10 gomor $
#
# file::javascript Brik
#
package Metabrik::File::Javascript;
use strict;
use warnings;

use base qw(Metabrik::String::Javascript);

sub brik_properties {
   return {
      revision => '$Revision: 6af3d9cda2c3 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         eval => [ qw(file_js) ],
         deobfuscate => [ qw(file_js) ],
      },
   };
}

sub eval {
   my $self = shift;
   my ($file) = @_;

   $self->brik_help_run_undef_arg('eval', $file) or return;
   $self->brik_help_run_file_not_found('eval', $file) or return;

   my $fr = Metabrik::File::Raw->new_from_brik_init($self) or return;
   $fr->encoding('ascii');

   my $js = $fr->read($file) or return;

   return $self->SUPER::eval($js);
}

sub deobfuscate {
   my $self = shift;
   my ($file) = @_;

   $self->brik_help_run_undef_arg('deobfuscate', $file) or return;
   $self->brik_help_run_file_not_found('deobfuscate', $file) or return;

   my $fr = Metabrik::File::Raw->new_from_brik_init($self) or return;
   $fr->encoding('ascii');

   my $js = $fr->read($file) or return;

   return $self->SUPER::deobfuscate($js);
}

1;

__END__

=head1 NAME

Metabrik::File::Javascript - file::javascript Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
