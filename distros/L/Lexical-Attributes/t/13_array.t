#!/usr/bin/perl -s

use strict;
use warnings;
use Test::More tests => 338;

use constant N    =>  5;
use constant KEYS =>  9;

BEGIN {
    if (-d 't') {
        chdir 't' or die "Failed to chdir: $!\n";
    }

    unshift @INC => ".";

    unless (grep {m!"blib/lib"!} @INC) {
        push @INC => grep {-d} "blib/lib", "../blib/lib"
    }

    use_ok ('Array');
}

ok (defined $Lexical::Attributes::VERSION &&
            $Lexical::Attributes::VERSION > 0, '$VERSION');


#
# Check whether methods were created (or not).
#

{
    no strict 'refs';
    for my $k (qw /default pr priv/) {
        ok (!defined &{"Array::a_${k}"},     "!defined &Array::a_${k}");
        ok (!defined &{"Array::set_a_${k}"}, "!defined &Array::set_a_${k}");
    }
    for my $k (qw /ro/) {
        ok ( defined &{"Array::a_${k}"},     " defined &Array::a_${k}");
        ok (!defined &{"Array::set_a_${k}"}, "!defined &Array::set_a_${k}");
    }
    for my $k (qw /rw/) {
        ok ( defined &{"Array::a_${k}"},     " defined &Array::a_${k}");
        ok ( defined &{"Array::set_a_${k}"}, " defined &Array::set_a_${k}");
    }
}


ok ( defined &Array::array,       " defined &Array::array");
ok ( defined &Array::set_array,   " defined &Array::set_array");
ok (!defined &Array::unused,      "!defined &Array::unused");
ok (!defined &Array::set_unused,  "!defined &Array::set_unused");


#
# Can we create objects?
#
my @obj;
for (0 .. N - 1) {
    $obj [$_] = Array -> new;
    isa_ok ($obj [$_], "Array");
}

for my $i (0 .. N - 2) {
    for my $j ($i + 1 .. N - 1) {
        ok $obj [$i] ne $obj [$j], "Different objects ($i, $j)";
    }
}

#
# Data to use
#

my @data;
for my $i (0 .. N - 1) {
    $data [$i] {reference} = [map {"val- ref-$_"} 0 .. $i * 2];
    $data [$i] {index}     = [map {"val-ind1-$_"} 0 .. $i * 2];
    $data [$i] {index2}    = [map {"val-ind2-$_"} 0 .. $i * 2];
    $data [$i] {rw}        = [map {"val- rw -$_"} 0 .. $i * 2];
    $data [$i] {ro}        = [map {"val- ro -$_"} 0 .. $i * 2];
    $data [$i] {pr}        = [map {"val- pr -$_"} 0 .. $i * 2];
    $data [$i] {priv}      = [map {"val-priv-$_"} 0 .. $i * 2];
    $data [$i] {default}   = [map {"val- def-$_"} 0 .. $i * 2];
    $data [$i] {push}      = [map {"val-push-$_"} 0 .. $i * 2];
    $data [$i] {unshift}   = [map {"val-unsh-$_"} 0 .. $i * 2];
    $data [$i] {splice}    = [map {"val-splc-$_"} 0 .. $i * 3];
}

#
# Set ro/pr/priv/default values by other means.
#
for my $i (0 .. N - 1) {
    $obj [$i] ->    set_a_rw     ([@{$data [$i] {rw}}]);
    $obj [$i] -> my_set_a_ro      (@{$data [$i] {ro}});
    $obj [$i] -> my_set_a_pr      (@{$data [$i] {pr}});
    $obj [$i] -> my_set_a_priv    (@{$data [$i] {priv}});
    $obj [$i] -> my_set_a_default (@{$data [$i] {default}});
}

#
# Query empty array
#
for my $i (0 .. N - 1) {
    my @a = $obj [$i] -> reference;
    my @b;
    is_deeply \@a, \@b, "Empty array";

    my $a = $obj [$i] -> reference;
    my $b = 0;
    is $a, $b, "Empty array (scalar)";

    my $c = $obj [$i] -> reference (0);
    my $d;
    is $c, $d, "Empty array (index)";

    my @e = $obj [$i] -> reference (1, 2);
    my @f = (undef, undef);
    is_deeply \@e, \@f, "Empty array (slice)";
}


for my $i (0 .. N - 1) {
    for my $f (qw /rw ro/) {
        my $method = "a_$f";

        my @a = $obj [$i] -> $method;
        my @b = @{$data [$i] {$f}};
        is_deeply \@a, \@b, "$f return value ($i)";

        my $a = $obj [$i] -> $method;
        my $b = @{$data [$i] {$f}};
        is $a, $b, "$f scalar return value ($i)";

        for my $j (0 .. 2 * $i) {
            my $a = $obj [$i] -> $method ($j);
            my $b = ${$data [$i] {$f}} [$j];
            is $a, $b, "$f by index ($i, $j)";
        }

        # Slice.
        my @i = map {$_ * 2} 0 .. $i;
        my @c = $obj [$i] -> $method (@i);
        my @d = @{$data [$i] {$f}} [@i];
        is_deeply \@c, \@d, "$f slice return value ($i)";
    }

    for my $f (qw /pr priv default/) {
        my $method = "my_get_a_$f";

        my @c = $obj [$i] -> $method;
        my @d = @{$data [$i] {$f}};
        is_deeply \@c, \@d, "$f return value ($i)";
    }

}


#
# Test rw functions.
#

for my $i (0 .. N - 1) {
    $obj [$i] -> set_reference ($data [$i] {reference});
    # Index by index.
    for my $j (0 .. $i * 2) {
        $obj [$i] -> set_index ($j, $data [$i] {index} [$j]);
    }
    # Complete set
    $obj [$i] -> set_index2 (map {$_ => $data [$i] {index2} [$_]} 0 .. $i * 2);
}
for my $i (0 .. N - 1) {
    # Get complete arrays.
    my @a = $obj [$i] -> reference;
    my @b = @{$data [$i] {reference}};
    is_deeply \@a, \@b, "'reference' return value ($i)";

    my $a = $obj [$i] -> reference;
    my $b = @{$data [$i] {reference}};
    is $a, $b, "'reference' scalar return value ($i)";

    my @c = $obj [$i] -> index;
    my @d = @{$data [$i] {index}};
    is_deeply \@c, \@d, "'index' return value ($i)";

    my $c = $obj [$i] -> index;
    my $d = @{$data [$i] {index}};
    is $c, $d, "'index' scalar return value ($i)";

    my @i = $obj [$i] -> index2;
    my @j = @{$data [$i] {index2}};
    is_deeply \@i, \@j, "'index2' return value ($i)";

    my $I = $obj [$i] -> index2;
    my $j = @{$data [$i] {index2}};
    is $I, $j, "'index2' scalar return value ($i)";

    # Get elements.
    for my $j (0 .. $i) {
        my $a = $obj [$i] -> reference ($j);
        my $b = $data [$i] {reference} [$j];
        is $a, $b, "'reference ($j)' return value ($i)";

        my $c = $obj [$i] -> index ($j);
        my $d = $data [$i] {index} [$j];
        is $c, $d, "'index ($j)' return value ($i)";
    }

    # Get slices.
    my @e = $obj [$i] -> reference (map {$_ * 2} 0 .. $i);
    my @f = @{$data [$i] {reference}} [map {$_ * 2} 0 .. $i];
    is_deeply \@e, \@f, "'reference' (slice) return value ($i)";

    my @g = $obj [$i] -> index (map {$_ * 2} 0 .. $i);
    my @h = @{$data [$i] {index}} [map {$_ * 2} 0 .. $i];
    is_deeply \@g, \@h, "'index' (slice) return value ($i)";

}

# Overwrite values.
for my $i (0 .. N - 1) {
    for my $k (0 .. $i) {
        my $j = $k * 2;
        $obj [$i] -> set_index ($j, $data [$i] {index2} [$j]);
    }
}
for my $i (0 .. N - 1) {
    for my $j (0 .. $i * 2) {
        my $a = $obj [$i] -> index ($j);
        my $b = $data [$i] {$j % 2 ? "index" : "index2"} [$j];
        is $a, $b, "'index2 ($j) return value ($i)";
    }
}

# Clear array.
for my $i (0 .. N - 1) {
    $obj [$i] -> set_reference;
}
for my $i (0 .. N - 1) {
    my @a = $obj [$i] -> reference;
    my @b = ();
    is_deeply \@a, \@b, "reference empty ($i)";
}

# Delete elements.
for my $i (0 .. N - 1) {
    my $a = $obj [$i] -> set_index2 ($i * 2);
    my $b = $obj [$i];
    is $a, $b, "index2 delete last ($i)";
}
for my $i (0 .. N - 1) {
    my  @a = $obj [$i] -> index2;
    my  @b = @{$data [$i] {index2}};
    pop @b;
    is_deeply \@a, \@b, "index2 popped ($i)";

    my  $a = $obj [$i] -> index2;
    my  $b = @b;
    is  $a, $b, "index2 popped (scalar) ($i)";
}
for my $i (0 .. N - 1) {
    my $a = $obj [$i] -> set_index2 (0);
    my $b = $obj [$i];
    is $a, $b, "index2 delete first ($i)";
}
for my $i (0 .. N - 1) {
    my  @a = $obj [$i] -> index2;
    my  @b = @{$data [$i] {index2}};
    pop @b;
    undef $b [0] if @b;
    is_deeply \@a, \@b, "index2 popped ($i)";

    my  $a = $obj [$i] -> index2;
    my  $b = @b;
    is  $a, $b, "index2 popped (scalar) ($i)";
}



#
# Array operations.
#

# push/$#/slice.
for my $i (0 .. N - 1) {
    $obj [$i] -> push_array (@{$data [$i] {push}});
}
for my $i (0 .. N - 1) {
    my @a = $obj [$i] -> array;
    my $a = $obj [$i] -> count_array;
    my @b = @{$data [$i] {push}};
    my $b = @b;
    is_deeply \@a, \@b, "push ($i)";
    is ($a, $b - 1, '$#.array ($i)');

    my @i = map {2 * $_} 0 .. $i;
    my @c = $obj [$i] -> slice_array (@i);
    my @d = @{$data [$i] {push}} [@i];
    is_deeply \@c, \@d, "slice ($i)";
}

# unshift/pop/shift.
for my $i (0 .. N - 1) {
    $obj [$i] -> unshift_array (@{$data [$i] {unshift}});
}
for my $i (0 .. N - 1) {
    my @a = $obj [$i] -> array;
    my $a = $obj [$i] -> count_array;
    my @b = map {@$_} @{$data [$i]} {qw /unshift push/};
    my $b = @b;
    is_deeply \@a, \@b, "unshift ($i)";
    is ($a, $b - 1, '$#.array ($i)');

    my $c = $obj [$i] -> pop_array;
    my $d = pop @b;
    my @c = $obj [$i] -> array;
    is $c, $d, "pop return ($i)";
    is_deeply \@c, \@b, "pop ($i)";

    my $e = $obj [$i] -> shift_array;
    my $f = shift @b;
    my @e = $obj [$i] -> array;
    is $e, $f, "pop return ($i)";
    is_deeply \@e, \@b, "pop ($i)";
}

# splice
for my $i (0 .. N - 1) {
    $obj [$i] -> set_array ([@{$data [$i] {splice}}]);
}
for my $i (0 .. N - 1) {
    my @a = $obj [$i] -> splice_array ($i, $i);
    my @b = @{$data [$i] {splice}} [$i .. 2 * $i - 1];
    is_deeply \@a, \@b, "splice ($i)";

    my @c = $obj [$i] -> array;
    my @d = @{$data [$i] {splice}} [0 .. $i - 1, 2 * $i .. 3* $i];
    is_deeply \@c, \@d, "splice left ($i)";
}


#
# How many entries?
#
my @a = Array -> give_status;
my @b = (0, (N) x (KEYS - 1), 0);
is_deeply (\@a, \@b, "status (0)");

for my $i (0 .. N - 1) {
    undef $obj [$i];
    my @a = Array -> give_status;
    my @b = (0, (N - ($i + 1)) x (KEYS - 1), 0);
    is_deeply (\@a, \@b, sprintf "status (%d)" => $i + 1);
}
@a = Array -> give_status;
@b = (0) x (KEYS + 1);
is_deeply (\@a, \@b, "final status");

__END__
