use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use FASTX::ScriptHelper;
use File::Temp qw/ tempfile tempdir /;
use Data::Dumper;
use File::Spec;
open STDERR, '>', File::Spec->devnull();

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

my $cpus = $script->cpu_count();
ok($cpus > 0, "CPUs found: $cpus > 0");
eval {
  $script->writelog('Log message');
};
ok($@ eq '', "Log written without errors to $log_filename: $@");

do {
    local *STDOUT;

    # redirect STDOUT to log.txt
    open (STDOUT, '>>', '/dev/null');
    eval {
      $script->fu_printfasta('Test', undef, 'CAGATA');
      $script->fu_printfasta('Test',undef, 'CAGATA', 'IIIIII');
    };
    ok($@ eq '', "Sequences printed to /dev/null $@");

};

unlink "$log_filename";
done_testing();
