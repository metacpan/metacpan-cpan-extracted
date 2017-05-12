#
# $Id: 01_use.t 141 2004-11-30 19:06:15Z james $
#

use strict;
use warnings;

BEGIN {
    use Test::More;
    our $tests = 2;
    eval "use Test::NoWarnings";
    $tests++ unless( $@ );
    plan tests => $tests;
}

# the expected package and version
my $package = 'Lingua::Alphabet::Phonetic::Password';
my $expected = '0.11';

# pull in the package
use_ok($package);

# make sure the package version is correct
my $version_var;
{
    no strict 'refs';
    $version_var = ${$package . '::VERSION'};
}
is($version_var, $expected, "$package is at version $expected");

#
# EOF
