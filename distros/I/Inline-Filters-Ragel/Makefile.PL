use strict;

use ExtUtils::MakeMaker;


my $ragel_version = `ragel -v`;
die "Unable to run 'ragel' -- This module requires the Ragel State Machine Compiler (http://www.colm.net/open-source/ragel/) to be installed and in your search path"
  if $?;


my %args = (
    NAME => 'Inline::Filters::Ragel',
    VERSION_FROM => 'lib/Inline/Filters/Ragel.pm',
    PREREQ_PM => {
      'File::Temp' => 0,
    },
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
            repository => 'git://github.com/hoytech/Inline-Filters-Ragel.git',
            bugtracker => 'https://github.com/hoytech/Inline-Filters-Ragel/issues',
        },
    };
}

WriteMakefile(%args);
