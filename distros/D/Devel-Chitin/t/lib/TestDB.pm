package TestDB;
use strict;
use warnings;

use Carp;
use base 'Devel::Chitin';

my $still_running_tests = 1;
sub poll {
    return $still_running_tests;
}

sub __done__ {
    $still_running_tests = 0;
}

my $current_test = 1;
sub idle {
    my($class, $loc) = @_;

    my $next_test_sub_name = 'main::test_' .$current_test++;
    eval { no strict 'refs'; &{$next_test_sub_name}($class, $loc) };
    Carp::confess($@) if $@;
    return 1;
}

TestDB->attach();

1;
