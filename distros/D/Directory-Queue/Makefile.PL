use strict;
use warnings;
use ExtUtils::MakeMaker;

my(%param, $emv, $name);

%param = (
    NAME                => 'Directory::Queue',
    AUTHOR              => 'Lionel Cons <lionel.cons@cern.ch>',
    VERSION             => '2.2',
    ABSTRACT_FROM       => 'lib/Directory/Queue.pm',
    LICENSE             => 'perl',
    PL_FILES            => {},
    BUILD_REQUIRES => {
        'File::Temp'    => 0,
        # optional: Pod::Coverage
        'Test::More'    => 0,
        # optional: Test::Pod
        # optional: Test::Pod::Coverage
    },
    PREREQ_PM => {
        'Encode'        => 0,
        'No::Worries'   => '1.4',
        'POSIX'         => 0,
        'Time::HiRes'   => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean               => { FILES => 'Directory-Queue-*' },
);

($emv = $ExtUtils::MakeMaker::VERSION) =~ s/_//;
if ($emv < 6.5503) {
    # missing BUILD_REQUIRES
    foreach $name (keys(%{ $param{BUILD_REQUIRES} })) {
	$param{PREREQ_PM}{$name} = $param{BUILD_REQUIRES}{$name};
    }
    delete($param{BUILD_REQUIRES});
}
if ($emv < 6.31) {
    # missing LICENSE
    delete($param{LICENSE});
}

WriteMakefile(%param);
