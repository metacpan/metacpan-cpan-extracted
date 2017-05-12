#
# $Id: Scalpel.pm,v f6ad8c136b19 2017/01/01 10:13:54 gomor $
#
# forensic::scalpel Brik
#
package Metabrik::Forensic::Scalpel;
use strict;
use warnings;

use base qw(Metabrik::Shell::Command Metabrik::System::Package);

# Default attribute values put here will BE inherited by subclasses
sub brik_properties {
   return {
      revision => '$Revision: f6ad8c136b19 $',
      tags => [ qw(unstable carving carve file filecarve filecarving) ],
      author => 'GomoR <GomoR[at]metabrik.org>',
      license => 'http://opensource.org/licenses/BSD-3-Clause',
      attributes => {
         datadir => [ qw(datadir) ],
         extensions => [ qw($extensions_list) ],
         conf => [ qw(file) ],
      },
      attributes_default => {
         extensions => [ qw(doc pdf jpg png zip odt) ],
         conf => 'scalpel.conf',
      },
      commands => {
         install => [ ], # Inherited
         generate_conf => [ qw($extensions_list|OPTIONAL file|OPTIONAL) ],
         scan => [ qw(file output|OPTIONAL conf|OPTIONAL) ],
      },
      require_modules => {
         'Metabrik::File::Find' => [ ],
         'Metabrik::File::Text' => [ ],
         'Metabrik::File::Type' => [ ],
         'Metabrik::System::File' => [ ],
      },
      require_binaries => {
         'scalpel' => [ ],
      },
      need_packages => {
         ubuntu => [ qw(scalpel) ],
         debian => [ qw(scalpel) ],
      },
   };
}

sub generate_conf {
   my $self = shift;
   my ($extensions, $file) = @_;

   my $datadir = $self->datadir;
   $extensions ||= $self->extensions;
   $file ||= $datadir.'/'.$self->conf;
   $self->brik_help_run_undef_arg('generate_conf', $extensions) or return;
   $self->brik_help_run_invalid_arg('generate_conf', $extensions, 'ARRAY') or return;
   $self->brik_help_run_undef_arg('generate_conf', $file) or return;

   my $sf = Metabrik::System::File->new_from_brik_init($self) or return;
   $sf->remove($file) or return;

   my $ext = [
      { case => "y", ext => "art", footer => "\\xcf\\xc7\\xcb", header => "\\x4a\\x47\\x04\\x0e", size => 150000, },
      { case => "y", ext => "art", footer => "\\xd0\\xcb\\x00\\x00", header => "\\x4a\\x47\\x03\\x0e", size => 150000, },
      { case => "y", ext => "gif", footer => "\\x00\\x3b", header => "\\x47\\x49\\x46\\x38\\x37\\x61", size => 5000000, },
      { case => "y", ext => "gif", footer => "\\x00\\x3b", header => "\\x47\\x49\\x46\\x38\\x39\\x61", size => 5000000, },
      { case => "y", ext => "jpg", footer => "\\xff\\xd9", header => "\\xff\\xd8\\xff\\xe0\\x00\\x10", size => 200000000, },
      { case => "y", ext => "png", footer => "\\xff\\xfc\\xfd\\xfe", header => "\\x50\\x4e\\x47?", size => 20000000, },
      { case => "y", ext => "bmp", footer => undef, header => "BM??\\x00\\x00\\x00", size => 100000, },
      { case => "y", ext => "tif", footer => undef, header => "\\x49\\x49\\x2a\\x00", size => 200000000, },
      { case => "y", ext => "tif", footer => undef, header => "\\x4D\\x4D\\x00\\x2A", size => 200000000, },
      { case => "y", ext => "avi", footer => undef, header => "RIFF????AVI", size => 50000000, },
      { case => "y", ext => "mov", footer => undef, header => "????moov", size => 10000000, },
      { case => "y", ext => "mov", footer => undef, header => "????mdat", size => 10000000, },
      { case => "y", ext => "mov", footer => undef, header => "????widev", size => 10000000, },
      { case => "y", ext => "mov", footer => undef, header => "????skip", size => 10000000, },
      { case => "y", ext => "mov", footer => undef, header => "????free", size => 10000000, },
      { case => "y", ext => "mov", footer => undef, header => "????idsc", size => 10000000, },
      { case => "y", ext => "mov", footer => undef, header => "????pckg", size => 10000000, },
      { case => "y", ext => "mpg", footer => "\\x00\\x00\\x01\\xb9", header => "\\x00\\x00\\x01\\xba", size => 50000000, },
      { case => "y", ext => "mpg", footer => "\\x00\\x00\\x01\\xb7", header => "\\x00\\x00\\x01\\xb3", size => 50000000, },
      { case => "y", ext => "fws", footer => undef, header => "FWS", size => 4000000 },
      { case => "y", ext => "doc", footer => "\\xd0\\xcf\\x11\\xe0\\xa1\\xb1\\x1a\\xe1\\x00\\x00", header => "\\xd0\\xcf\\x11\\xe0\\xa1\\xb1\\x1a\\xe1\\x00\\x00", size => 10000000, },
      { case => "y", ext => "doc", footer => undef, header => "\\xd0\\xcf\\x11\\xe0\\xa1\\xb1", size => 10000000, },
      { case => "y", ext => "pst", footer => undef, header => "\\x21\\x42\\x4e\\xa5\\x6f\\xb5\\xa6", size => 500000000, },
      { case => "y", ext => "ost", footer => undef, header => "\\x21\\x42\\x44\\x4e", size => 500000000, },
      { case => "y", ext => "dbx", footer => undef, header => "\\xcf\\xad\\x12\\xfe\\xc5\\xfd\\x74\\x6f", size => 10000000, },
      { case => "y", ext => "idx", footer => undef, header => "\\x4a\\x4d\\x46\\x39", size => 10000000, },
      { case => "y", ext => "mbx", footer => undef, header => "\\x4a\\x4d\\x46\\x36", size => 10000000, },
      { case => "y", ext => "wpc", footer => undef, header => "?WPC", size => 1000000 },
      { case => "n", ext => "htm", footer => "</html>", header => "<html", size => 50000, },
      { case => "y", ext => "pdf", footer => "%EOF\\x0d", header => "%PDF", size => 5000000, },
      { case => "y", ext => "pdf", footer => "%EOF\\x0a", header => "%PDF", size => 5000000, },
      { case => "y", ext => "mail", footer => undef, header => "\\x41\\x4f\\x4c\\x56\\x4d", size => 500000, },
      { case => "y", ext => "pgd", footer => undef, header => "\\x50\\x47\\x50\\x64\\x4d\\x41\\x49\\x4e\\x60\\x01", size => 500000, },
      { case => "y", ext => "pgp", footer => undef, header => "\\x99\\x00", size => 100000, },
      { case => "y", ext => "pgp", footer => undef, header => "\\x95\\x01", size => 100000, },
      { case => "y", ext => "pgp", footer => undef, header => "\\x95\\x00", size => 100000, },
      { case => "y", ext => "pgp", footer => undef, header => "\\xa6\\x00", size => 100000, },
      { case => "y", ext => "txt", footer => undef, header => "-----BEGIN\\040PGP", size => 100000, },
      { case => "y", ext => "rpm", footer => undef, header => "\\xed\\xab", size => 1000000, },
      { case => "y", ext => "wav", footer => undef, header => "RIFF????WAVE", size => 200000, },
      { case => "y", ext => "ra", footer => undef, header => "\\x2e\\x72\\x61\\xfd", size => 1000000, },
      { case => "y", ext => "ra", footer => undef, header => ".RMF", size => 1000000 },
      { case => "y", ext => "dat", footer => undef, header => "regf", size => 4000000 },
      { case => "y", ext => "dat", footer => undef, header => "CREG", size => 4000000 },
      { case   => "y", ext => "zip", footer => "\\x3c\\xac", header => "PK\\x03\\x04", size => 10000000, },
      { case => "y", ext => "java", footer => undef, header => "\\xca\\xfe\\xba\\xbe", size => 1000000, },
      { case => "y", ext => "max", footer => "\\x00\\x00\\x05\\x80\\x00\\x00", header => "\\x56\\x69\\x47\\x46\\x6b\\x1a\\x00\\x00\\x00\\x00", size => 1000000, },
      { case => "y", ext => "pins", footer => undef, header => "\\x50\\x49\\x4e\\x53\\x20\\x34\\x2e\\x32\\x30\\x0d", size => 8000, },
      { ext => "odt", case => "y", size => 20000000, header => "PK????????????????????????????mimetypeapplication/vnd.oasis.opendocument.textPK", footer => "META-INF/manifest.xmlPK????????????????????" },
      { ext => "ods", case => "y", size => 10000000, header => "PK????????????????????????????mimetypeapplication/vnd.oasis.opendocument.spreadsheetPK", footer => "META-INF/manifest.xmlPK????????????????????" },
      { ext => "odp", case => "y", size => 10000000, header => "PK????????????????????????????mimetypeapplication/vnd.oasis.opendocument.presentationPK", footer => "META-INF/manifest.xmlPK????????????????????" },
      { ext => "odg", case => "y", size => 10000000, header => "PK????????????????????????????mimetypeapplication/vnd.oasis.opendocument.graphicsPK", footer => "META-INF/manifest.xmlPK????????????????????" },
      { ext => "odc", case => "y", size => 10000000, header => "PK????????????????????????????mimetypeapplication/vnd.oasis.opendocument.chartPK", footer => "META-INF/manifest.xmlPK????????????????????" },
      { ext => "odf", case => "y", size => 10000000, header => "PK????????????????????????????mimetypeapplication/vnd.oasis.opendocument.formulaPK", footer => "META-INF/manifest.xmlPK????????????????????" },
      { ext => "odi", case => "y", size => 10000000, header => "PK????????????????????????????mimetypeapplication/vnd.oasis.opendocument.imagePK", footer => "META-INF/manifest.xmlPK????????????????????" },
      { ext => "odm", case => "y", size => 10000000, header => "PK????????????????????????????mimetypeapplication/vnd.oasis.opendocument.text-masterPK", footer => "META-INF/manifest.xmlPK????????????????????" },
      { ext => "sxw", case => "y", size => 10000000, header => "PK????????????????????????????mimetypeapplication/vnd.sun.xml.writerPK", footer => "META-INF/manifest.xmlPK????????????????????" },
   ];

   my @lines = ();
   push @lines, '# To redefine the wildcard character, change the setting below and all';
   push @lines, '# occurences in the formost.conf file.';
   push @lines, '#wildcard  ?';

   my $wanted = { map { $_ => 1 } @$extensions };
   for my $this (@$ext) {
      my $ext = $this->{ext};
      next unless exists($wanted->{$ext});
      my $case = $this->{case};
      my $size = $this->{size};
      my $header = $this->{header};
      my $footer = $this->{footer} || '';
      my $line = "   $ext $case $size $header $footer";
      push @lines, $line;
   }

   my $ft = Metabrik::File::Text->new_from_brik_init($self) or return;
   $ft->write(\@lines, $file) or return;
   $ft->close;

   return $file;
}

sub scan {
   my $self = shift;
   my ($file, $output, $conf) = @_;

   $self->brik_help_run_undef_arg("scan", $file) or return;

   my $datadir = $self->datadir;
   my ($base) = $file =~ m{^.*/(.*)$};
   $base ||= $file;
   $output ||= $datadir.'/'.$base.'.scalp';
   $conf ||= $datadir.'/'.$self->conf;
   $self->brik_help_run_file_not_found('scan', $file) or return;
   $self->brik_help_run_file_not_found('scan', $conf) or return;

   if (! -d $output) {
      $self->log->info("scan: never launched scalpel on this file, starting...");
      my $cmd = "scalpel -c $conf -o $output $file";
      $self->system($cmd) or return;
   }
   else {
      $self->log->info("scan: already launched scalpel, skipping new scan");
   }

   my $ff = Metabrik::File::Find->new_from_brik_init($self) or return;
   my $files = $ff->files($output) or return;

   my $ext = {
      'txt' => 'text/plain',
      'doc' => 'application/msword',
      'jpg' => 'image/jpeg',
      'pdf' => 'application/pdf',
      'png' => 'image/png',
      'zip' => 'application/zip',
      'odt' => 'application/vnd.oasis.opendocument.text',
   };

   my $ft = Metabrik::File::Type->new_from_brik_init($self) or return;

   # If we know the supposed MIME-type of a file, we correlate with it
   my @verified = ();
   my @unverified = ();
   for my $file (@$files) {
      my ($this) = $file =~ m{\.(\w+)$};
      if (exists($ext->{$this})) {
         my $check = $ft->get_mime_type($file) or next;
         if ($check eq $ext->{$this}) {
            push @verified, $file;
         }
         else {
            push @unverified, $file;
         }
      }
      else {
         push @unverified, $file;
      }
   }

   # We remove the audit.txt file which is generated by Scalpel itself
   @verified = grep {!/audit.txt$/} @verified;
   @unverified = grep {!/audit.txt$/} @unverified;

   return { verified => \@verified, unverified => \@unverified };
}

1;

__END__

=head1 NAME

Metabrik::Forensic::Scalpel - forensic::scalpel Brik

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2014-2017, Patrice E<lt>GomoRE<gt> Auffret

You may distribute this module under the terms of The BSD 3-Clause License.
See LICENSE file in the source distribution archive.

=head1 AUTHOR

Patrice E<lt>GomoRE<gt> Auffret

=cut
