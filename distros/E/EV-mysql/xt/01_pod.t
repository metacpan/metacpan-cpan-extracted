use strict;
use warnings;
use Test::More;

eval "use Test::Pod 1.48; 1"
    or plan skip_all => 'Test::Pod 1.48 required for POD validation';
eval "use Test::Pod::Coverage 1.08; 1"
    or plan skip_all => 'Test::Pod::Coverage 1.08 required for POD coverage';

subtest 'POD syntax' => sub {
    all_pod_files_ok();
};

subtest 'POD coverage' => sub {
    # Short aliases & ithreads hook documented in EV::mysql ALIASES/CLONE_SKIP
    pod_coverage_ok(
        'EV::mysql',
        {
            trustme => [
                qr/^(?:CLONE_SKIP|q|prep|reconnect|disconnect|errstr|error|errno|socket_fd|client_version|client_info)$/,
            ],
        },
        'EV::mysql POD coverage',
    );
};

done_testing;
