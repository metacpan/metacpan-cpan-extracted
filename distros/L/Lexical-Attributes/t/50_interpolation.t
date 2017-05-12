#!/usr/bin/perl -s

use strict;
use warnings;
use Test::More tests => 83;

BEGIN {
    if (-d 't') {
        chdir 't' or die "Failed to chdir: $!\n";
    }

    unshift @INC => ".";

    unless (grep {m!"blib/lib"!} @INC) {
        push @INC => grep {-d} "blib/lib", "../blib/lib"
    }

    use_ok ('Interpolation');
}

ok (defined $Lexical::Attributes::VERSION &&
            $Lexical::Attributes::VERSION > 0, '$VERSION');

my $N = 3;
my @obj;

foreach my $i (0 .. $N - 1) {
    $obj [$i] = Interpolation -> new;
    isa_ok ($obj [$i], "Interpolation");
}

foreach my $i (0 .. $N - 1) {
    $obj [$i] -> set_scalar ("key-$i");
    $obj [$i] -> set_scalar2 ("key2-$i");
    $obj [$i] -> set_array ([map {"key-$i-$_"} 0 .. $i + 1]);
    $obj [$i] -> set_hash ({map {;"key-$i-$_" => "val-$i-$_"} 0 .. $i + 1});
}
foreach my $i (0 .. $N - 1) {
    my @a = $obj [$i] -> array;
    my @b = map {"key-$i-$_"} 0 .. $i + 1;
    my %a = $obj [$i] -> hash;
    my %b = map {;"key-$i-$_" => "val-$i-$_"} 0 .. $i + 1;
    is ($obj [$i] -> scalar, "key-$i", "scalar ($i)");
    is ($obj [$i] -> scalar2, "key2-$i", "scalar2 ($i)");
    is_deeply (\@a, \@b, "array ($i)");
    is_deeply (\%a, \%b, "hash ($i)");
}
foreach my $i (0 .. $N - 1) {
    my @b = map {"key-$i-$_"} 0 .. $i + 1;
    my $b = "This is [@b]";
    my $c = sprintf "There are %d elements in %s", $#b, "[@b]";
    is ($obj [$i] -> scalar_as_string, "This is 'key-$i'",
                    "scalar interpolation ($i)");
    is ($obj [$i] -> scalar_single_quotes, 'This is "$.scalar"',
                    "scalar single quotes ($i)");
    is ($obj [$i] -> array_as_string, $b, "array_interpolation ($i)");
    is ($obj [$i] -> array_single_quotes, 'This is [@.array]',
                    "array single quotes ($i)");
    is ($obj [$i] -> count_array, $c, "\$# interpolation ($i)");
    is ($obj [$i] -> hash_as_string, "This is {%.hash}",
                    "hash interpolation ($i)");
}
foreach my $i (0 .. $N - 1) {
    my @a = $obj [$i] -> more_scalar_quotes;
    my @b = ("This is 'key-$i'", qq {This is "key-$i"}, "This is 'key-$i'",
             "This is 'key-$i'", qq {This is "key-$i"}, "This is 'key-$i'",
          q {This is '$.scalar'}, 'This is "$.scalar"', q {This is '$.scalar'},
          q {This is '$.scalar'}, 'This is "$.scalar"', q {This is '$.scalar'});
    is_deeply (\@a, \@b, "More quotes ($i)");
}
foreach my $i (0 .. $N - 1) {
    my $a = $obj [$i] -> double_interpolate;
    my $b = "This is 'key-$i' and that is 'key2-$i'";
    my $c = $obj [$i] -> with_normal_vars ("var-$i");
    my $d = "This is 'var-$i' and 'key-$i' as well";
    is ($a, $b, "Double interpolate ($i)");
    is ($c, $d, "Normal vars as well ($i)");
}
foreach my $i (0 .. $N - 1) {
    my @a = $obj [$i] -> escaped;
    my @b = ("This is 'key-$i' and that is '\$.scalar2'",
             "This is '\\key-$i' and that is '\\\$.scalar2'",);
    is_deeply (\@a, \@b, "Escaped interpolation ($i)");
}
foreach my $i (0 .. $N - 1) {
    foreach my $j (0 .. $i + 1) {
        my $a = $obj [$i] -> array_index ($j);
        my $b = "This is array element 'key-$i-$j' on index '$j'";
        my $c = $obj [$i] -> hash_index ("key-$i-$j");
        my $d = "This is hash element 'val-$i-$j' on index 'key-$i-$j'";
        is ($a, $b, "Array index ($i, $j)");
        is ($c, $d, "Hash index ($i, $j)");
    }
}
foreach my $i (0 .. $N - 1) {
    foreach my $j (0 .. $i + 1) {
        $obj [$i] -> set_a_index ($j);
        $obj [$i] -> set_h_index ("key-$i-$j");
        my $a = $obj [$i] -> array_a_index;
        my $b = "This is 'key-$i-$j'";
        my $c = $obj [$i] -> hash_h_index;
        my $d = "This is 'val-$i-$j'";
        is ($a, $b, "Array a_index ($i, $j)");
        is ($c, $d, "Hash h_index ($i, $j)");
    }
}

__END__
