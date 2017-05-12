#
# $Id: Text.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# file::text Brik
#
package Metabrik::File::Text;
use strict;
use warnings;

use base qw(Metabrik::File::Write);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable read write) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         input => [ qw(file) ],
         output => [ qw(file) ],
         as_array => [ qw(0|1) ],
         strip_crlf => [ qw(0|1) ],
         _fr => [ qw(INTERNAL) ],
      },
      # encoding: see `perldoc Encode::Supported' for other types
      attributes_default => {
         encoding => 'utf8',
         as_array => 0,
         strip_crlf => 0,
      },
      commands => {
         read => [ qw(input) ],
         read_line => [ qw(input count|OPTIONAL) ],
         read_split_by_blank_line => [ qw(input) ],
         write => [ qw($data|$data_ref|$data_list output) ],
      },
      require_modules => {
         'Metabrik::File::Read' => [ ],
      },
   };
}

sub _open {
   my $self = shift;
   my ($input) = @_;

   my $fr = Metabrik::File::Read->new_from_brik_init($self) or return;
   $fr->input($input);
   $fr->encoding($self->encoding);
   $fr->as_array($self->as_array);
   $fr->strip_crlf($self->strip_crlf);

   $fr->open or return;

   return $fr;
}

#
# Read everything available
#
sub read {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   $self->brik_help_run_undef_arg('read', $input) or return;

   my $fr = $self->_open($input) or return;
   my $data = $fr->read or return;
   $fr->close;

   return $data;
}

#
# Just return next available line
#
sub read_line {
   my $self = shift;
   my ($input, $count) = @_;

   $input ||= $self->input;
   $count ||= 1;
   $self->brik_help_run_undef_arg('read_line', $input) or return;
   $self->brik_help_run_file_not_found('read_line', $input) or return;

   my $fr = $self->_fr;
   if (! $fr) {
      $fr = $self->_open($input) or return;
      $self->_fr($fr);
   }

   if ($fr->eof) {
      $fr->close;
      $self->_fr(undef);
      return 0;
   }

   my $data;
   my @lines = ();
   if ($count > 1) {
      for (1..$count) {
         $data = $fr->read_line;
         push @lines, $data;
      }
   }
   else {
      $data = $fr->read_line;
   }

   return $count > 1 ? \@lines : $data;
}

#
# Will read everything until eof
#
sub read_split_by_blank_line {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   $self->brik_help_run_undef_arg('read_split_by_blank_line', $input) or return;

   my $fr = $self->_open($input) or return;

   my @chunks = ();
   while (my $this = $fr->read_until_blank_line) {
      push @chunks, $this;
      last if $fr->eof;
   }

   $fr->close;

   return \@chunks;
}

sub write {
   my $self = shift;
   my ($data, $output) = @_;

   $output ||= $self->output;
   $self->brik_help_run_undef_arg('write', $data) or return;
   $self->brik_help_run_undef_arg('write', $output) or return;

   $self->open($output) or return;
   # We check definedness because if we write 0 byte write will return 0
   my $r = $self->SUPER::write($data);
   if (! defined($r)) {
      return;
   }
   $self->close;

   return 1;
}

1;

__END__

=head1 NAME

Metabrik::File::Text - file::text Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
