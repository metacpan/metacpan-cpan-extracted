use strict;
use warnings;
use ExtUtils::MakeMaker;

BEGIN {
 eval { require Config };
 die 'OS unsupported' if $@;
 Config->import(qw/%Config/);
}

my %sigs;
@sigs{split ' ', $Config{sig_name}} = ();

for (qw/USR1 USR2/) {
 print "Checking if you have SIG$_... ";
 unless (exists $sigs{$_}) {
  print "no\n";
  die 'OS unsupported';
 }
 print "yes\n";
}

my $dist = 'IPC-MorseSignals';

(my $name = $dist) =~ s{-}{::}g;

(my $file = $dist) =~ s{-}{/}g;
$file = "lib/$file.pm";

my %PREREQ_PM = (
 'Bit::MorseSignals' => 0.05,
 'Carp'              => 0,
 'POSIX'             => 0,
 'Time::HiRes'       => 0,
 'base'              => 0,
);

my %META = (
 configure_requires => {
  'Config'              => 0,
  'ExtUtils::MakeMaker' => 0,
 },
 build_requires => {
  'utf8'                => 0,
  'Config'              => 0,
  'Data::Dumper'        => 0,
  'Exporter'            => 0,
  'ExtUtils::MakeMaker' => 0,
  'POSIX'               => 0,
  'Test::More'          => 0,
  %PREREQ_PM,
 },
 dynamic_config => 1,
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
 PREREQ_PM        => \%PREREQ_PM,
 MIN_PERL_VERSION => 5.008,
 META_MERGE       => \%META,
 dist             => {
  PREOP    => "pod2text -u $file > \$(DISTVNAME)/README",
  COMPRESS => 'gzip -9f', SUFFIX => 'gz',
 },
 clean            => {
  FILES => "$dist-* *.gcov *.gcda *.gcno cover_db Debian_CPANTS.txt"
 },
);
