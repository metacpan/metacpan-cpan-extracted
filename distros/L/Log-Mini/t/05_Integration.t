use lib 'lib';
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use File::Temp;
use Log::Mini;



subtest 'creates correct object LoggerFILE' => sub {
    my $file = File::Temp->new;
    isa_ok(Log::Mini->new( file => $file->filename), 'Log::Mini::LoggerFILE');
};

subtest 'creates correct object LoggerSTDERR' => sub {
    isa_ok(Log::Mini->new('stderr', level => 'debug'), 'Log::Mini::LoggerSTDERR');
    isa_ok(Log::Mini::LoggerSTDERR->new(level => 'debug'), 'Log::Mini::LoggerSTDERR');
};

done_testing;