#
# $Id$
#
# format::latex Brik
#
package Metabrik::Format::Latex;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package Metabrik::Client::Www);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         style => [ qw(file) ],
         capture_mode => [ qw(0|1) ],
      },
      attributes_default => {
         style => 'llncs.cls',
         capture_mode => 0,
      },
      commands => {
         install => [ ],  # Inherited
         update => [ ],
         make_dvi => [ qw(input style|OPTIONAL) ],
         make_pdf => [ qw(input style|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::File::Compress' => [ ],
         'Metabrik::System::File' => [ ],
      },
      require_binaries => {
         latex => [ ],
         pdflatex => [ ],
      },
      need_packages => {
         ubuntu => [ qw(texlive texlive-latex-extra texlive-lang-french) ],  # Sorry, the author is French
         debian => [ qw(texlive texlive-latex-extra texlive-lang-french) ],  # Sorry, the author is French
         kali => [ qw(texlive texlive-latex-extra texlive-lang-french) ],  # Sorry, the author is French
      },
   };
}

sub update {
   my $self = shift;

   my $datadir = $self->datadir;

   my @urls = (
      'ftp://ftp.springer.de/pub/tex/latex/llncs/latex2e/llncs.cls',
      'https://www.usenix.org/sites/default/files/usenix.sty_.txt',
      'https://www.usenix.org/sites/default/files/template.la_.txt',
   );

   my $r = $self->mirror(\@urls) or return;

   my @final = ();
   my $fc = Metabrik::File::Compress->new_from_brik_init($self) or return;
   my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
   for (@$r) {
      if (/usenix.sty_.txt$/) {
         my $files = $fc->uncompress($_) or next;
         next if (@$files == 0);
         $_ = $files->[0];
         my $basedir = $sf->basedir($_) or next;
         $sf->copy($_, $basedir.'/'.'usenix.sty') or next;
         $_ = $basedir.'/'.'usenix.sty';
      }
      elsif (/template.la_.txt$/) {
         my $files = $fc->uncompress($_) or next;
         next if (@$files == 0);
         $_ = $files->[0];
         my $basedir = $sf->basedir($_) or next;
         $sf->copy($_, $basedir.'/'.'usenix-template.tex') or next;
         $_ = $basedir.'/'.'usenix-template.tex';
      }
      push @final, $_;
   }

   return \@final;
}

sub make_dvi {
   my $self = shift;
   my ($input, $style) = @_;

   $style ||= $self->style;
   $self->brik_help_run_undef_arg('make_dvi', $input) or return;
   $self->brik_help_run_file_not_found('make_dvi', $input) or return;
   $self->brik_help_run_file_not_found('make_dvi', $style) or return;

   my $cmd = "latex \"$input\"";

   return $self->execute($cmd);
}

sub make_pdf {
   my $self = shift;
   my ($input, $style) = @_;

   my $datadir = $self->datadir;

   $style ||= $datadir.'/'.$self->style;
   $self->brik_help_run_undef_arg('make_pdf', $input) or return;
   $self->brik_help_run_file_not_found('make_pdf', $input) or return;
   $self->brik_help_run_file_not_found('make_pdf', $style) or return;

   my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
   $sf->copy($style, ".") or return;

   my $cmd = "pdflatex \"$input\"";

   return $self->execute($cmd);
}

1;

__END__

=head1 NAME

Metabrik::Format::Latex - format::latex Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2022, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
