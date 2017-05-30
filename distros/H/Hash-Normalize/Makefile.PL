use 5.010;

use strict;
use warnings;
use ExtUtils::MakeMaker;

my $dist = 'Hash-Normalize';

(my $name = $dist) =~ s{-}{::}g;

(my $file = $dist) =~ s{-}{/}g;
$file = "lib/$file.pm";

my %PREREQ_PM = (
 'Carp'               => 0,
 'Exporter'           => 0,
 'Unicode::Normalize' => 0,
 'Variable::Magic'    => '0.51',
 'base'               => 0,
);

my %BUILD_REQUIRES = (
 'ExtUtils::MakeMaker' => 0,
 'Test::More'          => 0,
 'lib'                 => 0,
 %PREREQ_PM,
);

my %META = (
 configure_requires => {
  'ExtUtils::MakeMaker' => 0,
 },
 build_requires => {
  %BUILD_REQUIRES,
 },
 dynamic_config => 0,
 resources => {
  bugtracker => "http://rt.cpan.org/Dist/Display.html?Name=$dist",
  homepage   => "http://search.cpan.org/dist/$dist/",
  license    => 'http://dev.perl.org/licenses/',
  repository => "http://git.profvince.com/?p=perl%2Fmodules%2F$dist.git",
 },
);

WriteMakefile(
 NAME             => $name,
 AUTHOR           => 'Vincent Pit <perl@profvince.com>',
 LICENSE          => 'perl',
 VERSION_FROM     => $file,
 ABSTRACT_FROM    => $file,
 PL_FILES         => {},
 BUILD_REQUIRES   => \%BUILD_REQUIRES,
 PREREQ_PM        => \%PREREQ_PM,
 MIN_PERL_VERSION => '5.010',
 META_MERGE       => \%META,
 dist             => {
  PREOP    => "pod2text -u $file > \$(DISTVNAME)/README",
  COMPRESS => 'gzip -9f', SUFFIX => 'gz'
 },
 clean            => {
  FILES => "$dist-* *.gcov *.gcda *.gcno cover_db Debian_CPANTS.txt"
 },
);
