package Extism::Plugin::CallException v0.3.0;

use 5.016;
use strict;
use warnings;
use Carp qw(croak shortmess);
our @CARP_NOT = qw(Extism::Plugin);
use overload '""' => sub {
    "$_[0]->{message}, code: $_[0]->{code} " . shortmess()
};

sub new {
    my ($name, $rc, $message) = @_;
    my %obj = (code => $rc, message => $message);
    bless \%obj, $name
}

1; # End of Extism::Plugin::CallException
