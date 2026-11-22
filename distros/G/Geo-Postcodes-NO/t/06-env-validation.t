use strict;
use warnings;
use utf8;

use File::Temp qw(tempfile);
use IPC::Open3 qw(open3);
use Symbol qw(gensym);
use Test::More;

my @bad_files = (
    [ 'too few fields', "9999\tMANGLER\t0301\tOSLO\r\n", qr/expected 5 tab-separated fields/ ],
    [ 'too many fields', "9999\tMANGLER\t0301\tOSLO\tG\tEXTRA\r\n", qr/expected 5 tab-separated fields/ ],
    [ 'invalid postcode', "999\tMANGLER\t0301\tOSLO\tG\r\n", qr/invalid postcode '999'/ ],
    [ 'empty location', "9999\t\t0301\tOSLO\tG\r\n", qr/empty location for postcode 9999/ ],
    [ 'invalid borough number', "9999\tMANGLER\t301\tOSLO\tG\r\n", qr/invalid borough number '301'/ ],
    [ 'empty borough', "9999\tMANGLER\t0301\t\tG\r\n", qr/empty borough for postcode 9999/ ],
    [ 'invalid category', "9999\tMANGLER\t0301\tOSLO\tX\r\n", qr/invalid category 'X'/ ],
    [ 'duplicate postcode', "9999\tFORSTE\t0301\tOSLO\tG\r\n9999\tANDRE\t0301\tOSLO\tG\r\n", qr/duplicate postcode '9999'/ ],
    [ 'conflicting borough name', "9999\tMANGLER\t0301\tOSLO\tG\r\n9998\tANDELE\t0301\tAKERSHUS\tG\r\n", qr/conflicting borough names for number '0301'/ ],
    [ 'unknown county', "9999\tMANGLER\t9901\tUKJENT\tG\r\n", qr/unknown county for borough number '9901'/ ],
);

for my $case (@bad_files) {
    my ($name, $content, $error) = @$case;
    my $path = write_file($content);
    my ($code, $output) = run_module($path);

    isnt($code, 0, "module rejects $name");
    like($output, $error, "module reports $name");
}

my $latin1_path = write_file("9998\tB" . chr(0xC6) . "RUM\t3201\tB" . chr(0xC6) . "RUM\tG\r\n");
my ($code, $output) = run_module($latin1_path, 'UTF-8');
isnt($code, 0, 'module rejects bytes that cannot be decoded with selected encoding');
like($output, qr/Cannot decode postcode data .* as UTF-8:/, 'module reports selected encoding on decode failure');

my $valid_path = write_file("9998\tBORG\t3201\tBAERUM\tG\r\n");
($code, $output) = run_module($valid_path, 'NO-SUCH-ENCODING');
isnt($code, 0, 'module rejects unknown encoding name');
like($output, qr/Cannot decode postcode data .* as NO-SUCH-ENCODING:/, 'module reports unknown encoding name');

sub write_file {
    my $content = shift;
    my ($fh, $path) = tempfile();
    binmode $fh, ':raw';
    print {$fh} $content;
    close $fh or die "Cannot close $path: $!";
    return $path;
}

sub run_module {
    my ($path, $encoding) = @_;
    local $ENV{GEO_POSTCODES_NO_DATA} = $path;
    local $ENV{GEO_POSTCODES_NO_ENCODING} = defined $encoding ? $encoding : 'cp1252';

    my $err = gensym;
    my $pid = open3(undef, my $out, $err, $^X, '-Ilib', '-MGeo::Postcodes::NO', '-E', 'print "loaded\n"');
    my $stdout = do { local $/; <$out> } // '';
    my $stderr = do { local $/; <$err> } // '';
    waitpid $pid, 0;
    return (($? >> 8), $stdout . $stderr);
}

done_testing;
