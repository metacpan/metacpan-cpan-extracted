#!/usr/bin/env perl
# FILENAME: update-dist-to-gentoo.pl
# CREATED: 10/11/14 03:21:18 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Update dist-to-gentoo file.

use strict;
use warnings;
use utf8;

my %premap = ();

my (@normal_virtuals) = qw(
  Archive-Tar
  Attribute-Handlers
  AutoLoader
  autodie
  B-Debug
  CPAN
  CPAN-Meta
  CPAN-Meta-Requirements
  CPAN-Meta-YAML
  Carp
  Compress-Raw-Bzip2
  Compress-Raw-Zlib
  DB_File
  Data-Dumper
  Devel-PPPort
  Digest
  Digest-MD5
  Digest-SHA
  Dumpvalue
  Encode
  Exporter
  ExtUtils-CBuilder
  ExtUtils-Command
  ExtUtils-Constant
  ExtUtils-Install
  ExtUtils-MakeMaker
  ExtUtils-Manifest
  ExtUtils-ParseXS
  File-Path
  File-Temp
  Filter-Simple
  Getopt-Long
  HTTP-Tiny
  I18N-LangTags
  IPC-Cmd
  IO
  IO-Compress
  IO-Zlib
  IO-Socket-IP
  JSON-PP
  Locale-Maketext
  Locale-Maketext-Simple
  MIME-Base64
  Math-BigInt
  Math-BigInt-FastCalc
  Math-BigRat
  Math-Complex
  Memoize
  Module-CoreList
  Module-Load
  Module-Load-Conditional
  Module-Loaded
  Module-Metadata
  Net-Ping
  Package-Constants
  Params-Check
  Parse-CPAN-Meta
  Perl-OSType
  Pod-Escapes
  Pod-Parser
  Pod-Perldoc
  Pod-Simple
  Safe
  Scalar-List-Utils
  Socket
  Storable
  Sys-Syslog
  Term-ANSIColor
  Term-ReadLine
  Test
  Test-Harness
  Test-Simple
  Text-Balanced
  Text-ParseWords
  Text-Tabs+Wrap
  Thread-Queue
  Thread-Semaphore
  Tie-RefHash
  Time-HiRes
  Time-Local
  Time-Piece
  XSLoader
  autodie
  bignum
  if
  libnet
  parent
  podlators
  threads
  threads-shared
  version
  Unicode-Collate
  Unicode-Normalize
);

for my $normal (@normal_virtuals) {
  $premap{$normal} = 'virtual/perl-' . $normal;
}
use Data::Handle;
my $handle = Data::Handle->new('main');

use FindBin;
use Path::Tiny qw(path);

while ( my $line = <$handle> ) {
  chomp $line;
  my ( $key, $value ) = split /,/, $line;
  if ( not $key ) {
    warn "> $line ";
    next;
  }
  $premap{$key} = $value;
}

my $target = path($FindBin::Bin)->sibling('share')->child('dist-to-gentoo.csv');
my $fh     = $target->openw_raw;
for my $key ( sort keys %premap ) {
  $fh->printf( "%s,%s\n", $key, $premap{$key} );
}

package main;

__DATA__
AcePerl,dev-perl/Ace
App-SVN-Bisect,dev-util/App-SVN-Bisect
Autodia,dev-util/autodia
BioPerl,sci-biology/bioperl
BioPerl-DB,sci-biology/bioperl-db
BioPerl-Network,sci-biology/bioperl-network
BioPerl-Run,sci-biology/bioperl-run
Frontier-RPC,dev-perl/frontier-rpc
GBrowse,sci-biology/GBrowse
Glib,dev-perl/glib-perl
Gnome2,dev-perl/gnome2-perl
Gnome2-Canvas,dev-perl/gnome2-canvas
Gnome2-VFS,dev-perl/gnome2-vfs-perl
Gnome2-Wnck,dev-perl/gnome2-wnck
Gtk2-Ex-FormFactory,dev-perl/gtk2-ex-formfactory
Gtk2-GladeXML,dev-perl/gtk2-gladexml
Gtk2-Spell,dev-perl/gtk2-spell
Gtk2-TrayIcon,dev-perl/gtk2-trayicon
Gtk2-TrayManager,dev-perl/gtk2-traymanager
Image-ExifTool,media-libs/exiftool
NTLM,dev-perl/Authen-NTLM
OLE-Storage_Lite,dev-perl/OLE-StorageLite
Padre,app-editors/padre
PathTools,virtual/perl-File-Spec
Snapback2,app-backup/snapback2
XML-XSH2,app-editors/XML-XSH2
ack,sys-apps/ack
gettext,dev-perl/Locale-gettext
