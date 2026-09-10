#!perl
use 5.008003;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

# clock_gettime(CLOCK_MONOTONIC) is POSIX and no Windows toolchain has it whole:
# MSVC before VS2015 has neither the function nor struct timespec, and the mingw
# of the older Strawberry perls declares timespec but no CLOCK_MONOTONIC. Every
# Windows build therefore dies in cpp, long before a test can run, which is what
# happened to 0.26. Both checks here encode the rule that broke it.

my $inc = File::Spec->catdir('include', 'fetch');
opendir(my $dh, $inc) or plan skip_all => "no $inc: run from the dist root";
my @src = sort grep { /\.(?:c|h)$/ } readdir $dh;
closedir $dh;

# Files whose POSIX clock use is unreachable on Windows: the kqueue/epoll/poll/
# io_uring backends are each guarded by their platform (Windows uses
# backend_select.c), and ft_h3.h is inside FT_HAVE_QUIC. ft_win.h is where the
# per-platform clock itself lives.
my %guarded = map { $_ => 1 } qw(
    backend_epoll.c backend_iouring.c backend_kqueue.c backend_poll.c
    ft_h3.h ft_win.h
);

my @offenders;
for my $f (@src) {
    next if $guarded{$f};
    open my $fh, '<', File::Spec->catfile($inc, $f) or die "$f: $!";
    while (my $line = <$fh>) {
        $line =~ s{/\*.*?\*/}{}g;          # a comment naming the trap is fine
        $line =~ s{/\*.*}{};
        next if $line =~ /^\s*\*/;
        push @offenders, "$f:$." if $line =~ /\b(?:clock_gettime|CLOCK_MONOTONIC|struct\s+timespec)\b/;
    }
    close $fh;
}
is_deeply(\@offenders, [], 'no unguarded POSIX clock in a header Windows compiles')
    or diag "use ft_monotonic() from ft_win.h instead";

# And prove the shim itself: under a Windows toolchain ft_monotonic must compile
# and link with the POSIX clock poisoned outright, which is what the smokers'
# compilers amount to. #pragma GCC poison is a real gate - the same source fails
# to compile on this POSIX host, where ft_win.h's other branch does name them.
my ($cc) = grep { my $p = $_; grep { -x "$_/$p" } File::Spec->path() }
           qw(i686-w64-mingw32-gcc x86_64-w64-mingw32-gcc);
plan skip_all => "no mingw-w64 cross compiler: header scan only" unless $cc;

my $dir = tempdir(CLEANUP => 1);
my $c   = File::Spec->catfile($dir, 'winclock.c');
my $exe = File::Spec->catfile($dir, 'winclock.exe');
open my $out, '>', $c or die "$c: $!";
print $out <<'C';
#pragma GCC poison clock_gettime CLOCK_MONOTONIC
#include "ft_win.h"
int main(void) { return ft_monotonic() > 0.0 ? 0 : 1; }
C
close $out;

my $log = File::Spec->catfile($dir, 'cc.log');
my $cmd = "$cc -Wall -D_CRT_RAND_S -I$inc -o $exe $c -lws2_32 >$log 2>&1";
my $rc  = system $cmd;
ok($rc == 0 && -s $exe, "$cc: ft_monotonic builds with no POSIX clock")
    or do { open my $l, '<', $log; diag do { local $/; <$l> } };

done_testing();
