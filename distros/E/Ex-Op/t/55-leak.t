#!perl
use 5.010;
use strict;
use warnings;
use Test::More;
use Ex::Op ();

sub rss {
    my $kb = `ps -o rss= -p $$ 2>/dev/null`;
    return $kb =~ /(\d+)/ ? $1 : undef;
}
plan skip_all => 'needs ps to read the process size' unless defined rss();

BEGIN {
    Ex::Op::make(add  => sub { my ($x, $y) = @_; $x + $y });
    Ex::Op::make(lst  => sub { my ($x) = @_; ($x, [$x], "$x") });
    Ex::Op::make(boom => sub { my ($x) = @_; die "boom\n" if $x; [$x] });
    Ex::Op::make(ret  => sub { my ($x) = @_; return { k => $x } });
}

sub churn {
    my ($n) = @_;
    my $s = 0;
    for my $i (1 .. $n) {
        $s = add($s, 1);
        my @l = lst($i);
        my $r = ret($i);
        eval { boom($i % 100 == 0) };
    }
    return $s;
}

churn(20_000);
my $before = rss();
churn(200_000);
my $mid = rss();
churn(200_000);
my $after = rss();

note "rss: $before kB, then $mid kB, then $after kB";
cmp_ok( $after - $mid, '<', 2048, 'a second 200,000 calls of each kind (2,000 dies) grows the process by less than 2 MB' );

done_testing;
