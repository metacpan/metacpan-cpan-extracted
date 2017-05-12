use ExtUtils::MakeMaker;

my %options =
  (
  NAME     => 'InlineX::C2XS::Context',
  VERSION_FROM => 'Context.pm',
  LICENSE  => 'perl',
  );

WriteMakefile(%options);

