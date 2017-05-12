package FormValidator::Simple::Exception;
use strict;

sub throw {
    my ($self, $msg) = @_;
    require Carp;
    Carp::croak($msg);
}

1;
__END__

