#!perl

use 5.010001;
use strict;
use warnings;

use Test::More;
use Test::Exception;
use Language::Expr;
use POSIX;
use lib "./t";
require "stdtests.pl";

my $itp = Language::Expr->new->get_interpreter('default');
$itp->vars(stdvars());

$itp->funcs({
    'floor'  => sub { POSIX::floor(shift) },
    'ceil'   => sub { POSIX::ceil(shift) },
    # uc
    # length
});

for my $t (stdtests()) {
    # currently interpreter doesn't support subexpr yet
    next if $t->{has_subexpr};

    my $tname = "category=$t->{category} $t->{text}";
    if ($t->{parse_error}) {
        $tname .= ", parse error: $t->{parse_error})";
        throws_ok { $itp->eval($t->{text}) } $t->{parse_error}, $tname;
    } else {
        if ($t->{run_error}) {
            $tname .= ", run error: $t->{run_error})";
            throws_ok { $itp->eval($t->{text}) } $t->{run_error}, $tname;
        } elsif ($t->{itp_run_error}) {
            $tname .= ", run error: $t->{itp_run_error})";
            throws_ok { $itp->eval($t->{text}) } $t->{itp_run_error}, $tname;
        } else {
            $tname .= ")";
            is_deeply( $itp->eval($t->{text}), $t->{result}, $tname );
        }
    }
}

DONE_TESTING:
done_testing;
