use strict;
use warnings;
use Test::More;

# THE METHOD, NOT A SHELL. `bin/cribbage` is two lines that call
# Game::Cribbage::Terminal->run(@ARGV), so the program is tested by calling the
# method with the handles localised. A script that can only be tested through a
# pipe makes every assertion here an assertion about a shell as well as about
# the program.
use Game::Cribbage::Terminal;

can_ok('Game::Cribbage::Terminal', 'run');

sub run {
    my (@argv) = @_;
    my $stdin = ref $argv[0] eq 'ARRAY' ? shift @argv : [];
    my ($out, $err) = ('', '');
    my $in = join '', map { "$_\n" } @$stdin;
    open my $o, '>', \$out or die $!;
    open my $e, '>', \$err or die $!;
    open my $i, '<', \$in  or die $!;
    $o->autoflush(1);
    $e->autoflush(1);

    my $status = do {
        local *STDOUT = $o;                          ## no critic
        local *STDERR = $e;                          ## no critic
        local *STDIN  = $i;                          ## no critic
        Game::Cribbage::Terminal->run(@argv);
    };
    return { status => $status, out => $out, err => $err };
}

subtest '--help is status 0 and carries the exit legend' => sub {
    my $r = run('--help');
    is($r->{status}, 0, 'status 0');
    like($r->{out}, qr/usage: cribbage/, 'usage on stdout');
    is($r->{err}, '', '  and nothing on stderr');

    # THE LEGEND IS IN THE HEREDOC, not only in a test: a program whose exit
    # statuses live in its test suite is a program nobody can script against.
    like($r->{out}, qr/exit status:/,        'the legend is there');
    like($r->{out}, qr/0\s+you won, or you quit/, '  0 is a win or a quit');
    like($r->{out}, qr/1\s+you lost/,        '  1 is a loss');
    like($r->{out}, qr/2\s+a bad option/,    '  2 is a bad option');

    like($r->{out}, qr/--pick/, 'and --pick is documented');
};

subtest 'a bad option is status 2, on stderr, and never status 0' => sub {
    for my $bad (['--nope'], ['extra-argument']) {
        my $r = run(@$bad);
        is($r->{status}, 2, "@$bad is status 2");
        isnt($r->{out} =~ /usage/ ? 'stdout' : 'stderr', 'stdout',
             '  and the usage went to stderr, not stdout');
    }
};

subtest 'the picker can be turned off from the command line' => sub {
    # 0.16 HAD NO OPTIONS AT ALL, and a program whose only interface is the
    # keyboard cannot be driven by anything else. --no-pick is what makes a run
    # down a pipe possible, which is also what this test is.
    for my $off (qw(--no-pick --nopick)) {
        my $r = run([], $off);
        isnt($r->{status}, 2, "$off is taken as an option");
    }
    my $r = run([], '--pick');
    isnt($r->{status}, 2, 'and so is --pick');
};

subtest 'the shebang is a shebang and no relative lib is baked in' => sub {
    # 0.16 SHIPPED `#!usr/bin/perl`, with no leading slash, in a script that is
    # in EXE_FILES; and `use lib 'lib'` beside it, which in an installed script
    # points at whatever ./lib happens to be in the directory somebody ran it
    # from. Both are one line each and neither shows up in a test of behaviour.
    my $src = do {
        open my $fh, '<', 'bin/cribbage' or die $!;
        local $/;
        <$fh>;
    };
    my ($shebang) = split /\n/, $src;
    like($shebang, qr{^#!/}, 'the shebang starts with a slash');
    unlike($src, qr/^use lib\b/m, 'and no use lib is baked into it');
    like($src, qr/^use strict;/m,   'it is strict');
    like($src, qr/^use warnings;/m, '  and warned');
};

done_testing();
