package Iglu::LMLM::Types::Hamakor;

use strict;
use warnings;

use Iglu::LMLM::Types::Iglu;

use vars qw(@ISA);

@ISA=qw(Iglu::LMLM::Types::Iglu);

sub get_default_hostname
{
    my $self = shift;

    return "hamakor.org.il";
}

1;
