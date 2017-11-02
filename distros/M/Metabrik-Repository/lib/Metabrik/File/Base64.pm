#
# $Id: Base64.pm,v 4f5647eb9e58 2017/03/05 12:22:13 gomor $
#
# file::base64 Brik
#
package Metabrik::File::Base64;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: 4f5647eb9e58 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         encoding => [ qw(utf8|ascii) ],
      },
      attributes_default => {
         encoding => 'ascii',
      },
      commands => {
         decode => [ qw(input output) ],
         decode_from_string => [ qw(input_string output) ],
         encode => [ qw(input output) ],
         encode_from_string => [ qw(input_string output) ],
      },
      require_modules => {
         'Metabrik::File::Raw' => [ ],
         'Metabrik::String::Base64' => [ ],
      },
   };
}

sub decode {
   my $self = shift;
   my ($input, $output) = @_;

   $self->brik_help_run_undef_arg('decode', $input) or return;
   $self->brik_help_run_file_not_found('decode', $input) or return;
   $self->brik_help_run_undef_arg('decode', $output) or return;

   my $fr_in = Metabrik::File::Raw->new_from_brik_init($self) or return;
   $fr_in->encoding($self->encoding);
   my $string = $fr_in->read($input) or return;

   my $sb = Metabrik::String::Base64->new_from_brik_init($self) or return;
   my $decoded = $sb->decode($string) or return;

   my $fr_out = Metabrik::File::Raw->new_from_brik_init($self) or return;
   $fr_out->encoding($self->encoding);
   $fr_out->overwrite(1);
   $fr_out->append(0);
   $fr_out->write($decoded, $output) or return;

   return $output;
}

sub decode_from_string {
   my $self = shift;
   my ($input_string, $output) = @_;

   $self->brik_help_run_undef_arg('decode_from_string', $input_string,) or return;
   $self->brik_help_run_undef_arg('decode_from_string', $output) or return;

   my $sb = Metabrik::String::Base64->new_from_brik_init($self) or return;
   my $decoded = $sb->decode($input_string) or return;

   my $fr = Metabrik::File::Raw->new_from_brik_init($self) or return;
   $fr->encoding($self->encoding);
   $fr->overwrite(1);
   $fr->append(0);
   $fr->write($decoded, $output) or return;

   return $output;
}

sub encode {
   my $self = shift;
   my ($input, $output) = @_;

   $self->brik_help_run_undef_arg('encode', $input) or return;
   $self->brik_help_run_file_not_found('encode', $input) or return;
   $self->brik_help_run_undef_arg('encode', $output) or return;

   my $fr_in = Metabrik::File::Raw->new_from_brik_init($self) or return;
   $fr_in->encoding($self->encoding);
   my $string = $fr_in->read($input) or return;

   my $sb = Metabrik::String::Base64->new_from_brik_init($self) or return;
   my $encoded = $sb->encode($string) or return;

   my $fr_out = Metabrik::File::Raw->new_from_brik_init($self) or return;
   $fr_out->encoding($self->encoding);
   $fr_out->overwrite(1);
   $fr_out->append(0);
   $fr_out->write($encoded, $output) or return;

   return $output;
}

sub encode_from_string {
   my $self = shift;
   my ($input_string, $output) = @_;

   $self->brik_help_run_undef_arg('encode_from_string', $input_string) or return;
   $self->brik_help_run_file_not_found('encode_from_string', $input_string) or return;
   $self->brik_help_run_undef_arg('encode_from_string', $output) or return;

   my $sb = Metabrik::String::Base64->new_from_brik_init($self) or return;
   my $encoded = $sb->encode($input_string) or return;

   my $fr = Metabrik::File::Raw->new_from_brik_init($self) or return;
   $fr->encoding($self->encoding);
   $fr->overwrite(1);
   $fr->append(0);
   $fr->write($encoded, $output) or return;

   return $output;
}

1;

__END__

=head1 NAME

Metabrik::File::Base64 - file::base64 Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
