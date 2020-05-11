#
# $Id$
#
# file::pdf Brik
#
package Metabrik::File::Pdf;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
      },
      attributes_default => {
      },
      commands => {
         secure => [ qw(pdf password) ],
         to_png => [ qw(pdf) ],
         from_png => [ qw(glob output) ],
         from_pdf_to_image_pdf => [ qw(pdf secure|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::String::Password' => [],
         'Metabrik::System::File' => [],
      },
      require_binaries => {
         pdftk => [],  # snap install pdftk
         pdftoppm => [],
         convert => [],
      },
      need_packages => {
         ubuntu => [ qw(poppler-utils imagemagick) ],  # pdftoppm, convert
         debian => [ qw(poppler-utils imagemagick) ],  # pdftoppm, convert
         kali => [ qw(poppler-utils imagemagick) ],    # pdftoppm, convert
      },
   };
}

#
# Secures a PDF by forbidding: printing, copy/paste and related things.
#
# Example:
#
# run string::password generate
# my $pass = $RUN->[3]
# ls *.pdf
# run file::pdf secure $RUN $pass
#
sub secure {
   my $self = shift;
   my ($pdf, $password) = @_;

   $self->brik_help_run_undef_arg('secure', $pdf) or return;
   $self->brik_help_run_undef_arg('secure', $password) or return;

   if (ref($pdf) ne 'ARRAY') {
      $pdf = [ $pdf ];
   }

   my @secure = ();
   for my $this (@$pdf) {
      if (! -f $this) {
         $self->log->warning("secure: file not found [$this], skipping");
         next;
      }
      my $secure = $this;
      $secure =~ s{\.pdf$}{\.secure\.pdf};
      $self->system("pdftk \"$this\" output \"$secure\" owner_pw $password");
      push @secure, $secure;
   }

   return \@secure;
}

sub to_png {
   my $self = shift;
   my ($pdf) = @_;

   $self->brik_help_run_undef_arg('to_png', $pdf) or return;
   $self->brik_help_run_file_not_found('to_png', $pdf) or return;

   my $output = $pdf;
   $output =~ s{\.pdf$}{};
   $self->system("pdftoppm \"$pdf\" \"$output\" -png");

   my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
   my $png = $sf->glob("*.png");

   return $png;
}

sub from_png {
   my $self = shift;
   my ($glob, $output) = @_;

   $self->brik_help_run_undef_arg('from_png', $glob) or return;
   $self->brik_help_run_undef_arg('from_png', $output) or return;

   $self->system("convert $glob \"$output\"");

   return $output;
}

sub from_pdf_to_image_pdf {
   my $self = shift;
   my ($pdf, $secure) = @_;

   $self->brik_help_run_undef_arg('from_pdf_to_image_pdf', $pdf) or return;
   $self->brik_help_run_file_not_found('from_pdf_to_image_pdf', $pdf)
      or return;

   my $sp = Metabrik::String::Password->new_from_brik_init($self) or return;
   my $sf = Metabrik::System::File->new_from_brik_init($self) or return;

   my $png = $self->to_png($pdf) or return;

   my $output = $pdf;
   $output =~ s{\.pdf$}{.image.pdf};

   my $png_list = '';
   for (@$png) {
      $png_list .= "\"$_\" ";
   }

   $self->system("convert $png_list \"$output\"");

   $sf->remove($png);

   if ($secure) {
      my $list = $sp->generate;
      my $pass = $list->[3];
      $output = $self->secure($output, $pass);
      return [ $output, $pass ];
   }

   return $output;
}

1;

__END__

=head1 NAME

Metabrik::File::Pdf - file::pdf Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
