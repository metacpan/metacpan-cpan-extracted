#!/usr/bin/perl

use lib 'lib', '../lib';

use Exception::Base (
    '+ignore_package' => ['My::Package2', 'My::Package3'],
    'Exception::My',
);


for my $i (0..4) {
    Exception::Base->import( verbosity => $i );
    print "*** default verbosity=", Exception::Base->ATTRS->{verbosity}->{default}, "\n";

    eval { My::Package1::func(1) };
    for my $j (0..4) {
        $@->verbosity($j);
        print "verbosity=$j, \$@='$@'\n";
    }
}


package My::Package1;

sub func {
    My::Package2::func(2);
}


package My::Package2;

sub func {
    My::Package3::func(3);
}


package My::Package3;

sub func {
    Exception::My->throw;
}
