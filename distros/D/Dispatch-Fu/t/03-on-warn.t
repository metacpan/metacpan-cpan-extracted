use strict;
use warnings;
use Dispatch::Fu;
use Test::More tests => 3;
use Test::Warn;
use Test::Exception;

dies_ok {
    dispatch { return "foo" } 1;
}
q{expecting to croak if no cases are defined};

dies_ok {
    dispatch { return "foo" } 1, on bar => sub { 1 };
}
q{expecting to croak if "dispatch" returns an unregistered case};

warning_like {
    on foo => sub { 1 }
}
qr/follows a comma/i, q{Make sure 'on' warns when used in void context};
