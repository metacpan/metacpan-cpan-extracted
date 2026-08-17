use ExtUtils::MakeMaker;

WriteMakefile(
  NAME             => 'HTTP::API::Core',
  VERSION_FROM     => 'lib/HTTP/API/Core.pm',
  ABSTRACT_FROM    => 'lib/HTTP/API/Core.pm',
  LICENSE          => 'perl_5',
  MIN_PERL_VERSION => '5.020',
  PREREQ_PM => {
    'HTTP::Tiny'    => 0,
    'JSON::PP'      => 0,
    'MIME::Base64'  => 0,
    'Scalar::Util'  => 0,
    'Time::HiRes'   => 0,
  },
  META_MERGE => {
    'meta-spec' => { version => 2 },
    resources => {
      repository => {
        type => 'git',
        url  => 'https://github.com/kawamurashingo/HTTP-API-Core.git',
        web  => 'https://github.com/kawamurashingo/HTTP-API-Core',
      },
      bugtracker => {
        web => 'https://github.com/kawamurashingo/HTTP-API-Core/issues',
      },
      homepage => 'https://github.com/kawamurashingo/HTTP-API-Core',
    },
  },
);
