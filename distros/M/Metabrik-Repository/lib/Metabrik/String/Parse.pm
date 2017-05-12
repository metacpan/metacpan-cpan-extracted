#
# $Id: Parse.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# string::parse Brik
#
package Metabrik::String::Parse;
use strict;
use warnings;

use base qw(Metabrik);

sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      commands => {
         identify => [ qw(string) ],
         to_array => [ qw($data) ],
         to_matrix => [ qw($data) ],
         split_by_blank_line => [ qw($data) ],
      },
   };
}

sub to_array {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('to_array', $data) or return;
   $self->brik_help_run_invalid_arg('to_array', $data, 'SCALAR') or return;

   my @array = split(/\n/, $data);

   return \@array;
}

sub to_matrix {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('to_matrix', $data) or return;

   my $array = $self->to_array($data) or return;

   my @matrix = ();
   for my $this (@$array) {
      push @matrix, [ split(/\s+/, $this) ];
   }

   return \@matrix;
}

sub identify {
   my $self = shift;
   my ($string) = @_;

   $self->brik_help_run_undef_arg('identify', $string) or return;

   my $length = length($string);
   # Truncate to 128 Bytes
   my $subset = substr($string, 0, $length > 128 ? 128 : $length);

   my $identify = [ 'text' ]; # Default dump text string

   if ($subset =~ /^<html>/i) {
      push @$identify, 'html';
   }
   elsif ($subset =~ /^<xml /i) {
      push @$identify, 'xml';
   }
   elsif ($subset =~ /^\s*{\s+["a-zA-Z0-9:]+\s+/) {
      push @$identify, 'json';
   }
   elsif ($string =~ /^[a-zA-Z0-9+]+={1,2}$/) {
      push @$identify, 'base64';
   }
   elsif ($length == 32 && $string =~ /^[a-f0-9]+$/) {
      push @$identify, 'md5';
   }
   elsif ($length == 40 && $string =~ /^[a-f0-9]+$/) {
      push @$identify, 'sha1';
   }
   elsif ($length == 64 && $string =~ /^[a-f0-9]+$/) {
      push @$identify, 'sha256';
   }

   return $identify;
}

sub split_by_blank_line {
   my $self = shift;
   my ($data) = @_;

   $self->brik_help_run_undef_arg('split_by_blank_line', $data) or return;
   $self->brik_help_run_invalid_arg('split_by_blank_line', $data, 'ARRAY') or return;

   my $new = [];
   my @chunks = ();
   for (@$data) {
      if (/^\s*$/ && @$new > 0) {
         push @chunks, $new;
         $new = [];
         next;
      }
      push @$new, $_;
   }

   # Read last lines before eof (no more blank lines can be found)
   if (@$new > 0) {
      push @chunks, $new;
   }

   return \@chunks;
}

1;

__END__

=head1 NAME

Metabrik::String::Parse - string::parse Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
