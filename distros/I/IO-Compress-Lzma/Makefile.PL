#! perl -w

use strict ;
require 5.006 ;

$::VERSION = '2.101' ;

use lib '.';
use private::MakeUtil;
use ExtUtils::MakeMaker 5.16 ;

UpDowngrade(getPerlFiles('MANIFEST'))
    unless $ENV{PERL_CORE};

WriteMakefile(
    NAME         => 'IO::Compress::Lzma',
    VERSION_FROM => 'lib/IO/Compress/Lzma.pm',
    'dist'       => { COMPRESS     => 'gzip',
                      TARFLAGS     => '-chvf',
                      SUFFIX       => 'gz',
                      DIST_DEFAULT => 'MyTrebleCheck tardist',
                    },

    (
      $ENV{SKIP_FOR_CORE}
        ? (MAN3PODS    => {})
	    : (PREREQ_PM   => { 'Compress::Raw::Lzma' => $::VERSION,
		                    'IO::Compress::Base'   => $::VERSION,
		                    'IO::Uncompress::Base' => $::VERSION,
		                    $] >= 5.005 && $] < 5.006
                                ? ('File::BSDGlob' => 0)
                                : () }
	      )
    ),

    (
    $] >= 5.005
        ? (ABSTRACT_FROM => 'lib/IO/Compress/Lzma.pm',
            AUTHOR       => 'Paul Marquess <pmqs@cpan.org>')
        : ()
    ),

     ( eval { ExtUtils::MakeMaker->VERSION(6.46) }
        ? ( META_MERGE  => {

                "meta-spec" => { version => 2 },

                no_index => {
                    directory => [ 't', 'private' ],
                },

                resources   => {

                    bugtracker  => {
                        web     => 'https://github.com/pmqs/IO-Compress-Lzma/issues'
                    },

                    homepage    => 'https://github.com/pmqs/IO-Compress-Lzma',

                    repository  => {
                        type    => 'git',
                        url     => 'git://github.com/pmqs/IO-Compress-Lzma.git',
                        web     => 'https://github.com/pmqs/IO-Compress-Lzma',
                    },
                },
              }
            )
        : ()
    ),

    ((ExtUtils::MakeMaker->VERSION() gt '6.30') ?
        ('LICENSE'  => 'perl')         : ()),

) ;

# end of file Makefile.PL
