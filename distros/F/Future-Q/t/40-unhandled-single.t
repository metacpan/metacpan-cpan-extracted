use strict;
use warnings;
use Test::More;
use Future::Q;
use Try::Tiny;
use FindBin;
use lib ("$FindBin::Bin");
use testlib::Utils qw(newf init_warn_handler test_log_num);

init_warn_handler;

note('--- Reporting unhandled failure: OK/NG cases of single (non-chained) Futures');

my @cases = (
    ## ** OK cases
    {label => "not-complete", warn_num => 0, code => sub { newf; }},
    {label => "done", warn_num => 0, code => sub { newf()->done; }},
    {label => "canceled", warn_num => 0, code => sub { newf()->cancel; }},
    {label => "fulfilled", warn_num => 0, code => sub { newf()->fulfill; }},

    ####### ** NG cases
    {label => "failed", warn_num => 1, code => sub { newf()->fail("failure") }},
    {label => "died", warn_num => 1, code => sub { newf()->die("died") }},
    {label => "rejected", warn_num => 1, code => sub { newf()->reject("rejected") }},
);

foreach my $case (@cases) {
    note("--- -- try $case->{label}: expecting $case->{warn_num} warning");
    test_log_num($case->{code}, $case->{warn_num}, "$case->{label}: it should emit $case->{warn_num} warning");
}


done_testing();
