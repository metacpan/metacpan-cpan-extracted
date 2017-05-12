package Exobrain::Agent::Foursquare;
use Moose::Role;
use Method::Signatures;
use WWW::Mechanize;

with 'Exobrain::Agent';

# ABSTRACT: Roles for Exobrain Foursquare agents
our $VERSION = '0.01'; # VERSION


sub component_name { "Foursquare" }


has mech => (is => 'ro', lazy => 1, builder => '_build_mech');
sub _build_mech { WWW::Mechanize->new( stack_depth => 0, autocheck => 1 ); }


has auth_token => (is => 'ro', isa => 'Str', lazy => 1, builder => '_build_token');
method _build_token() { $self->config->{auth_token} }


has api_base => (is => 'ro', isa => 'Str', default => 'https://api.foursquare.com/v2' );


method foursquare_api($path, %args) {
    my $base  = $self->api_base;

    my %full_args = (
        v => '20130425',
        oauth_token => $self->auth_token,
        %args
    );

    # Provide a full set of arguments we can just append
    # Eg: fooboz=42&v=20130425&oauth_token=...
    my $arguments = join('&', map { "$_=$full_args{$_}" } keys %full_args );

    # Make our call, and decode the resulting JSON.

    $self->mech->get("$base/$path?$arguments");
    return $self->json->decode( $self->mech->content );

}

1;

__END__

=pod

=head1 NAME

Exobrain::Agent::Foursquare - Roles for Exobrain Foursquare agents

=head1 VERSION

version 0.01

=head1 SYNOPSIS

    use Moose;
    with 'Exobrain::Agent::Foursquare'

=head1 DESCRIPTION

This role provides useful methods and attributes for agents wishing
to integrate with Foursquare

=head1 METHODS

=head2 mech

    my $mech = $self->mech;

Returns a L<WWW::Mechanize> object. By default its stack depth is set to zero
(which avoid memory leaks in long-running processes), and autocheck is on
(so it will throw an exception on error).

Primarily used by L</foursquare_api>.

=head2 auth_token

    my $token = $self->auth_token

Returns the auth_token, taken from the user's configuration.

Primarily used by L</foursquare_api>.

=head2 api_base

Returns the Foursquare API base path to use. By default this is
C<https://api.foursquare.com/v2>.

Primarily used by L</foursquare_api>.

=head2 foursquare_api

    my $checkins = $self->foursquare_api('checkins/recent',
        afterTimestamp => $last_check,
    );

Calls the Foursquare API endpoint specified in the first argument, and converts
the response into a Perl data structure. All additional named arguments are
considered to be parameters that will be appended to the call.

This method automatically adds auth tokens and version strings as appropriate.

=for Pod::Coverage component_name

=head1 AUTHOR

Paul Fenwick <pjf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Paul Fenwick.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
