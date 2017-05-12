package Enbld::Error;

use strict;
use warnings;

use overload (
        q{""} => 'to_string',
        fallback => 1,
        );

sub throw {
    my ( $class, $message ) = @_;

    die $class->new( $message );
}

sub new {
    my ( $class, $message ) = @_;

    chomp( $message );

    my $self = {
        message =>  $message,
    };

    return bless $self, $class;
}

sub to_string {
    my $self = shift;

    return "ERROR:$self->{message}\n";
}

1;
