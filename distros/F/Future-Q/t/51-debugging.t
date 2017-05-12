use strict;
use warnings;
BEGIN {
    $ENV{PERL_FUTURE_DEBUG} = 1;
}
use Future::Q;
use Test::More;

my @warns = ();

$SIG{__WARN__} = sub { push @warns, shift };

{
    my $f = Future::Q->new;
}

cmp_ok scalar(grep { qr/constructed.+lost/ } @warns), ">", 0, "at least 1 warning for non-ready Future destroyed.";
note("captured warn: $_") foreach @warns;

done_testing;

