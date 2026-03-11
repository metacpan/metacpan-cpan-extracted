package EBook::Ishmael::CharDet::ISO2022JP;
use 5.016;
our $VERSION = '2.03';
use strict;
use warnings;

use parent 'EBook::Ishmael::CharDet::ISO2022';

sub new {

    my ($class) = @_;

    my $self = bless {}, $class;
    $self->SUPER::initialize;

    $self->{Unique} = [
        '(B', # To ASCII
        '(J', # To JIS X 0201-1976
        '$@', # To JIS X 0208-1978
        '$B', # To JIX X 0208-1983
    ];

    return $self;

}

sub encoding { 'iso-2022-jp' }

1;
