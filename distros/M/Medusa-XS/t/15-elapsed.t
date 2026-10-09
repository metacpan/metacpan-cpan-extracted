#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use File::Spec;

plan tests => 5;

my $tempdir;
my $file;
BEGIN {
   # $tempdir = File::Temp::tempdir(CLEANUP => 1);
    $file = 'test.log'; #File::Spec->catfile($tempdir, 'test.log');
}

{
    package LALALA;
    use Medusa::XS LOG_FILE => $file;

    sub new { bless { a => { b => 2 } }, $_[0]; }

    sub audit :Audit {
        select(undef, undef, undef, 0.25);
        return 211;
    }
}

my $lalala = LALALA->new();
is($lalala->audit(0), 211, 'value check');


open my $fh, '<', $file or die "Cannot open $file: $!";
my $content = do { local $/; <$fh> };
close $fh;
my @lines = split "\n", $content;

like($lines[0], qr/arg/, 'args');
like($lines[1], qr/returned/, 'returns');
my ($elapsed) = $lines[1] =~ m/elapsed_call=†([0-9.e+-]+)†/;
ok(defined $elapsed, 'elapsed');
cmp_ok($elapsed || 0, '>=', 0.2, 'elapsed covers the call');

done_testing();
