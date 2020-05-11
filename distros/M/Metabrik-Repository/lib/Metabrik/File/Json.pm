#
# $Id$
#
# file::json Brik
#
package Metabrik::File::Json;
use strict;
use warnings;

use base qw(Metabrik::File::Text);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         input => [ qw(file) ],
         output => [ qw(file) ],
         encoding => [ qw(utf8|ascii) ],
         overwrite => [ qw(0|1) ],
        _sj => [ qw(INTERNAL) ],
      },
      attributes_default => {
         overwrite => 1,
      },
      commands => {
         read => [ qw(input_file|OPTIONAL) ],
         read_next => [ qw(input_file|OPTIONAL) ],
         write => [ qw($json_hash output_file|OPTIONAL) ],
         is_valid => [ qw(input_file|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::File::Write' => [ ],
         'Metabrik::String::Json' => [ ],
      },
   };
}

sub brik_use_properties {
   my $self = shift;

   return {
      attributes_default => {
         encoding => defined($self->global) && $self->global->encoding || 'utf8',
      },
   };
}

sub brik_init {
   my $self = shift;

   my $sj = Metabrik::String::Json->new_from_brik_init($self) or return;
   $self->_sj($sj);

   return $self->SUPER::brik_init;
}

sub read {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   $self->brik_help_run_undef_arg('read', $input) or return;

   my $sj = $self->_sj;

   my $data = $self->SUPER::read($input) or return;

   return $sj->decode($data);
}

sub read_next {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   $self->brik_help_run_undef_arg('read_next', $input) or return;

   my $sj = $self->_sj;

   my $data = $self->SUPER::read_line($input) or return;

   return $sj->decode($data);
}

sub write {
   my $self = shift;
   my ($json_hash, $output) = @_;

   $output ||= $self->output;
   $self->brik_help_run_undef_arg('write', $json_hash) or return;
   $self->brik_help_run_invalid_arg('write', $json_hash, 'ARRAY', 'HASH')
      or return;
   $self->brik_help_run_undef_arg('write', $output) or return;

   my $sj = $self->_sj;

   # Always make it an ARRAY
   $json_hash = ref($json_hash) eq 'ARRAY' ? $json_hash : [ $json_hash ];

   my @data = ();
   for my $this (@$json_hash) {
      my $data = $sj->encode($this) or next;
      push @data, $data;
   }

   $self->SUPER::write(\@data, $output) or return;

   return $output;
}

sub is_valid {
   my $self = shift;
   my ($input) = @_;

   $input ||= $self->input;
   $self->brik_help_run_undef_arg('is_valid', $input) or return;

   my $data = $self->SUPER::read($input) or return;

   my $sj = $self->_sj;

   return $sj->is_valid($data);
}

1;

__END__

=head1 NAME

Metabrik::File::Json - file::json Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
