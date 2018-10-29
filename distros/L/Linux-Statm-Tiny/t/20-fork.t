use strict;
use warnings;

use Test::More;

plan skip_all => "Not a Linux machine" if $^O ne 'linux';

use_ok 'Linux::Statm::Tiny';

ok my $stat = Linux::Statm::Tiny->new(), 'new';

my ($pread, $pwrite);
pipe($pread, $pwrite);

my $pid = fork();
die "fork failed" unless defined $pid;

if ($pid == 0) {
    my $check = ($$ == $stat->pid);
    print $pwrite "$check\n";
    exit;
}

waitpid($pid, 0);
my $t = <$pread>;
chomp($t);
ok $t, 'got the right pid in a fork';

done_testing();
