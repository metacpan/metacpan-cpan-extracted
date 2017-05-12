use strict;

use ExtUtils::MakeMaker;


my %args = (
    NAME => 'IO::Vectored',
    VERSION_FROM => 'lib/IO/Vectored.pm',
    PREREQ_PM => {
      'XSLoader' => 0,
      'Carp' => 0,
      'Exporter' => 0,
    },
    CCFLAGS => '-Wall',
    LIBS => [],
    DEFINE => '',
    LICENSE => 'perl',
    dist => {
      PREOP => 'pod2text $(VERSION_FROM) > $(DISTVNAME)/README',
    },
);


my $eummv = eval ($ExtUtils::MakeMaker::VERSION);
if ($eummv >= 6.45) {
    $args{META_MERGE} = {
        resources => {
            repository => 'git://github.com/hoytech/IO-Vectored.git',
            bugtracker => 'https://github.com/hoytech/IO-Vectored/issues',
        },
    };
}

WriteMakefile(%args);
