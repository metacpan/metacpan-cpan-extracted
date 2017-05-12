use 5.008001;
use strict;
use warnings;
use ExtUtils::MakeMaker;
my $name = 'Math::SimpleHisto::XS::CLI';
WriteMakefile(
    NAME              => $name,
    VERSION_FROM      => 'lib/Math/SimpleHisto/XS/CLI.pm', # finds $VERSION
    PREREQ_PM         => {
      'Math::SimpleHisto::XS' => '1.28',
      'Test::More' => '0.88',
      'Term::Size' => '0.200',
      'Pod::Usage' => '0',
    },
    EXE_FILES => [qw(bin/histify bin/drawasciihist bin/continuoushist)],
    ($] >= 5.005 ?
      (ABSTRACT_FROM  => 'lib/Math/SimpleHisto/XS/CLI.pm', # retrieve abstract from module
       AUTHOR         => 'Steffen Mueller <smueller@cpan.org>') : ()),
);

