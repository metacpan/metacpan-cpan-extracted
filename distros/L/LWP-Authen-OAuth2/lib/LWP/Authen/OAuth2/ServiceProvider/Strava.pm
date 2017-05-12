package LWP::Authen::OAuth2::ServiceProvider::Strava;

use strict;
use warnings;

our @ISA = qw(LWP::Authen::OAuth2::ServiceProvider);

sub authorization_endpoint {
    return "https://www.strava.com/oauth/authorize";
}

sub token_endpoint {
    return "https://www.strava.com/oauth/token";
}

sub authorization_required_params {
    my $self = shift;
    return ("client_id", "redirect_uri", "response_type", $self->SUPER::authorization_required_params());
}

sub authorization_optional_params {
    my $self = shift;
    return ("approval_prompt", "scope", "state", $self->SUPER::authorization_optional_params());
}

sub request_default_params {
    my $self = shift;
    return (
        "scope" => "public",
        "response_type" => "code",
        $self->SUPER::request_default_params()
    );
}

=head1 NAME

LWP::Authen::OAuth2::ServiceProvider::Strava - Access Strava API v3  OAuth2 APIs

=head1 VERSION

Version 0.02

=cut

package LWP::Authen::OAuth2::ServiceProvider::Strava;
our $VERSION = '0.02';

=head1 SYNOPSIS

See L<http://strava.github.io/api/> for Strava's own documentation. Strava's
documentation is very detailed, so that is the best place to find detailed
and up to date info about.

=head1 REGISTERING

Before you can use OAuth 2 with Strava you need to register yourself as a
client.  For that, go to L<https://www.strava.com/settings/api> and register
your application. You'll need to set C<redirect_uri> with them, which will 
need to be an C<https://...> URL under your control. (Though you can set
127.0.0.1 if you are using this in a script).

All the standard LWP::Useragent methods are available, but it will also
take a Request Object if you need something more. (LWP::Authen:OAuth2 contains
all the relevant doco).

=head1 AUTHOR

Leon Wright, C<< <techman@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-lwp-authen-oauth2 at rt.cpan.org>, or through
the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=LWP-Authen-OAuth2>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc LWP::Authen::OAuth2::ServiceProvider

You can also look for information at:

=over 4

=item Github (submit patches here)

L<https://github.com/domm/perl-oauth2>

=item RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=LWP-Authen-OAuth2>

=item AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/LWP-Authen-OAuth2>

=item CPAN Ratings

L<http://cpanratings.perl.org/d/LWP-Authen-OAuth2>

=item Search CPAN

L<http://search.cpan.org/dist/LWP-Authen-OAuth2/>

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2014 by Leon Wright.

This is free software; you can redistribute it and/or modify it under the same terms as the Perl 5 programming language system itself.

=cut

1;
