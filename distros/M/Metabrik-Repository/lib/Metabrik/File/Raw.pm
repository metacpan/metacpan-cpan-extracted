#
# $Id: Raw.pm,v 4f5647eb9e58 2017/03/05 12:22:13 gomor $
#
# file::raw Brik
#
package Metabrik::File::Raw;
use strict;
use warnings;

use base qw(Metabrik::File::Write);

sub brik_properties {
   return {
      revision => '$Revision: 4f5647eb9e58 $',
      tags => [ qw(unstable read write) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         input => [ qw(file) ],
         output => [ qw(file) ],
         encoding => [ qw(utf8|ascii) ],  # Inherited
      },
      attributes_default => {
         encoding => 'ascii',
      },
      commands => {
         read => [ qw(input) ],
         write => [ qw($data|$data_ref|$data_list output) ],
      },
      require_modules => {
         'Metabrik::File::Read' => [ ],
      },
   };
}

sub read {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   $self->brik_help_run_undef_arg('read', $input) or return;

   my $fr = Metabrik::File::Read->new_from_brik_init($self) or return;
   $fr->input($input);
   $fr->encoding('ascii');
   $fr->as_array(0);
   $fr->strip_crlf(0);

   $fr->open or return;
   my $data = $fr->read or return;
   $fr->close;

   return $data;
}

sub write {
   my $self = shift;
   my ($data, $output) = @_;

   $output ||= $self->output;
   $self->brik_help_run_undef_arg('write', $data) or return;
   $self->brik_help_run_undef_arg('write', $output) or return;

   $self->debug && $self->log->debug("write: data[$data]");

   $self->open($output) or return;
   $self->SUPER::write($data) or return;
   $self->close;

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::File::Raw - file::raw Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
