package Linux::Perl::EasyPack;

use strict;
use warnings;

#Do not use in external code. This interface may change.
sub split_pack_list {
    my (@array) = @_;

    my $pack = q<>;
    my @keys;

    for my $i (0 .. $#array) {
        if ($i % 2) {
            if (index($array[$i], 'x') == 0) {
                pop @keys;
            }

            $pack .= $array[$i];
        }
        else {
            push @keys, $array[$i];
        }
    }

    return \@keys, $pack;
}

1;
