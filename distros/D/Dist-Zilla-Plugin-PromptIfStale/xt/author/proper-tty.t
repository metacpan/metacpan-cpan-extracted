use strict;
use warnings;

# Thanks to the changes in 0.025, code now behaves differently depending on
# the state of our filehandles. We test here that we are indeed forcing stdin
# to a pty in all tests that need it, by forcing it closed up front and then
# unleashing the hounds. This simulates installing the module with stdin not
# using a tty, as in 'cpan-outdated | cpanm' or 'dzil listdeps | cpanm'.

use Test::More 0.96;
use Test::Warnings;
use File::Spec;
use IO::Handle;
use IPC::Open3;

use lib 't/lib';
use NoNetworkHits;
use EnsureStdinTty;
use DiagFilehandles;

# make it look like we are running non-interactively
open my $stdin, '<', File::Spec->devnull or die "can't open devnull: $!";
my $inc_switch = -d 'blib' ? '-Mblib' : '-Ilib';

local $TODO = 'on perls <5.16, IO::Pty may not work on all platforms' if "$]" < '5.016';

foreach my $test (glob('t/*'))
{
    next if not -f $test;
    next if $test =~ /\b00-/;
    subtest $test => sub {
        open my $stdout, '>', File::Spec->devnull or die "can't open devnull: $!";
        my $stderr = IO::Handle->new;
        # this *should* pick up our PERL5LIB and DTRT...
        diag "running $^X $inc_switch $test";
        my $pid = open3($stdin, $stdout, $stderr, $^X, $inc_switch, $test);
        binmode $stderr, ':crlf' if $^O eq 'MSWin32';
        my @stderr = <$stderr>;
        waitpid($pid, 0);

        is($?, 0, "$test ran ok");
        warn @stderr if @stderr;
    };
}

done_testing;
