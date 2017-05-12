use warnings;
use strict;

use Test::More tests => 89;

use File::Spec qw(tempfile);
use File::Temp;
use Test::Fatal;

use File::Open qw(fsysopen_nothrow fopen_nothrow fsysopen fopen);

require IO::Handle if $] < 5.014;

my $DIR = File::Temp->newdir('F_O_test.XXXXXX', CLEANUP => 1, EXLOCK => 0, TMPDIR => 1);
-w $DIR or BAIL_OUT "$DIR: I can't test open() without a writeable temp directory";

sub scratch {
    my ($stem) = @_;
    my $template = File::Spec->catfile($DIR, "$stem.XXXXXX");
    File::Temp::mktemp($template)
}

my $nofile = scratch "nosuchfile";

like $_, qr/\Q: $nofile: / for
    exception { fopen $nofile },
    exception { fopen $nofile, 'r' },
    exception { fopen $nofile, 'r+' },
    exception { fopen $nofile, '<' },
    exception { fopen $nofile, '+<' },
    exception { fopen $nofile, 'rb' },
    exception { fopen $nofile, 'r+b' },
    exception { fopen $nofile, '<b' },
    exception { fopen $nofile, '+<b' },
    exception { fsysopen $nofile, 'r' },
    exception { fsysopen $nofile, 'w' },
    exception { fsysopen $nofile, 'rw' },
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
    ok $fh->print("$$ ${\rand}\n");
    ok $fh->close;
} {
    my $fh = fopen $scratch, 'w';
    ok $fh->print("$nofile\n");
    ok $fh->close;
} {
    my $fh = fopen $scratch, 'a';
    ok $fh->print("$token\n$scratch\n");
    ok $fh->close;
} {
    my $fh = fopen $scratch;
    my $data = do {local $/; $fh->getline};
    is $data, "$nofile\n$token\n$scratch\n";
    ok $fh->close;
}
unlink $scratch;

{
    my $fh = fopen $scratch, 'wb';
    ok $fh->print("$$ ${\rand}\n");
    ok $fh->close;
} {
    my $fh = fopen $scratch, 'wb';
    ok $fh->print("$nofile\n");
    ok $fh->close;
} {
    my $fh = fopen $scratch, 'ab';
    ok $fh->print("$token\n$scratch\n");
    ok $fh->close;
} {
    my $fh = fopen $scratch, 'rb';
    my $data = do {local $/; $fh->getline};
    is $data, "$nofile\n$token\n$scratch\n";
    ok $fh->close;
}
unlink $scratch;

{
    my $fh = fopen_nothrow $scratch, 'w';
    ok $fh;
    ok $fh->print("$$ ${\rand}\n");
    ok $fh->close;
} {
    my $fh = fopen_nothrow $scratch, 'w';
    ok $fh;
    ok $fh->print("$nofile\n");
    ok $fh->close;
} {
    my $fh = fopen_nothrow $scratch, 'a';
    ok $fh;
    ok $fh->print("$token\n$scratch\n");
    ok $fh->close;
} {
    my $fh = fopen_nothrow $scratch;
    ok $fh;
    my $data = do {local $/; $fh->getline};
    is $data, "$nofile\n$token\n$scratch\n";
    ok $fh->close;
}
unlink $scratch;

{
    my $fh = fopen_nothrow $scratch, 'wb';
    ok $fh;
    ok $fh->print("$$ ${\rand}\n");
    ok $fh->close;
} {
    my $fh = fopen_nothrow $scratch, 'wb';
    ok $fh;
    ok $fh->print("$nofile\n");
    ok $fh->close;
} {
    my $fh = fopen_nothrow $scratch, 'ab';
    ok $fh;
    ok $fh->print("$token\n$scratch\n");
    ok $fh->close;
} {
    my $fh = fopen_nothrow $scratch, 'rb';
    ok $fh;
    my $data = do {local $/; $fh->getline};
    is $data, "$nofile\n$token\n$scratch\n";
    ok $fh->close;
}
unlink $scratch;

SKIP: {
    {
        my $fh = fsysopen $scratch, 'w', {creat => 0666, trunc => 1, excl => 1};
        ok $fh->print("$$ ${\rand}\n");
        ok $fh->close;
    } {
        skip "O_CREAT|O_TRUNC is broken on windows", 8 if $^O eq 'MSWin32';
        my $fh = fsysopen $scratch, 'w', {creat => 0, trunc => 1};
        ok $fh->print("$nofile\n");
        ok $fh->close;
    } {
        my $fh = fsysopen $scratch, 'w';
        ok $fh->close;
    } {
        like exception { fsysopen $scratch, 'w', {creat => 0666, excl => 1} }, qr/\Q: $scratch: /;
    } {
        my $fh = fsysopen $scratch, 'w', {creat => 0, append => 1};
        ok $fh->print("$token\n$scratch\n");
        ok $fh->close;
    } {
        my $fh = fsysopen $scratch, 'r';
        my $data = do {local $/; $fh->getline};
        is $data, "$nofile\n$token\n$scratch\n";
        ok $fh->close;
    }
}
unlink $scratch;

SKIP: {
    {
        my $fh = fsysopen_nothrow $scratch, 'w', {creat => 0666, trunc => 1, excl => 1};
        ok $fh;
        ok $fh->print("$$ ${\rand}\n");
        ok $fh->close;
    } {
        skip "O_CREAT|O_TRUNC is broken on windows", 12 if $^O eq 'MSWin32';
        my $fh = fsysopen_nothrow $scratch, 'w', {creat => 0, trunc => 1};
        ok $fh;
        ok $fh->print("$nofile\n");
        ok $fh->close;
    } {
        my $fh = fsysopen_nothrow $scratch, 'w';
        ok $fh;
        ok $fh->close;
    } {
        ok !fsysopen_nothrow $scratch, 'w', {creat => 0666, excl => 1};
    } {
        my $fh = fsysopen_nothrow $scratch, 'w', {creat => 0, append => 1};
        ok $fh;
        ok $fh->print("$token\n$scratch\n");
        ok $fh->close;
    } {
        my $fh = fsysopen_nothrow $scratch, 'r';
        ok $fh;
        my $data = do {local $/; $fh->getline};
        is $data, "$nofile\n$token\n$scratch\n";
        ok $fh->close;
    }
}
unlink $scratch;
