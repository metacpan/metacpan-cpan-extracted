#
# $Id$
#
# file::compress brik
#
package Metabrik::File::Compress;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

sub brik_properties {
   return {
      revision => '$Revision$',
      tags => [ qw(unstable gzip unzip gunzip uncompress) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(directory) ],
         input => [ qw(file) ],
         output => [ qw(file) ],
      },
      attributes_default => {
         datadir => '.', # Uncompress in current directory by default
      },
      commands => {
         install => [ ], # Inherited
         unzip => [ qw(input|OPTIONAL datadir|OPTIONAL) ],
         gunzip => [ qw(input|OPTIONAL output|OPTIONAL datadir|OPTIONAL) ],
         uncompress => [ qw(input|OPTIONAL output|OPTIONAL datadir|OPTIONAL) ],
         gzip => [ qw(input) ],
         bunzip2 => [ qw(input output|OPTIONAL datadir|OPTIONAL) ],
         bzip2 => [ qw(input) ],
      },
      require_modules => {
         'Compress::Zlib' => [ ],
         'Metabrik::File::Type' => [ ],
         'Metabrik::File::Write' => [ ],
      },
      require_binaries => {
         unzip => [ ],
         gzip => [ ],
         bunzip2 => [ ],
         bzip2 => [ ],
      },
      need_packages => {
         ubuntu => [ qw(unzip gzip bzip2) ],
         debian => [ qw(unzip gzip bzip2) ],
         kali => [ qw(unzip gzip bzip2) ],
      },
   };
}

sub unzip {
   my $self = shift;
   my ($input, $datadir) = @_;

   $input ||= $self->input;
   $datadir ||= $self->datadir;
   $self->brik_help_run_undef_arg('unzip', $input) or return;

   my $cmd = "unzip -o $input -d $datadir/";

   my $lines = $self->capture($cmd) or return;

   my @files = ();
   for (@$lines) {
      if (m{^\s*inflating:\s*([^\s]+)\s*$}) {
         push @files, $1;
      }
   }

   return \@files;
}

sub gunzip {
   my $self = shift;
   my ($input, $output, $datadir) = @_;

   $input ||= $self->input;
   $output ||= $self->output;
   $datadir ||= $self->datadir;
   $self->brik_help_run_undef_arg('gunzip', $input) or return;

   # If no output given, we use the input file name by removing .gz like gunzip command
   if (! defined($output)) {
      ($output = $input) =~ s/.gz$//;
   }

   my $gz = Compress::Zlib::gzopen($input, "rb");
   if (! $gz) {
      return $self->log->error("gunzip: gzopen file [$input]: [$Compress::Zlib::gzerrno]");
   }

   my $fw = Metabrik::File::Write->new_from_brik_init($self) or return;
   $fw->append(0);
   $fw->encoding('ascii');
   $fw->overwrite(1);

   if ($output !~ m{^/}) {  # Concatenare with $datadir only when not full path
      $output = $datadir.'/'.$output;
   }

   my $fd = $fw->open($output) or return;

   my $no_error = 1;
   my $buffer = '';
   while ($gz->gzread($buffer) > 0) {
      $self->log->debug("gunzip: gzread ".length($buffer));
      my $r = $fw->write($buffer);
      $buffer = '';
      if (! defined($r)) {
         $self->log->warning("gunzip: write failed");
         $no_error = 0;
         next;
      }
   }

   if (! $no_error) {
      $self->log->warning("gunzip: had some errors during gunzipping");
   }

   $fw->close;

   return [ $output ];
}

sub uncompress {
   my $self = shift;
   my ($input, $output, $datadir) = @_;

   $input ||= $self->input;
   $datadir ||= $self->datadir;
   $self->brik_help_run_undef_arg('uncompress', $input) or return;
   $self->brik_help_run_file_not_found('uncompress', $input) or return;

   my $ft = Metabrik::File::Type->new_from_brik_init($self) or return;
   my $type = $ft->get_mime_type($input) or return;

   if ($type eq 'application/gzip'
   ||  $type eq 'application/x-gzip') {
      return $self->gunzip($input, $output, $datadir);
   }
   elsif ($type eq 'application/zip'
   ||     $type eq 'application/vnd.oasis.opendocument.text'
   ||     $type eq 'application/java-archive') {
      return $self->unzip($input, $datadir);
   }
   elsif ($type eq 'application/x-bzip2') {
      return $self->bunzip2($input, $output, $datadir);
   }

   return $self->log->error("uncompress: don't know how to uncompress file [$input] with MIME type [$type]");
}

sub gzip {
   my $self = shift;
   my ($input) = @_;

   $self->brik_help_run_undef_arg('gzip', $input) or return;
   $self->brik_help_run_file_not_found('gzip', $input) or return;

   my $cmd = "gzip -f \"$input\"";

   $self->execute($cmd) or return;

   return "$input.gz";
}

sub bzip2 {
   my $self = shift;
   my ($input, $output, $datadir) = @_;

   $input ||= $self->input;
   $output ||= $self->output;
   $datadir ||= $self->datadir;
   $self->brik_help_run_undef_arg('bzip2', $input) or return;

   # If no output given, we use the input file name by adding .bz2 like bzip2 command
   if (! defined($output)) {
      ($output = $input) =~ s/$/.bz2/;
   }

   my $cmd = "bzip2 $input";

   my $lines = $self->capture($cmd) or return;

   return [ $output ];
}

sub bunzip2 {
   my $self = shift;
   my ($input, $output, $datadir) = @_;

   $input ||= $self->input;
   $output ||= $self->output;
   $datadir ||= $self->datadir;
   $self->brik_help_run_undef_arg('bunzip2', $input) or return;

   # If no output given, we use the input file name by removing .bz2 like bunzip2 command
   if (! defined($output)) {
      ($output = $input) =~ s/.bz2$//;
   }

   my $cmd = "bunzip2 $input";

   my $lines = $self->capture($cmd) or return;

   return [ $output ];
}

1;

__END__

=head1 NAME

Metabrik::File::Compress - file::compress Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2020, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
