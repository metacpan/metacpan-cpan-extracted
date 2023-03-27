use Test2::V0;
use File::Spec ();
use File::Temp ();
use File::Open qw(fsysopen_nothrow fopen_nothrow fsysopen fopen fopendir);

my $DIR = File::Temp->newdir('F_O_test.XXXXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);
-w $DIR or skip_all "$DIR: I can't test open() without a writeable temp directory";

sub scratch {
    my ($stem) = @_;
    my $template = File::Spec->catfile($DIR, "$stem.XXXXXX");
    File::Temp::mktemp($template)
}

my $nofile = scratch "nosuchfile";

like $_, qr/\Q: $nofile: / for
    dies { fopen $nofile },
    dies { fopen $nofile, 'r' },
    dies { fopen $nofile, 'r+' },
    dies { fopen $nofile, '<' },
    dies { fopen $nofile, '+<' },
    dies { fopen $nofile, 'rb' },
    dies { fopen $nofile, 'r+b' },
    dies { fopen $nofile, '<b' },
    dies { fopen $nofile, '+<b' },
    dies { fsysopen $nofile, 'r' },
    dies { fsysopen $nofile, 'w' },
    dies { fsysopen $nofile, 'rw' },
;

is $_, undef for
    fopen_nothrow($nofile),
    fopen_nothrow($nofile, 'r'),
    fopen_nothrow($nofile, 'r+'),
    fopen_nothrow($nofile, '<'),
    fopen_nothrow($nofile, '+<'),
    fopen_nothrow($nofile, 'rb'),
    fopen_nothrow($nofile, 'r+b'),
    fopen_nothrow($nofile, '<b'),
    fopen_nothrow($nofile, '+<b'),
    fsysopen_nothrow($nofile, 'r'),
    fsysopen_nothrow($nofile, 'w'),
    fsysopen_nothrow($nofile, 'rw'),
;

my $scratch = scratch "scratch${\int rand 100}";
unlink $scratch;

my $token = "${\rand}-$$";

{
    my $fh = fopen $scratch, 'w';
    ok print $fh "$$ ${\rand}\n";
    ok close $fh;
} {
    my $fh = fopen $scratch, 'w';
    ok print $fh "$nofile\n";
    ok close $fh;
} {
    my $fh = fopen $scratch, 'a';
    ok print $fh "$token\n$scratch\n";
    ok close $fh;
} {
    my $fh = fopen $scratch;
    my $data = do {local $/; readline $fh};
    is $data, "$nofile\n$token\n$scratch\n";
    ok close $fh;
}
unlink $scratch;

{
    my $fh = fopen $scratch, 'wb';
    ok print $fh "$$ ${\rand}\n";
    ok close $fh;
} {
    my $fh = fopen $scratch, 'wb';
    ok print $fh "$nofile\n";
    ok close $fh;
} {
    my $fh = fopen $scratch, 'ab';
    ok print $fh "$token\n$scratch\n";
    ok close $fh;
} {
    my $fh = fopen $scratch, 'rb';
    my $data = do {local $/; readline $fh};
    is $data, "$nofile\n$token\n$scratch\n";
    ok close $fh;
}
{
    my $basename = (File::Spec->splitpath($scratch))[-1];
    ok grep $_ eq $basename, readdir fopendir $DIR;
}
unlink $scratch;

{
    my $fh = fopen_nothrow $scratch, 'w';
    ok $fh;
    ok print $fh "$$ ${\rand}\n";
    ok close $fh;
} {
    my $fh = fopen_nothrow $scratch, 'w';
    ok $fh;
    ok print $fh "$nofile\n";
    ok close $fh;
} {
    my $fh = fopen_nothrow $scratch, 'a';
    ok $fh;
    ok print $fh "$token\n$scratch\n";
    ok close $fh;
} {
    my $fh = fopen_nothrow $scratch;
    ok $fh;
    my $data = do {local $/; readline $fh};
    is $data, "$nofile\n$token\n$scratch\n";
    ok close $fh;
}
{
    my $basename = (File::Spec->splitpath($scratch))[-1];
    ok grep $_ eq $basename, readdir fopendir $DIR;
}
unlink $scratch;

{
    my $fh = fopen_nothrow $scratch, 'wb';
    ok $fh;
    ok print $fh "$$ ${\rand}\n";
    ok close $fh;
} {
    my $fh = fopen_nothrow $scratch, 'wb';
    ok $fh;
    ok print $fh "$nofile\n";
    ok close $fh;
} {
    my $fh = fopen_nothrow $scratch, 'ab';
    ok $fh;
    ok print $fh "$token\n$scratch\n";
    ok close $fh;
} {
    my $fh = fopen_nothrow $scratch, 'rb';
    ok $fh;
    my $data = do {local $/; readline $fh};
    is $data, "$nofile\n$token\n$scratch\n";
    ok close $fh;
}
unlink $scratch;

SKIP: {
    {
        my $fh = fsysopen $scratch, 'w', {creat => 0666, trunc => 1, excl => 1};
        ok print $fh "$$ ${\rand}\n";
        ok close $fh;
    } {
        skip "O_CREAT|O_TRUNC is broken on windows", 8 if $^O eq 'MSWin32';
        my $fh = fsysopen $scratch, 'w', {creat => 0, trunc => 1};
        ok print $fh "$nofile\n";
        ok close $fh;
    } {
        my $fh = fsysopen $scratch, 'w';
        ok close $fh;
    } {
        like dies { fsysopen $scratch, 'w', {creat => 0666, excl => 1} }, qr/\Q: $scratch: /;
    } {
        my $fh = fsysopen $scratch, 'w', {creat => 0, append => 1};
        ok print $fh "$token\n$scratch\n";
        ok close $fh;
    } {
        my $fh = fsysopen $scratch, 'r';
        my $data = do {local $/; readline $fh};
        is $data, "$nofile\n$token\n$scratch\n";
        ok close $fh;
    }
}
unlink $scratch;

SKIP: {
    {
        my $fh = fsysopen_nothrow $scratch, 'w', {creat => 0666, trunc => 1, excl => 1};
        ok $fh;
        ok print $fh "$$ ${\rand}\n";
        ok close $fh;
    } {
        skip "O_CREAT|O_TRUNC is broken on windows", 12 if $^O eq 'MSWin32';
        my $fh = fsysopen_nothrow $scratch, 'w', {creat => 0, trunc => 1};
        ok $fh;
        ok print $fh "$nofile\n";
        ok close $fh;
    } {
        my $fh = fsysopen_nothrow $scratch, 'w';
        ok $fh;
        ok close $fh;
    } {
        ok !fsysopen_nothrow $scratch, 'w', {creat => 0666, excl => 1};
    } {
        my $fh = fsysopen_nothrow $scratch, 'w', {creat => 0, append => 1};
        ok $fh;
        ok print $fh "$token\n$scratch\n";
        ok close $fh;
    } {
        my $fh = fsysopen_nothrow $scratch, 'r';
        ok $fh;
        my $data = do {local $/; readline $fh};
        is $data, "$nofile\n$token\n$scratch\n";
        ok close $fh;
    }
}
unlink $scratch;

done_testing;
