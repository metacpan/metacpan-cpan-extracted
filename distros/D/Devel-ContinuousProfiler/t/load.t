use Test::More tests => 1;

system $^X, '-Mblib', 't/load.pl';
my $rc = $?;
is( $?, 0, "Loaded Devel::ContinuousProfiler" );
my $sig = $? & 127;

if ($sig && `gdb -h 2>&1`) {
    require Config;
    my %signum;
    @signum{split ' ', $Config::Config{sig_num}} = split ' ', $Config::Config{sig_name};
    if ('SEGV' eq $signum{$sig}) {
        diag( `gdb -batch -nx -x t/load.gdb $^X` );
    }
}
