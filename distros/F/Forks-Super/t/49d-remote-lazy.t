use Forks::Super ':test';
use Test::More;
use strict;
use warnings;

my $ntests = 16;
plan tests => $ntests;

# !!! - the remote feature is difficult to test. Don't sweat it too much
#       if the t/49*.t tests are the only ones that fail.

SKIP: {
    if (!Forks::Super::Config::CONFIG_module('Cwd')) {
        skip "sort of required Cwd", $ntests;
    }

    use lib '.';  # needed for perl 5.26
    require "t/remote.pl";
    my $sshd = get_test_sshd();
    if (!$sshd) {
        ok(1, "no ssh server available, skipping all tests")
            for 1..$ntests;
        exit;
    }
    my $cwd = Cwd::cwd();
    ($cwd) = $cwd =~ /(.*)/;

    my $xcmd = "$cwd/t/external-command.pl";
    if (! -r $xcmd) {
        skip "can't find external command for test", $ntests;
    }

    my $rhost = $sshd->host;
    my $ruser = $sshd->user;
    my $rport = $sshd->port;
    my $rhostx = $ruser . '@' . $rhost;
    if ($rport) {
        $rhostx .= ":" . $rport;
    }
    my $rpwd = $sshd->password;
    my $ids = $sshd->key_path;

    ### fully specified %remote_opts
    my $full_remote = { host => $rhost, user => $ruser, port => $rport,
                        proto => 'ssh' };

    if ($rpwd && $sshd->auth_method =~ /password/) {
        $full_remote->{password} = $sshd->password;
    } elsif ($ids && $sshd->auth_method =~ /publickey/) {
        $full_remote->{key_path} = $ids;
    }

    # remote => \@hosts
    my $full_remote2 = { %$full_remote };
    $full_remote2->{host} = [ $full_remote->{host} ];


    ok(!defined $Forks::Super::LAST_JOB, "\$Forks::Super::LAST_JOB not set");
    ok(!defined $Forks::Super::LAST_JOB_ID,
       "\$Forks::Super::LAST_JOB_ID not set");
    my $t2 = Time::HiRes::time();
    my $z = sprintf "%05d", 100000 * rand();
    my $x = bg_qx "$^X $cwd/t/external-command.pl -e=$z -s=3",
        { remote => $full_remote };
    my $t = Time::HiRes::time();
    ok(defined $Forks::Super::LAST_JOB, "\$Forks::Super::LAST_JOB set");
    ok(defined $Forks::Super::LAST_JOB_ID, "\$Forks::Super::LAST_JOB_ID set");
    ok(Forks::Super::isValidPid($Forks::Super::LAST_JOB_ID), 
       "\$Forks::Super::LAST_JOB_ID set");
    ok($Forks::Super::LAST_JOB->{_is_bg} > 0, 
       "\$Forks::Super::LAST_JOB marked bg");
    my $p = waitpid -1, 0;
    my $t3 = Time::HiRes::time() - $t;
    okl($p == -1 && $t3 <= 1.5,
        "waitpid doesn't catch bg_qx job, fast fail ${t3}s expect <=1s");
    ok($x eq "$z \n", "scalar bg_qx $x");
    my $h = Time::HiRes::time();
    ($t,$t2) = ($h-$t,$h-$t2);
    my $y = $x;
    ok($y == $z, "scalar bg_qx") or diag "z=$z != y=$y\n";
    okl($t2 >= 2.65 && $t <= 6.5,       ### 10 ### was 5.1 obs 5.57,6.31,2.66
        "scalar bg_qx took ${t}s ${t2}s expected ~3s");
    $x = 19;
    ok($x == 19, "result is not read only");

    ### interrupted bg_qx, scalar context ###

    my $j = $Forks::Super::LAST_JOB;
    $y = "";
    $z = sprintf "B%05d", 100000 * rand();
    $y = bg_qx "$^X $cwd/t/external-command.pl -s=5 -s=5 -e=$z",
        { remote => $full_remote, timeout => 2 };
    $t = Time::HiRes::time();

    ok(defined($y)==0 || "$y" eq "" || "$y" eq "\n",
       "scalar bg_qx empty on failure")  ### 12 ###
        or diag("\$y was $y, expected empty or undefined\n");
    ok($j ne $Forks::Super::LAST_JOB, "\$Forks::Super::LAST_JOB updated");
    $t = Time::HiRes::time() - $t;
    okl($t <= 6.5,                        ### 14 ### was 4 obs 4.92,6.0,7.7!
        "scalar bg_qx respected timeout, took ${t}s expected ~2s");

    ### interrupted bg_qx, capture existing output ###

    $z = sprintf "C%05d", 100000 * rand();
    $x = bg_qx "$^X $cwd/t/external-command.pl -e=$z -n -s=10", timeout => 4,
                remote => $full_remote;
    $t = Time::HiRes::time();
  TODO: {
      local $TODO = "Capture intermediate output from interrupted remote cmd";
      ok($x eq "$z \n" || $x eq "$z ",     ### 15 ###
         "scalar bg_qx failed but retrieved output")
          or diag("\$x was $x, expected $z\n");
    }
    if (!defined $x) {
        print STDERR "(output was: <undef>;target was \"$z \")\n";
    } elsif ($x ne "$z \n" && $x ne "$z ") {
        print STDERR "(output was: $x; target was \"$z \")\n";
    }
    $t = Time::HiRes::time() - $t;
    okl($t <= 7.5,                          ### 16 ### was 3 obs 3.62,5.88,7.34
        "scalar bg_qx respected timeout, took ${t}s expected ~4s");
}

sub hex_enc{join'', map {sprintf"%02x",ord} split//,shift} # for debug

    

