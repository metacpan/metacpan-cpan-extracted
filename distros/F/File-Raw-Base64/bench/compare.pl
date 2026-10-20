#!perl
# File::Raw::Base64 against MIME::Base64, on the Benchmark module: decoding
# a file that holds 1 MB of bytes (wrapped at 76 and on one line), and
# encoding 1 MB into a file. BENCH_SECONDS sets the CPU seconds per entry
# (default 2).
use strict;
use warnings;
use Benchmark qw(cmpthese timethese);
use File::Temp ();
use File::Raw ();
use File::Raw::Base64;
use MIME::Base64 ();

my $secs = $ENV{BENCH_SECONDS} || 2;
srand 1;
my $dir   = File::Temp->newdir;
my $bytes = join '', map { chr int rand 256 } 1 .. (1 << 20);
my %in = (
    'wrapped at 76' => MIME::Base64::encode_base64($bytes),
    'one line'      => MIME::Base64::encode_base64($bytes, ''),
);
sub slurp_raw { open my $fh, '<:raw', $_[0] or die; local $/; <$fh> }

printf "File::Raw::Base64 %s, MIME::Base64 %s, perl %vd\n", $File::Raw::Base64::VERSION, $MIME::Base64::VERSION, $^V;
for my $form (sort keys %in) {
    my $path = "$dir/in.b64";
    File::Raw::spew($path, $in{$form}) or die;
    my $ours   = sub { File::Raw::slurp($path, plugin => 'base64') };
    my $theirs = sub { MIME::Base64::decode_base64(slurp_raw($path)) };
    die "decode ($form) differs\n" unless $ours->() eq $bytes && $theirs->() eq $bytes;
    print "\n== decode, $form\n";
    cmpthese(timethese(-$secs, { 'File::Raw::Base64' => $ours, 'MIME::Base64' => $theirs }, 'none'));
}
my $out = "$dir/out.b64";
my $ours   = sub { File::Raw::spew($out, $bytes, plugin => 'base64', wrap => 76) };
my $theirs = sub { open my $fh, '>:raw', $out or die; print {$fh} MIME::Base64::encode_base64($bytes); close $fh };
print "\n== encode, wrapped at 76\n";
cmpthese(timethese(-$secs, { 'File::Raw::Base64' => $ours, 'MIME::Base64' => $theirs }, 'none'));
