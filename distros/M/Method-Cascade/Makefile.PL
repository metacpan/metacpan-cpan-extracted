use strict;

use ExtUtils::MakeMaker;


my %args = (
    NAME => 'Method::Cascade',
    VERSION_FROM => 'lib/Method/Cascade.pm',
    PREREQ_PM => {
    },
    LIBS => [],
    DEFINE => '',
    LICENSE => 'perl',
    dist => {
      PREOP => 'perldoc -uT lib/Method/Cascade.pm > README.pod; pod2text README.pod > $(DISTVNAME)/README',
    },
);


my $eummv = eval ($ExtUtils::MakeMaker::VERSION);
if ($eummv >= 6.45) {
    $args{META_MERGE} = {
        resources => {
            repository => 'git://github.com/hoytech/Method-Cascade.git',
            bugtracker => 'https://github.com/hoytech/Method-Cascade/issues',
        },
    };
}

WriteMakefile(%args);
