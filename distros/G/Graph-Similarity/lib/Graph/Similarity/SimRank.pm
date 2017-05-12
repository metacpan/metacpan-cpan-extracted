package Graph::Similarity::SimRank;

use strict;
use warnings;
use Moose;
use Graph;

with 'Graph::Similarity::Method';

our $VERSION = '0.02';

has 'graph'     => (is => 'rw', isa => 'Graph', required => 1);
has 'constant'  => (is => 'rw', isa => 'Num', default => 0.6);

__PACKAGE__->meta->make_immutable;
no Moose;

# Set constant value. In the paper, it's 0.8
sub setConst {
    my ($self, $value) = @_;
    $self->constant($value);
}

sub calculate {
    my $self = shift;

    my $g = $self->graph;
    my $c = $self->constant;
    my $itr = $self->num_of_iteration;
    
    # Initialize
    my @all = $g->vertices;
    my %R;
    for my $v1 (@all) {
        for my $v2 (@all) {
            if ($v1 eq $v2){
                $R{$v1}{$v2} = 1;
            }
            else {
                $R{$v1}{$v2} = 0;
            }
        }
    }
    
    for(my $i=0; $i<$itr; $i++){
        for my $v1 (@all) {
            for my $v2 (@all) {
                if ($v1 eq $v2){
                    $R{$v1}{$v2} = 1;
                }
                else {
                    my @p1 = $g->predecessors($v1);
                    my @p2 = $g->predecessors($v2);

                    if (scalar(@p1) == 0 || scalar(@p2) == 0){
                        $R{$v1}{$v2} = 0;
                    }
                    else {
                        my $sum = 0;
                        for my $p1 (@p1){
                            for my $p2 (@p2) {
                                $sum += $R{$p1}{$p2}; 
                            }
                        }
                            $R{$v1}{$v2} = ( $c / (scalar(@p1) * scalar(@p2)) ) * $sum;
                    }
                }
            }
        }
    }
    $self->_setSimilarity(\%R);
    return \%R;
}


=head1 NAME

Graph::Similarity::SimRank - SimRank implementation

=head1 VERSION

Version 0.02

=head1 SYNOPSIS

Please see L<Graph::Similarity>

=head1 DESCRIPTION 

This is the implementation of the below paper.

B<Glen Jeh, Jennifer Widon, "SimRank: A Measure of Structural-Context Similarity">

=head1 METHODS

=head2 setConst($const)

The const value is 0.6 by default becasue wikipedia mentions this is more acturate value,
whereas the paper uses 0.8.
You can change this to what you want. The value should be between 0 and 1. 

=head2 calculate()

This calculates SimRank. The algorithm is Naive Method in section 4.4.1 in the paper. 

=head1 AUTHOR

Shohei Kameda, C<< <shoheik at cpan.org> >>

=head1 LICENSE AND COPYRIGHT

Copyright 2012 Shohei Kameda.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1; # End of Graph::Similarity::SimRank
