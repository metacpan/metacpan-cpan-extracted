package Graph::Grammar::Rule::Edge;

# ABSTRACT: Rule to be evaluated on graph edges
our $VERSION = '0.2.0'; # VERSION

use strict;
use warnings;

sub new
{
    my( $class, $code ) = @_;
    return bless { code => $code }, $class;
}

sub matches
{
    my $self = shift;
    return $self->{code}->( @_ );
}

1;
