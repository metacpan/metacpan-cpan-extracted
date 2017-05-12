package Mail::Karmasphere::Parser::RBL::SimpleIP;

use strict;
use warnings;
use base 'Mail::Karmasphere::Parser::RBL::Base';

sub _type { "ip4" }

sub _streams { qw(ip4) }

sub my_format { "rbl.simpleip" } # if the source table's "magic" field is rbl.simpleip, this module deals with it.

sub tweaks {
    my $self = shift;
 
    # we assume it's a url identity.

	my ($firstword) = split(' ', $_[0], 2);

    return ("ip4", 0, $firstword);
}

1;
