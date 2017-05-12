package Exobrain::Foursquare;
use Moose;
use Exobrain::Config;
use JSON::Any;
use Try::Tiny;
use feature qw(say);

# ABSTRACT: Foursquare components for Exobrain
our $VERSION = '0.01'; # VERSION

with 'Exobrain::Component';

my $FOURSQUARE_API = 'https://api.foursquare.com/v2';

sub component { "foursquare" };

sub services {
    return (
        source => 'Foursquare::Source',
    );
}

sub setup {

    # Load module and die swiftly on failure
    eval 'use WWW::Mechanize; 1;' or die $@;

    say "Welcome to the Exobrain::Foursquare setup process.";
    say "To complete setup, we'll need a valid FourSquare auth token";
    say "You can yoink this out of the API explorer at";
    say 'https://developer.foursquare.com/docs/explore';

    print "Auth token: ";
    chomp( my $token = <STDIN> );

    # Check to see if we auth okay.

    my $mech = WWW::Mechanize->new( autocheck => 1 );
    my $json = JSON::Any->new;

    $mech->get("$FOURSQUARE_API/checkins/recent?oauth_token=$token&v=20130425");

    my $status = $json->decode($mech->content);

    if ($status->{meta}{code} != 200) {
        my $reason = $status->{meta}{errorDetail} || "Unknown error, sorry!";
        die "Auth failed! $reason\n";
    }
    
    say "\nThanks! Writing configuration...";

    my $config =
        "[Components]\n" .
        "Foursquare=$VERSION\n\n" .

        "[Foursquare]\n" .
        "auth_token = $token\n"
    ;

    my $filename = Exobrain::Config->write_config('Foursquare.ini', $config);

    say "\nConfig written to $filename. Have a nice day!";

    return;
}

1;

__END__

=pod

=head1 NAME

Exobrain::Foursquare - Foursquare components for Exobrain

=head1 VERSION

version 0.01

=for Pod::Coverage setup services component

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
