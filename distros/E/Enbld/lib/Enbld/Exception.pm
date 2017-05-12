package Enbld::Exception;

use strict;
use warnings;

use Carp;

use overload (
        q{""} => \&to_string,
        fallback => 1,
        );

sub throw {
    my ( $class, $message, $param ) = @_;

    die $class->new( $message, $param );
}

sub new {
    my ( $class, $message, $param ) = @_;

    chomp( $message );

    if ( $param ) { $message .= "\n" . $param . "\n" };

    my $location = $ENV{HARNESS_ACTIVE} ? Carp::longmess() : Carp::shortmess();

    my $self = {
        message         =>  $message,
        caller_location =>  $location,
    };

    return bless $self, $class;
}

sub to_string {
    my $self = shift;

    return "ABORT:$self->{message}$self->{caller_location}";
}

1;
