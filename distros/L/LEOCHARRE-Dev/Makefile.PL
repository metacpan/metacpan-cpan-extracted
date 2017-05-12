use ExtUtils::MakeMaker;

WriteMakefile(
   NAME => 'LEOCHARRE::Dev',
   VERSION_FROM => 'lib/LEOCHARRE/Dev.pm',
   ABSTRACT_FROM => 'lib/LEOCHARRE/Dev.pm',
   AUTHOR => 'Leo Charre leocharre at cpan dot org',

   # gen /usr/bin/pmused by Fri Aug 14 11:16:48 EDT 2009 
   PREREQ_PM => {
      'AppConfig::Std'                    => '1.07',
      'Carp'                              => '1',
      'Class::Inspector'                  => '1.23',
      'Cwd'                               => '3',
      'DMS'                               => '1.56',
      'Data::Dumper'                      => '2.121_02',
      'Devel::ModInfo'                    => '0',
      'Devel::Symdump'                    => '2.07',
      'Exporter'                          => '5',
      'ExtUtils::MakeMaker'               => '6',
      'File::Basename'                    => '2.73',
      'File::Find'                        => '1.07',
      'File::Find::Rule'                  => '0.30',
      'File::Path'                        => '2.07',
      'File::Trash'                       => '1.06',
      'Getopt::Std::Strict'               => '1.01',
      'HTTP::Request::Common'             => '1.28',
      'HTTP::Status'                      => '1.28',
      'LEOCHARRE::CLI'                    => '1.19',
      'LEOCHARRE::CLI2'                   => '1.07',
      'LEOCHARRE::Class2'                 => '1.19',
      'LEOCHARRE::DEBUG'                  => '1.12',
      'LEOCHARRE::Dir'                    => '1.07',
      'LEOCHARRE::Test'                   => '1.10',
      'LWP::UserAgent'                    => '2.036',
      'Module::Info'                      => '0.31',
      'Net::FTP'                          => '2.75',
      'Smart::Comments'                   => '1',
      'Term::ReadKey'                     => '2.30',
      'Test::Simple'                      => '0',
      'Time::Format'                      => '1.09',
      'WWW::CPAN'                         => '0',
   },

   
   LICENSE => 'perl',
   
   
   
   EXE_FILES => [qw(bin/cpanupload
		bin/cvs2cl
		bin/devdebug-httpd
		bin/dyercvsinstall
		bin/pinstall
		bin/pmassertexe
		bin/pmassertos
		bin/pmchanges
		bin/pmclassinspector
		bin/pmcommit
		bin/pmdbhmysql
		bin/pmdistest
		bin/pmdistupdate
		bin/pmfindcode
		bin/pmhelp
		bin/pminspect
		bin/pmlicense
		bin/pmmakefile
		bin/pmmanifest
		bin/pmmanifest.skip
		bin/pmname
		bin/pmonoff
		bin/pmpod
		bin/pmpodoutline
		bin/pmreadme
		bin/pmsub
		bin/pmsubs
		bin/pmtestcheck
		bin/pmtestmake
		bin/pmtodo
		bin/pmused
		bin/pmusing
		bin/pmver
		bin/pmvercpan
		bin/pmverstatus
		bin/unbleach)],
);


