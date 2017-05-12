#!/usr/bin/env perl -w
use strict;
use warnings;
use Log::LTSV::Instance;
use Test::More;
use Test::Deep;
use Test::Deep::Matcher;
use File::Temp;

subtest 'def:null do:crit' => sub {
    my $log = '';
    my $logger = Log::LTSV::Instance->new(
        logger => sub { $log .= shift },
    );
    $logger->crit(msg => 'hungup');
    print $log;

    chomp($log);
    my %map = ( map { split ':', $_, 2 } split "\t", $log);

    cmp_deeply \%map, {
        time      => ignore,
        log_level => 'CRITICAL',
        msg       => 'hungup',
    },
};

subtest 'def:debug do:crit' => sub {
    my $log = '';
    my $logger = Log::LTSV::Instance->new(
        logger => sub { $log .= shift },
        level  => 'DEBUG',
    );
    $logger->crit(msg => 'hungup');

    chomp($log);
    my %map = ( map { split ':', $_, 2 } split "\t", $log);

    cmp_deeply \%map, {
        time      => ignore,
        log_level => 'CRITICAL',
        msg       => 'hungup',
    },
};

subtest 'def:debug do:debug' => sub {
    my $log = '';
    my $logger = Log::LTSV::Instance->new(
        logger => sub { $log .= shift },
        level  => 'DEBUG',
    );
    $logger->debug(msg => 'hungup');

    chomp($log);
    my %map = ( map { split ':', $_, 2 } split "\t", $log);

    cmp_deeply \%map, {
        time      => ignore,
        log_level => 'DEBUG',
        msg       => 'hungup',
    },
};

subtest 'def:crit do:debug' => sub {
    my $log = '';
    my $logger = Log::LTSV::Instance->new(
        logger => sub { $log .= shift },
        level  => 'CRITICAL',
    );
    $logger->debug(msg => 'hungup');
    is $log, '';
};

subtest 'sticks' => sub {
    my $log = '';
    my $logger = Log::LTSV::Instance->new(
        logger => sub { $log .= shift },
    );
    $logger->sticks('id' => 1);
    $logger->crit(msg => 'hungup');

    chomp($log);
    my %map = ( map { split ':', $_, 2 } split "\t", $log);

    cmp_deeply \%map, {
        id        => 1,
        time      => ignore,
        log_level => 'CRITICAL',
        msg       => 'hungup',
    },
};

subtest 'sticks (coderef)' => sub {
    my $log = '';
    my $logger = Log::LTSV::Instance->new(
        logger => sub { $log .= shift },
    );
    $logger->sticks('id' => sub { 1 });
    $logger->sticks('caller' => sub {
        my @caller = caller(2);
        {
            file => $caller[1],
            line => $caller[2],
        }
    });
    $logger->crit(msg => 'hungup');

    chomp($log);
    my %map = ( map { split ':', $_, 2 } split "\t", $log);

    cmp_deeply \%map, {
        id            => 1,
        time          => ignore,
        log_level     => 'CRITICAL',
        msg           => 'hungup',
        'caller.file' => 't/print.t',
        'caller.line' => is_integer,
    } or note explain \%map;
};

subtest 'hashref' => sub {
    my $log = '';
    my $logger = Log::LTSV::Instance->new(
        logger => sub { $log .= shift },
    );
    $logger->crit({msg => 'hungup'});

    chomp($log);
    my %map = ( map { split ':', $_, 2 } split "\t", $log);

    cmp_deeply \%map, {
        time      => ignore,
        log_level => 'CRITICAL',
        msg       => 'hungup',
    },
};

subtest 'scalar' => sub {
    my $log = '';
    my $logger = Log::LTSV::Instance->new(
        logger => sub { $log .= shift },
    );
    $logger->crit('hungup');

    chomp($log);
    my %map = ( map { split ':', $_, 2 } split "\t", $log);

    cmp_deeply \%map, {
        time      => ignore,
        log_level => 'CRITICAL',
        message   => 'hungup',
    },
};

subtest 'scalar (default_key)' => sub {
    my $log = '';
    my $logger = Log::LTSV::Instance->new(
        logger      => sub { $log .= shift },
        default_key => 'msg',
    );
    $logger->crit('hungup');

    chomp($log);
    my %map = ( map { split ':', $_, 2 } split "\t", $log);

    cmp_deeply \%map, {
        time      => ignore,
        log_level => 'CRITICAL',
        msg       => 'hungup',
    },
};

subtest 'File::RotateLogs' => sub {
    my ($fh, $filename) = File::Temp::tempfile( UNLINK => 1 );
    my $logger = Log::LTSV::Instance->new(
        level  => 'DEBUG',
        logfile => $filename,
    );
    $logger->crit(msg => 'hungup');


    read $fh, my $log, 4096;
    chomp($log);
    my %map = ( map { split ':', $_, 2 } split "\t", $log);

    cmp_deeply \%map, {
        time      => ignore,
        log_level => 'CRITICAL',
        msg       => 'hungup',
    },
};

subtest 'dumped' => sub {
    my $log = '';
    my $logger = Log::LTSV::Instance->new(
        logger => sub { $log .= shift },
    );

    my $obj = bless { cval => 1 }, 'TEST';
    $logger->crit(
        class    => $obj,
        hashref  => { hval => 1 },
        arrayref => [ 'a', 'b' ],
    );

    chomp($log);
    my %map = ( map { split ':', $_, 2 } split "\t", $log);

    cmp_deeply \%map, {
        'time'          => ignore,
        'log_level'     => 'CRITICAL',
        'class.cval'    => 1,
        'hashref.hval'  => 1,
        'arrayref.0'    => 'a',
        'arrayref.1'    => 'b',
    },
};

subtest 'compare' => sub {

    my $_obj = bless {
        cval => 1.
    }, 'TEST';
    my $_hash  = {
        ha => 1,
        hb => 2,
    };
    my $_array = [ 1, 2 ];

    my $loaf = {
        obj   => $_obj,
        hash  => $_hash,
        array => $_array,
    };

    my $raw = {
        'obj.cval'    => $_obj->{cval},
        'hash.ha'     => 1,
        'hash.hb'     => 2,
        'array.0'     => 1,
        'array.1'     => 2,
    };

    my $loaf_log = '';
    my $loaf_logger = Log::LTSV::Instance->new( logger => sub { $loaf_log .= shift } );
    my $raw_log = '';
    my $raw_logger = Log::LTSV::Instance->new( logger => sub { $raw_log .= shift } );

    chomp($loaf_log);
    chomp($raw_log);
    my %loaf_map = ( map { split ':', $_, 2 } split "\t", $loaf_log);
    my %raw_map = ( map { split ':', $_, 2 } split "\t", $raw_log);
    cmp_deeply \%loaf_map, \%raw_map;
};

subtest 'escape' => sub {
    my $log = '';
    my $logger = Log::LTSV::Instance->new(
        logger => sub { $log .= shift },
    );

    $logger->crit(message => "tab \t\t, line feed\n\n");

    chomp($log);
    my %map = ( map { split ':', $_, 2 } split "\t", $log);

    cmp_deeply \%map, {
        time      => ignore,
        log_level => 'CRITICAL',
        message   => 'tab \t\t, line feed\n\n',
    },
};

done_testing;
