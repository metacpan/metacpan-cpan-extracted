package
AliasModule;
our $VERSION = '0.000001';

use 5.014;
use warnings;

use Lexical::Failure
                   fail => 'error',
             ON_FAILURE => 'on_error';

our $DIE_LINE = -1;

sub import {
    my (undef, undef, $errors) = @_;
    on_error($errors);
}

sub dont_succeed {

    $DIE_LINE = __FILE__ . ' line ' . (__LINE__ + 1);
    error "Didn't succeed";

    return 'This value should never be returned';
}

# Module implementation here


1; # Magic true value required at end of module
