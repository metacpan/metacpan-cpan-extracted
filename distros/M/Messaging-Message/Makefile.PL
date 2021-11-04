use strict;
use warnings;
use ExtUtils::MakeMaker;

my(%param, $emv, $name);

%param = (
    NAME                   => 'Messaging::Message',
    AUTHOR                 => 'Lionel Cons <lionel.cons@cern.ch>',
    VERSION                => '1.7',
    ABSTRACT               => 'message related modules',
    LICENSE                => 'perl',
    PL_FILES               => {},
    BUILD_REQUIRES => {
        'File::Temp'       => 0,
        # optional: Pod::Coverage
        'POSIX'            => 0,
        'Test::More'       => 0,
        # optional: Test::Pod
        # optional: Test::Pod::Coverage
    },
    PREREQ_PM => {
        # optional: Compress::LZ4
        # optional: Compress::Snappy
        # optional: Compress::Zlib
        'Digest::MD5'      => 0,
        # optional: Directory::Queue
        'Encode'           => 0,
        'JSON'             => 0,
        'MIME::Base64'     => 0,
        'No::Worries'      => '1.1',
        'Params::Validate' => 0,
    },
    dist                   => { COMPRESS => 'gzip -9f', SUFFIX => 'gz' },
    clean                  => { FILES => 'Messaging-Message-*' },
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
