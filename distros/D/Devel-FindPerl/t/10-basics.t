#! perl

use strict;
use warnings;

use Test::More;

use Config;
use IPC::Open2 'open2';
use Devel::FindPerl 'find_perl_interpreter';

my $perl = find_perl_interpreter;

diag("$perl is not $Config{perlpath}, this may or may not be problematic") if lc $perl ne lc $Config{perlpath} and not $ENV{PERL_CORE};

my $pid = open2(my($in, $out), $perl, qw/-MConfig=myconfig -e print -e myconfig/) or die "Could not start perl at $perl";
binmode $in, ':crlf' if $^O eq 'MSWin32';
my $ret = do { local $/; <$in> };
waitpid $pid, 0;
is(lc $ret, lc Config->myconfig, 'Config of found perl equals current perl');

done_testing;
