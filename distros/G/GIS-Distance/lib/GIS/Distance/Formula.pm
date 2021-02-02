package GIS::Distance::Formula;
use 5.008001;
use strictures 2;
our $VERSION = '0.19';

use Class::Measure::Length qw( length );
use Carp qw( croak );
use Scalar::Util qw( blessed );
use namespace::clean;

our $SELF;

sub new {
    my $class = shift;

    my $args = $class->BUILDARGS( @_ );

    my $self = bless { %$args }, $class;
    $self->{code} = $class->can('_distance');
    $self->BUILD() if $self->can('BUILD');

    return $self;
}

sub BUILDARGS {
    my $class = shift;

    return shift
        if @_==1 and ref($_[0]) eq 'HASH';

    return { @_ };
}

sub distance {
    my $self = shift;

    my @coords;
    foreach my $coord (@_) {
        if ((blessed($coord)||'') eq 'Geo::Point') {
            push @coords, $coord->latlong();
            next;
        }

        push @coords, $coord;
    }

    croak 'Invalid arguments passsed to distance()'
        if @coords!=4;

    local $SELF = $self;

    return length(
        $self->{code}->( @coords ),
        'km',
    );
}

sub distance_metal {
    my $self = shift;
    return $self->{code}->( @_ );
}

1;
__END__

=encoding utf8

=head1 NAME

GIS::Distance::Formula - Formula base class.

=head1 DESCRIPTION

This is the parent class for all L<GIS::Distance> formula classes such as
those listed at L<GIS::Distance/FORMULAS>.

To author your own formula class:

    package My::Formula;
    
    use parent 'GIS::Distance::Formula';
    
    sub _distance {
        my ($lat1, $lon1, $lat2, $lon2) = @_;
        
        # ...
        
        return $kilometers;
    }
    
    1;

Then use it:

    my $gis = GIS::Distance->new('My::Formula');
    my $km = $gis->distance( @coords );

The global C<$GIS::Distance::Formula::SELF> is available when your
C<_distance()> subroutine is called if, and only if, the entry point
was L<GIS::Distance/distance> and NOT L<GIS::Distance/distance_metal>
or otherwise.

Much of the interface described in L<GIS::Distance> is actually
implemented by this module.

=head1 SUPPORT

See L<GIS::Distance/SUPPORT>.

=head1 AUTHORS

See L<GIS::Distance/AUTHORS>.

=head1 LICENSE

See L<GIS::Distance/LICENSE>.

=cut

