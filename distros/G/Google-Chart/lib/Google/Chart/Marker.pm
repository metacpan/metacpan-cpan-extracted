# $Id$

package Google::Chart::Marker;
use Moose;
use Moose::Util::TypeConstraints;

use constant parameter_name => 'chm';

with 'Google::Chart::QueryComponent::Simple';

has 'markerset' => (
    is => 'rw',
    isa => 'ArrayRef[Google::Chart::Marker::Item]',
    required => 1,
    default => sub { 
        [ Google::Chart::Marker::Item->new ] ;
    }
);

__PACKAGE__->meta->make_immutable;

no Moose;
no Moose::Util::TypeConstraints;

sub BUILDARGS {
    my $self = shift;
    my @markerset;
    my @markerargs;
    my %args;

    if (@_ == 1 && ref $_[0] eq 'ARRAY') {
        @markerargs = @{$_[0]};
    } else {
        %args = @_;
        my $arg = delete $args{markerset};
        if (ref $arg eq 'ARRAY') {
            @markerargs = @{ $arg };
        } elsif (ref $arg eq 'HASH') {
            @markerargs = ( $arg );
        }
    }


    @markerargs = ( {} ) unless @markerargs;

    foreach my $marker ( @markerargs ) {
        if (! Scalar::Util::blessed $marker) {
            $marker = Google::Chart::Marker::Item->new($marker)
        }
        push @markerset, $marker;
    }

    return { %args, markerset => \@markerset };
}

sub parameter_value {
    my $self = shift;
    return join ('|',
        map {$_->as_string} @{$self->markerset}
    );
}

package # hide from PAUSE
    Google::Chart::Marker::Item;
use Moose;
use Moose::Util::TypeConstraints;
use Google::Chart::Types;
use Google::Chart::Color;

coerce 'Google::Chart::Marker::Item'
    => from 'HashRef'
    => via {
        Google::Chart::Marker::Item->new(%{$_});
    }
;

coerce 'Google::Chart::Marker::Item'
    => from 'ArrayRef'
    => via {
        Google::Chart::Marker::Item->new(%{$_});
    }
;

enum 'Google::Chart::Marker::Item::Type' => (
    'a', # arrow
    'c', # corrs
    'd', # diamond
    'o', # circle
    's', # square
    't', # text
    'v', # vertical line from x-axis to the data point
    'V', # vertical line to the top of the chart
    'h', # horizontal line across
    'x', # x shape
    'D', # Line and bar chart line styles
);

has 'marker_type' => (
    is => 'rw',
    isa => 'Google::Chart::Marker::Item::Type',
    required => 1,
    default => 'o'
);

has 'color' => (
    is => 'rw',
    isa => 'Google::Chart::Color::Data',
    required => 1,
    # XXX - Hack (for some reason moose didn't like a plain '000000')
    # will investigate later
    default => sub { return '000000' },
);

has 'dataset' => (
    is => 'rw',
    isa => 'Int',
    required => 1,
    default => 0,
);

has 'datapoint' => (
    is => 'rw',
    isa => 'Num',
    required => 1,
    default => -1,
);

has 'size' => (
    is => 'rw',
    isa => 'Num',
    required => 1,
    default => 5,
);

has 'priority' => (
    is => 'rw',
    isa => 'Int',
    required => 1,
    default => 0,
);

__PACKAGE__->meta->make_immutable;

no Moose;
no Moose::Util::TypeConstraints;

sub as_string {
    my $self = shift;

    return join(',', 
        map { $self->$_ } qw(marker_type color dataset datapoint size priority) );
}

1;

__END__

=head1 NAME

Google::Chart::Marker - Google::Chart Marker

=head1 METHODS

=head2 parameter_value

=cut
