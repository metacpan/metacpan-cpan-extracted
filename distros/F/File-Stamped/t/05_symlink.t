use strict;
use warnings;
use Test::More;
use File::Temp qw/tempdir/;
use File::Spec;
use File::Stamped;
use File::Basename;

plan skip_all => 'This environment does not support a symlink' unless eval { symlink '',''; 1 };

my $dir = tempdir(CLEANUP => 1);
my $pattern = File::Spec->catdir($dir, 'foo.%Y%m%d.log');
my $symlink = File::Spec->catdir($dir, 'symlink.log');

my $f = File::Stamped->new(pattern => $pattern, symlink => $symlink);
$f->print("OK\n");
print {$f} "OK2\n";

my $fname = do {
    my $fname;
    opendir my $dh, $dir or die;
    LOOP: while (my $e = readdir $dh) {
        $e = File::Spec->catfile($dir, $e);
        next unless -f $e;
        next if $e eq $symlink;
        if (-f $e) {
            $fname = $e;
            last LOOP;
        }
    }
    closedir $dh;
    $fname;
};
is readlink $symlink, $fname;
like basename($fname), qr{^foo.\d{8,}\.log$};
open my $fh, '<', $symlink or die;
my $content = do { local $/; <$fh> };
is $content, "OK\nOK2\n";

done_testing;

