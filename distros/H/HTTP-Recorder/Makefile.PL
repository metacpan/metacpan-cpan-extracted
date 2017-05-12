use ExtUtils::MakeMaker;

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
  NAME         => 'HTTP::Recorder',
  VERSION_FROM => 'lib/HTTP/Recorder.pm',
  AUTHOR       => 'Shmuel Fomberg (semuelf@cpan.org)',
  PREREQ_PM    => {
    LWP::UserAgent        => 0,
    HTML::TokeParser      => 0,
    URI::Escape           => 0,
    URI::QueryParam       => 0,
    HTTP::Request::Params => 0,
    HTTP::Proxy           => 0,
    Getopt::Long          => 0,
    Pod::Usage            => 0,
    HTML::Parser          => 0,
  },
  EXE_FILES => [ qw(
      bin/httprecorder
      ) ],
  META_MERGE => {
    resources =>
      {repository => 'https://github.com/semuel/perl-cpan-http-recorder.git',},
  },
);
