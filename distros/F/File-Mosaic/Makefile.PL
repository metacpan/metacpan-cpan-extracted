require 5.005;
use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'              => 'File::Mosaic',
    'VERSION_FROM'      => 'lib/File/Mosaic.pm',
    'PREREQ_PM'         => { 'Digest::MD5'   => undef,
                             'Storable'      => undef,
                             'File::Spec'    => undef,
                             'File::Path'    => undef,
                             'IO::File'      => undef,
                             'Log::Log4perl' => undef,
                            },

    ($] >= 5.005 ? 
        ( 'ABSTRACT_FROM'   => 'lib/File/Mosaic.pm',
          'AUTHOR'          => 'Christopher Boumenot <boumenot@gmail.com>') : ()),
);
