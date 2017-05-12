package Foorum::Search;

use strict;
use warnings;
our $VERSION = '1.001000';

use Foorum::Search::Sphinx;
use Foorum::Search::Database;

sub new {
    my $class = shift;
    my $self  = {@_};

    my $sphinx = new Foorum::Search::Sphinx;
    if ( $sphinx->can_search() ) {
        $self->{use_sphinx} = 1;
        $self->{sphinx}     = $sphinx;
    } else {
        $self->{use_db} = 1;
        $self->{db}     = new Foorum::Search::Database;
    }

    return bless $self => $class;
}

sub query {
    my ( $self, $type, $params ) = @_;

    # if Sphinx searchd is on and Foorum::Search::Sphinx implemented the $type
    if ( $self->{use_sphinx} and $self->{sphinx}->can($type) ) {
        return $self->{sphinx}->query( $type, $params );
    } elsif ( $self->{db}->can($type) )
    {    # if Foorum::Search::Database implemented the $type
        return $self->{db}->query( $type, $params );
    }
}

1;
__END__

=pod

=head1 NAME

Foorum::Search - search Foorum

=head1 SYNOPSIS

  use Foorum::Search;
  
  my $search = new Foorum::Search;
  my $ret = $search->query('topic', { author_id => 1, title => 'test', page => 2, per_page => 20 } );
  # this ->query would use Foorum::Search::Sphinx when 'searchd' is available.
  # or else, use Foorum::Search::Database to get the results.

=head1 DESCRIPTION

This module is mainly to design the interface of Foorum search regardless the backend (Sphinx or Database or others)

=head1 SEE ALSO

L<Foorum::Search::Database>, L<Foorum::Search::Sphinx>

=head1 AUTHOR

Fayland Lam <fayland at gmail.com>

=cut
