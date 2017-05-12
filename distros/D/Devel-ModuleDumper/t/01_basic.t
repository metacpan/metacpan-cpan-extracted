use strict;
use warnings;
use Devel::ModuleDumper;
use Test::More;
use Capture::Tiny qw/capture_stdout/;

my $stdout = capture_stdout { print Devel::ModuleDumper->show(); };

like $stdout, qr/^Perl\t\d+/;
like $stdout, qr/Test::More\t\d+/;
like $stdout, qr/Capture::Tiny\t\d+/;

if ($ENV{AUTHOR_TEST}) {
    note $stdout;
}

done_testing;
