package Finance::Wesabe;

use Moose;

use URI;
use LWP::UserAgent;
use XML::Simple ();

use Finance::Wesabe::Account;
use Finance::Wesabe::Profile;

our $VERSION = '0.02';
our $API_VERSION = '1.0.0';

my $agent_name = __PACKAGE__ . "/$VERSION Wesabe-API/$API_VERSION"; 

=head1 NAME

Finance::Wesabe - Access your wesabe.com account information

=head1 SYNOPSIS

    my $w = Finance::Wesabe->new( {
        username => $u,
        password => $p,
    } );
    
    printf "%s: %s\n", $_->name, $_->pretty_balance for $w->accounts;

=head1 DESCRIPTION

    Wesabe is part money management tool, part community.

This module provides access to your basic account info via the wesabe
API. It currently supports a subset of the 1.0.0 API.

=head1 WESABE.COM SHUTDOWN / OPEN SOURCE "MESABE"

On July 31st, 2010, the wesabe.com service shut its doors. Subsequently,
parts of the application have been released as open source code on the wesabe
github account (L<http://www.github.com/wesabe>).

Of particular interest are the instructions to get a local copy of the wesabe
web app running locally (known as "mesabe"): L<http://github.com/wesabe/mesabe/wiki>.

At the time of this writing, it is unclear if this module will interface
with a locally run version of the app, however, the base URL is configurable
as follows:

    my $w = Finance::Wesabe->new( {
        url      => 'http://localhost:3000/', # change as required
        username => $u,
        password => $p,
    } );
    

=head1 ACCESSORS

=over 4

=item * agent - A useragent for all requests

=item * url - Base URI for all requests

=item * username - your wesabe.com username

=item * password - your wesabe.com password

=back

=cut

has 'agent' =>
    ( is => 'ro', isa => 'Object', default => sub { LWP::UserAgent->new( agent => $agent_name ) } );

has 'url' =>
    ( is => 'ro', isa => 'URI',
     default => sub { URI->new( 'https://www.wesabe.com/' ) } );

has 'username' => ( is => 'ro', isa => 'Str' );

has 'password' => ( is => 'ro', isa => 'Str' );

=head1 METHODS

=head2 accounts( )

Returns L<Finance::Wesabe::Account> objects for each of your accounts.

=cut

sub accounts {
    my $self = shift;
    my $xml = $self->_get_req( '/accounts.xml' );
    return map { Finance::Wesabe::Account->new( content => $_, parent => $self ) } @{ $xml->{ account } };
}

=head2 account( $index )

Returns a L<Finance::Wesabe::Account> object for the given <$index>.

NB: Accounts have no specific numeric id, so C<1> means the first account,
and so on.

=cut

sub account {
    my( $self, $id ) = @_;
    my $xml = $self->_get_req( "/accounts/${id}.xml" );
    return Finance::Wesabe::Account->new( content => $xml, parent => $self );
}

=head2 profile( )

Returns a L<Finance::Wesabe::Profile> with your profile information.

=cut

sub profile {
    my( $self ) = @_;
    my $xml = $self->_get_req( "/profile.xml" );
    return Finance::Wesabe::Profile->new( content => $xml, parent => $self );
}

sub _get_req {
    my( $self, $path ) = @_;

    my $url = $self->url->clone;
    $url->path( $path );

    my $req = HTTP::Request->new( GET => $url );
    $req->authorization_basic( $self->username, $self->password );
    my $response = $self->agent->request( $req );

    my $xml = XML::Simple::XMLin( $response->content, KeyAttr => [] );
    return $xml;
}

no Moose;

__PACKAGE__->meta->make_immutable;

=head1 SEE ALSO

=over 4

=item * L<http://www.wesabe.com>

=item * L<http://github.com/wesabe/mesabe/wiki>

=back

=head1 AUTHOR

Brian Cassidy E<lt>bricas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2009-2010 by Brian Cassidy

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself. 

=cut

1;
