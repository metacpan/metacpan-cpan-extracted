#!/usr/bin/perl -w
#
# bin/dkim2sign -- the standalone signer CLI.
#
# The library's signing path otherwise only exists behind the milter and the
# reflector; this CLI exists so a cross-implementation matrix can drive Perl the
# same way it drives the Python, Go and C signers.

use 5.020;
use strict;
use warnings;
use Test::More;
use Path::Tiny;
use File::Temp qw(tempdir);
use File::Spec;

my $keyfile = '../keys/sel1._domainkey.test1.dkim2.com.pem';
plan skip_all => 'shared ../keys not available' unless -e $keyfile;
my $keyfile2 = '../keys/sel1._domainkey.test2.dkim2.com.pem';
plan skip_all => 'shared ../keys not available' unless -e $keyfile2;

my $dir = tempdir(CLEANUP => 1);
my $src = path($dir)->child('base.eml');
$src->spew_raw(join('',
    "From: sender\@test1.dkim2.com\r\n",
    "To: rcpt\@test2.dkim2.com\r\n",
    "Subject: sign cli test\r\n",
    "Date: Fri, 24 Jul 2026 12:00:00 +0000\r\n",
    "Message-ID: <signcli\@test1.dkim2.com>\r\n",
    "\r\n",
    "Hello signer.\r\n",
));

sub sign {
    my ($in, @args) = @_;
    my @cmd = ($^X, '-Ilib', 'bin/dkim2sign', @args, "$in");
    open my $fh, '-|', @cmd or die "cannot run signer: $!";
    binmode $fh;
    my $data = do { local $/; <$fh> };
    close $fh;
    return ($data, $? >> 8);
}

# As sign(), but with the usage/error text suppressed -- for the cases where a
# non-zero exit is what we are asserting.
sub sign_quietly {
    my @args = @_;
    open my $olderr, '>&', \*STDERR or die $!;
    open STDERR, '>', File::Spec->devnull or die $!;
    my @r = sign(@args);
    open STDERR, '>&', $olderr or die $!;
    return @r;
}

# --- originator: adds Message-Instance m=1 and DKIM2-Signature i=1 ---
my ($signed, $rc) = sign($src,
    '-s' => 'sel1', '-d' => 'test1.dkim2.com', '-k' => $keyfile,
    '--mailfrom' => '<sender@test1.dkim2.com>',
    '--rcptto'   => '<rcpt@test2.dkim2.com>',
    '--timestamp' => 1740000000);
is($rc, 0, 'signer exits 0');
like($signed, qr/^DKIM2-Signature: i=1; m=1; t=1740000000;/m,
    'emits DKIM2-Signature i=1 m=1 with the fixed timestamp');
is(scalar(() = $signed =~ /^Message-Instance:/mg), 1,
    'emits exactly one Message-Instance');
like($signed, qr/^Message-Instance: m=1;/m, 'the instance is m=1');
like($signed, qr/\r\n/, 'output uses CRLF line endings');

# The original headers survive.
like($signed, qr/^Subject: sign cli test\r$/m, 'original headers preserved');

# --- unmodified re-sign: reuses the instance, adds no new one (§9.1/§9.2.5) ---
my $hop1 = path($dir)->child('hop1.eml');
$hop1->spew_raw($signed);

my ($resigned, $rc2) = sign($hop1,
    '-s' => 'sel1', '-d' => 'test2.dkim2.com', '-k' => $keyfile2,
    '--mailfrom' => '<sender@test2.dkim2.com>',
    '--rcptto'   => '<final@test3.dkim2.com>',
    '--timestamp' => 1740000100);
is($rc2, 0, 're-signer exits 0');
is(scalar(() = $resigned =~ /^Message-Instance:/mg), 1,
    'an unmodified hop adds no Message-Instance');
is(scalar(() = $resigned =~ /^DKIM2-Signature:/mg), 2,
    'but does add a second DKIM2-Signature');
like($resigned, qr/^DKIM2-Signature: i=2; m=1;/m,
    'the new signature references the reused instance m=1');

# --- nd= hop omits mf=/rt= (§9.3) ---
my ($nd, $rc3) = sign($src,
    '-s' => 'sel1', '-d' => 'test1.dkim2.com', '-k' => $keyfile,
    '--next-domain' => 'test2.dkim2.com',
    '--timestamp' => 1740000000);
is($rc3, 0, 'nd= signer exits 0');
like($nd, qr/nd=test2\.dkim2\.com/, 'nd= hop carries nd=');
unlike($nd, qr/\bmf=/, 'nd= hop omits mf=');
unlike($nd, qr/\brt=/, 'nd= hop omits rt=');

# --- missing required options fail rather than producing garbage ---
my (undef, $rc4) = sign_quietly($src, '-d' => 'test1.dkim2.com', '-k' => $keyfile);
isnt($rc4, 0, 'missing --selector is an error');

done_testing();
