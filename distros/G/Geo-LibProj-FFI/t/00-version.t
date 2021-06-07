#!perl
use strict;
use warnings;

use Test::More;

plan tests => 1;

use Alien::proj;
use File::Spec;
use IPC::Run3 qw(run3);


my $bin = File::Spec->catdir(Alien::proj->dist_dir, 'bin', 'cs2cs');

my $out = '';
eval {
	run3 [ $bin ], \undef, \$out, \$out;
};

my ($eval_err, $os_err, $code) = ($@, $!, $?);
my ($status, $signal) = ($code >> 8, $code & 0x7f);
if ($code || $os_err && $code == -1 || $eval_err) {
	diag "cs2cs got an error:";
	diag "eval: $eval_err" if $eval_err;
	diag "\$!: $os_err" if $code == -1 || $code == 0xff00;
	$code = sprintf "0x%04x (status %d, signal %d)", $code, $status, $signal if $code > 0;
	diag "\$?: $code" if $code;
}

my ($version) = $out =~ m/\b(\d+\.\d+(?:\.\d\w*)?)\b/;
diag "Alien::proj $Alien::proj::VERSION providing PROJ $version" if $version;

# need to run at least one test
pass;

done_testing;
