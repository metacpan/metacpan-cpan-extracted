use ExtUtils::MakeMaker;
require 5.6.0;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile
   (
   'ABSTRACT'     => 'Report exceptions with formatted call-stack',
   'AUTHOR'       => 'Tommy Butler <cpan@atrixnet.com>',
   'INSTALLDIRS'  => 'site',
   'NAME'         => 'Exception::Handler',
   'VERSION_FROM' => 'Handler.pm',
   'linkext'      => { LINKTYPE => '' }, # no link needed
   'dist'         =>
      {
         'COMPRESS'  => 'gzip -9f',
         'SUFFIX'    => 'gz',
         'ZIP'       => '/usr/bin/zip',
         'ZIPFLAGS'  => '-rl',
      }
   );
