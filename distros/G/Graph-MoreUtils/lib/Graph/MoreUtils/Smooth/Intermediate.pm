package Graph::MoreUtils::Smooth::Intermediate;

# ABSTRACT: Container for intermediate vertices
our $VERSION = '0.2.0'; # VERSION

use strict;
use warnings;

use Scalar::Util qw( blessed );

sub new {
    my $class = shift;
    my $self = [ map { blessed $_ &&
                       $_->isa( Graph::MoreUtils::Smooth::Intermediate:: ) ? @$_ : $_ } @_ ];
    return bless $self, $class;
}

sub reverse {
    my( $self ) = @_;
    @$self = reverse @$self;
    return $self;
}

1;
