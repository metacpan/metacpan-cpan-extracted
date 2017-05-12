package Test_Global_Hints;

use 5.010; use warnings;
use Lexical::Hints;
use Test::More;

# Set up data...
my @hints = qw< TGH1 TGH2 >;
my %hints; @hints{@hints} = @hints;

# Initialize module's hints...
sub import {
    for my $hint_name (qw< TGH1 TGH2 >) {
        set_hint($hint_name => $hints{$hint_name});
    }
}

# Test hints are set...
sub verify_set {
    for my $hint_name (qw< TGH1 TGH2 >) {
        is get_hint($hint_name), $hints{$hint_name} => "$hint_name correctly set";
    }
}

# Test hints are NOT set...
sub verify_unset {
    for my $hint_name (qw< TGH1 TGH2 >) {
        is get_hint($hint_name), undef() => "$hint_name NOT set";
    }
}

1; # Magic true value required at end of module
