package EBook::Ishmael::CharDet::ISO2022KR;
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
        '$)C', # KS X 1001 to G1
    ];

    return $self;

}

sub encoding { 'iso-2022-kr' }

1;
