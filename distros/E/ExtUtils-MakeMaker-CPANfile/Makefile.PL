use strict;
use warnings;
use ExtUtils::MakeMaker;

my %params = (
  NAME => 'ExtUtils::MakeMaker::CPANfile',
  AUTHOR => 'Kenichi Ishigaki <ishigaki@cpan.org>',
  ABSTRACT_FROM => 'lib/ExtUtils/MakeMaker/CPANfile.pm',
  VERSION_FROM => 'lib/ExtUtils/MakeMaker/CPANfile.pm',
  LICENSE => 'perl',
  PREREQ_PM => {
    'ExtUtils::MakeMaker' => '6.17', # Lancaster Consensus
    'Cwd' => '0',
    'File::Path' => '0',
    'Module::CPANfile' => '0',
    'CPAN::Meta::Converter' => '2.141170',
    'Test::More' => '0.88',
    'version' => '0.76',
  },
  META_MERGE => {
    resources => {
      repository => 'https://github.com/charsbar/ExtUtils-MakeMaker-CPANfile',
    },
  },
);

my $eumm = eval $ExtUtils::MakeMaker::VERSION;
delete $params{LICENSE}    if $eumm < 6.31;
delete $params{META_MERGE} if $eumm < 6.46;

WriteMakefile(%params);
