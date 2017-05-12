package
ExtrasModule;
our $VERSION = '0.000001';

use 5.014;
use warnings;
use Carp;

use Lexical::Failure
    handlers => { squawk => sub { carp 'Squawked as expected'; return 'squawk!' } };

sub import {
    my (undef, undef, $errors) = @_;
    ON_FAILURE($errors);
}

sub dont_succeed {

    fail "Didn't succeed";
    return 'This value should not be returned';
}


1; # Magic true value required at end of module


