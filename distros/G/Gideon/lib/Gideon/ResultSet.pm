package Gideon::ResultSet;
{
  $Gideon::ResultSet::VERSION = '0.0.3';
}
use Moose;
use overload
  '@{}'    => sub { $_[0]->elements },
  fallback => 1;

#ABSTRACT: Gideon result set

has driver => ( is => 'ro', required => 1 );
has target => ( is => 'ro', required => 1 );
has query  => ( is => 'ro' );
has elements => ( is => 'ro', builder => '_build_elements', lazy => 1 );

sub size {
    my $self = shift;
    return scalar @{ $self->elements };
}

sub _build_elements {
    my $self     = shift;
    my @elements = $self->driver->find( %{ $self->query } );
    return \@elements;
}

sub find {
    my ( $self, %query ) = @_;

    return $self->new(
        driver => $self->driver,
        target => $self->target,
        query  => $self->_combine_query( \%query )
    );
}

sub _combine_query {
    my ( $self, $query2 ) = @_;
    my $query = $self->query;

    return $query  unless $query2;
    return $query2 unless $query;

    my $new_query = {};
    my @keys = keys %{ { %$query, %$query2 } };

    foreach my $key (@keys) {
        my $value1 = $query->{$key};
        my $value2 = $query2->{$key};

        $new_query->{$key} = $value1 unless $value2;
        $new_query->{$key} = $value2 unless $value1;

        if ( $value1 and $value2 ) {
            $new_query->{$key} = [ -and => $value1, $value2 ];
        }

    }

    return $new_query;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=head1 NAME

Gideon::ResultSet - Gideon result set

=head1 VERSION

version 0.0.3

=head1 SYNOPSIS

  my $rs = Users->find( id => { '>' => 10 );
  $rs = $rs->find( id => { '<' => $limit ) if $limit;

=head1 DESCRIPTION

By default gideon tries to defer calling the database until it’s absolutely
necessary. For that purpose when C<find> method is invoked in scalar context
a new L<Gideon::ResultSet> is created. You can also combine several queries
together by invoking C<find> on a L<Gideon::ResultSet>

=head1 NAME

Gideon::ResultSet - Gideon Result Set Class

=head1 VERSION

version 0.0.3

=head1 AUTHOR

Mariano Wahlmann, Gines Razanov

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Mariano Wahlmann, Gines Razanov.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
