package IO::Validation::Domainvalidation;


use 5.026001;
use strict;
use warnings;

sub validate {
    my ($self, $domain) = @_;
    if( not ( $domain =~ m/^(?!\-)(?:[a-zA-Z\d\-]{0,62}[a-zA-Z\d]\.){1,126}(?!\d+)[a-zA-Z\d]{1,63}$/ ))
    {

     die "Invalid Domain name";

    }
}


1;
__END__
