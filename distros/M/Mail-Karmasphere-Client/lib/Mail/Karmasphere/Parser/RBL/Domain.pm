package Mail::Karmasphere::Parser::RBL::Domain;

use strict;
use warnings;
use base 'Mail::Karmasphere::Parser::RBL::Base';

sub _type { "domain" }

sub _streams { qw(domain) }

sub my_format { "rbl.domain" } # if the source table's "magic" field is rbl.domain, this module deals with it.

sub tweaks {
    my $self = shift;
 
    # we assume it's a domain identity.

    return ("domain", 0, $_[0]);
}

1;
