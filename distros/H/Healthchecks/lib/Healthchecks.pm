# vim:set sw=4 ts=4 sts=4 ft=perl expandtab:
package Healthchecks;
# ABSTRACT: interact with Healthchecks API
use Mojo::Base -base, -signatures;

use Mojo::UserAgent;
use Mojo::JSON qw(decode_json encode_json);
use Carp qw(carp);
use Data::Dumper;

our $VERSION = "0.01";

has 'url';
has 'apikey';
has 'user';
has 'password';
has 'proxy';
has 'ua' => sub { Mojo::UserAgent->new; };

=encoding utf-8

=head1 SYNOPSIS

  use Healthchecks;
  my $hc = Healthchecks->new(
    url      => 'http://hc.example.org',
    apikey   => 'secret_healthchecks_API_key',
    user     => 'http_user',
    password => 'http_password',
    proxy    => {
        http  => 'http://proxy.example.org',
        https => 'http://proxy.example.org'
    }
  );

  $hc->get_check('uuid_or_unique_key');

=head1 DESCRIPTION

Client module for L<Healthchecks|https://healthchecks.io/> L<HTTP API|https://healthchecks.io/docs/api/>.

=head1 ATTRIBUTES

L<Healthchecks> implements the following attributes.

=head2 url

  my $url = $hc->url;
  $hc     = $hc->url('http://hc.example.org');

MANDATORY. The Healthchecks URL, no default.

=head2 apikey

  my $apikey = $hc->apikey;
  $hc        = $hc->apikey('secret_etherpad_API_key');

MANDATORY. Secret API key, no default

=head2 ua

  my $ua = $hc->ua;
  $hc    = $hc->ua(Mojo::UserAgent->new);

OPTIONAL. User agent, default to a Mojo::UserAgent. Please, don't use anything other than a Mojo::Useragent.

=head2 user

  my $user = $hc->user;
  $hc      = $hc->user('bender');

OPTIONAL. HTTP user, use it if your Healthchecks is protected by a HTTP authentication, no default.

=head2 password

  my $password = $hc->password;
  $hc          = $hc->password('beer');

OPTIONAL. HTTP password, use it if your Healthchecks is protected by a HTTP authentication, no default.

=head2 proxy

  my $proxy = $hc->proxy;
  $hc       = $hc->proxy({
    http  => 'http://proxy.example.org',
    https => 'http://proxy.example.org'
  });

OPTIONAL. Proxy settings. If set to { detect => 1 }, Healthchecks will check environment variables HTTP_PROXY, http_proxy, HTTPS_PROXY, https_proxy, NO_PROXY and no_proxy for proxy information. No default.

=cut

sub _execute {
    my $c    = shift;
    my $args = shift;

    if (defined $c->proxy) {
        if ($c->proxy->{detect}) {
            $c->ua->proxy->detect;
        } else {
            $c->ua->proxy->http($c->proxy->{http})  if defined $c->proxy->{http};
            $c->ua->proxy->http($c->proxy->{https}) if defined $c->proxy->{https};
        }
    }

    my $url = Mojo::URL->new($args->{url} // $c->url);
    $url->userinfo($c->user.':'.$c->password) if defined $c->user && defined $c->password;

    my $path = $url->path;
    $path =~ s#/$##;
    $url->path($path.'/api/'.$args->{api}) unless $args->{url};

    $url->query($args->{query} // {});

    my $method = $args->{method} // 'get';

    my $res;
    if (defined $args->{data}) {
        $res = $c->ua->$method($url => { 'X-Api-Key' => $c->apikey } => json => $args->{data})->result;
    } else {
        $res = $c->ua->$method($url => { 'X-Api-Key' => $c->apikey })->result;
    }

    return $res->is_success if $args->{success};

    if ($res->is_success) {
        # Can’t use $res->json when json is too large
        my $json = decode_json($res->body);
        my $data;
        if (defined $args->{key}) {
            $data = (ref($json) eq 'HASH') ? $json->{$args->{key}} : $json;
        } else {
            $data = $json;
        }

        return (wantarray) ? @{$data}: $data if ref($data) eq 'ARRAY';
        return $data;
    } else {
        carp Dumper $res->message;
        return undef;
    }
}

=head1 METHODS

Healthchecks inherits all methods from Mojo::Base and implements the following new ones.

=cut

#################### subroutine header begin ####################

=head3 get_all_checks

 Usage     : $hc->get_all_checks();
 Purpose   : Get all checks
 Returns   : An array of checks belonging to the user, optionally filtered by one or more tags.
 Argument  : None
 See       : https://healthchecks.io/docs/api/#list-checks

=cut

#################### subroutine header end ####################

sub get_all_checks($c) {
    return $c->_execute({
        api => 'v1/checks/',
        key => 'checks'
    });
}

#################### subroutine header begin ####################

=head3 get_check

 Usage     : $hc->get_check('uuid_or_unique_key');
 Purpose   : Get details of a check
 Returns   : A hash, representation of a single check. 
 Argument  : Accepts either check's UUID or the unique_key (a field derived from UUID and returned by API responses when using the read-only API key) as argument.
             MANDATORY
 See       : https://healthchecks.io/docs/api/#get-check

=cut

#################### subroutine header end ####################

sub get_check($c, $uuid) {
    return $c->_execute({
        api => 'v1/checks/'.$uuid
    });
}

#################### subroutine header begin ####################

=head3 create_check

 Usage     : $hc->({name => 'foobarbaz'});
 Purpose   : Create a check
 Returns   : A hash, representation of a single check. 
 Argument  : A hash of the check’s options (see API documentation)
             OPTIONAL
 See       : https://healthchecks.io/docs/api/#create-check

=cut

#################### subroutine header end ####################

sub create_check($c, $data){
    return $c->_execute({
        api    => 'v1/checks/',
        method => 'post',
        data   => $data
    });
}

#################### subroutine header begin ####################

=head3 update_check

 Usage     : $hc->update_check('uuid', { name => 'quux' });
 Purpose   : Update the configuration of a check
 Returns   : A hash, representation of a single check.
 Argument  : The check's UUID (MANDATORY) and a hash of the check’s options (see API documentation)
             OPTIONAL
 See       : https://healthchecks.io/docs/api/#update-check

=cut

#################### subroutine header end ####################

sub update_check($c, $uuid, $data){
    return $c->_execute({
        api    => 'v1/checks/'.$uuid,
        method => 'post',
        data   => $data
    });
}

#################### subroutine header begin ####################

=head3 pause_check

 Usage     : $hc->pause_check('uuid');
 Purpose   : Disables monitoring for a check without removing it. The check goes into a "paused" state. You can resume monitoring of the check by pinging it.
 Returns   : A boolean : true if the check is paused, false otherwise.
 Argument  : The check's UUID
             MANDATORY
 See       : https://healthchecks.io/docs/api/#pause-check

=cut

#################### subroutine header end ####################

sub pause_check($c, $uuid){
    return $c->_execute({
        api    => 'v1/checks/'.$uuid.'/pause',
        method => 'post',
        key    => 'status'
    }) eq 'paused';
}

#################### subroutine header begin ####################

=head3 delete_check

 Usage     : $hc->delete_check('uuid');
 Purpose   : Permanently deletes the check from the user's account.
 Returns   : A boolean : true if the check has been successfully deleted, false otherwise.
 Argument  : The check's UUID
             MANDATORY
 See       : https://healthchecks.io/docs/api/#delete-check

=cut

#################### subroutine header end ####################

sub delete_check($c, $uuid){
    return $c->_execute({
        api     => 'v1/checks/'.$uuid,
        method  => 'delete',
        success => 1
    });
}

#################### subroutine header begin ####################

=head3 get_check_pings

 Usage     : $hc->get_check_pings('uuid');
 Purpose   : Get the pings of a check.
 Returns   : An array of pings this check has received.
 Argument  : The check's UUID
             MANDATORY
 See       : https://healthchecks.io/docs/api/#list-pings

=cut

#################### subroutine header end ####################

sub get_check_pings($c, $uuid){
    return $c->_execute({
        api => 'v1/checks/'.$uuid.'/pings/',
        key => 'pings'
    });
}

#################### subroutine header begin ####################

=head3 get_check_flips

 Usage     : $hc->get_check_flips('uuid_or_unique_key', { seconds => 3, start => 1592214380, end => 1592217980});
 Purpose   : Get the "flips" of a check has experienced.
 Returns   : An array of the "flips" the check has experienced. A flip is a change of status (from "down" to "up," or from "up" to "down").
 Argument  : Accepts either check's UUID or the unique_key (a field derived from UUID and returned by API responses when using the read-only API key) as argument.
             MANDATORY
             You can specify an optional hash table to add parameters as query string (see API documentation)
 See       : https://healthchecks.io/docs/api/#list-flips

=cut

#################### subroutine header end ####################

sub get_check_flips($c, $uuid, $query){
    return $c->_execute({
        api   => 'v1/checks/'.$uuid.'/flips/',
        key   => 'flips',
        query => $query
    });
}

#################### subroutine header begin ####################

=head3 get_integrations

 Usage     : $hc->get_all_checks();
 Purpose   : Get a list of existing integrations
 Returns   : An array of integrations belonging to the project.
 Argument  : None
 See       : https://healthchecks.io/docs/api/#list-channels

=cut

#################### subroutine header end ####################

sub get_integrations($c){
    return $c->_execute({
        api => 'api/v1/channels/',
        key => 'channels'
    });
}

#################### subroutine header begin ####################

=head3 ping_check

 Usage     : $hc->ping_check('uuid');
 Purpose   : Ping a check
 Returns   : A boolean : true if the check has been successfully pinged, false otherwise.
 Argument  : The check's UUID
             MANDATORY
 See       : This is not part of the Healthchecks API but a facility offered by this module

=cut

#################### subroutine header end ####################

sub ping_check($c, $uuid){
    return $c->_execute({
        url     => $c->_execute({
            api => 'v1/checks/'.$uuid,
            key => 'ping_url'
        }),
        success => 1
    });
}

1;

__END__

#################### footer pod documentation begin ###################
=head1 INSTALL

After getting the tarball on https://metacpan.org/release/Healthchecks, untar it, go to the directory and:

    perl Makefile.PL
    make
    make test
    make install

If you are on a windows box you should use 'nmake' rather than 'make'.

=head1 BUGS and SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Healthchecks

Bugs and feature requests will be tracked on:

    https://framagit.org/fiat-tux/perl-modules/healthchecks/issues

The latest source code can be browsed and fetched at:

    https://framagit.org/fiat-tux/perl-modules/healthchecks
    git clone https://framagit.org/fiat-tux/perl-modules/healthchecks.git

Source code mirror:

    https://github.com/ldidry/etherpad

You can also look for information at:

    AnnoCPAN: Annotated CPAN documentation

    http://annocpan.org/dist/Healthchecks
    CPAN Ratings

    http://cpanratings.perl.org/d/Healthchecks
    Search CPAN

    http://search.cpan.org/dist/Healthchecks

=head1 AUTHOR

    Luc DIDRY
    CPAN ID: LDIDRY
    ldidry@cpan.org
    https://fiat-tux.fr/

=head1 LICENSE

Copyright (C) Luc Didry.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

