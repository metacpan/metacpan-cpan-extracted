use strict;
use warnings;
use utf8;

use File::Temp qw(tempfile);
use IPC::Open3 qw(open3);
use Symbol qw(gensym);
use Test::More;

my $checker = 'script/check-postcodes-no';
my $bundled = 'lib/Geo/Postcodes/NO/postnummerregister-ansi.txt';

ok(-x $checker, 'shell checker is executable');
ok(-f $bundled, 'bundled postcode file exists');

my ($code, $output) = run_checker($bundled);
is($code, 0, 'checker accepts bundled postcode file');
like($output, qr/^OK: \d+ postcodes loaded from /, 'checker prints success summary');

my ($fh, $bad_path) = tempfile();
binmode $fh, ':raw';
print {$fh} "9999\tMANGLER\t0301\tOSLO\tX\r\n";
close $fh or die "Cannot close $bad_path: $!";

($code, $output) = run_checker($bad_path);
isnt($code, 0, 'checker rejects invalid category');
like($output, qr/invalid category/, 'checker reports validation error');

my ($fh2, $county_path) = tempfile();
binmode $fh2, ':raw';
print {$fh2} "9999\tMANGLER\t9901\tUKJENT\tG\r\n";
close $fh2 or die "Cannot close $county_path: $!";

($code, $output) = run_checker($county_path);
isnt($code, 0, 'checker rejects unknown county prefix');
like($output, qr/unknown county for borough number '9901'/, 'checker reports unknown county in standalone pre-check');

sub run_checker {
    my $path = shift;
    my $err = gensym;
    my $pid = open3(undef, my $out, $err, 'sh', $checker, $path);

    my $stdout = do { local $/; <$out> } // '';
    my $stderr = do { local $/; <$err> } // '';

    waitpid $pid, 0;
    my $code = $? >> 8;
    return ($code, $stdout . $stderr);
}

done_testing;
