use lib 'lib';
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use File::Temp;
use Log::Mini;

subtest 'creates stderr logger' => sub {
    my $logger = Log::Mini->new('stderr');

    isa_ok $logger, 'Log::Mini::LoggerSTDERR';
};

subtest 'creates file logger' => sub {
    my $file = File::Temp->new;
    my $logger = Log::Mini->new('file' => $file->filename);

    isa_ok $logger, 'Log::Mini::LoggerFILE';
};

subtest 'return STDERR on unknown logger' => sub {
    my $logger = Log::Mini->new('unknown');
    isa_ok $logger, 'Log::Mini::LoggerSTDERR';
};

done_testing;