use strict;
use warnings;
use FindBin qw($RealBin);
use Test::More;
use FASTX::ScriptHelper;
use File::Temp qw/ tempfile tempdir /;
use Data::Dumper;
BEGIN {

    eval {
        require File::Spec;
        Module->import( qw(devnull) );     # No need if you don't import any subroutines

        open STDERR, '>', File::Spec->devnull();
    };
}

#say STDERR "Requesting unpeneded temp file:";
my (undef, $log_filename) = tempfile('HELPERTEST_XXXXXXXX', OPEN => 0);
my %opt = (
  verbose => 1,
  logfile => "$log_filename",
  linesize => 10,
);
my $script = FASTX::ScriptHelper->new(\%opt);
isa_ok($script, "FASTX::ScriptHelper", "FASTX::ScriptHelper created");

ok(defined $script->{logfile}, "[Helper] log file defined: $script->{logfile}");

ok('ATT' eq $script->rc("AAT"), "[Helper] rev complementary done");
my $execution = $script->run('pwd', { candie => 1});
ok(defined $execution->{exit}, "[Run] Comand returned exit status");
ok(defined $execution->{stdout}, "[Run] Returned STDOUT");

unlink "$log_filename";
done_testing();
