use lib 'lib';
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use File::Temp;
use Log::Mini;


subtest 'creates correct object Logger::FILE' => sub {
    my $file = File::Temp->new;
    isa_ok(Log::Mini->new(file => $file->filename),               'Log::Mini::Logger::FILE');
    isa_ok(Log::Mini::Logger::FILE->new(file => $file->filename), 'Log::Mini::Logger::FILE');
};

subtest 'creates correct object Logger::STDERR' => sub {
    isa_ok(Log::Mini->new('stderr', level => 'debug'),       'Log::Mini::Logger::STDERR');
    isa_ok(Log::Mini::Logger::STDERR->new(level => 'debug'), 'Log::Mini::Logger::STDERR');
};

subtest 'creates correct object Logger::NULL' => sub {
    isa_ok(Log::Mini->new('null', level => 'debug'),       'Log::Mini::Logger::NULL');
    isa_ok(Log::Mini::Logger::NULL->new(level => 'debug'), 'Log::Mini::Logger::NULL');
};

done_testing;
