=head1 NAME

DynGig::Range::Integer::Parse - Implements DynGig::Range::Interface::Parse.

=cut
package DynGig::Range::Integer::Parse;

use base DynGig::Range::Interface::Parse;

use warnings;
use strict;

use DynGig::Range::Integer::Object;

=head1 DESCRIPTION

=head2 OBJECT

A even sized ARRAY containing boundary values of contiguous elements,
in ascending order.

e.g. '-5,23,4~13,0~2' is stored as [ -5, -5, 0, 2, 4, 13, 23, 23 ]

=cut
sub _object { DynGig::Range::Integer::Object->new( [] ) }

=head2 LITERAL

A rudimentary range form. e.g.

 '4~13'
 '-5'

=cut
sub _literal
{
    my ( $this, $input ) = @_;
    my ( $node, @range ) = '';
    my %symbol = $this->symbol();

    if ( $input->[0] ne $symbol{range} && $input->[-1] ne $symbol{range} )
    { 
        while ( @$input )
        {
            my $char = $input->[0];
    
            if ( $char eq $symbol{range} )
            {
                push @range, $node;
                $node = '';
    
                last if @range == 2;
            }
            else
            {
                last unless $char =~ /\d/ || $char =~ /[-+]/ && $node eq '';
                $node .= $char;
            }
    
            shift @$input;
        }
    }

    if ( @$input )
    {
        splice @range;
        splice @$input;
    }
    else
    {
        push @range, $node;

        if ( @range == 1 )
        {
            $range[1] = $range[0];
        }
        elsif ( $range[1] < $range[0] )
        {
            @range = reverse @range;
        }
    }

    DynGig::Range::Integer::Object->new( \@range );
}

=head1 NOTE

See DynGig::Range

=cut

1;

__END__
