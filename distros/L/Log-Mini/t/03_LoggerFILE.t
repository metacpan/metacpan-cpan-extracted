use lib 'lib';
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use File::Temp;
use Log::Mini::Logger::FILE;


subtest 'creates correct object' => sub {
    my $file = _build_temp_file();
    isa_ok(Log::Mini::Logger::FILE->new(file => $file->filename), 'Log::Mini::Logger::FILE');
};

subtest 'prints to file' => sub {
    
    for my $level (qw/error warn info debug trace/) {
        my $file = _build_temp_file();
        my $log = _build_logger(file => $file->filename, level => $level);

        $log->$level('message');
        undef $log;

        my $content = _slurp($file);

        ok $content;
    }
};

subtest 'prints to file synced' => sub {
    my $file = _build_temp_file();
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
        my $file = _build_temp_file();
        my $log = _build_logger(file => $file->filename, level => $level);

        $log->$level('message');

        undef $log;

        my $content = _slurp($file);

        like $content, qr/\n$/;
    }
};

subtest 'prints sprintf formatted line' => sub {
    for my $level (qw/error warn info debug trace/) {
        my $file = _build_temp_file();
        my $log = _build_logger(file => $file->filename, level => $level);

        $log->$level('message %s', 'formatted');

        undef $log;

        my $content = _slurp($file);

        like $content,
            qr/^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d.\d{3} \[$level\] message formatted$/;
    }
};

subtest 'recreate file if its gone' => sub {
    
    my $file = _build_temp_file();
    my $log = _build_logger(file => $file->filename);

    $log->error('message before gone');
    unlink $file->filename;
    sleep 1;

    $log->error('message after gone');
    undef $log;

    my $content = _slurp($file);

    like $content,
            qr/^\d\d\d\d-\d\d-\d\d \d\d:\d\d:\d\d.\d{3} \[error\] message after gone$/;
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

sub _build_temp_file {
    return File::Temp->new();   
}

done_testing;