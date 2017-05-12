#! /usr/bin/perl -w
require 5.008_005;
use strict;
use ExtUtils::MakeMaker;

WriteMakefile(
               AUTHOR    => 'Aukjan van Belkum <aukjan@cpan.org>',
               ABSTRACT  => 'Retrieves information about LSF hosts',
               NAME      => 'LSF-Hosts',
               VERSION   => '0.02',
               PREREQ_PM => { 'LSF' => '0.9', 'IPC::Run' => 0 },
               dist      => { COMPRESS => 'gzip -9', SUFFIX => '.gz', },
             );
__END__
