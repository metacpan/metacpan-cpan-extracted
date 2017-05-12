package Graph::Similarity::Method;

use Moose::Role;
use Data::Dumper;

requires qw/calculate/;

our $VERSION = '0.02';

has 'num_of_iteration'  => (is => 'rw', isa => 'Int', default => 100);
has 'sim' => (is => 'rw', isa => 'HashRef');

no Moose::Role;

# Set number of the iteration. 
sub setNumOfIteration {
    my ($self, $value) = @_;
    $self->num_of_iteration($value);
}

sub showAllSimilarities {
    my $self = shift;
    my $sim = $self->sim;
    for my $i (keys %$sim) {
        for my $j (keys %{$$sim{$i}}) {
            print "$i - $j : $$sim{$i}{$j}\n";
        }
    }
    #print Dumper $sim;
}

# This is used by the algoritm module 
# to set the similarity hash
sub _setSimilarity {
    my ($self, $ref) = @_; 
    $self->sim($ref);
}

sub getSimilarity {
    my ($self, $a, $b) = @_;
    my $sim = $self->sim;
    for my $i (keys %$sim) {
        if ($i eq $a ) {
            for my $j (keys %{$$sim{$i}}) {
                if ($j eq $b) {
                    return $$sim{$i}{$j};
                }
            }
        }
        elsif ($i eq $b) {
            for my $j (keys %{$$sim{$i}}) {
                if ($j eq $a) {
                    return $$sim{$i}{$j};
                }
            }
        }
    }
    return;
}


=head1 NAME

Graph::Similarity::Method - A common role of Graph::Similarity 

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

Please see L<Graph::Similarity>

=head1 DESCRIPTION 

This is absctract class with Moose::Role which provides common methods.  

=head1 METHODS

The following methods are implemented here.

=head2 setNumOfIteration($num)

Please see L<Graph::Similarity>

=head2 showAllSimilarities()

Please see L<Graph::Similarity>

=head2 getSimilarity("X", "Y")

Please see L<Graph::Similarity>

=head1 AUTHOR

Shohei Kameda, C<< <shoheik at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Shohei Kameda.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
