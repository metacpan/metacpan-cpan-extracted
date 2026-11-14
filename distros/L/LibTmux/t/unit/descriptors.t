use v5.44;
use Test2::V1;
use File::Temp qw(tempfile);
use POSIX      ();
use LibTmux::Transport;

my ($file, $path) = tempfile('libtmux-perl-fd-XXXX', TMPDIR => 1, UNLINK => 1);

# dup creates a native descriptor without close-on-exec, as an XS caller may.
my $fd = POSIX::dup(fileno($file));
die "dup: $!" unless defined $fd;
my $result;
try {
    $result = LibTmux::Transport->run(
        argv => [
            $^X, '-e', q{
        for my $pid ($$, getppid) {
            opendir my $fds, "/proc/$pid/fd" or die $!;
            my @inherited = grep {
                /\A[0-9]+\z/ && (readlink("/proc/$pid/fd/$_") // '') eq $ARGV[0]
            } readdir $fds;
            closedir $fds;
            print @inherited ? "inherited\n" : "closed\n";
        }
    }, $path
        ],
        timeout => 0.8
    );
    T2->is($result->stdout, "closed\nclosed\n",
        'command and supervisor both close unrelated native descriptors');
    T2->is(POSIX::write($fd, 'retained', 8),
        8, 'caller native descriptor remains usable');
    T2->is(readlink("/proc/self/fd/$fd"),
        $path, 'caller retains the original file identity');
}
catch ($error) { POSIX::close($fd); die $error }
POSIX::close($fd);
close $file;
T2->done_testing;
