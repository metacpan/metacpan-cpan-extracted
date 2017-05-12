use strict;
use warnings;
use Devel::ModuleDumper qw/showskip/;
use Test::More;
use Capture::Tiny qw/capture_stdout/;

require t::lib::Skip; # added $Devel::ModuleDumper::skips

my $stdout = capture_stdout { print Devel::ModuleDumper->show(); };

like $stdout, qr/^Perl\t\d+/;
like $stdout, qr/Test::More\t\d+/;
like $stdout, qr/Capture::Tiny\t\d+/;

unlike $stdout, qr/t::lib::Skip/;

if ($ENV{AUTHOR_TEST}) {
    note $stdout;
}

done_testing;
