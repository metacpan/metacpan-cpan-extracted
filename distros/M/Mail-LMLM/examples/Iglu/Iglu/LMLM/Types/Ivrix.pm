package Iglu::LMLM::Types::Ivrix;

use strict;
use warnings;

use Mail::LMLM::Types::Majordomo;

use vars qw(@ISA);

@ISA=qw(Mail::LMLM::Types::Majordomo);

sub initialize
{
    my $self = shift;

    $self->SUPER::initialize(@_);

    if (!exists($self->{'hostname'}))
    {
        $self->{'hostname'} = "ivrix.org.il";
    }
    if (!exists($self->{'homepage'}))
    {
        $self->{'homepage'} = "http://www.ivrix.org.il/";
    }
    if (!exists($self->{'owner'}))
    {
        $self->{'owner'} = [ "nyh", "math.technion.ac.il" ];
    }

    return 0;
}

sub get_online_archive
{
    my $self = shift;

    return ("http://" .
        $self->get_hostname() .
        "/mailing-lists/" .
        $self->get_group_base() .
        "/archive") ;
}


