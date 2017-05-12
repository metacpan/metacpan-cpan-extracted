package Test_Compiletime_Hints;

use 5.010; use warnings;
use Lexical::Hints;
use Test::More;

# Initialize module's hints...
sub import {
    my ($package, $hint_value) = @_;
    if (defined $hint_value) {
        set_hint(cth => $hint_value);
    }
}

# Test hints are set...
sub verify_hint_is {
    my ($hint_value) = @_;
    is get_hint('cth'), $hint_value => "Verifying value is now: " . ($hint_value//'undef');
}

# Set hints...
sub set_hint_to {
    my ($hint_value) = @_;
    set_hint('cth' => $hint_value);
}

# Attempt to create a new hint...
sub set_new_hint_to {
    my ($hint_value) = @_;
    is eval{ set_hint('new_cth' => $hint_value); }, undef() => 'Runtime autovivification failed';
    like $@, qr{^Cannot autovivify hint 'new_cth' at runtime for Test_Compiletime_Hints}
                                                            => 'Correct error message';
}

1; # Magic true value required at end of module
