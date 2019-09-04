package IO::Validation::Tokenvalidation;


use 5.026001;
use strict;
use warnings;

sub validate {
    my ($self, $token) = @_;
    if(length($token) <= 25)
    {

     die "Invalid IPFINDER API Token";

    }
}


1;
__END__
