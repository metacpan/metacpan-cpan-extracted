use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use FASTX::ScriptHelper;
use File::Temp qw/ tempfile tempdir /;
use Data::Dumper;
say STDERR "Requesting unpeneded temp file:";
my (undef, $log_filename) = tempfile('HELPERTEST_XXXXXXXX', OPEN => 0);

my %opt = (
  verbose => 1,
  logfile => "$log_filename",
  linesize => 10,
);

my $script = FASTX::ScriptHelper->new(\%opt);

$opt{'invalid'} = 1;
eval {
	my $s2 =  FASTX::ScriptHelper->new(\%opt);
};
ok($@, 'Invalid option: Error managed');

$script->fu_printfasta('Test', undef, 'CAGATA');
$script->fu_printfasta('Test',undef, 'CAGATA', 'IIIIII');

done_testing();
