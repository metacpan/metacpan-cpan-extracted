use Test::More 'no_plan';

BEGIN {
    require 5.006_001 or plan 'skip_all';
    close *STDERR;
    open *STDERR, '>', \my $stderr;
    *CORE::GLOBAL::exit = sub { die $stderr };
}

if (eval { require Getopt::Euclid and Getopt::Euclid->import(':foo'); 1 }) {
    ok 0 => 'Unexpectedly succeeded';
}
else {
    like $@, qr/Unknown mode \(':foo'\)/ => 'Failed as expected'; 
}

if (eval { require Getopt::Euclid and Getopt::Euclid->import(':minimal_keys'); 1 }) {
    ok 1 => 'Minimal mode accepted';
}
else {
    ok 0 => 'Unexpectedly failed';
}
