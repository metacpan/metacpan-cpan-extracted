use strict;
use warnings;

use ExtUtils::MakeMaker;

my %eumm_args = (
  NAME             => 'List::Categorize',
  AUTHOR           => ['Bill Odom <wnodom@cpan.org>',
                       'Laurent Dami <dami@cpan.org>'],
  ABSTRACT         => 'Categorize list items into a tree of named sublists.',
  VERSION_FROM     => 'lib/List/Categorize.pm',
  LICENSE          => "artistic_2",
  MIN_PERL_VERSION => 5.006001,
  META_MERGE => {
    resources => {
      repository => 'git://github.com/damil/List-Categorize.git',
      bugtracker => 'http://rt.cpan.org/NoAuth/Bugs.html?Dist=List-Categorize',
      license    => 'http://www.perlfoundation.org/artistic_license_2_0',
    },
  },

  # no PREREQ_PM, only using core modules

  TEST_REQUIRES => {
    'Test::More'       => 0,
    'Test::Deep'       => 0,
    'Test::NoWarnings' => 0,
  },
);


my $eumm_ver  = eval $ExtUtils::MakeMaker::VERSION;
delete $eumm_args{MIN_PERL_VERSION}  if $eumm_ver < 6.48;
delete $eumm_args{META_MERGE}        if $eumm_ver < 6.46;
delete $eumm_args{LICENSE}           if $eumm_ver < 6.31;
$eumm_args{PREREQ_PM}
  = delete $eumm_args{TEST_REQUIRES} if $eumm_ver < 6.31;

WriteMakefile(%eumm_args);
