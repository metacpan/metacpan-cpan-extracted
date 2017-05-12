#!/usr/bin/perl -s

use strict;
use warnings;
use Test::More tests => 398;

use constant    N  =>  5;
use constant KEYS  =>  9;

BEGIN {
    if (-d 't') {
        chdir 't' or die "Failed to chdir: $!\n";
    }

    unshift @INC => ".";

    unless (grep {m!"blib/lib"!} @INC) {
        push @INC => grep {-d} "blib/lib", "../blib/lib"
    }

    use_ok ('Hash');
}

ok (defined $Lexical::Attributes::VERSION &&
            $Lexical::Attributes::VERSION > 0, '$VERSION');


#
# Check whether methods were created (or not).
#
{
    no strict 'refs';
    for my $k (qw /default pr priv/) {
        ok (!defined &{"Hash::h_${k}"},     "!defined &Hash::h_${k}");
        ok (!defined &{"Hash::set_h_${k}"}, "!defined &Hash::set_h_${k}");
    }
    for my $k (qw /ro/) {
        ok ( defined &{"Hash::h_${k}"},     " defined &Hash::h_${k}");
        ok (!defined &{"Hash::set_h_${k}"}, "!defined &Hash::set_h_${k}");
    }
    for my $k (qw /rw/) {
        ok ( defined &{"Hash::h_${k}"},     " defined &Hash::h_${k}");
        ok ( defined &{"Hash::set_h_${k}"}, " defined &Hash::set_h_${k}");
    }
}


ok ( defined &Hash::hash,       " defined &Hash::hash");
ok ( defined &Hash::set_hash,   " defined &Hash::set_hash");
ok (!defined &Hash::unused,      "!defined &Hash::unused");
ok (!defined &Hash::set_unused,  "!defined &Hash::set_unused");


#
# Can we create objects?
#
my @obj;
for (0 .. N - 1) {
    $obj [$_] = Hash -> new;
    isa_ok ($obj [$_], "Hash");
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
my %map = (reference  => ' ref',
           index      => 'ind1',
           index2     => 'ind2',
           rw         => ' rw ',
           ro         => ' ro ',
           pr         => ' pr ',
           priv       => 'priv',
           default    => ' def',
           hash       => 'hash',
);
for my $i (0 .. N - 1) {
    my $max = $i * 2;
    while (my ($type, $abb) = each %map) {
        $data [$i] {$type}  = {map {;"key-$abb-$i-$_" =>
                                     "val-$abb-$i-$_"} 0 .. $max};
    }
}

#
# Set ro/pr/priv/default values by other means.
#
for my $i (0 .. N - 1) {
    $obj [$i] ->    set_h_rw     ({%{$data [$i] {rw}}});
    $obj [$i] -> my_set_h_ro      (%{$data [$i] {ro}});
    $obj [$i] -> my_set_h_pr      (%{$data [$i] {pr}});
    $obj [$i] -> my_set_h_priv    (%{$data [$i] {priv}});
    $obj [$i] -> my_set_h_default (%{$data [$i] {default}});
}

#
# Query empty hash
#
for my $i (0 .. N - 1) {
    my @a = $obj [$i] -> reference;
    my @b;
    is_deeply \@a, \@b, "Empty hash";

    my $a = $obj [$i] -> reference;
    my $b = 0;
    is $a, $b, "Empty hash (scalar)";

    my $c = $obj [$i] -> reference ("foo");
    my $d;
    is $c, $d, "Empty hash (index)";

    my @e = $obj [$i] -> reference ("bar", "baz");
    my @f = (undef, undef);
    is_deeply \@e, \@f, "Empty hash (slice)";
}

for my $i (0 .. N - 1) {
    for my $f (qw /rw ro/) {
        my $method = "h_$f";

        my %a = $obj [$i] -> $method;
        my %b = %{$data [$i] {$f}};
        is_deeply \%a, \%b, "$f return value ($i)";

        my $a = $obj [$i] -> $method;
        my $b = keys %{$data [$i] {$f}};
        is $a, $b, "$f scalar return value ($i)";

        for my $j (0 .. 2 * $i) {
            my $key = "key- $f -$i";
            my $a   = $obj [$i] -> $method ($key);
            my $b   = $data [$i] {$f} {$key};
            is $a, $b, "$f by index ($i, $j)";
        }

        # Slice.
        my @i = map {sprintf "key- %s -%d", $f, $_ * 2} 0 .. $i;
        my @c = $obj [$i] -> $method (@i);
        my @d = @{$data [$i] {$f}} {@i};
        is_deeply \@c, \@d, "$f slice return value ($i)";
    }

    for my $f (qw /pr priv default/) {
        my $method = "my_get_h_$f";

        my %c = $obj [$i] -> $method;
        my %d = %{$data [$i] {$f}};
        is_deeply \%c, \%d, "$f return value ($i)";
    }

}


#
# Test rw functions.
#
for my $i (0 .. N - 1) {
    $obj [$i] -> set_reference ($data [$i] {reference});
    # Index by index.
    while (my ($key, $val) = each %{$data [$i] {index}}) {
        $obj [$i] -> set_index ($key, $val);
    }
    # Complete set
    $obj [$i] -> set_index2 (%{$data [$i] {index2}});
}

for my $i (0 .. N - 1) {
    # Get complete hashes.
    my %a = $obj [$i] -> reference;
    my %b = %{$data [$i] {reference}};
    is_deeply \%a, \%b, "'reference' return value ($i)";

    my $a = $obj [$i] -> reference;
    my $b = keys %{$data [$i] {reference}};
    is $a, $b, "'reference' scalar return value ($i)";

    my %c = $obj [$i] -> index;
    my %d = %{$data [$i] {index}};
    is_deeply \%c, \%d, "'index' return value ($i)";

    my $c = $obj [$i] -> index;
    my $d = keys %{$data [$i] {index}};
    is $c, $d, "'index' scalar return value ($i)";

    my %e = $obj [$i] -> index;
    my %f = %{$data [$i] {index}};
    is_deeply \%e, \%f, "'index2' return value ($i)";

    my $e = $obj [$i] -> index;
    my $f = keys %{$data [$i] {index}};
    is $e, $f, "'index2' scalar return value ($i)";

    for my $type (qw /reference index index2/) {
        while (my ($key, $value) = each %{$data [$i] {$type}}) {
            my $a = $obj [$i] -> $type ($key);
            my $b = $value;
            is $a, $b, "'$type ($key)' return value ($i)";
        }
    }

    # Get slices.
    for my $type (qw /reference index index2/) {
      redo unless
        my @keys = grep {rand (1) < .5} keys %{$data [$i] {$type}};
        my @a    = $obj [$i] -> $type (@keys);
        my @b    = @{$data [$i] {$type}} {@keys};
        is_deeply \@a, \@b, "'$type' (slice) return value ($i)";
    }
}

# Overwrite values.
for my $i (0 .. N - 1) {
    for my $j (0 .. $i) {
        my $key = sprintf "key-ind2-$i-%d" => 2 * $j;
        $obj [$i] -> set_index ($key, $data [$i] {index2} {$key});
    }
}
for my $i (0 .. N - 1) {
    for my $j (0 .. $i * 2) {
        my $key = sprintf "key-ind%d-$i-%d" => $j % 2 ? 1 : 2, $j;
        my $a = $obj [$i] -> index ($key);
        my $b = $data [$i] {$j % 2 ? "index" : "index2"} {$key};
        is $a, $b, "'index ($key) return value ($i)";
    }
}

# Clear hash.
for my $i (0 .. N - 1) {
    $obj [$i] -> set_reference;
}
for my $i (0 .. N - 1) {
    my %a = $obj [$i] -> reference;
    my %b = ();
    is_deeply \%a, \%b, "reference empty ($i)";
}

# Delete elements.
for my $i (0 .. N - 1) {
    my %I = %{$data [$i] {index2}};
    my @I = keys %I;

    while (@I) {
        my $key = splice @I, rand @I, 1;
        my $a   = $obj [$i] -> set_index2 ($key);
        my $b   = $obj [$i];
        delete    $I {$key};
        my %a   = $obj [$i] -> index2;
        my %b   = %I;
        is         $a,  $b, "index2 delete return value ($i, $key)";
        is_deeply \%a, \%b, "index2 delete ($i, $key)";
    }
}

#
# Hash tests.
#
for my $i (0 .. N - 1) {
    $obj [$i] -> set_hash (%{$data [$i] {hash}});
}
for my $i (0 .. N - 1) {
    my %a = $obj [$i] -> hash;
    my %b = %{$data [$i] {hash}};
    is_deeply \%a, \%b, "hash ($i)";

    my @c = sort {$a cmp $b} $obj [$i] -> hash_keys;
    my @d = sort {$a cmp $b} keys %{$data [$i] {hash}};
    is_deeply \@c, \@d, "keys ($i)";

    my @e = sort {$a cmp $b} $obj [$i] -> hash_values;
    my @f = sort {$a cmp $b} values %{$data [$i] {hash}};
    is_deeply \@e, \@f, "values ($i)";

    while (my ($key, $value) = each %{$data [$i] {hash}}) {
        my $g = $obj [$i] -> hash_by_key ($key);
        my $h = $value;
        is $g, $h, "hash_by_key ($i, $key)";
    }
    {
      redo unless
        my @keys = grep {rand (1) < .5} keys %{$data [$i] {hash}};
        my @j    = $obj [$i] -> slice_hash (@keys);
        my @k    = @{$data [$i] {hash}} {@keys};
        is_deeply \@j, \@k, "slice_hash ($i)";
    }
}

#
# How many entries?
#
my @a = Hash -> give_status;
my @b = (0, (N) x (KEYS - 1), 0);
is_deeply (\@a, \@b, "status (0)");

for my $i (0 .. N - 1) {
    undef $obj [$i];
    my @a = Hash -> give_status;
    my @b = (0, (N - ($i + 1)) x (KEYS - 1), 0);
    is_deeply (\@a, \@b, sprintf "status (%d)" => $i + 1);
}
@a = Hash -> give_status;
@b = (0) x (KEYS + 1);
is_deeply (\@a, \@b, "final status");

__END__
