package Mail::Exim::ACL::Attachments;

# SPDX-License-Identifier: Artistic-1.0-Perl OR GPL-1.0-or-later

use 5.016;
use warnings;
use utf8;

our $VERSION = 1.001;

use Exporter qw(import);
use IO::Uncompress::Unzip;

our @EXPORT_OK = qw(check_filename check_zip);

# https://docs.microsoft.com/en-us/deployoffice/compat/office-file-format-reference
# https://en.wikipedia.org/wiki/List_of_Microsoft_Office_filename_extensions
our %MACRO_ENABLED = (
  doc  => 'Word Document',
  docb => 'Word Document',
  docm => 'Word Document',
  dot  => 'Word Template',
  dotm => 'Word Template',
  pot  => 'PowerPoint Template',
  potm => 'PowerPoint Template',
  ppa  => 'PowerPoint Add-in',
  ppam => 'PowerPoint Add-in',
  pps  => 'PowerPoint Slide Show',
  ppsm => 'PowerPoint Slide Show',
  ppt  => 'PowerPoint Presentation',
  pptm => 'PowerPoint Presentation',
  sldm => 'PowerPoint Slide',
  vsd  => 'Visio Drawing File',
  vsdm => 'Visio Drawing File',
  vss  => 'Visio Stencil File',
  vssm => 'Visio Stencil File',
  vst  => 'Visio Drawing Template',
  vstm => 'Visio Drawing Template',
  xla  => 'Excel Add-in',
  xlam => 'Excel Add-in',
  xlm  => 'Excel Macro',
  xls  => 'Excel Spreadsheet',
  xlsb => 'Excel Spreadsheet',
  xlsm => 'Excel Spreadsheet',
  xlt  => 'Excel Spreadsheet Template',
  xltm => 'Excel Spreadsheet Template',
  xlw  => 'Excel Workspace',
);

# https://support.office.com/en-us/article/blocked-attachments-in-outlook-434752e1-02d3-4e90-9124-8b81e49a8519
our %BLOCKED_BY_OUTLOOK = (
  ade           => 'Access Project Extension',
  adp           => 'Access Project',
  app           => 'Executable Application',
  asp           => 'Active Server Page',
  aspx          => 'Active Server Page Extended',
  asx           => 'ASF Redirector file',
  bas           => 'BASIC Source Code',
  bat           => 'Batch Processing',
  cer           => 'Internet Security Certificate File',
  chm           => 'Compiled HTML Help',
  cmd           => 'Command File',
  cnt           => 'Microsoft Help Workshop Application',
  com           => 'Command',
  cpl           => 'Windows Control Panel Extension',
  crt           => 'Certificate File',
  csh           => 'csh Script',
  der           => 'DER Encoded X509 Certificate File',
  diagcab       => 'Microsoft Support diagnostic tools',
  exe           => 'Executable File',
  fxp           => 'FoxPro Compiled Source',
  gadget        => 'Windows Vista gadget',
  grp           => 'Microsoft program group',
  hlp           => 'Windows Help File',
  hpj           => 'AppWizard Help project',
  hta           => 'Hypertext Application',
  htc           => 'HTML component file',
  inf           => 'Information or Setup File',
  ins           => 'IIS Internet Communications Settings',
  isp           => 'IIS Internet Service Provider Settings',
  its           => 'Internet Document Set',
  jar           => 'Java Archive',
  jnlp          => 'Java Network Launch Protocol',
  js            => 'JavaScript Source Code',
  jse           => 'JScript Encoded Script File',
  ksh           => 'UNIX Shell Script',
  lnk           => 'Windows Shortcut File',
  mad           => 'Access Module Shortcut',
  maf           => 'Access',
  mag           => 'Access Diagram Shortcut',
  mam           => 'Access Macro Shortcut',
  maq           => 'Access Query Shortcut',
  mar           => 'Access Report Shortcut',
  mas           => 'Access Stored Procedures',
  mat           => 'Access Table Shortcut',
  mau           => 'Media Attachment Unit',
  mav           => 'Access View Shortcut',
  maw           => 'Access Data Access Page',
  mcf           => 'Media Container Format',
  mda           => 'Access Add-in',
  mdb           => 'Access Application',
  mde           => 'Access MDE Database File',
  mdt           => 'Access Add-in Data',
  mdw           => 'Access Workgroup Information',
  mdz           => 'Access Wizard Template',
  msc           => 'Microsoft Management Console Snap-in Control File',
  msh           => 'Microsoft Shell',
  msh1          => 'Microsoft Shell',
  msh2          => 'Microsoft Shell',
  mshxml        => 'Microsoft Shell',
  msh1xml       => 'Microsoft Shell',
  msh2xml       => 'Microsoft Shell',
  msi           => 'Windows Installer File',
  msp           => 'Windows Installer Update',
  mst           => 'Windows SDK Setup Transform Script',
  msu           => 'Windows Update file',
  ops           => 'Office Profile Settings File',
  osd           => 'Open Software Description ',
  pcd           => 'Visual Test',
  pif           => 'Windows Program Information File',
  pl            => 'Perl script',
  plg           => 'Developer Studio Build Log',
  prf           => 'Windows System File',
  prg           => 'Program File',
  printerexport => 'Printer backup file',
  ps1           => 'Windows PowerShell',
  ps1xml        => 'Windows PowerShell',
  ps2           => 'Windows PowerShell',
  ps2xml        => 'Windows PowerShell',
  psc1          => 'Windows PowerShell',
  psc2          => 'Windows PowerShell',
  psd1          => 'Windows PowerShell',
  psdm1         => 'Windows PowerShell',
  pst           => 'Outlook Personal Folder File',
  py            => 'Python script',
  pyc           => 'Python script',
  pyo           => 'Python script',
  pyw           => 'Python script',
  pyz           => 'Python script',
  pyzw          => 'Python script',
  reg           => 'Registry Data File',
  scf           => 'Windows Explorer Command',
  scr           => 'Windows Screen Saver',
  sct           => 'Windows Script Component',
  shb           => 'Windows Shortcut into a Document',
  shs           => 'Shell Scrap Object File',
  theme         => 'Desktop theme file settings',
  tmp           => 'Temporary File/Folder',
  url           => 'Internet Location',
  vb            => 'VBScript File or Any Visual Basic Source',
  vbe           => 'VBScript Encoded Script File',
  vbp           => 'Visual Basic project file',
  vbs           => 'VBScript File',
  vhd           => 'Virtual Hard Disk',
  vhdx          => 'Virtual Hard Disk Extended',
  vsmacros      => 'Visual Studio .NET Binary-based Macro Project',
  vsw           => 'Visio Workspace File',
  webpnp        => 'Internet printing file',
  website       => 'Pinned site shortcut from Internet Explorer',
  ws            => 'Windows Script File',
  wsc           => 'Windows Script Component',
  wsf           => 'Windows Script File',
  wsh           => 'Windows Script Host Settings File',
  xbap          => 'Browser applications',
  xll           => 'Excel Add-in',
  xnk           => 'Exchange Public Folder Shortcut',
);

# File associations from 7-Zip and others
our %ARCHIVES = (
  '7z'     => '7-Zip Archive',
  ace      => 'ACE File',
  arj      => 'ARJ File',
  bz2      => 'bzip2 File',
  bzip2    => 'bzip2 File',
  cab      => 'Windows Cabinet File',
  cpio     => 'CPIO Archive',
  deb      => 'Debian Package',
  dmg      => 'Disk Image',
  esd      => 'Disk Image',
  fat      => 'Zip Archive',
  gz       => 'gzip File',
  gzip     => 'gzip File',
  hfs      => 'Disk Image',
  iso      => 'Disk Image',
  lha      => 'LHA File',
  lzh      => 'LZH File',
  lzma     => 'LZMA File',
  ntfs     => 'Disk Image',
  rar      => 'RAR Archive',
  rpm      => 'RPM File',
  sfx      => 'Self-extracting Archive',
  squashfs => 'Disk Image',
  swm      => 'Disk Image',
  tar      => 'tar Archive',
  taz      => 'tar Archive',
  tbz      => 'tar Archive',
  tbz2     => 'tar Archive',
  tgz      => 'tar Archive',
  tpz      => 'tar Archive',
  txz      => 'tar Archive',
  uue      => 'uuencoded File',
  wim      => 'Disk Image',
  xar      => 'XAR File',
  xz       => 'XZ File',
  z        => 'gzip File',
  zip      => 'Zip Archive',
);

our %BLOCKLIST = (%MACRO_ENABLED, %BLOCKED_BY_OUTLOOK, %ARCHIVES);

sub check_filename {
  my $filename = shift;

  my $extension = q{};
  if ($filename =~ m{[.]\h*([^.]+)\z}) {
    $extension = lc $1;
  }

  if (exists $BLOCKLIST{$extension}) {
    return 'blocked';
  }

  # Reject split archives like "001" and "r01".
  if ($extension =~ m{\A[r\d]\d{2,}\z}) {
    return 'blocked';
  }

  return 'ok';
}

sub _get_filename {
  my $zip = shift;

  my $filename;

  my $header = eval { $zip->getHeaderInfo };
  if (defined $header) {
    $filename = $header->{Name};
  }

  return $filename;
}

sub check_zip {
  my $input = shift;

  my $result = 'blocked';

  my $zip = eval { IO::Uncompress::Unzip->new($input) };
  if (defined $zip) {
    my $status = 1;
    STREAM:
    while ($status > 0) {
      my $filename = _get_filename($zip);
      if (defined $filename) {
        $result = check_filename($filename);
      }
      else {
        $result = 'blocked';
      }
      if ($result ne 'ok') {
        last STREAM;
      }
      $status = eval { $zip->nextStream } // -1;
    }
    $zip->close;
  }

  return $result;
}

1;
__END__

=encoding UTF-8

=head1 NAME

Mail::Exim::ACL::Attachments - Reject email attachments

=head1 VERSION

version 1.001

=head1 SYNOPSIS

  acl_check_mime:

    warn
      condition = ${if and{{def:mime_filename} \
        {!match{${lc:$mime_filename}}{\N\.((json|xml)\.gz|zip)$\N}} \
        {eq{${perl{check_filename}{$mime_filename}}}{blocked}}}}
      set acl_m_blocked = yes

    warn
      condition = ${if match{${lc:$mime_filename}}{\N\. *(jar|zip)$\N}}
      decode = default
      condition = ${if eq{${perl{check_zip}{$mime_decoded_filename}}} \
                         {blocked}}
      set acl_m_blocked = yes

    accept

=head1 DESCRIPTION

A Perl module for the L<Exim|https://www.exim.org/> mailer that checks email
attachments for blocked filenames.  Common executable, macro-enabled and
archive file formats are identified.

The list of blocked filename extensions is built from information published by
Microsoft and Wikipedia.

=head1 SUBROUTINES/METHODS

=head2 check_filename

  my $result = check_filename($filename);

Checks if a filename has got a blocked extension.  Returns "ok" or "blocked".

=head2 check_zip

  my $result = check_zip($input);

Checks a Zip archive for files with blocked filename extensions.  Returns "ok"
or "blocked".

=head1 DIAGNOSTICS

None.

=head1 CONFIGURATION AND ENVIRONMENT

=head2 Exim

Create a file such as F</etc/exim/exim.pl>.  Add the following Perl code.

  use Mail::Exim::ACL::Attachments qw(check_filename check_zip);

Edit Exim's configuration file.  Enable Perl and MIME part scanning in the main
section.

  perl_startup = do '/etc/exim/exim.pl'
  perl_taintmode = yes

  acl_smtp_mime     = acl_check_mime
  acl_not_smtp_mime = acl_check_mime

Check for blocked filename extensions in the configuration file's ACL section,
headed by C<begin acl>.

  acl_check_mime:

    accept authenticated = *

    warn
      condition = ${if and{{def:mime_filename} \
        {!match{${lc:$mime_filename}}{\N\.((json|xml)\.gz|zip)$\N}} \
        {eq{${perl{check_filename}{$mime_filename}}}{blocked}}}}
      set acl_m_blocked = yes

    warn
      condition = ${if match{${lc:$mime_filename}}{\N\. *(jar|zip)$\N}}
      decode = default
      condition = ${if eq{${perl{check_zip}{$mime_decoded_filename}}} \
                         {blocked}}
      set acl_m_blocked = yes

    accept

Add statements that reject spam messages with blocked attachments to your DATA
ACL.

  acl_check_data:

    deny message = Message rejected as high-probability spam
      spam = nobody:true
      condition = ${if >={$spam_score_int}{50}}

    deny message = Blocked attachment detected
      spam = nobody:true
      condition = ${if and{{>{$spam_score_int}{0}} \
                           {bool{$acl_m_blocked}}}}

    warn spam = nobody
      add_header = X-Spam-Flag: YES

    warn condition = ${if bool{$acl_m_blocked}}
      add_header = X-Warning: Blocked attachment detected

=head1 DEPENDENCIES

Requires the Perl modules L<Exporter> and L<IO::Uncompress::Unzip>, which are
distributed with Perl.

=head1 INCOMPATIBILITIES

None.

=head1 AUTHOR

Andreas Vögele E<lt>voegelas@cpan.orgE<gt>

=head1 BUGS AND LIMITATIONS

Legacy Microsoft Office filename extensions like F<.doc>, F<.xls> and F<.ppt>
are always considered to be macro-enabled.  Scanning documents for macros is
expensive and not worth the effort.  Use F<.docx>, F<.xlsx> and F<.pptx>
instead.

The RAR decoder in popular file archivers and antivirus products has suffered
from security vulnerabilities.  I recommend to only accept Zip compressed
data.

DMARC and SMTP TLS reporting send attachments with the filename extensions
F<.json.gz> and F<.xml.gz>.  Make sure that such messages are not rejected.

Headers that are added in Exim's MIME and DATA ACLs are not available to
SpamAssassin.  But you can pass ACL variables from the MIME to the DATA ACL.

=head1 LICENSE AND COPYRIGHT

Copyright 2022 Andreas Vögele

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
