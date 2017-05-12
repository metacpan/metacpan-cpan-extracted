if( $^O=~/mswin32/i ){ print "Operating System Unsupported." and exit; }
use ExtUtils::MakeMaker;

WriteMakefile(
	NAME => 'File::PathInfo::Ext',
	VERSION_FROM => 'lib/File/PathInfo/Ext.pm',
   ABSTRACT_FROM => 'lib/File/PathInfo/Ext.pod',
   AUTHOR => 'Leo Charre leocharre at cpan dot org',
   LICENSE => 'perl',


   # gen /usr/bin/pmused by Tue Jun 10 11:52:12 EDT 2008 
   PREREQ_PM => {
      'Carp'                              => '1',
      'Cwd'                               => '3',
      'Digest::MD5'                       => '2',
      'File::Copy'                        => '2',
      'File::Path'                        => '1',
      'File::PathInfo'                    => '1.27',
      'File::Type'                        => '0',
      'Test::Simple'                      => '0',
      'YAML'                              => '0',
   },

); 
