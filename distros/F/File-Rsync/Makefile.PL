# This -*- perl -*- script writes the Makefile for File-Rsync

use 5.004;
use ExtUtils::MakeMaker;
use Config;

$NAME         = 'File::Rsync';
$DISTNAME     = 'File-Rsync';
$VERSION_FROM = 'Rsync.pm';
$AUTHOR       = 'Lee Eakin <leakin@dfw.nostrum.com>';
$ABSTRACT     = 'Wrapper module for rsync(1) http://rsync.samba.org/';

WriteMakefile(
      VERSION_FROM   => $VERSION_FROM,
      NAME           => $NAME,
      DISTNAME       => $DISTNAME,
      AUTHOR         => $AUTHOR,
      ABSTRACT       => $ABSTRACT,
      PREREQ_PM      => {
                          'Scalar::Util' => 0,
                          'File::Path' => 0,
                          'Test::More' => 0,
                          'IPC::Run3'  => 0,
                        },
      PM             => { 'Rsync.pm'  => '$(INST_LIB)/File/Rsync.pm' },
      dist           => { COMPRESS => 'gzip', SUFFIX => 'gz' },
);

