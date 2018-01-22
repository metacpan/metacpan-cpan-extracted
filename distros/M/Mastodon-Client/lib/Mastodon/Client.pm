# ABSTRACT: Talk to a Mastodon server
package Mastodon::Client;

use strict;
use warnings;
use v5.10.0;

our $VERSION = '0.013';

use Carp;
use Mastodon::Types qw( Acct Account DateTime Image URI Instance );
use Moo;
use Types::Common::String qw( NonEmptyStr );
use Types::Standard
  qw( Int Str Optional Bool Maybe Undef HashRef ArrayRef Dict slurpy );
use Types::Path::Tiny qw( File );

use Log::Any;
my $log = Log::Any->get_logger(category => 'Mastodon');

with 'Mastodon::Role::UserAgent';

has coerce_entities => (
  is   => 'rw',
  isa  => Bool,
  lazy => 1,
  default => 0,
);

has access_token => (
  is   => 'rw',
  isa  => NonEmptyStr,
  lazy => 1,
);

has authorized => (
  is      => 'rw',
  isa     => DateTime|Bool,
  lazy    => 1,
  default => sub { defined $_[0]->access_token },
  coerce  => 1,
);

has client_id => (
  is   => 'rw',
  isa  => NonEmptyStr,
  lazy => 1,
);

has client_secret => (
  is   => 'rw',
  isa  => NonEmptyStr,
  lazy => 1,
);

has name => (
  is  => 'ro',
  isa => NonEmptyStr,
);

has website => (
  is  => 'ro',
  isa => Str,
  lazy => 1,
  default => q{},
);

has account => (
  is  => 'rw',
  isa => HashRef|Account,
  init_arg => undef,
  lazy => 1,
  default => sub {
    $_[0]->get_account;
  },
);

has scopes => (
  is      => 'ro',
  isa     => ArrayRef->plus_coercions( Str, sub { [ split / /, $_ ] } ),
  lazy    => 1,
  default => sub { [ 'read' ] },
  coerce  => 1,
);

after access_token => sub {
  my $self = shift;
  $self->authorized(1);
};

sub authorize {
  my $self = shift;

  unless ( $self->client_id and $self->client_secret ) {
    croak $log->fatal(
      'Cannot authorize client without client_id and client_secret');
  }

  if ( $self->access_token ) {
    $log->warn('Client is already authorized');
    return $self;
  }

  state $check = compile(
    slurpy Dict [
      access_code => Str->plus_coercions( Undef, sub {q{}} ),
      username  => Str->plus_coercions( Undef, sub {q{}} ),
      password  => Str->plus_coercions( Undef, sub {q{}} ),
    ],
  );
  my ($params) = $check->(@_);

  my $data = {
    client_id     => $self->client_id,
    client_secret => $self->client_secret,
    redirect_uri  => $self->redirect_uri,
  };

  if ( $params->{access_code} ) {
    $data->{grant_type} = 'authorization_code';
    $data->{code}       = $params->{access_code};
  }
  else {
    $data->{grant_type} = 'password';
    $data->{username}   = $params->{username};
    $data->{password}   = $params->{password};
  }

  my $response = $self->post( 'oauth/token' => $data );

  if ( defined $response->{error} ) {
    $log->warn( $response->{error_description} );
  }
  else {
    my $granted_scopes   = join q{ }, sort split( / /, $response->{scope} );
    my $requested_scopes = join q{ }, sort @{ $self->scopes };

    croak $log->fatal('Granted and requested scopes do not match')
      if $granted_scopes ne $requested_scopes;

    $self->access_token( $response->{access_token} );
    $self->authorized( $response->{created_at} );
  }

  return $self;
}

# Authorize follow requests by account ID
sub authorize_follow {
  my $self = shift;
  state $check = compile( Int );
  my ($id) = $check->(@_);
  return $self->post( 'follow_requests/authorize' => { id => $id } );
}

# Clears notifications
sub clear_notifications {
  my $self = shift;
  state $check = compile();
  $check->(@_);

  return $self->post( 'notifications/clear' );
}

# Delete a status by ID
sub delete_status {
  my $self = shift;

  state $check = compile( Int );
  my ($id) = $check->(@_);

  return $self->delete( "statuses/$id" );
}

sub fetch_instance {
  my $self = shift;

  # Do not return from the instance attribute, since the user might have
  # disabled coercions, and the attribute is always coerced
  my $instance = $self->get( 'instance' );
  $self->instance($instance);
  return $instance;
}

sub get_account {
  my $self = shift;
  my $own = 'verify_credentials';

  state $check = compile( Optional [Int|HashRef], Optional [HashRef] );
  my ($id, $params) = $check->(@_);

  if (ref $id eq 'HASH') {
    $params = $id;
    $id = undef;
  }

  $id     //= $own;
  $params //= {};

  my $data = $self->get( "accounts/$id", $params );

  # We fetched authenticated user account's data
  # Update local reference
  $self->account($data) if ($id eq $own);
  return $data;
}

# Get a single notification by ID
sub get_notification {
  my $self = shift;
  state $check = compile( Int, Optional [HashRef] );
  my ($id, $params) = $check->(@_);

  return $self->get( "notifications/$id", $params );
}

# Get a single status by ID
sub get_status {
  my $self = shift;
  state $check = compile( Int, Optional [HashRef] );
  my ($id, $params) = $check->(@_);

  return $self->get( "statuses/$id", $params );
}

# Post a status
sub post_status {
  my $self = shift;
  state $check = compile( Str|HashRef, Optional[HashRef]);
  my ($text, $params) = $check->(@_);
  $params //= {};

  my $payload;
  if (ref $text eq 'HASH') {
    $params = $text;
    croak $log->fatal('Post must contain a (possibly empty) status text')
      unless defined $params->{status};
    $payload = $params;
  }
  else {
    $payload = { status => $text, %{$params} };
  }

  return $self->post( 'statuses', $payload);
}

# Reblog a status by ID
sub reblog_status {
  my $self = shift;

  state $check = compile( Int );
  my ($id) = $check->(@_);

  return $self->post( "statuses/$id/reblog" );
}

sub register {
  my $self = shift;

  if ( $self->client_id && $self->client_secret ) {
    $log->warn('Client is already registered');
    return $self;
  }

  state $check = compile(
    slurpy Dict [
      instance => Instance->plus_coercions( Undef, sub { $self->instance } ),
      redirect_uris =>
        Str->plus_coercions( Undef, sub { $self->redirect_uri } ),
      scopes =>
        ArrayRef->plus_coercions( Undef, sub { $self->scopes } ),
      website => Str->plus_coercions( Undef, sub { $self->website } ),
    ]
  );
  my ($params) = $check->(@_);

  my $response = $self->post('apps' => {
    client_name   => $self->name,
    redirect_uris => $params->{redirect_uris},
    scopes        => join q{ }, sort( @{ $params->{scopes} } ),
  });

  $self->client_id( $response->{client_id} );
  $self->client_secret( $response->{client_secret} );

  return $self;
}

sub statuses {
  my $self = shift;
  state $check = compile( Optional [HashRef|Int], Optional [HashRef]);
  my ($id, $params) = $check->(@_);
  if (ref $id) {
    $params = $id;
    $id = undef;
  }
  $id //= $self->account->{id};
  $params //= {};

  return $self->get( "accounts/$id/statuses", $params );
}

# Reject follow requsts by account ID
sub reject_follow {
  my $self = shift;
  state $check = compile( Int );
  my ($id) = $check->(@_);
  return $self->post( 'follow_requests/reject' => { id => $id } );
}

# Follow a remote user by acct (username@instance)
sub remote_follow {
  my $self = shift;
  state $check = compile( Acct );
  my ($acct) = $check->(@_);
  return $self->post( 'follows' => { uri => $acct } );
}

# Report a user account or list of statuses
sub report {
  my $self = shift;
  state $check = compile( slurpy Dict[
    account_id => Optional[Int],
    status_ids => Optional[ArrayRef->plus_coercions( Int, sub { [ $_ ] } ) ],
    comment => Optional[Str],
  ]);
  my ($data) = $check->(@_);

  croak $log->fatal('Either account_id or status_ids are required for report')
    unless join(q{ }, keys(%{$data})) =~ /\b(account_id|status_ids)\b/;

  return $self->post( 'reports' => $data );
}

sub relationships {
  my $self = shift;

  state $check = compile( slurpy ArrayRef [Int|HashRef] );
  my ($ids) = $check->(@_);
  my $params = (ref $ids->[-1] eq 'HASH') ? pop(@{$ids}) : {};

  croak $log->fatal('At least one ID number needed in relationships')
    unless scalar @{$ids};

  $params = {
    id => $ids,
    %{$params},
  };

  return $self->get( 'accounts/relationships', $params );
}

sub search {
  my $self = shift;

  state $check = compile( Str, Optional [HashRef] );
  my ($query, $params) = $check->(@_);
  $params //= {};

  $params = {
    'q' => $query,
    %{$params},
  };

  return $self->get( 'search', $params );
}

sub search_accounts {
  my $self = shift;

  state $check = compile( Str, Optional [HashRef] );
  my ($query, $params) = $check->(@_);
  $params //= {};

  $params = {
    'q' => $query,
    %{$params},
  };

  return $self->get( 'accounts/search', $params );
}

sub stream {
  my $self = shift;

  state $check = compile( NonEmptyStr );
  my ($query) = $check->(@_);

  my $endpoint
    = $self->instance->uri
    . '/api/v'
    . $self->api_version
    . '/streaming/'
    . (( $query =~ /^#/ )
        ? ( 'hashtag?' . $query )
        : $query
      );

  use Mastodon::Listener;
  return Mastodon::Listener->new(
    url             => $endpoint,
    access_token    => $self->access_token,
    coerce_entities => $self->coerce_entities,
  );
}

sub timeline {
  my $self = shift;

  state $check = compile( NonEmptyStr, Optional [HashRef] );
  my ($query, $params) = $check->(@_);

  my $endpoint
    = ( $query =~ /^#/ )
    ? 'timelines/tag/' . $query
    : 'timelines/'     . $query;

  return $self->get($endpoint, $params);
}

sub update_account {
  my $self = shift;

  state $check = compile(
    slurpy Dict [
      display_name => Optional [Str],
      note         => Optional [Str],
      avatar       => Optional [Image],
      header       => Optional [Image],
    ]
  );
  my ($data) = $check->(@_);

  return $self->patch( 'accounts/update_credentials' => $data );
}

sub upload_media {
  my $self = shift;

  state $check = compile(
    File->plus_coercions( Str, sub { Path::Tiny::path($_) } )
  );
  my ($file) = $check->(@_);

  return $self->post( 'media' =>
    { file => [ $file, undef ] },
    headers => { Content_Type => 'form-data' },
  );
}

# POST requests with no data and a mandatory ID number
foreach my $pair ([
    [ statuses => [qw( reblog unreblog favourite unfavourite     )] ],
    [ accounts => [qw( mute unmute block unblock follow unfollow )] ],
  ]) {

  my ($base, $endpoints) = @{$pair};

  foreach my $endpoint (@{$endpoints}) {
    my $method = ($base eq 'statuses') ? $endpoint . '_status' : $endpoint;

    no strict 'refs';
    *{ __PACKAGE__ . '::' . $method } = sub {
      my $self = shift;
      state $check = compile( Int );
      my ($id) = $check->(@_);

      return $self->post( "$base/$id/$endpoint" );
    };
  }
}

# GET requests with no parameters but optional parameter hashref
for my $action (qw(
    blocks favourites follow_requests mutes notifications reports
  )) {

  no strict 'refs';
  *{ __PACKAGE__ . '::' . $action } = sub {
    my $self = shift;
    state $check = compile(Optional [HashRef]);
    my ($params) = $check->(@_);
    $params //= {};

    return $self->get( $action, $params );
  };
}

# GET requests with optional ID and parameter hashref
# ID number defaults to authenticated account's ID
for my $action (qw( following followers )) {
  no strict 'refs';
  *{ __PACKAGE__ . '::' . $action } = sub {
    my $self = shift;
    state $check = compile( Optional [Int|HashRef], Optional [HashRef] );
    my ($id, $params) = $check->(@_);

    if (ref $id eq 'HASH') {
      $params = $id;
      $id = undef;
    }

    $id     //= $self->account->{id};
    $params //= {};

    return $self->get( "accounts/$id/$action", $params );
  };
}

# GET requests for status details
foreach my $pair ([
    [ get_status_context    => 'context'       ],
    [ get_status_card       => 'card'          ],
    [ get_status_reblogs    => 'reblogged_by'  ],
    [ get_status_favourites => 'favourited_by' ],
  ]) {

  my ($method, $endpoint) = @{$pair};

  no strict 'refs';
  *{ __PACKAGE__ . '::' . $method } = sub {
    my $self = shift;
    state $check = compile( Int, Optional [HashRef] );
    my ($id, $params) = $check->(@_);

    return $self->get( "statuses/$id/$endpoint", $params );
  };
}

1;

__END__

=encoding utf8

=head1 NAME

Mastodon::Client - Talk to a Mastodon server

=head1 SYNOPSIS

  use Mastodon::Client;

  my $client = Mastodon::Client->new(
    instance        => 'mastodon.social',
    name            => 'PerlBot',
    client_id       => $client_id,
    client_secret   => $client_secret,
    access_token    => $access_token,
    coerce_entities => 1,
  );

  $client->post_status('Posted to a Mastodon server!');
  $client->post_status('And now in secret...',
    { visibility => 'unlisted' }
  )

  # Streaming interface might change!
  my $listener = $client->stream( 'public' );
  $listener->on( update => sub {
    my ($listener, $status) = @_;
    printf "%s said: %s\n",
      $status->account->display_name,
      $status->content;
  });
  $listener->start;

=head1 DESCRIPTION

Mastodon::Client lets you talk to a Mastodon server to obtain authentication
credentials, read posts from timelines in both static or streaming mode, and
perform all the other operations exposed by the Mastodon API.

Most of these are available through the convenience methods listed below, which
validate input parameters and are likely to provide more meaningful feedback in
case of errors.

Alternatively, this distribution can be used via the low-level request methods
(B<post>, B<get>, etc), which allow direct access to the API endpoints. All
other methods call one of these at some point.

=head1 ATTRIBUTES

=over 4

=item B<instance>

A Mastodon::Entity::Instance object representing the instance to which this
client will speak. Defaults to C<mastodon.social>.

=item B<api_version>

An integer specifying the version of the API endpoints to use. Defaults to C<1>.

=item B<redirect_uri>

The URI to which authorization codes should be forwarded as part of the OAuth2
flow. Defaults to C<urn:ietf:wg:oauth:2.0:oob> (meaning no redirection).

=item B<user_agent>

The user agent to use for the requests. Defaults to an instance of
L<LWP::UserAgent>. It is expected to have a C<request> method that accepts
instances of L<HTTP::Request> objects.

=item B<coerce_entities>

A boolean value. Set to true if you want Mastodon::Client to internally coerce
all response entities to objects. This adds a level of validation, and can
make the objects easier to use.

Although this does require some additional processing, the coercion is done by
L<Type::Tiny>, so the impact is negligible.

For now, it defaults to B<false> (but this will likely change, so I recommend
you use it).

=item B<access_token>

The access token of your client. This is provided by the Mastodon API and is
used for the OAuth2 authentication required for most API calls.

You can get this by calling B<authorize> with either an access code or your
account's username and password.

=item B<authorized>

Boolean. False is the client has no defined access_token. When an access token
is set, this is set to true or to a L<DateTime> object representing the time of
authorization if possible (as received from the server).

=item B<client_id>

=item B<client_secret>

The client ID and secret are provided by the Mastodon API when you register
your client using the B<register> method. They are used to identify where your
calls are coming from, and are required before you can use the B<authorize>
method to get the access token.

=item B<name>

Your client's name. This is required when registering, but is otherwise seldom
used. If you are using the B<authorization_url> to get an access code from your
users, then they will see this name when they go to that page.

=item B<account>

Holds the authenticated account. It is set internally by the B<get_account>
method.

=item B<scopes>

This array reference holds the scopes set by you for the client. These are
required when registering your client with the Mastodon instance. Defaults to
C<read>.

Mastodon::Client will internally make sure that the scopes you were provided
when calling B<authorize> match those that you requested. If this is not the
case, it will helpfully die.

=item B<website>

The URL of a human-readable website for the client. If made available, it
appears as a link in the "authorized applications" tab of the user preferences
in the default Mastodon web GUI. Defaults to the empty string.

=back

=head1 METHODS

=head2 Authorizing an application

Although not all of the API methods require authentication to be used, most of
them do. The authentication process involves a) registering an application with
a Mastodon server to obtain a client secret and ID; b) authorizing the
application by either providing a user's credentials, or by using an
authentication URL.

The methods facilitating this process are detailed below:

=over 4

=item B<register()>

=item B<register($data)>

Obtain a client secret and ID from a given mastodon instance. Takes a single
hash reference as an argument, with the following possible keys:

=over 4

=item B<redirect_uris>

The URL to which authorization codes should be forwarded after authorized by
the user. Defaults to the value of the B<redirect_uri> attribute.

=item B<scopes>

The scopes requested by this client. Defaults to the value of the B<scopes>
attribute.

=item B<website>

The client's website. Defaults to the value of the C<website> attribute.

=back

When successful, sets the C<client_secret> and C<client_id> attributes of
the Mastodon::Client object and returns the modified object.

This should be called B<once> per client and its contents cached locally.

=item B<authorization_url()>

Generate an authorization URL for the given application. Accessing this URL
via a browser by a logged in user will allow that user to grant this
application access to the requested scopes. The scopes used are the ones in the
B<scopes> attribute at the time this method is called.

=item B<authorize()>

=item B<authorize( %data )>

Grant the application access to the requested scopes for a given user. This
method takes a hash with either an access code or a user's login credentials to
grant authorization. Valid keys are:

=over 4

=item B<access_code>

The access code obtained by visiting the URL generated by B<authorization_url>.

=item B<username>

=item B<password>

The user's login credentials.

=back

When successful, the method automatically sets the client's B<authorized>
attribute to a true value and caches the B<access_token> for all future calls.

=back

The remaining methods listed here follow the order of those in the official API
documentation.

=head2 Accounts

=over 4

=item B<get_account()>

=item B<get_account($id)>

=item B<get_account($params)>

=item B<get_account($id, $params)>

Fetches an account by ID. If no ID is provided, this defaults to the current
authenticated account. Global GET parameters are available for this method.

Depending on the value of C<coerce_entities>, it returns a
Mastodon::Entity::Account object, or a plain hash reference.

=item B<update_account($params)>

Make changes to the authenticated account. Takes a hash reference with the
following possible keys:

=over 4

=item B<display_name>

=item B<note>

Strings

=item B<avatar>

=item B<header>

A base64 encoded image, or the name of a file to be encoded.

=back

Depending on the value of C<coerce_entities>, returns the modified
Mastodon::Entity::Account object, or a plain hash reference.

=item B<followers()>

=item B<followers($id)>

=item B<followers($params)>

=item B<followers($id, $params)>

Get the list of followers of an account by ID. If no ID is provided, the one
for the current authenticated account is used. Global GET parameters are
available for this method.

Depending on the value of C<coerce_entities>, returns an array reference of
Mastodon::Entity::Account objects, or a plain array reference.

=item B<following()>

=item B<following($id)>

=item B<following($params)>

=item B<following($id, $params)>

Get the list of accounts followed by the account specified by ID. If no ID is
provided, the one for the current authenticated account is used. Global GET
parameters are available for this method.

Depending on the value of C<coerce_entities>, returns an array reference of
Mastodon::Entity::Account objects, or a plain array reference.

=item B<statuses()>

=item B<statuses($id)>

=item B<statuses($params)>

=item B<statuses($id, $params)>

Get a list of statuses from the account specified by ID. If no ID is
provided, the one for the current authenticated account is used.

In addition to the global GET parameters, this method accepts the following
parameters:

=over 4

=item B<only_media>

=item B<exclude_replies>

Both boolean.

=back

Depending on the value of C<coerce_entities>, returns an array reference of
Mastodon::Entity::Status objects, or a plain array reference.

=item B<follow($id)>

=item B<unfollow($id)>

Follow or unfollow an account specified by ID. The ID argument is mandatory.

Depending on the value of C<coerce_entities>, returns the new
Mastodon::Entity::Relationship object, or a plain hash reference.

=item B<block($id)>

=item B<unblock($id)>

Block or unblock an account specified by ID. The ID argument is mandatory.

Depending on the value of C<coerce_entities>, returns the new
Mastodon::Entity::Relationship object, or a plain hash reference.

=item B<mute($id)>

=item B<unmute($id)>

Mute or unmute an account specified by ID. The ID argument is mandatory.

Depending on the value of C<coerce_entities>, returns the new
Mastodon::Entity::Relationship object, or a plain hash reference.

=item B<relationships(@ids)>

=item B<relationships(@ids, $params)>

Get the list of relationships of the current authenticated user with the
accounts specified by ID. At least one ID is required, but more can be passed
at once. Global GET parameters are available for this method, and can be passed
as an additional hash reference as a final argument.

Depending on the value of C<coerce_entities>, returns an array reference of
Mastodon::Entity::Relationship objects, or a plain array reference.

=item B<search_accounts($query)>

=item B<search_accounts($query, $params)>

Search for accounts. Takes a mandatory string argument to use as the search
query. If the search query is of the form C<username@domain>, the accounts
will be searched remotely.

In addition to the global GET parameters, this method accepts the following
parameters:

=over 4

=item B<limit>

The maximum number of matches. Defaults to 40.

=back

Depending on the value of C<coerce_entities>, returns an array reference of
Mastodon::Entity::Account objects, or a plain array reference.

This method does not require authentication.

=back

=head2 Blocks

=over 4

=item B<blocks()>

=item B<blocks($params)>

Get the list of accounts blocked by the authenticated user. Global GET
parameters are available for this method.

Depending on the value of C<coerce_entities>, returns an array reference of
Mastodon::Entity::Account objects, or a plain array reference.

=back

=head2 Favourites

=over 4

=item B<favourites()>

=item B<favourites($params)>

Get the list of statuses favourited by the authenticated user. Global GET
parameters are available for this method.

Depending on the value of C<coerce_entities>, returns an array reference of
Mastodon::Entity::Status objects, or a plain array reference.

=back

=head2 Follow requests

=over 4

=item B<follow_requests()>

=item B<follow_requests($params)>

Get the list of accounts requesting to follow the the authenticated user.
Global GET parameters are available for this method.

Depending on the value of C<coerce_entities>, returns an array reference of
Mastodon::Entity::Account objects, or a plain array reference.

=item B<authorize_follow($id)>

=item B<reject_follow($id)>

Accept or reject the follow request by the account of the specified ID. The ID
argument is mandatory.

Returns an empty object.

=back

=head2 Follows

=over 4

=item B<remote_follow($acct)>

Follow a remote user by account string (ie. C<username@domain>). The argument
is mandatory.

Depending on the value of C<coerce_entities>, returns an
Mastodon::Entity::Account object, or a plain hash reference with the local
representation of the specified account.

=back

=head2 Instances

=over 4

=item B<fetch_instance()>

Fetches the latest information for the current instance the client is talking
to. When successful, this method updates the value of the C<instance>
attribute.

Depending on the value of C<coerce_entities>, returns an
Mastodon::Entity::Instance object, or a plain hash reference.

This method does not require authentication.

=back

=head2 Media

=over 4

=item B<upload_media($file)>

Upload a file as an attachment. Takes a single argument with the name of a
local file to encode and upload. The argument is mandatory.

Depending on the value of C<coerce_entities>, returns an
Mastodon::Entity::Attachment object, or a plain hash reference.

The returned object's ID can be passed to the B<post_status> to post it to a
timeline.

=back

=head2 Mutes

=over 4

=item B<mutes()>

=item B<mutes($params)>

Get the list of accounts muted by the authenticated user. Global GET
parameters are available for this method.

Depending on the value of C<coerce_entities>, returns an array reference of
Mastodon::Entity::Account objects, or a plain array reference.

=back

=head2 Notifications

=over 4

=item B<notifications()>

=item B<notifications($params)>

Get the list of notifications for the authenticated user. Global GET
parameters are available for this method.

Depending on the value of C<coerce_entities>, returns an array reference of
Mastodon::Entity::Notification objects, or a plain array reference.

=item B<get_notification($id)>

Get a notification by ID. The argument is mandatory.

Depending on the value of C<coerce_entities>, returns an
Mastodon::Entity::Notification object, or a plain hash reference.

=item B<clear_notifications()>

Clears all notifications for the authenticated user.

This method takes no arguments and returns an empty object.

=back

=head2 Reports

=over 4

=item B<reports()>

=item B<reports($params)>

Get a list of reports made by the authenticated user. Global GET
parameters are available for this method.

Depending on the value of C<coerce_entities>, returns an array reference of
Mastodon::Entity::Report objects, or a plain array reference.

=item B<report($params)>

Report a user or status. Takes a mandatory hash with the following keys:

=over 4

=item B<account_id>

The ID of a single account to report.

=item B<status_ids>

The ID of a single status to report, or an array reference of statuses to
report.

=item B<comment>

An optional string.

=back

While the comment is always optional, either the B<account_id> or the list of
B<status_ids> must be present.

Depending on the value of C<coerce_entities>, returns the new
Mastodon::Entity::Report object, or a plain hash reference.

=back

=head2 Search

=over 4

=item B<search($query)>

=item B<search($query, $params)>

Search for content. Takes a mandatory string argument to use as the search
query. If the search query is a URL, Mastodon will attempt to fetch the
provided account or status. Otherwise, it will do a local account and hashtag
search.

In addition to the global GET parameters, this method accepts the following
parameters:

=over 4

=item B<resolve>

Whether to resolve non-local accounts.

=back

=back

=head2 Statuses

=over 4

=item B<get_status($id)>

=item B<get_status($id, $params)>

Fetches a status by ID. The ID argument is mandatory. Global GET parameters are available for this method as an additional hash reference.

Depending on the value of C<coerce_entities>, it returns a
Mastodon::Entity::Status object, or a plain hash reference.

This method does not require authentication.

=item B<get_status_context($id)>

=item B<get_status_context($id, $params)>

Fetches the context of a status by ID. The ID argument is mandatory. Global GET parameters are available for this method as an additional hash reference.

Depending on the value of C<coerce_entities>, it returns a
Mastodon::Entity::Context object, or a plain hash reference.

This method does not require authentication.

=item B<get_status_card($id)>

=item B<get_status_card($id, $params)>

Fetches a card associated to a status by ID. The ID argument is mandatory.
Global GET parameters are available for this method as an additional hash
reference.

Depending on the value of C<coerce_entities>, it returns a
Mastodon::Entity::Card object, or a plain hash reference.

This method does not require authentication.

=item B<get_status_reblogs($id)>

=item B<get_status_reblogs($id, $params)>

=item B<get_status_favourites($id)>

=item B<get_status_favourites($id, $params)>

Fetches a list of accounts who have reblogged or favourited a status by ID.
The ID argument is mandatory. Global GET parameters are available for this
method as an additional hash reference.

Depending on the value of C<coerce_entities>, it returns an array reference of
Mastodon::Entity::Account objects, or a plain array reference.

This method does not require authentication.

=item B<post_status($text)>

=item B<post_status($text, $params)>

Posts a new status. Takes a mandatory string as the content of the status
(which can be the empty string), and an optional hash reference with the
following additional parameters:

=over 4

=item B<status>

The content of the status, as a string. Since this is already provided as the
first argument of the method, this is not necessary. But if provided, this
value will overwrite that of the first argument.

=item B<in_reply_to_id>

The optional ID of a status to reply to.

=item B<media_ids>

An array reference of up to four media IDs. These can be obtained as the result
of a call to B<upload_media()>.

=item B<sensitive>

Boolean, to mark status content as NSFW.

=item B<spoiler_text>

A string, to be shown as a warning before the actual content.

=item B<visibility>

A string; one of C<direct>, C<private>, C<unlisted>, or C<public>.

=back

Depending on the value of C<coerce_entities>, it returns the new
Mastodon::Entity::Status object, or a plain hash reference.

=item B<delete_status($id)>

Delete a status by ID. The ID is mandatory. Returns an empty object.

=item B<reblog($id)>

=item B<unreblog($id)>

=item B<favourite($id)>

=item B<unfavourite($id)>

Reblog or favourite a status by ID, or revert this action. The ID argument is
mandatory.

Depending on the value of C<coerce_entities>, it returns the specified
Mastodon::Entity::Status object, or a plain hash reference.

=back

=head2 Timelines

=over 4

=item B<timeline($query)>

=item B<timeline($query, $params)>

Retrieves a timeline. The first argument defines either the name of a timeline
(which can be one of C<home> or C<public>), or a hashtag (if it begins with the
C<#> character). This argument is mandatory.

In addition to the global GET parameters, this method accepts the following
parameters:

Accessing the public and tag timelines does not require authentication.

=over 4

=item B<local>

Boolean. If true, limits results only to those originating from the current
instance. Only applies to public and tag timelines.

=back

Depending on the value of C<coerce_entities>, it returns an array of
Mastodon::Entity::Status objects, or a plain array reference. The more recent
statuses come first.

=back

=head1 STREAMING RESULTS

Alternatively, it is possible to use the streaming API to get a constant stream
of updates. To do this, there is the B<stream()> method.

=over 4

=item B<stream($query)>

Creates a Mastodon::Listener object which will fetch a stream for the
specified query. Possible values for the query are either C<user>, for events
that are relevant to the authorized user; C<public>, for all public statuses;
or a tag (if it begins with the C<#> character), for all public statuses for
the particular tag.

For more details on how to use this object, see the documentation for
L<Mastodon::Listener>.

Accessing streaming public timeline does not require authentication.

=back

=head1 REQUEST METHODS

Mastodon::Client uses four lower-level request methods to contact the API
with GET, POST, PATCH, and DELETE requests. These are left available in case
one of the higher-level convenience methods are unsuitable or undesirable, but
you use them at your own risk.

They all take a URL as their first parameter, which can be a string with the
API endpoint to contact, or a L<URI> object, which will be used as-is.

If passed as a string, the methods expect one that contains only the variable
parts of the endpoint (ie. not including the C<HOST/api/v1> part). The
remaining parts will be filled-in appropriately internally.

=over 4

=item B<delete($url)>

=item B<get($url)>

=item B<get($url, $params)>

Query parameters can be passed as part of the L<URI> object, but it is not
recommended you do so, since Mastodon has expectations for array parameters
that do not meet those of eg. L<URI::QueryParam>. It will be easier and safer
if any additional parameters are passed as a hash reference, which will be
added to the URL before the request is sent.

=item B<post($url)>

=item B<post($url, $data)>

=item B<patch($url)>

=item B<patch($url, $data)>

the C<post> and C<patch> methods work similarly to C<get> and C<delete>, but
the optional hash reference is sent in as form data, instead of processed as
query parameters. The Mastodon API does not use query parameters on POST or
PATCH endpoints.

=back

=head1 CONTRIBUTIONS AND BUG REPORTS

Contributions of any kind are most welcome!

The main repository for this distribution is on
L<GitLab|https://gitlab.com/jjatria/Mastodon-Client>, which is where patches
and bug reports are mainly tracked. The repository is also mirrored on
L<Github|https://github.com/jjatria/Mastodon-Client>, in case that platform
makes it easier to post contributions.

If none of the above is acceptable, bug reports can also be sent through the
CPAN RT system, or by mail directly to the developers at the address below,
although these will not be as closely tracked.

=head1 AUTHOR

=over 4

=item *

José Joaquín Atria <jjatria@cpan.org>

=back

=head1 CONTRIBUTORS

=over 4

=item *

Lance Wicks <lancew@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by José Joaquín Atria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
