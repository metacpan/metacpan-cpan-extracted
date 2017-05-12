use strict;

use ExtUtils::MakeMaker;


my %args = (
    NAME => 'Log::Defer::Viz',
    VERSION_FROM => 'lib/Log/Defer/Viz.pm',
    EXE_FILES => [ 'bin/log-defer-viz', ],
    PREREQ_PM => {
      'JSON::XS' => 0,
      'Date::Format' => 0,
      'Date::Calc' => 0,
      'Getopt::Long' => 0,
      'common::sense' => 0,
      'Term::Size' => 0,
      'Term::ANSIColor' => 0,
      'Pod::Perldoc' => 0,
      'Try::Tiny' => 0,
    },
    LIBS              => [],
    DEFINE            => '',
    LICENSE => 'perl',
    dist => {
      PREOP => 'pod2text bin/log-defer-viz > $(DISTVNAME)/README',
    },
);


my $eummv = eval ($ExtUtils::MakeMaker::VERSION);
if ($eummv >= 6.45) {
    $args{META_MERGE} = {
        resources => {
            repository => 'git://github.com/hoytech/Log-Defer-Viz.git',
            bugtracker => 'https://github.com/hoytech/Log-Defer-Viz/issues',
        },
    };
}

WriteMakefile(%args);
