use lib 'lib';
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use File::Temp;
use Log::Mini;


subtest 'creates stderr logger' => sub {
    my $logger = Log::Mini->new('stderr');

    isa_ok $logger, 'Log::Mini::Logger::STDERR';
};

subtest 'creates null logger' => sub {
    my $logger = Log::Mini->new('null');

    isa_ok $logger, 'Log::Mini::Logger::NULL';
};

subtest 'creates file logger' => sub {
    my $file   = File::Temp->new;
    my $logger = Log::Mini->new('file' => $file->filename);

    isa_ok $logger, 'Log::Mini::Logger::FILE';
};

subtest 'return STDERR on no logger name given' => sub {
    my $logger = Log::Mini->new();
    isa_ok $logger, 'Log::Mini::Logger::STDERR';
};

subtest 'throw on unknown logger adapter' => sub {
    like(
        exception { Log::Mini->new('unknown'); },
        qr/^Failed to load adapter: unknown, .*/,
        "the code died on unknown adapter",
    );
};

done_testing;
