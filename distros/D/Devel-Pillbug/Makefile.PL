use ExtUtils::MakeMaker;

my $prereqs = {
  HTTP::Server::Simple::Mason => 0.13,
  File::HomeDir  => 0.86,
  Media::Type::Simple => 0.02,
  Net::Server    => 0.97,
  Test::More     => 0.86,

};

WriteMakefile(
  VERSION_FROM  => 'lib/Devel/Pillbug.pm',
  NAME          => 'Devel::Pillbug',
  PREREQ_PM     => $prereqs,
  LICENSE       => 'perl',
  AUTHOR        => 'Alex Ayars <pause@nodekit.org>',
  EXE_FILES     => ['bin/pillbug' ],

);
