package Mail::Decency::ContentFilter::Core::WeightTranslate;

use Moose::Role;
use Data::Dumper;

use version 0.74; our $VERSION = qv( "v0.1.6" );

=head1 NAME

Mail::Decency::ContentFilter::Core::Virus

=head1 DESCRIPTION

For all modules being a virus filter

=head1 CLASS ATTRIBUTES

=head2 weight_translate : HashRef[Int]

Hashref of translation values. 

Example:

    weight_translate:
        10: 100
        0: 50
        -5: -50
        -10: -100

Will translate anything 


=cut

has weight_translate => ( is => 'rw', isa => 'HashRef[Int]', predicate => 'has_weight_translate' );

=head2 METHODS

=head2 pre_init

Add check params: cmd, check, train and untrain to list of check params

=cut

before init => sub {
    my ( $self ) = @_;
    push @{ $self->{ config_params } ||=[] }, qw/ weight_translate /;
};


=head2 translate_weight

Uses the weight translation array and determines dececency weighting from module weighting (eg crm114 to decency translation)

=cut

sub translate_weight {
    my ( $self, $received_score ) = @_;
    
    my ( $translated_score, $last );
    
    # sort ascending (-1, 0, 1)
    my @sorted = sort { $a <=> $b } map { 1 * $_ } keys %{ $self->weight_translate };
    
    $self->logger->debug3( "Translating '$received_score' with '". join( ', ', map {
        sprintf( '%d -> %d', $_, $self->weight_translate->{ $_ } );
    } @sorted ) );
    
    # received value is smaller then first value
    return $self->weight_translate->{ $sorted[0] }
        if $received_score <= $sorted[0];
    
    # go through sorted score .. -10, -5, 0, 10, 100
    foreach my $module_score( @sorted ) {
        
        # search for the smallest score bigger then the received score
        if ( $received_score < $module_score ) {
            return $self->weight_translate->{ $module_score };
        }
        $last = $module_score;
    }
    
    # fallback to last (BIGGEST) score if not found any
    return $self->weight_translate->{ $last };
}

=head1 AUTHOR

Ulrich Kautz <uk@fortrabbit.de>

=head1 COPYRIGHT

Copyright (c) 2010 the L</AUTHOR> as listed above

=head1 LICENCSE

This library is free software and may be distributed under the same terms as perl itself.

=cut

1;
