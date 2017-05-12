use strict;
use Test::More;
use Linux::Smaps;

my $init_pid=1;

my $init_exists=kill 0=>$init_pid;
if ($init_exists) {
  plan skip_all => 'Probably running test suite as root, skipping this test...';
  exit 0;
} elsif (!$!{EPERM}) {
  plan skip_all => "Unexpected: pid=$init_pid does not exist, skipping this test...";
  exit 0;
} elsif (do {my $f; open $f, '<', "/proc/$init_pid/smaps" and defined(<$f>)}) {
  plan skip_all => "/proc/1/smaps is readable";
  exit 0;
}

plan tests => 4;

my $s=eval { Linux::Smaps->new($init_pid) };
like $@, qr{read failed}, "Permission denied to read process with pid $init_pid";
ok !$s, "No object constructed";

$s=Linux::Smaps->new(uninitialized=>1);
$s->pid=$init_pid;
is $s->update, undef, "  ->update";
like $s->lasterror, qr{read failed}, "  ->lasterror";

done_testing;

# Local Variables:
# mode: perl
# End:
