package IO::Validation::Asnvalidation;

use 5.026001;
use strict;
use warnings;

sub validate {
    my ($self, $asn) = @_;
    if( not ( $asn =~ m/^(as|AS)(\d+)$/ ))
    {

     die "Invalid ASN number";

    }
}


1;
__END__
