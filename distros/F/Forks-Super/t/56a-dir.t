use Forks::Super ':test';
use Test::More tests => 15;
use Time::HiRes;
use Config;
use strict;
use warnings;

# this test crashes on Windows 7

mkdir "t/dir1-$$" or die;
mkdir "t/dir2-$$" or die;
mkdir "t/dir2-$$/dir3" or die;

my $END_PID = $$;

my $PERL = $Config{perlpath};  # in case $^X is a relative path ...
$PERL = $^X if ! -x $PERL;

my $pid0 = fork { dir => get_path("t/dir2-$$") };
   # ok: $$ is parent pid, not new child pid

if ($pid0 == 0) {
    open my $BAR, '>', 'www';
    print $BAR 'Prey for whirled peas';
    close $BAR;
    exit;
}
ok(isValidPid($pid0), "natural child launched with dir option");
wait;
ok(-f "t/dir2-$$/www", "child called chdir");
ok(-s "t/dir2-$$/www" == length('Prey for whirled peas'), 
   "child created file in target dir");
ok($pid0->status == 0, "child completed normally");
unlink "www", "t/dir2-$$/www";


my $pid1 = fork { 
    dir => get_path("t/dir1-$$"),
    sub => sub { 
	open my $FOO, '>>', 'xxx';
	print $FOO "Hello world";
	close $FOO;
    }
};
ok(isValidPid($pid1), "sub child launched with dir option");
wait;
ok(-f "t/dir1-$$/xxx", "child called chdir");
ok(-s "t/dir1-$$/xxx" == 11, "child created file in target dir");
ok($pid1->status == 0, "child completed normally");
unlink "xxx", "t/dir1-$$/xxx";

my $pid2 = fork {
    chdir => get_path("t/dir2-$$/dir3"),
    exec => [$PERL, "../../external-command.pl", "-o=yyy", "-e=message"]
};
ok(isValidPid($pid2), "exec child launched with chdir option");
wait;
ok(-f "t/dir2-$$/dir3/yyy", "child called chdir");
ok(-s "t/dir2-$$/dir3/yyy", "child created file in target dir");
ok($pid2->status == 0, "child completed normally");
unlink "t/dir2-$$/dir3/yyy", "yyy";

my $pid3 = fork {
    dir => get_path("t/dir56789"),
    cmd => [ $PERL, "../external-command.pl", "-o=zzz", "-e=message" ]
};
ok(isValidPid($pid3), "cmd child launched with invalid dir option");
wait;
ok(! -d "t/dir56789", "child target dir not created");
ok($pid3->status != 0, "child failed with invalid target dir");

sub get_path {
    my $path = shift;
    if (${^TAINT}) {
	$path = Forks::Super::Util::abs_path($path);
	($path) = $path =~ /(.*)/;
    }
    return $path;
}

END {
    if ($$ == $END_PID) {
	unlink "t/dir2-$$/dir3/*";
	rmdir "t/dir2-$$/dir3";
	unlink glob("t/dir2-$$/*");
	rmdir "t/dir2-$$";
	unlink glob("t/dir1-$$/*");
	rmdir "t/dir1-$$";
    }
}
