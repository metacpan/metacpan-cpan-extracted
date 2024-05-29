use strict;
use warnings;
use Test::More;
use Linux::Info;

my $class = 'Linux::Info::Processes';

my @processes = (
    'ppid',   'nlwp',     'owner',   'pgrp',   'state',   'session',
    'ttynr',  'minflt',   'cminflt', 'mayflt', 'cmayflt', 'stime',
    'utime',  'ttime',    'cstime',  'cutime', 'prior',   'nice',
    'sttime', 'actime',   'vsize',   'nswap',  'cnswap',  'cpu',
    'size',   'resident', 'share',   'trs',    'drs',     'lrs',
    'dtp',    'cmd',      'cmdline', 'wchan',  'fd',
);

plan tests => scalar(@processes) + 7;

require_ok($class);
can_ok(
    $class,
    (
        'new',       'init',        'get',          'raw',
        '_load',     '_get_limits', '_deltas',      '_get_statm',
        '_get_stat', '_get_owner',  '_get_cmdline', '_get_wchan',
        '_get_io',   '_get_fd',     '_get_pids',    '_uptime',
        '_calsec',
    )
);

my @required_files = (
    "/proc/$$/stat",   "/proc/$$/statm",
    "/proc/$$/status", "/proc/$$/cmdline",
    "/proc/$$/wchan",  "/proc/$$/limits",
);

foreach my $file (@required_files) {
    unless ( -r $file ) {
        plan skip_all => "$file is not readable";
        exit(0);
    }
}

note('Testing from Linux::Info interface');
my $sys = Linux::Info->new();
$sys->set( processes => 1 );
note('Waiting for data');
my $stats = $sys->get;

unless ( scalar( keys %{ $stats->processes } > 0 ) ) {
    plan skip_all => "processlist is empty";
    exit(0);
}

foreach my $pid ( keys %{ $stats->processes } ) {
    foreach my $process_info (@processes) {
        ok( defined $stats->processes->{$pid}->{$process_info},
            "checking processes $process_info" );
    }
    last;    # we check only one process, that should be enough
}

note('Creating instance with own pid');
my $instance = Linux::Info::Processes->new( pids => [ $$, ] );
isa_ok( $instance, $class );
$instance->init;
my $data_ref = $instance->get;
is( ref $data_ref, 'HASH', 'get returns a hash reference' );
ok(
    not( exists( $data_ref->{$$}->{limits} ) ),
    'there is no limits information since not requested'
) or diag( explain($data_ref) );

note('Creating instance with own pid and requesting limits');
$instance = Linux::Info::Processes->new(
    pids    => [ $$, ],
    enabled => { limits => 1 },
);
$instance->init;
$data_ref = $instance->get;
is( ref $data_ref, 'HASH', 'get returns a hash reference' );
ok(
    exists( $data_ref->{$$}->{limits} ),
    'there is limits information since requested'
);
