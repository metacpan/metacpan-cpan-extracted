# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 01BuildFails.t'

use Test::More tests => 1;

#BEGIN { use_ok('Java::Build') };

require Java::Build;
eval q{
    import Java::Build;
};
like($@, qr/Java::Build is a doc/, "don't use Java::Build directly");
