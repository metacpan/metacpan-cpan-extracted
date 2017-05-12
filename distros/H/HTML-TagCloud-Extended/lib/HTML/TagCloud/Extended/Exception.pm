package HTML::TagCloud::Extended::Exception;
use strict;

sub throw {
    my ($class, $message) = @_;
    require Carp;
    Carp::croak($message);
}

1;
__END__

