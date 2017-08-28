#!perl

use strict ("subs", "vars", "refs");
use warnings ("all");
BEGIN { $ENV{LIST_MOREUTILS_PP} = 1; }
END { delete $ENV{LIST_MOREUTILS_PP} } # for VMS
use lib ("t/lib");
use List::MoreUtils (":all");


use Test::More;
use Test::LMU;
use Tie::Array ();

SCOPE:
{
    my $lorem =
      "Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua. At vero eos et accusam et justo duo dolores et ea rebum. Stet clita kasd gubergren, no sea takimata sanctus est Lorem ipsum dolor sit amet. Lorem ipsum dolor sit amet, consetetur sadipscing elitr, sed diam nonumy eirmod tempor invidunt ut labore et dolore magna aliquyam erat, sed diam voluptua.";
    my @lorem = grep { $_ } split /(?:\b|\s)/, $lorem;

    my $n_comma = scalar(split /,/,      $lorem) - 1;
    my $n_dot   = scalar(split /\./,     $lorem);       # there is one at end ... mind the gap
    my $n_et    = scalar(split /\bet\b/, $lorem) - 1;

    my @l = @lorem;
    my @o = occurrences @l;

    is(undef, $o[0], "Each word is counted");
    is(undef, $o[1], "Text to long, each word is there at least twice");
    is_deeply([','],  $o[$n_comma], "$n_comma comma");
    is_deeply(['.'],  $o[$n_dot],   "$n_dot dots");
    is_deeply(['et'], $o[$n_et],    "$n_et words 'et'");

    @o = occurrences grep { /\w+/ } @lorem;
    my $wc = reduce_0 { defined $b ? $a + $_ * scalar @$b : $a } @o;
    is( $wc, 124, "Words are as many as requested at www.loremipsum.de" );
}

SCOPE:
{
    my @probes = ((1) x 3, (2) x 4, (3) x 2, (4) x 7, (5) x 2, (6) x 4);
    my $fp     = freeze(\@probes);
    my @o      = map { ref $_ ? [sort @$_] : $_ } occurrences @probes;
    is($fp, freeze(\@probes), "probes untouched");
    my @expectation = (undef, undef, [3, 5], [1], [2, 6], undef, undef, [4]);
    is_deeply(\@expectation, \@o, "occurrences of integer probes");
}

SCOPE:
{
    my @probes = ((1) x 3, undef, (2) x 4, undef, (3) x 2, undef, (4) x 7, undef, (5) x 2, undef, (6) x 4);
    my $fp     = freeze(\@probes);
    my @o      = map {
        ref $_
          ? [sort { (defined $a <=> defined $b) or $a <=> $b } @$_]
          : $_
    } occurrences @probes;
    is($fp, freeze(\@probes), "probes untouched");
    my @expectation = (undef, undef, [3, 5], [1], [2, 6], [undef], undef, [4]);
    is_deeply(\@expectation, \@o, "occurrences of integer probes");
}

leak_free_ok(
    occurrences => sub {
        my @probes = ((1) x 3, (2) x 4, (3) x 2, (4) x 7, (5) x 2, (6) x 4);
        my @o = occurrences @probes;
    },
    'scalar occurrences' => sub {
        my @probes = ((1) x 3, (2) x 4, (3) x 2, (4) x 7, (5) x 2, (6) x 4);
        my $o = occurrences @probes;
    }
);

leak_free_ok(
    'occurrences with exception in overloading stringify',
    sub {
        eval {
            my $obj    = DieOnStringify->new;
            my @probes = ((1) x 3, $obj, (2) x 4, $obj, (3) x 2, $obj, (4) x 7, $obj, (5) x 2, $obj, (6) x 4);
            my @o      = occurrences @probes;
        };
        eval {
            my $obj    = DieOnStringify->new;
            my @probes = ((1) x 3, $obj, (2) x 4, $obj, (3) x 2, $obj, (4) x 7, $obj, (5) x 2, $obj, (6) x 4);
            my $o      = occurrences @probes;
        };
    }
);

done_testing;


