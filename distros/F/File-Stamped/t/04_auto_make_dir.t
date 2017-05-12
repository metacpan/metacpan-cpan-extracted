use strict;
use warnings;
use Test::More;
use File::Temp qw/tempdir/;
use File::Spec;
use File::Stamped;
use File::Basename;

my $dir = tempdir(CLEANUP => 1);
my $pattern = File::Spec->catdir($dir, '%Y%m%d/foo.%Y%m%d.log');

my $f = File::Stamped->new(pattern => $pattern, auto_make_dir => 1);
$f->print("OK\n");
print {$f} "OK2\n";

my $fname = do {
    my $fname;
    opendir my $dh, $dir or die;
    LOOP: while (my $e = readdir $dh) {
        next if $e eq '.' || $e eq '..';
        $e = File::Spec->catfile($dir, $e);
        if (-d $e) {
            opendir my $cdh, $e or die;
            while (my $ce = readdir $cdh) {
                $ce = File::Spec->catfile($e, $ce);
                next unless -f $ce;
                $fname = $ce;
                last LOOP;
            }
        }
    }
    closedir $dh;
    $fname;
};
like basename($fname), qr{^foo.\d{8,}\.log$};
open my $fh, '<', $fname or die;
my $content = do { local $/; <$fh> };
is $content, "OK\nOK2\n";

done_testing;

