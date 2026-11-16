#!/usr/bin/perl
use strict;
use warnings;

# ======================================================================
# t/NameCase-list.t - run the hand-written schema under make test.
#
# NameCase-list.yml covers NameCase([...]) at the top level and the
# NameCase('A', 'B') call shape in a transform, which extract-schemas cannot
# describe from the single documented arrayref parameter.  The extended fuzz
# test also runs it, but this file makes sure the schema is generated and
# exercised by a plain "make test".
# ======================================================================

use Test::Needs {
	'App::Test::Generator' => '0.43',
	'IPC::Run3' => 0,
	'Test::Most' => 0,
	'Test::Which' => 0,
};

use Test::Most;
use FindBin qw($Bin);
use File::Spec;
use IPC::Run3;
use Test::Which 'fuzz-harness-generator';

my $root = File::Spec->rel2abs(File::Spec->catdir($Bin, File::Spec->updir()));
my $schema = File::Spec->catfile($Bin, 'conf', 'NameCase-list.yml');

ok(-f $schema, 'the hand-written NameCase schema is present') or BAIL_OUT("cannot find $schema");

# The generated harness runs in a child process; make sure it loads the
# checkout under test rather than an installed copy of Lingua::EN::NameCase.
my @inc = grep { -d } map { File::Spec->catdir($root, split m{/}, $_) } qw(blib/lib lib);
local $ENV{PERL5LIB} = join(':', @inc, $ENV{PERL5LIB} // '');

my ($stdout, $stderr) = ('', '');
run3(['fuzz-harness-generator', '-r', $schema], \undef, \$stdout, \$stderr);
my $exit = $? >> 8;

is($exit, 0, 'fuzz-harness-generator generated and ran the schema')
	or diag("stdout:\n$stdout\nstderr:\n$stderr");
like($stdout, qr/^Result: PASS/m, 'the generated harness passed');

my ($tests) = $stdout =~ /Files=1, Tests=(\d+)/m;
cmp_ok($tests // 0, '>', 0, 'the generated harness ran at least one test');

done_testing();
