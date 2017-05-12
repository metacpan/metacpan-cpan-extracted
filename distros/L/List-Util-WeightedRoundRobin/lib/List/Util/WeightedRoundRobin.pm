package List::Util::WeightedRoundRobin;

$VERSION = 0.4;

use strict;


sub new {
    my $class = shift;

    my $self = {};
    bless $self, $class;

    return( $self );
};


sub create_weighted_list {
    my $self = shift;
    my $sources = shift;

    my $weighted_list = [];

    # The weighting of one source is a list 
    # containing only that source
    if( @{$sources} == 1 ) {
        $weighted_list = [ $sources->[0]->{name} ];
        return( $weighted_list );
    };

    $sources = $self->_reduce_and_sort_weightings( $sources );

    foreach my $source ( @{$sources} ) {
        my $total_weight = scalar @{$weighted_list};
        my $frequency = $total_weight / $source->{weight};

        # If we haven't yet added elements, add all of the first source
        unless( $total_weight ) {
            for( my $count = 0; $count < $source->{weight}; $count++ ) {
                push @{$weighted_list}, $source->{name};
            };
            next;
        };

        for( my $count = $source->{weight}; $count > 0; $count-- ) {
            my $tmp = sprintf( "%.f", $count * $frequency );
            splice( @{$weighted_list}, $tmp, 0, $source->{name} );
        };

    };

    return( $weighted_list );
};


sub _reduce_and_sort_weightings {
    my $self = shift;
    my $sources = shift;

    my @weights = ();

    foreach my $source ( @{$sources} ) {
        push @weights, $source->{weight};
    };   

    my $common_factor = multigcf( @weights );

    my $sorted_sources = [];

    foreach my $source ( sort sort_weights_descending(@{$sources}) ) {
        $source->{weight} /= $common_factor;
        push @{$sorted_sources}, $source;
    };   

    return( $sorted_sources );
};


sub sort_weights_descending { $a->{weight} <=> $b->{weight}; };


# Taken from: http://www.perlmonks.org/?node=greatest%20common%20factor
sub gcf {
    my ($x, $y) = @_;
    ($x, $y) = ($y, $x % $y) while $y;
    return $x;
}

sub multigcf {
    my $x = shift;
    $x = gcf($x, shift) while @_;
    return $x;
};

1;

=head1 NAME

List::Util::WeightedRoundRobin - Creates a list based on weighted input

=head1 SYNOPSIS

  my $list = [
    {
        name    => 'jingle',
        weight  => 6,
    },
    {
        name    => 'bells',
        weight  => 2,
    },
  ];

  my $WeightedList = List::Util::WeightedRoundRobin->new();
  my $weighted_list = $WeightedList->create_weighted_list( $list );
    
=head1 DESCRIPTION

C<List::Util::WeightedRoundRobin> is a utility for creating a weighted list
based on the input and associated weights.

=head1 METHOD

=over 4

=head2 new

Constructs a new C<List::Util::WeightedRoundRobin> and returns it. Takes no
arguments.

=head2 create_weighted_list

Takes an array reference as an argument. The array reference must contain
hash entries which have a 'name' and 'weight' key.

If the sources are valid and a weighted list has been created, the method will
return a weighted list. In the case of an error, the returned list will be 
empty.

=head1 AUTHOR

Alistair Francis, http://search.cpan.org/~friffin/

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10 or,
at your option, any later version of Perl 5 you may have available.

=cut