#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 21209;

use_ok('Math::Vector::Real::kdTree');

use Sort::Key::Top qw(nhead);
use Math::Vector::Real;
use Math::Vector::Real::Test qw(eq_vector);

sub find_in_ball_bruteforce {
    my ($vs, $ix, $d) = @_;
    my $d2 = $d * $d;
    grep { $ix <=> $_ and $vs->[$ix]->dist2($vs->[$_]) <= $d2 } 0..$#$vs;
}

sub nearest_vectors_bruteforce {
    my ($bottom, $top) = Math::Vector::Real->box(@_);
    my $box = $top - $bottom;
    my $v = [map $_ - $bottom, @_];
    my $ixs = [0..$#_];
    my $dist2 = [($box->abs2 * 10 + 1) x @_];
    my $neighbors = [(undef) x @_];
    _nearest_vectors_bruteforce($v, $ixs, $dist2, $neighbors, $box, 0);
    return @$neighbors;
}

sub _nearest_vectors_bruteforce {
    my ($v, $ixs, $dist2, $neighbors) = @_;
    my $ixix = 0;
    for my $i (@$ixs) {
        $ixix++;
        my $v0 = $v->[$i];
        for my $j (@$ixs[$ixix..$#$ixs]) {
            my $d2 = $v0->dist2($v->[$j]);
            if ($dist2->[$i] > $d2) {
                $dist2->[$i] = $d2;
                $neighbors->[$i] = $j;
            }
            if ($dist2->[$j] > $d2) {
                $dist2->[$j] = $d2;
                $neighbors->[$j] = $i;
            }
        }
    }
}

sub farthest_vectors_bruteforce {
    my @best_ix;
    my @best_d2 = ((-1) x @_);
    for my $i (1..$#_) {
        my $v = $_[$i];
        for my $j (0..$i - 1) {
            my $d2 = Math::Vector::Real::dist2($v, $_[$j]);
            if ($d2 > $best_d2[$i]) {
                $best_d2[$i] = $d2;
                $best_ix[$i] = $j;
            }
            if ($d2 > $best_d2[$j]) {
                $best_d2[$j] = $d2;
                $best_ix[$j] = $i;
            }
        }
    }
    return @best_ix;
}

sub find_two_nearest_vectors_bruteforce {
    my @best_ix = (undef, undef);
    my $best_d2 = 'inf' + 0;
    for my $i (1..$#_) {
        my $v = $_[$i];
        for my $j (0..$i - 1) {
            my $d2 = Math::Vector::Real::dist2($v, $_[$j]);
            if ($d2 < $best_d2) {
                $best_d2 = $d2;
                @best_ix = ($i, $j);
            }
        }
    }
    (@best_ix, sqrt($best_d2))
}

sub test_neighbors {
    unshift @_, $_[0];
    goto &test_neighbors_indirect;
}

sub test_neighbors_indirect {
    my ($o1, $o2, $n1, $n2, $msg) = @_;
    my (@d1, @d2);
    for my $ix (0..$#$o1) {
        my $eo   = $o1->[$ix];
        my $ixn1 = $n1->[$ix];
        defined $ixn1 or do {
            fail($msg);
            diag("expected index for element $ix is undefined");
            goto break_me;
        };
        my $ixn2 = $n2->[$ix];
        defined $ixn2 or do {
            fail($msg);
            diag("template index for element $ix is undefined");
            goto break_me;
        };
        $ixn1 < @$o2 or do {
            fail($msg);
            diag("expected index $ixn1 out of range");
            goto break_me;
        };
        $ixn2 < @$o2 or do {
            fail($msg);
            diag("template index $ixn1 out of range");
            goto break_me;
        };
        my $en1 = $o2->[$ixn1];
        my $en2  = $o2->[$ixn2];
        push @d1, $eo->dist2($en1);
        push @d2, $eo->dist2($en2);
    }
    is "@d1", "@d2", $msg and return 1;

 break_me:
    diag "break me!";
    0;
}

my %gen = ( num => sub { rand },
            int => sub { int rand(10) } );


#srand 318275924;
diag "srand: " . srand;
for my $g (keys %gen) {
    for my $d (1, 2, 3, 10) {
        for my $n (2, 10, 50, 250, 500) {
        # for my $n ((2) x 100) {
            my $id = "gen: $g, d: $d, n: $n";
            my @o = map V(map $gen{$g}->(), 1..$d), 1..$n;
            my @nbf = nearest_vectors_bruteforce(@o);

            my $t = Math::Vector::Real::kdTree->new(@o);

            my @n = map scalar($t->find_nearest_vector_internal($_)), 0..$#o;
            is ($#n, $#o, "count find_nearest_vector_internal - build - $id");
            test_neighbors(\@o, \@n, \@nbf, "find_nearest_vector_internal - build - $id");
            is_deeply([map $t->at($_), 0..$#o], \@o , "at - build - after find_nearest_vector_internal - $id");

            @n = $t->find_nearest_vector_all_internal;
            is ($#n, $#o, "count find_nearest_vector_all_internal - build - $id");
            test_neighbors(\@o, \@n, \@nbf, "find_nearest_vector_all_internal - build - $id");
            is_deeply([map $t->at($_), 0..$#o], \@o , "at - build - after find_nearest_vector_all_internal - $id");

            $t = Math::Vector::Real::kdTree->new;
            for my $ix (0..$#o) {
                $t->insert($o[$ix]);
                my @obp = $t->ordered_by_proximity;
                is ($ix, $#obp, "ordered_by_proxymity - count - $id, ix: $ix");
            }
            is_deeply([map $t->at($_), 0..$#o], \@o , "at - insert - after insert - $id");

            @n = map scalar($t->find_nearest_vector_internal($_)), 0..$#o;
            test_neighbors(\@o, \@n, \@nbf, "find_nearest_vector_internal - insert - $id");
            is_deeply([map $t->at($_), 0..$#o], \@o , "at - insert - after find_nearest_vector_internal - $id");

            @n = $t->find_nearest_vector_all_internal;
            test_neighbors(\@o, \@n, \@nbf, "find_nearest_vector_all_internal - insert - $id");
            is_deeply([map $t->at($_), 0..$#o], \@o , "at - insert - after find_nearest_vector_all_internal - $id");

            my @fbf = farthest_vectors_bruteforce(@o);
            @n = map scalar($t->find_farthest_vector_internal($_)), 0..$#o;
            test_neighbors(\@o, \@n, \@fbf, "find_farthest_vector_internal - insert - $id");
            is_deeply([map $t->at($_), 0..$#o], \@o , "at - insert - after find_farthest_vector_internal - $id");

            my ($b1, $b2, $min_d2) = $t->find_two_nearest_vectors;
            my ($b1bf, $b2bf, $min_d2_bf) = find_two_nearest_vectors_bruteforce(@o);
            is($min_d2, $min_d2_bf, "nearest_two_vectors") or do {
                diag "values differ: $min_d2 $min_d2_bf best: $b1, $b2, best_bf: $b1bf, $b2bf\n";
                diag $t->dump_to_string(pole_id => 1, remark => [$b1, $b2, $b1bf, $b2bf]);
            };

            my %seed_errs = (k_means_seed => [1], k_means_seed_pp => [1, 0.9, 0.5]);

            my $k;
            for ($k = 1; $k < @n; $k *= 2) {
                for my $seed_method (qw(k_means_seed)) { # k_means_seed_pp)) {
                    for my $err (@{$seed_errs{$seed_method}}) {
                        no warnings 'once';
                        local $Math::Vector::Real::kdTree::k_means_seed_pp_test = sub {
                            my ($t, $err, $kmvs, $ws) = @_;
                            # use Data::Dumper;
                            # diag Dumper $ws;
                            # diag Dumper $kmvs;
                            my @error;
                            for my $ix (0..$#o) {
                                my $w = nhead map { $o[$ix]->dist2($_) } @$kmvs;
                                # diag "checking element $ix, o: $o[$ix] ws: $ws->[$ix], w: $w";
                                if ($ws->[$ix] + 0.0001 < $w * $err or $ws->[$ix] * $err > $w + 0.0001) {
                                    push @error, "weight calculation failed for ix $ix: precise: $w, estimated: $ws->[$ix], err: $err"
                                }
                            }
                            ok(@error == 0, "k_means_seed_pp_test, k: $k, err: $err, $id");
                            diag $_ for @error;
                        };

                        my @kms = $t->$seed_method($k, $err);
                        my $k_gen = scalar(@kms);
                        if ($seed_method eq 'k_means_seed') {
                            is ($k_gen, $k, "$seed_method generates $k results - err: $err, $id");
                        }
                        else {
                            ok(1, "keep number of tests unchanged") for $k_gen..$k-1;
                            ok($k_gen >= 1,  "$seed_method generates at least one result");
                            ok($k_gen <= $k, "$seed_method generates $k or less results");
                        }
                        my @km = $t->k_means_loop(@kms);
                        is (scalar(@km), $k_gen, "k_means_loop generates $k_gen results - err: $err, $id")
                            or do {
                                diag "break me 2";
                            };
                        my @kma = $t->k_means_assign(@km);
                        my $t1 = Math::Vector::Real::kdTree->new(@km);
                        my @n = map scalar($t1->find_nearest_vector($_)), @o;
                        test_neighbors_indirect(\@o, \@km, \@kma, \@n, "k_means_assign - err: $err, k: $k, $id");

                        my @sum = map V((0) x $d), 1..$k_gen;
                        my @count = ((0) x $k_gen);

                        for my $ix (0..$#kma) {
                            my $cluster = $kma[$ix];
                            $count[$cluster]++;
                            $sum[$cluster] += $o[$ix];
                        }
                        for my $cluster (0..$#sum) {
                            if ($count[$cluster]) {
                                $sum[$cluster] /= $count[$cluster];
                            }
                            else {
                                $sum[$cluster] = $km[$cluster];
                            }

                            eq_vector($sum[$cluster], $km[$cluster], "cluster centroid - $cluster - k: $k, $id");
                        }
                        ok (1, "keep number of tests unchanged") for $#sum..$k-1;
                    }
                }
            }

            for my $ix (0..$#o) {
                my $r = 0.0001 + rand(1);
                my @bix = sort { $a <=> $b } $t->find_in_ball($o[$ix], $r, $ix);
                my @bixbf = find_in_ball_bruteforce(\@o, $ix, $r);

                is_deeply (\@bix, \@bixbf, "find_in_ball - $ix - $id") or
                    do {;
                        diag "break me 3";
                    }
            }
        }
    }
}
