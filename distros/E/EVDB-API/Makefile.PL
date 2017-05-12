use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'       => 'EVDB::API',
    'VERSION'    => '0.99',
    'PREREQ_PM'	 => 
    {
      'Carp'                      => 0,
      'Digest::MD5'               => 0.1,
      'XML::Simple'               => 0.1,
      'LWP::UserAgent'            => 0.1,
      'Module::Pluggable::Object' => 0,
      'Test::More'                => 0,
    },
);
