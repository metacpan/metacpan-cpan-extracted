use strict;
use warnings;
use utf8;

use File::Temp qw(tempfile);
use IPC::Open3 qw(open3);
use Symbol qw(gensym);
use Test::More;

my ($fh, $path) = tempfile();
binmode $fh, ':encoding(UTF-8)';
print {$fh} join("\t", '9998', 'BÆRUM', '3201', 'BÆRUM', 'G'), "\r\n";
close $fh or die "Cannot close $path: $!";

my ($code, $output) = run_perl_with_env(
    $path,
    'UTF-8',
    'my $expected = "B" . chr(0xC6) . "RUM"; die Geo::Postcodes::NO::data_encoding() unless Geo::Postcodes::NO::data_encoding() eq q(UTF-8); die Geo::Postcodes::NO::borough_of(q(9998)) unless Geo::Postcodes::NO::borough_of(q(9998)) eq $expected; print "ok\n";'
);

is($code, 0, 'module loads UTF-8 postcode file when encoding env var is set');
is($output, "ok\n", 'UTF-8 decoded value is correct');

($code, $output) = run_checker_with_env($path, 'UTF-8');
is($code, 0, 'checker accepts UTF-8 postcode file when encoding env var is set');
like($output, qr/using UTF-8\n\z/, 'checker reports selected encoding');

sub run_perl_with_env {
    my ($path, $encoding, $code) = @_;
    local $ENV{GEO_POSTCODES_NO_DATA} = $path;
    local $ENV{GEO_POSTCODES_NO_ENCODING} = $encoding;

    my $err = gensym;
    my $pid = open3(undef, my $out, $err, $^X, '-Ilib', '-MGeo::Postcodes::NO', '-E', $code);
    my $stdout = do { local $/; <$out> } // '';
    my $stderr = do { local $/; <$err> } // '';
    waitpid $pid, 0;
    return (($? >> 8), $stdout . $stderr);
}

sub run_checker_with_env {
    my ($path, $encoding) = @_;
    local $ENV{GEO_POSTCODES_NO_ENCODING} = $encoding;

    my $err = gensym;
    my $pid = open3(undef, my $out, $err, 'sh', 'script/check-postcodes-no', $path);
    my $stdout = do { local $/; <$out> } // '';
    my $stderr = do { local $/; <$err> } // '';
    waitpid $pid, 0;
    return (($? >> 8), $stdout . $stderr);
}

done_testing;
