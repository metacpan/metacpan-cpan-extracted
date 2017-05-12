package Iglu::LMLM::Types::Perl_IL;

use strict;
use warnings;

use Mail::LMLM::Types::Mailman;

use vars qw(@ISA);

@ISA=qw(Mail::LMLM::Types::Mailman);

sub initialize
{
    my $self = shift;

    $self->SUPER::initialize(@_);

    if (! exists($self->{'hostname'}) )
    {
        $self->{'hostname'} = "perl.org.il";
    }

    if (! exists($self->{'owner'}) )
    {
        $self->{'owner'} = [ "gabor", "perl.org.il" ],
    }

    if (! exists($self->{'homepage'}))
    {
        $self->{'homepage'} = "http://www.perl.org.il/";
    }

    return 0;
}

sub get_online_archive
{
    my $self = shift;

    if ( exists($self->{'online_archive'}) )
    {
        return $self->{'online_archive'};
    }
    else
    {
        return "http://www.perl.org.il/pipermail/" .
            $self->get_group_base() . "/";
    }
}

1;
