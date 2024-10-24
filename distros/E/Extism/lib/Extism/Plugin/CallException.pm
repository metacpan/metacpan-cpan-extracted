package Extism::Plugin::CallException;

use 5.016;
use strict;
use warnings;
use version 0.77;
our $VERSION = qv(v0.2.0);
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
