package Metaweb;

use warnings;
use strict;

use base qw(Class::Accessor);
use URI::Escape;
use LWP::UserAgent;
use JSON::XS;
use Metaweb::Result;

__PACKAGE__->mk_accessors(qw(
    username
    password
    server
    login_path
    read_path
    write_path
    credentials
    ua
    raw_query
    raw_result
    err_code
    err_message
));

=head1 NAME

Metaweb - Perl interface to the Metaweb/Freebase API

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

    use Metaweb;

    my $mw = Metaweb->new({
        username => $username,
        password => $password
    });
    $mw->login();

  my $result = $mw->query({
      name => 'my_query',
      query => \%query,
  });

=head1 DESCRIPTION

This is a Perl interface to the Metaweb database, best known through the
application Freebase (http://freebase.com).  

If this is your first encounter with Metaweb/Freebase, chances are
you're confused about what the two terms mean.  In short, Metaweb is the
underlying database technology and Freebase is large, well-known
application that runs on it.  For comparison, consider Mediawiki
(software) and Wikipedia (website and data collection). 

This means that you can use this Metaweb module to talk to Freebase or
- in future - any other website built on the Metaweb platform.

The Metaweb Query Language (MQL) is based on JSON and query-by-example.
The MQL and API documentation can be found on the Freebase website in
the developers' area.  There is also an online Query Editor tool, with
many examples of MQL, at http://www.freebase.com/view/queryeditor/

This CPAN module provides you with everything you need to build an
application around Freebase or any other Metaweb database.  It also
provides a command line client ('metaweb') for playing around with MQL.

=head1 IMPORTANT NOTES

=head2 Alpha release

Freebase is currently in alpha release, with world-readable data but
requiring an invitation and login to be able to update/write data.

This module is very much alpha code.  It has lots of stuff not
implemented and will undergo significant changes.  Breakage may occur
between versions, so consider yourself warned.

=head2 TMTOWTDI

Also note that Hayden Stainsby is working on a different Metaweb module
called L<WWW::Metaweb>.  There's more than one way to do it.  I
encourage you to check out both modules and provide feedback/suggestions
to both of us, either directly or via the Freebase developers' mailing
list.

=head1 FUNCTIONS

=head2 new()

Instantiate a Metaweb client object.  Takes various options including:

=over 4

=item username

The username to login with

=item password

The password to login with

=item server

The server address

=item read_path

The URL path of the read service, relative to the server address

=item write_path

The URL path of the write service, relative to the server address

=item login_path

The URL path of the login service, relative to the server address

=back

None of these are actually required; the server and path options default
to Freebase's, and the username/login are only required for write
access.  Therefore, if you only want to read from Freebase, all you need
is:

    my $mw = Metaweb->new();

=cut

sub new {
    my ($class, $args) = @_;
    my $self = {};
    bless $self, $class;
    $self->username($args->{username});
    $self->password($args->{password});
    $self->server     ( $args->{server}     || 'http://www.freebase.com' );
    $self->read_path  ( $args->{read_path}  || '/api/service/mqlread'    );
    $self->write_path ( $args->{write_path} || '/api/service/mqlwrite'   );
    $self->login_path ( $args->{login_path} || '/api/account/login'      );
    return $self;
}

=head2 login()

Perform a login to the Metaweb server and pick up the necessary cookie.
Uses the username/password details provided to the constructor method,
or via the appropriately named accessor methods (see below).

=cut

sub login {
    my ($self, $args) = @_;

    my $username   = $self->username();
    my $password   = $self->password();
    my $server     = $self->server();
    my $login_path = $self->login_path();

    # warn "Server: $server\n";
    # warn "Login URL: $login_path\n";

    unless ($self->ua()) {
        $self->ua(LWP::UserAgent->new());
    }
    my $res = $self->ua->post("$server$login_path", {username=>$username,password=>$password});

    my $raw = $res->header('Set-Cookie'); 
    unless ($raw) {
        warn "Couldn't login to $server";
        return undef;
    }
    my @cookies = split(', ',$raw);        # Break cookies at commas

    # Each cookie is broken into fields with semicolons. 
    # We want the only first field of each cookie
    my $credentials = ''; # We'll accumulate login credentials here
    for my $cookie (@cookies) {                        # Loop through cookies
        my @parts = split(";", $cookie);               # Split each one on ;
        $credentials = $credentials . $parts[0] . ';'; # Remember first part
    }
    chop($credentials);   # Remove trailing semicolon
    $self->credentials($credentials);
    $self->ua->default_header('Cookie' => $credentials);

    return 1;
}

=head2 query()

Perform a MQL query.  You must provide a name and a query hash as
arguments:

  my $result = $mw->query({
      name => 'my_query',
      query => { type => 'person', name => undef } # all people!
  });

The query is a a Perl data structure that's converted to JSON using the
L<JSON::XS> module's C<to_json()> method.  The MQL envelope will
automatically be put around the query, using the name you provide.

Currently this method only supports "read" queries.  If you want to
write/upload, use C<json_query()>.

The results of this method are returned as a Perl data structure (or
undef on failure); the following attributes are also set for diagnostic
purposes.

=over 4

=item raw_query

The raw JSON used in the query.

=item raw_result

The raw JSON returned.

=item err_code

Error code (only used if an error occurs).

=item err_message

Error message (only used if an error occurs).

=back

See the accessor methods (below) for how to access all these attributes.

=cut

sub query {
    my ($self, $args) = @_;

    warn "Query name not specified" unless $args->{name};
    warn "Query not specified"      unless $args->{query};

    $args->{query} = _add_envelope($args->{name}, to_json($args->{query}));

    my $raw_result = $self->json_query($args);
    my $outer = from_json($raw_result);
    my $inner = $outer->{$args->{name}};
    
    if ($inner->{code} !~ m|^/api/status/ok|) {  # If the query was not okay
        my $err = $inner->{messages}[0];
        $self->err_code($err->{code});
        $self->err_message($err->{message});
        return undef;
    } else {
        $self->err_code(undef);
        $self->err_message(undef);
    }

    my $result = Metaweb::Result->new($inner->{result});
    return $result;
}

=head2 json_query

This method sends and receives raw JSON to the Metaweb API.  

Arguments are passed as a hashref and include:

=over 4

=item type

May be "read", "write", or "update".  Default is "read".

=item query 

The query in JSON format.  You are expected to send the full JSON,
including the envelope.

=back

The raw JSON is returned.  No parsing whatsoever is done.

C<raw_query> and C<raw_result()> are set as a side effect, same as for
C<query()>, but C<err_code()> and C<err_message> are *not* set, as we'd
need to parse the JSON to get at it and the whole point of this is that
it's unparsed.

=cut

sub json_query {
    my ($self, $args) = @_;

    warn "Query not specified"      unless $args->{query};
    my $query = $args->{query};
    $self->raw_query($query);
    my $type = $args->{type} || "read";

    unless ($self->ua()) {
        $self->ua(LWP::UserAgent->new());
    }

    my $server  = $self->server() || warn "Server not specified";

    my $response;
    if ($type eq 'write') {
        $self->ua->default_header('X-Metaweb-Request' => 1);
        my $path = $self->write_path() || warn "Query URL not specified for write";
        my $url = $server . $path;
        $response = $self->ua->post($url, { queries => $query });
    } else {
        my $path = $self->read_path() || warn "Query URL not specified for read";
        $query = uri_escape($query);
        my $url = $server . $path . "?queries=" . $query;
        $response = $self->ua->get($url);
    }

    if ($response->is_success()) {
        my $raw = $response->content();
        $self->raw_result($raw);
        return $raw;
    } else {
        warn "Request failed";
        print $self->ua->content();
    }
}

sub _add_envelope {
    my ($name, $query) = @_;
    return qq({
      "$name": {
        "query": $query
      }
    }); 
}

=head1 ACCESSOR METHODS

You probably won't need these much in day-to-day use, but they're here
for you if you want them.

=head2 username()

Get/set default login username.

=head2 password()

Get/set default login password.

=head2 server()

Get/set server to login to.  Defaults to 'http://www.freebase.com'.

=head2 login_path()

Get/set the URL to login to, relative to the server.  Defaults to
'/api/account/login'.

=head2 read_path()

Get/set the URL to perform read queries, relative to the server.  Defaults to
'/api/service/mqlread'.

=head2 write_path()

Get/set the URL to perform write queries, relative to the server.  Defaults to
'/api/service/mqlwrite'.

=head2 raw_query()

The raw JSON of the last query made.  This is set by both C<query()> and 
C<json_query()>.

=head2 raw_result()

The raw JSON from the response.  This is set by both C<query()> and
C<json_query()>.

=head2 err_code()

Set on error by C<query()>.  C<json_query()> doesn't set this; you need
to parse the JSON yourself.

=head2 err_message()

Set on error by C<query()>.  C<json_query()> doesn't set this; you need
to parse the JSON yourself.

=head1 SEE ALSO

L<JSON>, L<metaweb> (command line client), L<WWW::Metaweb> (alternative
interface).

=head1 AUTHOR

Kirrily Robert, C<< <skud at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-metaweb at rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Metaweb>.
I will be notified, and then you'll automatically be notified of progress on
your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Metaweb

You can also look for information at:

=over 4

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Metaweb>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Metaweb>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Metaweb>

=item * Search CPAN

L<http://search.cpan.org/dist/Metaweb>

=back

=head1 ACKNOWLEDGEMENTS

Thanks to the following people with whom I have discussed Metaweb Perl
APIs recently...

    Hayden Stainsby (CPAN: HDS)
    Kirsten Jones (CPAN: SYNEDRA)

=head1 COPYRIGHT & LICENSE

Copyright 2007 Kirrily Robert, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1; # End of Metaweb
