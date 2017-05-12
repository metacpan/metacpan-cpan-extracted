package Exobrain::Agent::Foursquare::Source;
use Moose;
use Method::Signatures;

with 'Exobrain::Agent::Foursquare';
with 'Exobrain::Agent::Poll';

use constant DEBUG => 0;
use constant LAST_CHECK => 'last_check';

# ABSTRACT: Send foursquare events to the exobrain bus
our $VERSION = '0.01'; # VERSION

# last_check is an attribute that's backed by our cache.
# TODO: It would be cool if Exobrain::Agent supplied a new keyword
#       for setting up these sorts of attributes.

has last_check => (
    is => 'rw',
    isa => 'Int', 
    trigger => \&_last_check_update,
    builder => '_build_last_check',
);

method _build_last_check() {
    return $self->cache->compute(LAST_CHECK, undef, sub { time() } );
}

method _last_check_update($value!, ...) {
    $self->cache->set(LAST_CHECK, $value);
}

method poll() {
    # Record when we're making our call. We do this before we make our
    # API call, because it can be laggy, and we want to know when we
    # started the API call, not when it returned.
    my $checktime = time();

    my $last_check = $self->last_check;

    my $checkins = $self->foursquare_api('checkins/recent',
        afterTimestamp => $last_check,
    )->{response}{recent};

    # Checkins come in most-recent first, so we reverse them and make
    # them chronological.

    foreach my $checkin (reverse @$checkins) {
        my $name = ( $checkin->{user}{firstName} // "" ) . " "
                 . ( $checkin->{user}{lastName}  // "" );

        my $time = localtime($checkin->{createdAt});

        my $user = $checkin->{user}{id};

        warn "Displaying checkin at $checkin->{venue}{name} by $name\n"
            if DEBUG;

        $self->exobrain->measure('Geo::Foursquare',
            checkin => $checkin,
        );
    }

    # Finally, update our check-time.
    $self->last_check( $checktime );

}

1;

__END__

=pod

=head1 NAME

Exobrain::Agent::Foursquare::Source - Send foursquare events to the exobrain bus

=head1 VERSION

version 0.01

=for Pod::Coverage DEBUG LAST_CHECK

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
