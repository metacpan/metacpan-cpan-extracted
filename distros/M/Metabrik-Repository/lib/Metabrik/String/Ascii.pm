#
# $Id: Ascii.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# string::ascii Brik
#
package Metabrik::String::Ascii;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable encode decode) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         from_dec => [ qw(data|$data_list) ],
      },
   };
}

sub from_dec {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('from_dec', $data) or return;
   my $ref = $self->brik_help_run_invalid_arg('from_dec', $data, 'ARRAY', 'SCALAR')
      or return;

   my @data = ();
   if ($ref eq 'ARRAY') {
      for my $this (@$data) {
         if ($this =~ /^\d+$/) {
            push @data, $this;
         }
         else {
            $self->log->warning("from_dec: data [$this] is not decimal, skipping");
         }
      }
   }
   else {
      if ($data =~ /^\d+$/) {
         push @data, $data;
      }
      else {
         $self->log->warning("from_dec: data [$data] is not decimal, skipping");
      }
   }

   my $str = '';
   for (@data) {
      $str .= sprintf("%c", $_);
   }

   return $str;
}

1;

__END__

=head1 NAME

Metabrik::String::Ascii - string::ascii Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
