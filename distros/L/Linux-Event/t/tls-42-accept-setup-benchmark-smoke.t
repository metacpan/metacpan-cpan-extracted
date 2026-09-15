use v5.36;
use strict;
use warnings;

use Test::More;
use File::Spec;
use FindBin qw($Bin);

my $root = File::Spec->catdir($Bin, '..');
my $bench = File::Spec->catfile($root, 'bench', 'run-tls-accept-setup-bench.pl');
my $perl = $^X;
my $blib_lib = File::Spec->catdir($root, 'blib', 'lib');
my $blib_arch = File::Spec->catdir($root, 'blib', 'arch');

my $command = join ' ',
    map { quotemeta($_) }
    ($perl, "-I$blib_lib", "-I$blib_arch", $bench,
     '--iterations=4', '--repeats=1');
my $output = `$command 2>&1`;
my $status = $?;

is($status, 0, 'TLS accept/setup benchmark succeeds');
like($output, qr/^fresh_context repeat=1 /m,
    'fresh per-connection TLS context row runs');
like($output, qr/^prepared_clone repeat=1 /m,
    'prepared Listener TLS context clone row runs');
like($output, qr/^Median TLS setup summary$/m,
    'benchmark prints its summary');
like($output, qr/No handshake is timed\./,
    'benchmark states the lifecycle boundary');

done_testing;
