use ExtUtils::MakeMaker;



my $fxconnect_home = $ENV{FXCONNECT_HOME} || '.';

WriteMakefile(
    NAME                => 'Finance::FXCM::Simple',
    VERSION_FROM        => 'lib/Finance/FXCM/Simple.pm',
    LIBS                => ["-L$fxconnect_home/lib -lForexConnect -lfxmsg"],
    DEFINE              => '',
    INC                 => "-I. -I$fxconnect_home/include",
    OBJECT              => '$(O_FILES)', # link all the C files too
    'XSOPT'             => '-C++',
    'TYPEMAPS'          => ['perlobject.map'],
    'CC'                => 'g++',
    'LD'                => '$(CC)',
    'MYEXTLIB'          => 'ForexConnectWrapper/libForexConnectWrapper$(LIB_EXT)',
    'BUILD_REQUIRES'    => {
        'Test::More'    =>  0,
        'Scalar::Util'  =>  0,
    },
    'PREREQ_PM'         => {
        'YAML::XS'    => 0,
    },
    LICENSE             => 'mit',
    ( $] >= 5.005 ? 
        (   ABSTRACT_FROM       => 'lib/Finance/FXCM/Simple.pm',
            AUTHOR              => 'João Costa <joaocosta@zonalivre.org>',
        ) : ()
    ),
  'BUILD_REQUIRES' => {
    'Data::Dumper' => '0',
    'Scalar::Util' => '0',
    'Test::More' => '0'
  },
  'CONFIGURE_REQUIRES' => {
    'ExtUtils::MakeMaker' => '0.34'
  },
  'PREREQ_PM' => {
    'XSLoader' => '0',
    'YAML::XS' => '0',
    'strict' => '0',
    'warnings' => '0'
  },
);

sub MY::postamble {
    '
    $(MYEXTLIB): ForexConnectWrapper/Makefile
		cd ForexConnectWrapper && $(MAKE) $(PASSTHRU)
    ';
}


