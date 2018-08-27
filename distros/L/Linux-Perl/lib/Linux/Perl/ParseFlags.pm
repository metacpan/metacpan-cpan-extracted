package Linux::Perl::ParseFlags;

use strict;
use warnings;

sub parse {
    my ($arch_module, $flags_ar) = @_;

    my $flags = 0;
    if ( $flags_ar ) {
        for my $fl ( @$flags_ar ) {
            my $val_cr = $arch_module->can("_flag_$fl") or do {
                die "unknown flag: “$fl”";
            };
            $flags |= $val_cr->();
        }
    }

    return $flags;
}

1;
