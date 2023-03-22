use lib 'lib';
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use File::Temp;
use Log::Mini::Logger::FILE;


subtest 'creates correct object' => sub {
    isa_ok(Log::Mini::Logger::FILE->new, 'Log::Mini::Logger::FILE');
};

subtest 'prints to file' => sub {
    
    for my $level (qw/error warn info debug trace/) {
        my $file = File::Temp->new;
        my $log = _build_logger(file => $file->filename, level => $level);

        $log->$level('message');
        undef $log;

        my $content = _slurp($file);

        ok $content;
    }
};

subtest 'prints to file synced' => sub {
    my $file = File::Temp->new;
    my $log = _build_logger(file => $file->filename, synced => 1);

    for my $level (qw/error warn info debug trace /) {
        $log->set_level($level);
        $log->$level('message');

        my $content = _slurp($file);

        ok $content;
    }
};

subtest 'prints to stderr with \n' => sub {
    for my $level (qw/error warn info debug trace/) {
        my $file = File::Temp->new;
        my $log = _build_logger(file => $file->filename, level => $level);

        $log->$level('message');

        undef $log;

        my $content = _slurp($file);

        like $content, qr/\n$/;
    }
};

subtest 'prints sprintf formatted line' => sub {
    for my $level (qw/error warn info debug trace/) {
        my $file = File::Temp->new;
        my $log = _build_logger(file => $file->filename, level => $level);

        $log->$level('message %s', 'formatted');

        undef $log;

        my $content = _slurp($file);

        like $content,
            qr/^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d.\d{3} \[$level\] message formatted$/;
    }
};

sub _slurp {
    my $file = shift;
    my $content = do { local $/; open my $fh, '<', $file->filename or die $!; <$fh> };
    return $content;
}

sub _build_logger {
    my $logger = Log::Mini::Logger::FILE->new(@_);

    return $logger;
}

done_testing;