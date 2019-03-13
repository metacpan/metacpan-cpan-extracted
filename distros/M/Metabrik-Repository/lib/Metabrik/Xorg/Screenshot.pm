#
# $Id: Screenshot.pm,v 6bd6acfc81d5 2019/03/13 09:56:26 gomor $
#
# xorg::screenshot Brik
#
package Metabrik::Xorg::Screenshot;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision: 6bd6acfc81d5 $',
      tags => [ qw(unstable) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         output => [ qw(output) ],
         format => [ qw(image_format) ],
         delay => [ qw(microseconds) ],
      },
      attributes_default => {
         output => 'screenshot-00001',
         format => 'png',
         delay => 100,
         ignore_error => 0,
      },
      commands => {
         install => [ ], # Inherited
         active_window => [ qw(output|OPTIONAL format|OPTIONAL) ],
         full_screen => [ qw(output|OPTIONAL format|OPTIONAL) ],
         select_window => [ qw(output|OPTIONAL format|OPTIONAL) ],
         window_id => [ qw(window_id output|OPTIONAL format|OPTIONAL) ],
         continuous_by_window_id => [ qw(window_id delay|OPTIONAL) ],
      },
      require_modules => {
         'Time::HiRes' => [ ],
         'Metabrik::File::Find' => [ ],
         'Metabrik::System::File' => [ ],
      },
      require_binaries => {
         'import' => [ ],
         'scrot' => [ ],
      },
      need_packages => {
         ubuntu => [ qw(imagemagick scrot) ],
         debian => [ qw(imagemagick scrot) ],
         kali => [ qw(imagemagick scrot) ],
      },
   };
}

sub _get_new_output {
   my $self = shift;
   my ($format) = @_;

   $format ||= $self->format;

   my $datadir = $self->datadir;

   my $ff = Metabrik::File::Find->new_from_brik_init($self) or return;
   my $files = $ff->files($datadir, 'screenshot-\d+\.'.$format) or return;

   if (@$files == 0) {
      return "$datadir/screenshot-00001.$format"; # First output file
   }

   my @sorted = sort { $a cmp $b } @$files;
   my ($id) = $sorted[-1] =~ m{screenshot-(\d+)\.$format};

   return $self->output(sprintf("$datadir/screenshot-%05d.$format", $id + 1));
}

sub active_window {
   my $self = shift;
   my ($output, $format) = @_;

   $format ||= $self->format;
   $output ||= $self->_get_new_output($format);

   $self->log->verbose("active_window: saving to file [$output]");

   my $cmd = "scrot --focused --border $output";
   $self->execute($cmd) or return;

   return $output;
}

sub full_screen {
   my $self = shift;
   my ($output, $format) = @_;

   $format ||= $self->format;
   $output ||= $self->_get_new_output($format);

   $self->log->verbose("full_screen: saving to file [$output]");

   my $cmd = "scrot $output";
   $self->execute($cmd) or return;

   return $output;
}

sub select_window {
   my $self = shift;
   my ($output, $format) = @_;

   $format ||= $self->format;
   $output ||= $self->_get_new_output($format);

   $self->log->verbose("select_window: saving to file [$output]");

   my $cmd = "scrot --select --border $output";
   $self->execute($cmd) or return;

   return $output;
}

sub window_id {
   my $self = shift;
   my ($window_id, $output, $format) = @_;

   $format ||= $self->format;
   $output ||= $self->_get_new_output($format);
   $self->brik_help_run_undef_arg('window_id', $window_id) or return;

   if ($format ne 'gif') {
      return $self->log->error("window_id: only GIF format supported");
   }

   my $cmd = "import -window $window_id $output";
   my $r = $self->execute($cmd) or return;

   if ($r == 256) {
      return $self->log->error("window_id: import failed");
   }

   return $output;
}

sub continuous_by_window_id {
   my $self = shift;
   my ($window_id, $delay) = @_;

   $delay ||= $self->delay;
   $self->brik_help_run_undef_arg('continuous_by_window_id', $window_id) or return;

   my $datadir = $self->datadir;

   my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
   my $list = $sf->glob("$datadir/continuous-*gif") or return;
   $sf->remove($list) or return;

   my @files = ();
   my $file = '';
   my $frame = 1;
   while (1) {
      $file = sprintf("$datadir/continuous-%05d.gif", $frame);
      my $r = $self->execute("import -window $window_id $file");
      if ($r > 1) {  # It means we have been interrupted
         $self->log->verbose("continuous_by_window_id: interrupted by user");
         last;
      }
      $self->log->verbose("continuous_by_window_id: done with [$file]");
      push @files, $file;
      Time::HiRes::usleep($delay);
      $frame++;
   }

   return \@files;
}

1;

__END__

=head1 NAME

Metabrik::Xorg::Screenshot - xorg::screenshot Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2019, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
