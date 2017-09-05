# From: http://search.cpan.org/~bdfoy/Test-Prereq-2.002/lib/Test/Prereq.pm#SYNOPSIS

use Test::More;
eval "use Test::Prereq";

my $msg;
if ($@) {
    $msg = 'Test::Prereq::Build required to test dependencies';
} elsif (not $ENV{TEST_AUTHOR}) {
    $msg = 'Author test.  Set $ENV{TEST_AUTHOR} to a true value to run.';
}

plan skip_all => $msg if $msg;
prereq_ok();
