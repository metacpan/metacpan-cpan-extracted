use strict;
use warnings;
use Test::More 0.88;
use File::Temp qw/tempdir/;
use File::Spec;
use File::Stamped;
use File::Basename;

# This test case is taken from File-Stamped-Extended.
# Thanks bayashi san.

my $dir = tempdir(CLEANUP => 1);
my $pattern = File::Spec->catdir($dir, 'foo.!!.%Y%m%d.log');
my $extra = 'bar';

my $f = File::Stamped->new(callback => sub {
    my $self = shift;
    local $_ = $pattern;
    s/!!/$extra/ge;
    $_ = POSIX::strftime($_, localtime());
    return $_;
});
$f->print("OK\n");
print {$f} "OK2\n";

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
like basename($fname), qr{^foo\.bar\.\d{8,}\.log$};
open my $fh, '<', $fname or die;
my $content = do { local $/; <$fh> };
is $content, "OK\nOK2\n";

done_testing;
