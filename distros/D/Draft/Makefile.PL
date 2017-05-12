use ExtUtils::MakeMaker;
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'              => 'Draft',
    'VERSION_FROM'      => 'lib/Draft.pm', # finds $VERSION
    'EXE_FILES'         => [ 'bin/tkdraft.pl' ],
    'PREREQ_PM'         => { 'Tk' => '',
                'Tk::WorldCanvas' => '',
                   'Test::Helper' => '',
                           'YAML' => '', 
              'File::PathConvert' => '',
                       'SGI::FAM' => '' },
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'lib/Draft.pm', # retrieve abstract from module
       AUTHOR     => 'Bruno Postle <bruno@postle.net>') : ()),
);

