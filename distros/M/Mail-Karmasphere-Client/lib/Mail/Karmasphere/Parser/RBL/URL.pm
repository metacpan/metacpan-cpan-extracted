package Mail::Karmasphere::Parser::RBL::URL;

use strict;
use warnings;
use base 'Mail::Karmasphere::Parser::RBL::Base';

sub _type { "url" }

sub _streams { qw(url) }

sub my_format { "rbl.url" } # if the source table's "magic" field is rbl.url, this module deals with it.

sub tweaks {
    my $self = shift;
 
    # we assume it's a url identity.

    return ("url", 0, $_[0]);
}

1;
