use strict;
use warnings;
use ExtUtils::MakeMaker;

my %params = (
  NAME          => 'DateTimeX::Web',
  AUTHOR        => 'Kenichi Ishigaki <ishigaki@cpan.org>',
  VERSION_FROM  => 'lib/DateTimeX/Web.pm',
  ABSTRACT_FROM => 'lib/DateTimeX/Web.pm',
  PREREQ_PM => {
    'DateTime'                   => 0,
    'DateTime::Format::HTTP'     => 0,
    'DateTime::Format::Mail'     => 0,
    'DateTime::Format::MySQL'    => 0,
    'DateTime::Format::W3CDTF'   => 0,
    'DateTime::Format::Strptime' => 0,
    'DateTime::Locale'           => 0,
    'DateTime::TimeZone'         => 0,
    'Scalar::Util'               => 0,
    'Test::More'                 => '0.47',
    'Test::UseAllModules'        => '0.09',
  },
  LICENSE => 'perl',
  META_MERGE => {
    resources => {
      repository => 'https://github.com/charsbar/DateTimeX-Web',
    },
  },
);

my $eumm = eval $ExtUtils::MakeMaker::VERSION;
delete $params{LICENSE}    if $eumm < 6.31;
delete $params{META_MERGE} if $eumm < 6.46;

WriteMakefile(%params);
