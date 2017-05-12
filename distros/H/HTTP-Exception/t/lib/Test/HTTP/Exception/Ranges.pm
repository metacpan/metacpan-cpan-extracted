package Test::HTTP::Exception::Ranges;
use strict;
use Test::More;

################################################################################
sub test_range_ok {
    my @ranges = @_;
    s/XX$/00/ for (@ranges);
    my %instantiable;
    @instantiable{@ranges} = ();

    for my $status_code (100, 200, 300, 400, 500) {
        my $e;
        eval { $e = "HTTP::Exception::$status_code"->new; };

        if (exists $instantiable{$status_code}) {
            ok defined $e, "$status_code is instantiable";
        } else {
            ok !defined $e, "$status_code is not instantiable";
        }
    }
}

################################################################################
sub simple_test_range_ok {
    my @ranges = @_;

    require HTTP::Exception;
    HTTP::Exception->import(@ranges);

    test_range_ok(@ranges);
}

1;