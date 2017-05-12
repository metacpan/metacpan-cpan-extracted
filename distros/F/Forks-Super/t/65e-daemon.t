use Forks::Super ':test';
use Test::More tests => 3;
use Cwd;
use Carp;
use strict;
use warnings;

our $CWD = Cwd::getcwd;

if (${^TAINT}) {
    ($CWD) = $CWD =~ /(.*)/;
    $ENV{KEEP} ||= 0;
    ($ENV{KEEP}) = $ENV{KEEP} =~ /(.*)/;
}

my $output = "$CWD/t/out/daemon5.$$.out";

# does daemon respect a timeout option
my $pid = fork {
     env => { LOG_FILE => $output, VALUE => 30 },
     name => 'daemon4',
     daemon => 1,
     cmd => [ $^X, "$CWD/t/external-daemon.pl" ],
     timeout => 4,
};
ok(isValidPid($pid), "fork to cmd with daemon & timeout");
sleep 2;
my $k = Forks::Super::kill 'ZERO', $pid;
ok($k, "($k) daemon proc is alive");
sleep 6;
$k = Forks::Super::kill 'ZERO', $pid;
okl(!$k, "($k) daemon proc timed out in <= 8s") or do {
    if (!$Forks::Super::SysInfo::PREFER_ALTERNATE_ALARM) {
        diag qq[You may have better luck setting\n],
                qq[\$PREFER_ALTERNATE_ALARM to a true value\n],
                qq[in lib/Forks/Super/SysInfo.pm\n];
    }
    if ($k) {
        for (1..5) {
            sleep 1;
            $k = Forks::Super::kill 'ZERO',$pid;
            if (!$k) {
                diag "daemon proc timed out after additional $_ s";
                last;
            }
        }
    }
};

unlink $output, "$output.err" unless $ENV{KEEP};
