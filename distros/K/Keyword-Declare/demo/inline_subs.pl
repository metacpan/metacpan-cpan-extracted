#! /usr/bin/env perl

use 5.014; use warnings;
use lib qw< dlib ../dlib >;

use Keyword::Declare;

keyword inline (Ident $name, List $raw_params, Block $code) {{{
    keyword <{$name}> (List $args) {
        my $code   = q[<{ substr($code, 1, -1) =~ s/^\s*return.*//gmr }>];
        my $cooked_params = q[<{$raw_params}>];
        $cooked_params =~ s/\s+//gr ne $args=~s/\s+//gr
            ? qq({ my $cooked_params = $args; $code })
            : $code;
    }

    sub <{$name}> {
        my <{$raw_params}> = @_;
        <{substr $code, 1, -1}>
    }
}}}


inline foo ($n,$count)
{
    $count += 1;
    if ($count % 1000 == 0) {
        $count += $n;
    }
    return $count;
}

use Time::HiRes 'time';

say 'Starting...';

my $count = 0;
my $start = time();
for my $n (1..10_000_000) {
    $count += 1;
    if ($count % 1000 == 0) {
        $count += $n;
    }
}
printf "Literal got $count in %.2fs\n", time()-$start;

$count = 0;
$start = time();
for my $n (1..100_000_00) {
    $count = main::foo($n,$count);
}
printf "Subcall got $count in %.2fs\n", time()-$start;

$count = 0;
$start = time();
for my $n (1..10_000_000) {
    foo($n,$count);
}
printf "Inlined got $count in %.2fs\n", time()-$start;
