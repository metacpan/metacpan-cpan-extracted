#!perl
# File::Raw::Hash against Digest::SHA and Digest::MD5, on the Benchmark
# module: a 64 MB file through the plugin against addfile, and a 64 KB buffer
# through the C runner against the one-shot functions. BENCH_SECONDS sets the
# CPU seconds per entry (default 2); BENCH_ONLY (a regex) picks algorithms.
use strict;
use warnings;
use Benchmark qw(cmpthese timethese);
use File::Temp ();
use File::Raw ();
use File::Raw::Hash;
use Digest::SHA ();
use Digest::MD5 ();

my $secs = $ENV{BENCH_SECONDS} || 2;
srand 1;
my $dir  = File::Temp->newdir;
my $file = "$dir/64m.bin";
my $block = join '', map { chr int rand 256 } 1 .. (1 << 20);
File::Raw::spew($file, $block x 64) or die;
my $buf = substr($block, 0, 64 << 10);

printf "File::Raw::Hash %s, Digest::SHA %s, Digest::MD5 %s, perl %vd\n",
    $File::Raw::Hash::VERSION, $Digest::SHA::VERSION, $Digest::MD5::VERSION, $^V;
printf "implementation: %s\n", File::Raw::Hash->can('implementation')
    ? join(', ', map { "$_ " . File::Raw::Hash::implementation()->{$_} } sort keys %{ File::Raw::Hash::implementation() })
    : 'portable (0.06 has no implementation())';

my %theirs_file = (
    md5    => sub { open my $fh, '<:raw', $file or die; Digest::MD5->new->addfile($fh)->hexdigest },
    sha1   => sub { Digest::SHA->new(1)->addfile($file, 'b')->hexdigest },
    sha256 => sub { Digest::SHA->new(256)->addfile($file, 'b')->hexdigest },
    sha512 => sub { Digest::SHA->new(512)->addfile($file, 'b')->hexdigest },
);
my %theirs_buf = (
    md5    => sub { Digest::MD5::md5_hex($buf) },
    sha1   => sub { Digest::SHA::sha1_hex($buf) },
    sha256 => sub { Digest::SHA::sha256_hex($buf) },
    sha512 => sub { Digest::SHA::sha512_hex($buf) },
);
for my $algo (grep { !$ENV{BENCH_ONLY} || /$ENV{BENCH_ONLY}/ } qw(md5 sha1 sha256 sha512)) {
    my $ours_file = sub { File::Raw::slurp($file, plugin => 'hash', algo => $algo, into => \my $d); $d };
    my $ours_buf  = sub { File::Raw::Hash::_test_feed($algo, $buf, 0) };
    die "$algo: the file digests differ\n"   unless $ours_file->() eq $theirs_file{$algo}->();
    die "$algo: the buffer digests differ\n" unless $ours_buf->()  eq $theirs_buf{$algo}->();
    print "\n== $algo, 64 MB file\n";
    cmpthese(timethese(-$secs, { 'File::Raw::Hash' => $ours_file, 'Digest' => $theirs_file{$algo} }, 'none'));
    print "\n== $algo, 64 KB buffer\n";
    cmpthese(timethese(-$secs, { 'File::Raw::Hash' => $ours_buf, 'Digest' => $theirs_buf{$algo} }, 'none'));
}
