use ExtUtils::MakeMaker;

my %args = (
  NAME => 'Log::Defer',
  VERSION_FROM => 'lib/Log/Defer.pm',
  LIBS => [''],
  LICENSE => 'perl',
  INC => '-I lib/',
  PREREQ_PM => {
    'Guard' => 0,
  },
  dist => {
    PREOP => 'pod2text $(VERSION_FROM) > $(DISTVNAME)/README',
  },
);


my $eummv = eval ($ExtUtils::MakeMaker::VERSION);
if ($eummv >= 6.45) {
    $args{META_MERGE} = {
        resources => {
            repository => 'git://github.com/hoytech/Log-Defer.git',
            bugtracker => 'https://github.com/hoytech/Log-Defer/issues',
        },
    };
}

WriteMakefile(%args);
