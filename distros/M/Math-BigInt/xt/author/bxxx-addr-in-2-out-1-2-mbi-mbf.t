# -*- mode: perl; -*-

use strict;
use warnings;

use Scalar::Util qw< refaddr >;
use Test::More;

use Math::BigFloat;

my @num = qw< 1 2.5 4 4.5 7.5 8 9 Inf >;
@num = ((map { "-$_" } reverse @num), 0, @num, "NaN");

my @methods = qw< bfdiv bfmod btdiv btmod >;

for my $method (@methods) {
    for my $context ('scalar', 'list') {
        for my $downgrade (undef, "Math::BigInt") {
            for my $upgrade (undef, "Math::BigFloat") {

                my $title = "\u$context context, ";

                if ($downgrade) {
                    if ($upgrade) {
                        $title .= "upgrading and downgrading";
                    } else {
                        $title .= "downgrading, but no upgrading";
                    }
                } else {
                    if ($upgrade) {
                        $title .= "upgrading, but no downgrading"
                    } else {
                        $title .= "no upgrading or downgrading";
                    }
                }

                for my $xclass ("Math::BigInt", "Math::BigFloat") {
                    for my $yclass ("Math::BigInt", "Math::BigFloat", "") {
                        for my $xs (@num) {
                            for my $ys (@num) {

                                # Set default upgrading and downgrading.

                                my $test;
                                $test .= 'Math::BigInt -> upgrade(undef);';
                                $test .= ' Math::BigFloat -> downgrade(undef);';

                                # Append constructors.

                                $test .= qq| \$x = $xclass -> new("$xs");|;

                                if ($yclass) {
                                    $test .= qq| \$y = $yclass -> new("$ys");|
                                } else {
                                    $test .= $ys =~ /^\+?inf$/i ? qq| \$y = 1e99**1e99;|
                                          :  $ys =~ /^\-inf$/i  ? qq| \$y = -(1e99**1e99);|
                                          :  $ys =~ /^nan$/i    ? qq| \$y = (1e99**1e99)-(1e99**1e99);|
                                          :                       qq| \$y = $ys;|;
                                }

                                # Get address.

                                $test .= ' $xa = refaddr($x);';

                                # Append upgrading and downgrading, if applicable.

                                $test .= qq| Math::BigInt -> upgrade("$upgrade");|       if $upgrade;
                                $test .= qq| Math::BigFloat -> downgrade("$downgrade");| if $downgrade;

                                # Apply method call.

                                $test .= $context eq 'list' ? q| ($q, $r)| : q| $q|;
                                $test .= qq| = \$x -> $method(\$y);|;

                                # Wrap test into a one-liner, which is displayed
                                # before the test is run.

                                my $note;
                                $note .= q|perl -Ilib -MMath::BigFloat -MScalar::Util=refaddr -wle '|;
                                $note .= $test;
                                $note .= q|'|;

                                note "\n", $note, "\n\n";

                                subtest $test => sub {
                                    my ($x, $xa, $y, $q, $r);
                                    eval $test;
                                    is($@, '', '$@ is empty');
                                    is($xa, refaddr($q), 'refaddr($x) = refaddr($q)');
                                };
                            }
                        }
                    }
                }
            }
        }
    }
}

done_testing();
