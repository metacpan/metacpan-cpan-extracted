use strict;
use warnings;
use Test::More;
use File::Temp qw/tempdir/;
use File::Spec;
use File::Stamped;
use File::Basename;

my $dir = tempdir(CLEANUP => 1);
my $pattern = File::Spec->catdir($dir, 'foo.%Y%m%d.log');

my $f = File::Stamped->new(pattern => $pattern);
$f->syswrite("OK\n");
syswrite $f, "OK2\n";
syswrite $f, "OK3\nfoo", 4;
syswrite $f, "barOK4\nfoo", 4, 3;

my $fname = do {
    my $fname;
    opendir my $dh, $dir or die;
    LOOP: while (my $e = readdir $dh) {
        $e = File::Spec->catfile($dir, $e);
        next unless -f $e;
        if (-f $e) {
            $fname = $e;
            last LOOP;
        }
    }
    closedir $dh;
    $fname;
};
like basename($fname), qr{^foo.\d{8,}\.log$};
open my $fh, '<', $fname or die;
my $content = do { local $/; <$fh> };
is $content, "OK\nOK2\nOK3\nOK4\n";

done_testing;

