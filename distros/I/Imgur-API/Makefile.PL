use 5.008005;
use ExtUtils::MakeMaker 7.12; # for XSMULTI option


WriteMakefile(
  NAME           => 'Imgur::API',
  VERSION_FROM   => 'lib/Imgur/API.pm',
  PREREQ_PM      => {
	'ExtUtils::MakeMaker' => '7.12',
	'LWP::UserAgent'=>0,
    'Data::Dumper'=>0,
    'HTTP::Message'=>0,
	'FindBin'=>0,
	'Test::More'=>0,
	'JSON::XS'=>0,
	'Moo'=>0,
	'Mouse'=>0,
	'URI::Escape'=>0,
	'HTTP::Request'=>0,
	
  },
  ABSTRACT_FROM  => 'lib/Imgur/API.pm',
  ABSTRACT		 => 'Minimal client for Imgur API',
  AUTHOR         => 'Michael Hollenbeck',
  CCFLAGS        => '',
  LIBS			=> '',
  OPTIMIZE       => '-O3',
  LICENSE        => 'OtherLicense',
  XSMULTI        => 1,
  TYPEMAPS		=>["lib/typemap"],
  dist  => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
);
