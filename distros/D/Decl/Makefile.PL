use strict;
use warnings;
use ExtUtils::MakeMaker;

WriteMakefile(
    NAME                => 'Decl',
    AUTHOR              => q{Michael Roberts <michael@vivtek.com>},
    VERSION_FROM        => 'lib/Decl.pm',
    ABSTRACT_FROM       => 'lib/Decl.pm',
    ($ExtUtils::MakeMaker::VERSION >= 6.3002
      ? ('LICENSE'=> 'perl')
      : ()),
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
        'DBI' => 0,
        'DBD::CSV' => 0,   # Really just for testing of the database functionality
        'FSA::Rules' => 0,
        'Getopt::Lucid' => 0,
        'Iterator::Simple' => 0,
        'Term::Shell' => 0,
        'Text::ParseWords' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => 'Decl-*' },
);
