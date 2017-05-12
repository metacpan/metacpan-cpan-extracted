use Test::More tests => 3;

my @cmd = (
    $^X,
        '-Mblib',
        '-MDevel::ContinuousProfiler',
        '-MData::Dumper',
        '-e' => '1 for 1..1_000_000;open(STDOUT,">t/basic.tmp")||die$!;print Dumper(\%Devel::ContinuousProfiler::DATA)'
);
system @cmd;
is( $?, 0, "@cmd" );

SKIP: {
    skip "Can't open t/basic.tmp: $!", 2 unless open my $fh, '<t/basic.tmp';

    local $/ = undef;
    my $data = readline $fh;
    unlink 't/basic.tmp';
    diag( $data );
    ok( $data, "Got something" );
    ok( eval($data), "It compiles" );
}
