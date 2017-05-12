package Test_Renaming;

use 5.010; use warnings;
use Lexical::Hints { set_hint => 'install_hint', get_hint => 'retrieve_hint' };
use Test::More;

# Initialize module's hints...
sub import {
    my ($package, $hint_value) = @_;
    if (defined $hint_value) {
        install_hint(cth => $hint_value);
    }
}

# Test hints are set...
sub verify_hint_is {
    my ($hint_value) = @_;
    is retrieve_hint('cth'), $hint_value => "Verifying value is now: $hint_value";
}

# Set hints...
sub install_hint_to {
    my ($hint_value) = @_;
    install_hint('cth' => $hint_value);
}

# Attempt to create a new hint...
sub set_new_hint_to {
    my ($hint_value) = @_;
    is eval{ install_hint('new_cth' => $hint_value); }, undef() => 'Runtime autovivification failed';
    like $@, qr{^Cannot autovivify hint 'new_cth' at runtime for Test_Compiletime_Hints}
                                                            => 'Correct error message';
}

1; # Magic true value required at end of module

