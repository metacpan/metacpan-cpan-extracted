package LWP::Authen::OAuth2::ServiceProvider::MediaWiki;

use base qw(LWP::Authen::OAuth2::ServiceProvider);
use strict;
use warnings;

use Error::Pure qw(err);

our $VERSION = '0.01';

sub authorization_endpoint {
	err 'Need to be implemented. End point /oauth2/authorize.';
}

sub token_endpoint {
	err 'Need to be implemented. End point oauth2/access_token.';
}

sub authorization_required_params {
	my $self = shift;
	return ('response_type', 'client_id');
}

sub authorization_optional_params {
	my $self = shift;
	return ('redirect_uri', 'scope', 'state', 'code_challenge', 'code_challenge_method');
}

sub authorization_default_params {
	my $self = shift;
	return ('response_type' => 'code');
}

sub request_required_params {
	my $self = shift;
	return ('grant_type');
}

sub request_optional_params {
	my $self = shift;
	return ('client_id', 'client_secret', 'redirect_uri', 'scope', 'code',
		'refresh_token', 'code_verifier');
}

sub request_default_params {
	my $self = shift;
	return ('grant_type' => 'authorization_code');
}

sub refresh_required_params {
	my $self = shift;
	return ('grant_type', 'refresh_token', 'client_id', 'client_secret');
}

sub refresh_default_params {
	my $self = shift;
	return ('grant_type' => 'refresh_token');
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

LWP::Authen::OAuth2::ServiceProvider::MediaWiki - Access MediaWiki using OAuth2.

=head1 SYNOPSIS

 use package LWP::Authen::OAuth2::ServiceProvider::Foo;

 use base qw(LWP::Authen::OAuth2::ServiceProvider::MediaWiki);
 use strict;
 use warnings;

 sub authorization_endpoint {
         return 'https://example.com/oauth2/authorize';
 }

 sub token_endpoint {
         return 'https://example.com/oauth2/access_token';
 }

 1;

=head1 DESCRIPTION

See L<https://www.mediawiki.org/wiki/Extension:OAuth> for MediaWiki extension documentation.

See L<https://www.mediawiki.org/wiki/OAuth/For_Developers> page which is for
developers.

Real implementation is LWP::Authen::OAuth2::ServiceProvider::Wikimedia for
Wikimedia meta OAuth2.

=head1 DEPENDENCIES

L<Error::Pure>,
L<LWP::Authen::OAuth2::ServiceProvider>.

=head1 SEE ALSO

=over

=item L<LWP::Authen::OAuth2>

Make requests to OAuth2 APIs.

=item L<LWP::Authen::OAuth2::ServiceProvider>

ServiceProvider base class

=item L<LWP::Authen::OAuth2::ServiceProvider::Wikimedia>

Access Wikimedia using OAuth2.

=back

=head1 REPOSITORY

L<https://github.com/michal-josef-spacek/LWP-Authen-OAuth2-ServiceProvider-MediaWiki>

=head1 AUTHOR

Michal Josef Špaček L<mailto:skim@cpan.org>

L<http://skim.cz>

=head1 LICENSE AND COPYRIGHT

© Michal Josef Špaček 2022

BSD 2-Clause License

=head1 VERSION

0.01

=cut
