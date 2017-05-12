package Microsoft::AdCenter::SOAPFault;
# Copyright (C) 2012 Xerxes Tsang
# This program is free software; you can redistribute it and/or modify it
# under the terms of Perl Artistic License.

use strict;
use warnings;

use base qw/Class::Accessor::Chained Microsoft::AdCenter/;

use Data::Dumper;

=head1 NAME

Microsoft::AdCenter::SOAPFault - Encapsulates SOAP fault details.

=cut

=head1 SYNOPSIS

    eval {
        ...
    };
    if (my $soap_fault = $@) {
        # Handle the SOAP fault
        print $soap_fault->faultstring;
        ...
    }

=head1 METHODS

=head2 faultcode

Returns the fault code

=head2 faultstring

Returns the fault string

=head2 detail

Returns the fault detail

=cut

__PACKAGE__->mk_accessors(qw/
    faultcode
    faultstring
    detail
/);

use overload q("") => \&to_string;

sub to_string {
    my $self = shift;
    return Dumper($self);
}

1;
