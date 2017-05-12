use ExtUtils::MakeMaker;
use strict;

WriteMakefile (
    NAME            => 'File::Alter',
    VERSION_FROM    => 'lib/File/Alter.pm', # finds $VERSION
    dist            => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    PREREQ_PM       => { 
                        'Test::More'    => 0, 
                        'IO::String'    => 0,
                        'IO::File'      => 0,
                        'Params::Check' => '0.23',
                    },
    AUTHOR          => 'Jos Boumans <kane[at]cpan.org>',
    ABSTRACT        => 'In memory file manipulation'
);     
