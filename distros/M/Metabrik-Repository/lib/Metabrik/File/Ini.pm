#
# $Id: Ini.pm,v 6fa51436f298 2018/01/12 09:27:33 gomor $
#
# file::ini Brik
#
package Metabrik::File::Ini;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: 6fa51436f298 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         input => [ qw(file) ],
         output => [ qw(file) ],
         encoding => [ qw(utf8|ascii) ],
         overwrite => [ qw(0|1) ],
      },
      attributes_default => {
         encoding => 'utf8',
         overwrite => 1,
      },
      commands => {
         read => [ qw(input|OPTIONAL) ],
         write => [ qw(ini_hash output|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::String::Ini' => [ ],
         'Metabrik::File::Text' => [ ],
      },
   };
}

sub read {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   $self->brik_help_run_undef_arg('read', $input) or return;

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;
   $ft->encoding($self->encoding);

   my $string = $ft->read($input) or return;

   my $si = Metabrik::String::Ini->new_from_brik_init($self) or return;

   my $ini_hash = $si->decode($string) or return;

   return $ini_hash;
}

sub write {
   my $self = shift;
   my ($ini_hash, $output) = @_;

   $output ||= $self->output;
   $self->brik_help_run_undef_arg('write', $output) or return;
   $self->brik_help_run_undef_arg('write', $ini_hash) or return;
   $self->brik_help_run_invalid_arg('write', $ini_hash, 'HASH') or return;

   my $si = Metabrik::String::Ini->new_from_brik_init($self) or return;

   my $string = $si->encode($ini_hash) or return;

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;
   $ft->encoding($self->encoding);

   $ft->write($string, $output) or return;

   return $output;
}

1;

__END__

=head1 NAME

Metabrik::File::Ini - file::ini Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2018, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
