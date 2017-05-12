package HTML::TagCloud::Extended::Factor;
use strict;
use HTML::TagCloud::Extended::Exception;

sub new {
    my $class = shift;
    my $self  = bless {
        min     => 0,
        max     => 0,
        range   => 0,
        _factor => 0,
    }, $class;
    $self->_init(@_);
    return $self;
}

sub _init {
    my($self, %args) = @_;
    foreach my $key ( qw/min max range/ ) {
        if ( exists $args{$key} ) {
            $self->{$key} = $args{$key};
        } else {
            HTML::TagCloud::Extended::Exception->throw(qq/
                "$key" isn't found.
            /);
        }
        my $range = $args{range};
        my $min   = sqrt($args{min});
        my $max   = sqrt($args{max});
        $min -= $range if ($min == $max);
        $self->{_factor} = $range / ($max - $min);
    }
}

sub get_level {
    my ($self, $number) = @_;
    return int( ( sqrt($number + 0) - sqrt($self->{min}) ) * $self->{_factor} );
}

1;
__END__

