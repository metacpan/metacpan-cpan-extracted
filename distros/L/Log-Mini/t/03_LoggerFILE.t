use lib 'lib';
use strict;
use warnings;

use Test::More;
use Test::Fatal;
use File::Temp;
use Log::Mini::LoggerFILE;


subtest 'creates correct object' => sub {
    isa_ok(Log::Mini::LoggerFILE->new, 'Log::Mini::LoggerFILE');
};

subtest 'prints to file' => sub {
    
    for my $level (qw/error warn debug/) {
        my $file = File::Temp->new;
        my $log = _build_logger(file => $file->filename);

        $log->$level('message');
        undef $log;

        my $content = _slurp($file);

        ok $content;
    }
};

subtest 'prints to file synced' => sub {
    my $file = File::Temp->new;
    my $log = _build_logger(file => $file->filename, synced => 1);

    for my $level (qw/error warn debug/) {
        $log->$level('message');

        my $content = _slurp($file);

        ok $content;
    }
};

subtest 'prints to stderr with \n' => sub {
    for my $level (qw/error warn debug/) {
    
        my $file = File::Temp->new;
        my $log = _build_logger(file => $file->filename);

        $log->$level('message');

        undef $log;

        my $content = _slurp($file);

        like $content, qr/\n$/;
    }
};

subtest 'prints sprintf formatted line' => sub {
    for my $level (qw/error warn debug/) {
        my $file = File::Temp->new;
        my $log = _build_logger(file => $file->filename);

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
    my $logger = Log::Mini::LoggerFILE->new(@_);
    $logger->set_level('debug');
    return $logger;
}

done_testing;