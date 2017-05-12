package Document::TriPart::Cabinet::UUID;

use strict;
use warnings;

use vars qw/$re/;
$re = '[a-f\d]{8}-[a-f\d]{4}-[a-f\d]{4}-[a-f\d]{4}-[a-f\d]{12}';

use Data::UUID::LibUUID;

sub make {
    return Data::UUID::LibUUID->new_uuid_string( @_ ); 
}

sub normalize {
    my $self = shift;
    my $uuid = shift;
    die "Can't normalize uuid $uuid since it isn't valid" unless $self->validate( $uuid );
    return lc $uuid;
}

sub validate {
    my $self = shift;
    my $uuid = shift;
    die "Wasn't given a uuid" unless $uuid;
#    return $uuid =~ m/^[a-f\d]{8}-[a-f\d]{4}-[a-f\d]{4}-[a-f\d]{4}-[a-f\d]{12}$/;
    return $uuid =~ m/^$re$/;
}

1;
