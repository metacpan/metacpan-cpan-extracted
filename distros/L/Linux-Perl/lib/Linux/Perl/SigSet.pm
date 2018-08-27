package Linux::Perl::SigSet;

use strict;
use warnings;

my $sig_num_hr;

use constant _SIG_MAX => 63;

sub from_list {
    my (@list) = @_;

    my $vec = q<>;

    for my $sig (@list) {
        if ($sig =~ tr<0-9><>c) {

            $sig_num_hr ||= do {
                require Config;
                my @names = split m< >, $Config::Config{'sig_name'};
                my %signum;

                @signum{@names} = split m< >, $Config::Config{'sig_num'};
                \%signum;
            };

            $sig = $sig_num_hr->{$sig} || die "Unrecognized signal: '$sig'";
        }

        vec( $vec, $sig - 1, 1 ) = 1;
    }

    vec( $vec, _SIG_MAX(), 1 ) = 0;

    return $vec;
}

1;
