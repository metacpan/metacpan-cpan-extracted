#! perl -T

use strict;
use warnings;

use Test::More;

use Config;
use Devel::FindPerl qw/find_perl_interpreter perl_is_same/;

my $perlpath = $Config{perlpath};
plan(skip_all => 'Taint test can\'t be run from uninstalled perl') if $ENV{PERL_CORE};
plan(skip_all => 'Taint test can\'t be run for relocatable perl') if $Config{userelocatableinc};
plan(skip_all => 'Taint test can\'t be run for Strawberry Portable') if $INC{"Portable/Config.pm"};
plan(skip_all => "Perl not in perlpath '$perlpath'") unless -x $perlpath and perl_is_same($perlpath);
plan(skip_all => 'Testrun without taint mode') if not $^T;

my $interpreter = do {
	local $SIG{__WARN__} = sub { fail("Got a warning during find_perl_interpreter") };
	find_perl_interpreter();
};
like($interpreter, qr/\Q$perlpath/, 'Always find $Config{perlpath} under tainting');

done_testing;
