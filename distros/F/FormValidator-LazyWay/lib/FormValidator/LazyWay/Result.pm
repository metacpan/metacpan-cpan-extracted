package FormValidator::LazyWay::Result;

use strict;
use warnings;
use Carp;

use base qw/Class::Accessor::Fast/;
__PACKAGE__->mk_accessors(
    qw/
        unknown
        missing
        valid
        invalid
        error_message
        has_missing
        has_custom_invalid
        has_invalid
        has_error
        success
        fixed
        /
);

sub custom_invalid {
    my $self    = shift;
    my $key     = shift;
    my $message = shift;
    if ($key) {
        $self->has_error(1);
        $self->has_custom_invalid(1);
        $self->success(0);
        $self->{custom_invalid}->{$key} = $message;
        $self->{error_message}->{$key}    = $message;
    }

    return $self->{custom_invalid};
}

1;
