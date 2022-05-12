use Test2::Tools::Compare 'float';
use Test2::V0;

use Math::DCT ':all';

my $M_PI  = 3.14159265358979323846;

foreach my $sz (qw/3 4 8 11 32 64/) {
    my (@array, @array2d, @array2d_fl);
    foreach my $x (1..$sz) {
        @array = map { rand(256) } ( 1..$sz );
        push @array2d_fl, @array;
        push @array2d, [@array];
    }
    my $exp = naive_perl_dct1d(\@array);
    subtest "Size $sz 1D array" => sub {
        compare_arrays($exp, dct1d(\@array));
        compare_arrays($exp, @{dct([\@array])});
    };
    subtest "Size $sz 1D iDCT" => sub {
        compare_arrays(\@array, idct1d($exp), 1e-4);
    };
    $exp = naive_perl_dct2d(\@array2d);
    subtest "Size $sz".'x'."$sz 2D array" => sub {
        compare_arrays($exp, dct2d(\@array2d_fl));
        compare_arrays($exp, dct([@array2d]));
    };
    subtest "Size $sz 2D iDCT" => sub {
        compare_arrays(\@array2d_fl, idct2d(flat_array($exp)), 1e-4);
    };
}

done_testing();

sub compare_arrays {
    my ($ref, $check, $tolerance) = @_;
    $tolerance ||= 1e-8;
    $ref   = flat_array($ref)   if ref $ref->[0]   eq 'ARRAY';
    $check = flat_array($check) if ref $check->[0] eq 'ARRAY';
    my $sz = scalar @$ref;
    is(
        $ref->[$_],
        float($check->[$_], tolerance => $tolerance),
        "Array item ".($_+1)." of $sz matches."
    )
        foreach (0..$sz-1);
}

sub flat_array {
    my $array = shift;
    my @flat;
    push(@flat, @$_) foreach @$array;
    return \@flat;
}

sub naive_perl_dct1d {
    my $vector = shift;
    my $factor = $M_PI/scalar(@$vector);
    my @result;

    for (my $i = 0; $i < scalar(@$vector); $i++) {
        my $sum = 0;
        for (my $j = 0; $j < scalar(@$vector); $j++) {
            $sum += $vector->[$j] * cos(($j+0.5)*$i*$factor);
        }
        push @result, $sum;
    }
    return \@result;
}

sub naive_perl_dct2d {
    my $vector = shift;
    my $N      = scalar(@$vector);
    my $fact   = $M_PI/$N;
    my ($temp, $result);

    for (my $x = 0; $x < $N; $x++) {
        for (my $i = 0; $i < $N; $i++) {
            my $sum = 0;
            for (my $j = 0; $j < $N; $j++) {
                $sum += $vector->[$x]->[$j] * cos(($j+0.5)*$i*$fact);
            }
            $temp->[$x]->[$i] = $sum;
        }
    }

    for (my $y = 0; $y < $N; $y++) {
        for (my $i = 0; $i < $N; $i++) {
            my $sum = 0;
            for (my $j = 0; $j < $N; $j++) {
                $sum += $temp->[$j]->[$y] * cos(($j+0.5)*$i*$fact);
            }
            $result->[$i]->[$y] = $sum;
        }
    }
    return $result;
}
