package Hey::heyPass;

our $VERSION = 2.11;

use Storable qw(freeze thaw);

=cut

=head1 NAME

Hey::heyPass - Client for heyPass Centralized Authentication System

=head1 SYNOPSIS

  use Hey::heyPass;

  my $hp = Hey::heyPass->new({
    uuid => '1f0123de58d123ddb4da123851399123',
    key => 'your-app-password-here',
  });

  my $login = $hp->login({
    return_url => 'http://www.my-super-website-place.com/return.cgi?login_code=%s', # %s replaced with login_code
    attributes => { # attributes that we want permission to access (heyPass will ask the user for permission)
      '7990a9de584511dda17e00185139906f/birthdate' => {
        permission => 'ro', # asking for read-only access to this attribute (user can override this)
        expires => '3600', # asking for a grant to this attribute that expires in 1 hour (user can override this)
      },
      '7990a9de584511dda17e00185139906f/email_address' => {
        permission => 'ro', # asking for read-only access to this attribute (user can override this)
        expires => 'never', # asking for a never-expiring grant to this attribute (user can override this)
      },
    },
  });
  $my_session_blah->{login_code} = $login->{code};  # if you want to put the login_code in your session
                                                    # system instead of having it in the return_url
                                                    # (you're in charge of your own session system...)
  print "Status: 302\nLocation: $login->{url}\n\n";

      ... user is at heyPass logging in

                             now the user returns ...

  my $user = $hp->user({
    login_code => $login_code,  # get this from where you stored it, either from the return_url (GET param)
                                # or from your session system.. or whatever.
  });
  print "User's UUID is $user." if $user;
  die "User isn't logged in... login_code is invalid, expired, or whatever." unless $user;

  my $attributes = $hp->read({
    user => $user, # $user comes from the output of the 'user' command above.
    attributes => [
      '1f0123de58d123ddb4da123851399123/username',      # format: 'app_uuid/attribute'
      '1f0123de58d123ddb4da123851399123/postcount',
      '7990a9de584511dda17e00185139906f/birthdate',     # your app must either own the variable (your app's uuid)
      '7990a9de584511dda17e00185139906f/email_address', # or have been given permission by the user (via grants)
    ],
  });

  $hp->write({
    user => $user,
    attributes => {
      '1f0123de58d123ddb4da123851399123/username' => 'fred_jones',
      '1f0123de58d123ddb4da123851399123/postcount' => 123456,
    },
  });

=head1 DESCRIPTION

heyPass is a centralized authentication system made for any web application that
needs user authentication.  The heyPass system is hosted, maintained, and
managed by hey.nu Network Community Services and Megagram Managed Technical
Services in a joint venture to help web application developers provide a safe,
user privacy-controlled authentication and profile data sharing system.

All data stored within heyPass by individual applications can be shared with
other heyPass-powered applications based on the user's permission and the
application's permission settings.  This system makes it easy for an application
to store both public and private data for a user and share only permitted data
with other applications that have been given permission by the user.

Through this system, no heyPass-powered applications have access to the user's
login information, email address, or any other identifying data.  Upon
successful login, the only piece of data that an application is given is a user
UUID that identifies that user with that application.  Only after the
application requests specific profile data and the user has given explicit
permission via a web interface will an application be able to access additional
data stored within heyPass.  This system ensure that a user's privacy is
maintained at the levels that they prefer.  For example, a user is not required
to provide an application their email address or identity information just to
login.

This system was originally designed as a central authentication system for
hey.nu Network Official sites, but it is now being made available to the general
public.  Any application developer or application owner may use the heyPass
system for their applications.  Any heyPass user can create their own
applications and any application developer can distribute their heyPass-powered
applications to others.

=head1 INTERFACE

=head2 new

  my $hp = Hey::heyPass->new({
    uuid => '1f0123de58d123ddb4da123851399123',
    key => 'your-app-password-here',
  });

Creates the heyPass object to be used later on for requests.

=over 4

=item uuid [required]

Your application's UUID.  This is assigned upon creation of your application at
the heyPass website.  Your UUID is listed on the application detail screen.
This is not a secret.  In fact, you can freely give this out if you'd like other
applications to potentially access your data (if *both* you and your users allow
it).

=item key [required]

Your application's password.  This is a secret!  Anyone with this password can
do anything with your data that your application can.  You get to choose this
value when you setup your new application in heyPass.  It's best to keep this
password long and complicated.  You can change it at any time at the heyPass
website.

=item return_url [optional]

This is the URL that heyPass will send the user to when the user has either
successfully logged with heyPass or if the user hit the cancel button.  If you
set it here, it becomes the default return_url for all requests.  Otherwise, it
can be set for any request that sends the user to heyPass.

=item access_url [optional]

It shouldn't ever be necessary to use this, but if you are in a special
situation where the predefined heyPass API URL needs to be set to a different
value, you'd do that with this.

=back

=cut

sub new
{
  my $class = shift;
  my $args = shift; # hashref
  my $self = {};

  $self->{uuid} = $args->{uuid} or die(qq(Hey::heyPass requires UUID.\n));
  $self->{key} = $args->{key} or die(qq(Hey::heyPass requires KEY.\n));
  $self->{return_url} = $args->{return_url};
  $self->{access_url} = $args->{access_url} || 'https://heypass.megagram.com/api/';

  use LWP::UserAgent;
  $self->{_ua} = LWP::UserAgent->new();
  $self->{_ua}->agent('Hey::heyPass/'.$VERSION.' ('.$self->{uuid}.'; Perl '.join('.', map({ord} split('', $^V))).'; https://heypass.megagram.com/)');

  return bless($self, $class);
}

=cut

=head2 login

  my $login = $hp->login({
    return_url => 'http://www.my-super-website-place.com/return.cgi?login_code=%s', # %s replaced with login_code
    attributes => { # attributes that we want permission to access (heyPass will ask the user for permission)
      '7990a9de584511dda17e00185139906f/birthdate' => {
        permission => 'ro', # asking for read-only access to this attribute (user can override this)
        expires => '3600', # asking for a grant to this attribute that expires in 1 hour (user can override this)
      },
      '7990a9de584511dda17e00185139906f/email_address' => {
        permission => 'ro', # asking for read-only access to this attribute (user can override this)
        expires => 'never', # asking for a never-expiring grant to this attribute (user can override this)
      },
    },
  });
  $my_session_blah->{login_code} = $login->{code};  # if you want to put the login_code in your session
                                                    # system instead of having it in the return_url
                                                    # (you're in charge of your own session system...)
  print "Status: 302\nLocation: $login->{url}\n\n";

Sends a request to heyPass to start the login process for a non-authenticated
user.  Returns the URL where you will send the user to login as well as the
login_code that will be used later to check to see if the user is logged in, to
get the logged-in user's UUID, and other things.

WARNING!  Do *not* use login_code as a session id for your application.  At any
moment the login_code may need to change (the user logged out and you want them
to log back in, etc) and this will mess up your sessions.  You should use your
own session management system like L<CGI::Session|CGI::Session> or something like
that.  Don't rely on heyPass to maintain your session ids!  That's not what
login_code is for.

=over 4

=item return_url [optional-ish]

If you didn't set this when you created your $hp object, you are required to do
it here.  If you did set it, this will override it for just this one request.

=item attributes [optional]

A hashref containing the attributes that you'd like to have access to.  The
attribute is formatted "APP_UUID/ATTRIBUTE".  You need to know the UUID of the
application that owns the attribute and the name of the attribute that you want
access to.

When the user logs in with heyPass, they will be prompted to grant access to
these attributes to your application.  The user can override any of the settings
that you provided (permission, expiration).  Depending on how the user answers,
they may be asked everytime they login, once it expires, or never again.

The attributes that you list here must have been permitted to be shared by the
application that owns the data.  This means they have set either "read-only" or
"read-write" access to the data.

=back

=cut

sub login
{
  my $self = shift;
  my $args = shift; # hashref
  my $request = {};

  $request->{uuid} = $args->{uuid} || $self->{uuid};
  $request->{key} = $args->{key} || $self->{key};
  $request->{return_url} = $args->{return_url} || $self->{return_url};
  $request->{access_url} = $args->{access_url} || $self->{access_url};
  $request->{attributes} = $args->{attributes};

  my $req = HTTP::Request->new(POST => $request->{access_url}.'login');
  $req->content_type('application/x-storable');
  $req->content(freeze($request));
  my $res = $self->{_ua}->request($req);

  if ($res->is_success)
  {
    my $response = thaw($res->content);
    return { url => $response->{login_url}, code => $response->{applogin_id} };
  }

  if ($res->code == 403)
  {
    die("Application authentication failed.\n");
  }

  return undef;
}

=cut

=head2 logout

  # "local" logout, only logs out this one login_code
  $hp->logout({ # logout based on the login_code.  doesn't return anything at all either on success or failure.
    login_code => $login_code,
  });

  # "global" logout, logs out every user session on every computer for this application
  $hp->logout({ # logout based on the user's uuid.  doesn't return anything at all either on success or failure.
    user => $user,
  });

Performs a logout action.  Either logout just this single login_code (leaving all other sessions alone)
or logout every session for this user for your app.  You'll use either "login_code" or "user", but
not both at the same time.

=over 4

=item login_code [required, without user]

If provided, the provided login_code will be logged out.  The user will be
logged out of your application for the computer that the user is sitting at.
Any existing sessions for this user for your application at other computers will
not be logged out.

=item user [required, without login_code]

This is the user's UUID.  If provided, the user will be logged out of your
application at every computer that was used to log into your application.  This
is considered a "global application logout".

FYI: If a user wants to do a true global logout (logout of all heyPass-powered
apps for this user), they must do that through the heyPass website.  Your
application can direct them there, but the user has to click the button to make
it happen.

=back

=cut

sub logout
{
  my $self = shift;
  my $args = shift; # hashref
  my $request = {};

  $request->{uuid} = $args->{uuid} || $self->{uuid};
  $request->{key} = $args->{key} || $self->{key};
  $request->{access_url} = $args->{access_url} || $self->{access_url};
  $request->{user} = $args->{user};
  $request->{login_code} = $args->{login_code};
  return undef unless ($request->{user} || $request->{login_code}); # must use one of them

  my $req = HTTP::Request->new(POST => $request->{access_url}.'logout');
  $req->content_type('application/x-storable');
  $req->content(freeze($request));
  my $res = $self->{_ua}->request($req);

  if ($res->is_success)
  {
    my $response = thaw($res->content);
    return undef;
  }

  if ($res->code == 403)
  {
    die("Application authentication failed.\n");
  }

  return undef;
}

=cut

=head2 user

  my $user = $hp->user({
    login_code => $login_code,  # get this from where you stored it, either from the return_url (GET param)
                                # or from your session system.. or whatever.
  });
  print "User's UUID is $user." if $user;
  die "User isn't logged in... login_code is invalid, expired, or whatever." unless $user;

Get the logged in user's UUID.  This is the static identifier that lets your
application know that this user is who they are.  This value never changes for
each individual user.  You will use this value in your databases or wherever to
match against each time this user logs in or wishes to perform an action.
According to your application, the user's UUID is their identity.  You will use
the user's UUID to perform other tasks, like writing to their attributes,
logout, requesting attribute grants, and reading attributes.

If $user is null, the login_code is not valid.  This means the user is not
authenticated and should be treated as such.  Either the login_code was never
authenticated, the authentication expired, or the user was logged out.

=over 4

=item login_code [required]

Provide the login_code that you originally got from login.

=back

=cut

sub user
{
  my $self = shift;
  my $args = shift; # hashref
  my $request = {};

  $request->{uuid} = $args->{uuid} || $self->{uuid};
  $request->{key} = $args->{key} || $self->{key};
  $request->{access_url} = $args->{access_url} || $self->{access_url};
  $request->{login_code} = $args->{login_code} or return undef;

  my $req = HTTP::Request->new(POST => $request->{access_url}.'user');
  $req->content_type('application/x-storable');
  $req->content(freeze($request));
  my $res = $self->{_ua}->request($req);

  if ($res->is_success)
  {
    my $response = thaw($res->content);
    return $response->{user};
  }

  if ($res->code == 403)
  {
    die("Application authentication failed.\n");
  }

  return undef;
}

=cut

=head2 read

  my $attributes = $hp->read({
    user => $user, # $user comes from the output of the 'user' command above.
    attributes => [
      '1f0123de58d123ddb4da123851399123/username',      # format: 'app_uuid/attribute'
      '1f0123de58d123ddb4da123851399123/postcount',
      '7990a9de584511dda17e00185139906f/birthdate',     # your app must either own the variable (your app's uuid)
      '7990a9de584511dda17e00185139906f/email_address', # or have been given permission by the user (via grants)
    ],
  });

Get the specified attributes from the user's profile.  For attributes in your
application's namespace (starting with your app's UUID), you don't need
permission from the user to get the data.  For any other namespace, you must
have a valid, non-expired grant from the user.  You get a grant using "grant" or
during the initial "login".  If you don't have a valid grant, your request for
the denied attributes will be ignored and omitted from the response.  If the
attribute or application UUID doesn't exist, that too will be ignored and
omitted.  If you have a valid grant for a piece of data, but the data doesn't
exist for this user (it was never written to), it'll be omitted from the
response.

=over 4

=item user [required]

The user's UUID that you'd like to get the information from.  For any data that
you have a valid grant for, the user doesn't need to be present to request the
data.

=item attributes [required]

An array reference containing a list of attributes to get from the user's
heyPass profile.

=back

=cut

sub read
{
  my $self = shift;
  my $args = shift; # hashref
  my $request = {};

  $request->{uuid} = $args->{uuid} || $self->{uuid};
  $request->{key} = $args->{key} || $self->{key};
  $request->{access_url} = $args->{access_url} || $self->{access_url};
  $request->{user} = $args->{user} or return undef;
  $request->{attributes} = $args->{attributes};

  my $req = HTTP::Request->new(POST => $request->{access_url}.'read');
  $req->content_type('application/x-storable');
  $req->content(freeze($request));
  my $res = $self->{_ua}->request($req);

  if ($res->is_success)
  {
    my $response = thaw($res->content);
    return $response;
  }

  if ($res->code == 403)
  {
    die("Application authentication failed.\n");
  }

  return undef;
}

=cut

=head2 write

  $hp->write({
    user => $user,
    attributes => {
      '1f0123de58d123ddb4da123851399123/username' => 'fred_jones', # our attributes, we don't need to get a grant for these
      '1f0123de58d123ddb4da123851399123/postcount' => 123456,
      '123aa31e58d1dc7de982375238526727/status_text' => 'Ready to Chat', # only if you have been granted "rw" access to this by the user and the owning app
    },
  });

Write to the user's profile attributes.  If your application owns the
attributes, you don't need a grant.  Otherwise, you need a read-write grant to
the attributes.  Any attributes that you don't have read-write access to will be
ignored.

=over 4

=item user [required]

The user's UUID that you'd like to write the information to.  For any data that
you have a valid read-write grant for, the user doesn't need to be present to
write the data.

=item attributes [required]

A hash reference containing the attributes to be written and their values.

=back

=cut

sub write
{
  my $self = shift;
  my $args = shift; # hashref
  my $request = {};

  $request->{uuid} = $args->{uuid} || $self->{uuid};
  $request->{key} = $args->{key} || $self->{key};
  $request->{access_url} = $args->{access_url} || $self->{access_url};
  $request->{user} = $args->{user} or return undef;
  $request->{attributes} = $args->{attributes};

  my $req = HTTP::Request->new(POST => $request->{access_url}.'write');
  $req->content_type('application/x-storable');
  $req->content(freeze($request));
  my $res = $self->{_ua}->request($req);

  if ($res->is_success)
  {
    my $response = thaw($res->content);
    return $response;
  }

  if ($res->code == 403)
  {
    die("Application authentication failed.\n");
  }

  return undef;
}

=cut

=head2 grant

  # ask for new grants, this method is used when the user is present and the login_code is valid
  my $grant = $hp->grant({
    login_code => $login_code,
    attributes => {
      '7990a9de584511dda17e00185139906f/email_address' => {
        permission => 'ro',
        expires => 'never', # never expire
      },
      '7990a9de584511dda17e00185139906f/birthdate' => {
        permission => 'ro',
        expires => '3600', # expire in 3600 seconds (1 hour)
      },
    },
  });
  print "Status: 302\nLocation: $grant->{url}\n\n" if $grant->{url}; # sends the user to heyPass to grant permission

  # ask for new grants, this method is used when the user is NOT present and/or the login_code is invalid
  my $grant = $hp->grant({
    user => $user,
    attributes => {
      '7990a9de584511dda17e00185139906f/email_address' => {
        permission => 'ro',
        expires => 'never', # never expire
      },
      '7990a9de584511dda17e00185139906f/birthdate' => {
        permission => 'ro',
        expires => '3600', # expire in 3600 seconds (1 hour)
      },
    },
  });
  # Doesn't provide a URL.  Instead, the user will be prompted at next login.

Request a grant for attributes for a user.  The application that owns the
attributes being requested must have specified that the attributes are either
read-only or read-write.  The user will need to visit the heyPass site to grant
this permission.  If you use "login_code", a URL will be provided that you can
send the user to.  Otherwise, the user will be prompted next time they login.

=over 4

=item return_url [optional-ish]

If you didn't set this when you created your $hp object, you are required to do
it here.  If you did set it, this will override it for just this one request.

=item login_code [required, without user]

Provide the login_code for the current user session.  Returned will be the URL
that the user must visit to grant the requested permissions.  The user must
be present to use "login_code" for this.

=item user [required, without login_code]

Provide the user's UUID instead of login_code to request permission to
attributes.  In doing so, the user doesn't need to be present when you make this
request.  The next time the user logs into your application, they'll be asked to
give permission.  You can use this method for user-not-present batch requests.

=item attributes [required]

A hashref containing the attributes that you'd like to have access to.  The
attribute is formatted "APP_UUID/ATTRIBUTE".  You need to know the UUID of the
application that owns the attribute and the name of the attribute that you want
access to.

When the user logs in with heyPass or is sent to heyPass with the returned URL,
they will be prompted to grant access to these attributes to your application.
The user can override any of the settings that you provided (permission,
expiration).  Depending on how the user answers, they may be asked everytime
they login, once it expires, or never again.

The attributes that you list here must have been permitted to be shared by the
application that owns the data.  This means they have set either "read-only" or
"read-write" access to the data.

=back

=cut

sub grant
{
  my $self = shift;
  my $args = shift; # hashref
  my $request = {};

  $request->{uuid} = $args->{uuid} || $self->{uuid};
  $request->{key} = $args->{key} || $self->{key};
  $request->{access_url} = $args->{access_url} || $self->{access_url};
  $request->{attributes} = $args->{attributes};
  $request->{user} = $args->{user};
  $request->{login_code} = $args->{login_code};
  return undef unless ($request->{user} || $request->{login_code}); # must use one of them

  my $req = HTTP::Request->new(POST => $request->{access_url}.'grant');
  $req->content_type('application/x-storable');
  $req->content(freeze($request));
  my $res = $self->{_ua}->request($req);

  if ($res->is_success)
  {
    my $response = thaw($res->content);
    return { url => $response->{grant_url} };
  }

  if ($res->code == 403)
  {
    die("Application authentication failed.\n");
  }

  return undef;
}

=cut

=head2 attrlist

  my $attributes = $hp->attrlist(); # no arguments
  use Data::Dumper;
  print Dumper($attributes);

Returns a list of attributes that your application has defined in heyPass.

=cut

sub attrlist
{
  my $self = shift;
  my $args = shift; # hashref
  my $request = {};

  $request->{uuid} = $args->{uuid} || $self->{uuid};
  $request->{key} = $args->{key} || $self->{key};
  $request->{access_url} = $args->{access_url} || $self->{access_url};

  my $req = HTTP::Request->new(POST => $request->{access_url}.'attrlist');
  $req->content_type('application/x-storable');
  $req->content(freeze($request));
  my $res = $self->{_ua}->request($req);

  if ($res->is_success)
  {
    my $response = thaw($res->content);
    return $response;
  }

  if ($res->code == 403)
  {
    die("Application authentication failed.\n");
  }

  return undef;
}

=cut

=head2 attrcreate

  $hp->attrcreate({ # create attributes, doesn't return anything
    attributes => { # this is what we create.  errors are simply ignored.
      'testcreate_1' => {
        permission => 'rw',
        title => 'Test Created Field #1',
        description => 'This field was created programmatically via the API.',
      },
      'testcreate_2' => {
        permission => 'rw',
        title => 'Test Created Field #2',
        description => 'This field was created programmatically via the API.',
      },
      'testcreate_3' => {
        permission => 'rw',
        title => 'Test Created Field #3',
        description => 'This field was created programmatically via the API.',
      },
    },
  });

Programmatically create new attributes within heyPass in your application's
namespace.  This is akin to adding a column in a database table.

=over 4

=item attributes [required]

A hash reference containing the attribute, title, description, and permission
for the attributes that you'd like to create.  If the attribute already exists,
it'll be ignored from the request.

=back

=cut

sub attrcreate
{
  my $self = shift;
  my $args = shift; # hashref
  my $request = {};

  $request->{uuid} = $args->{uuid} || $self->{uuid};
  $request->{key} = $args->{key} || $self->{key};
  $request->{access_url} = $args->{access_url} || $self->{access_url};
  $request->{attributes} = $args->{attributes};

  my $req = HTTP::Request->new(POST => $request->{access_url}.'attrcreate');
  $req->content_type('application/x-storable');
  $req->content(freeze($request));
  my $res = $self->{_ua}->request($req);

  if ($res->is_success)
  {
    my $response = thaw($res->content);
    return $response;
  }

  if ($res->code == 403)
  {
    die("Application authentication failed.\n");
  }

  return undef;
}

=cut

=head2 attrupdate

  $hp->attrupdate({ # update attributes, doesn't return anything
    attributes => { # this is what we update.  errors are simply ignored.  omitted fields will be left alone.
      'testcreate_1' => {
        title => 'Test Updated Field #1',
        description => 'This field was updated programmatically via the API.',
      },
      'testcreate_2' => {
        permission => 'ro', # only changing permission
      },
      'testcreate_3' => {
        title => 'Test Updated Field #3',
        description => 'This field was updated programmatically via the API.',
      },
    },
  });

Alter an existing attribute for your application within heyPass.  This is used
to make changes to the permission, title, and description of the attribute.
This doesn't modify the value of the attribute; it modifies the definition of
the attribute.  If you want to modify values, you would use "write" instead.

=over 4

=item attributes [required]

A hash reference containing the attribute, title, description, and permission
for the attributes that you'd like to update.  If the attribute doesn't exist,
it'll be ignored from the request.  Any fields you omit from this hash will
be left untouched.  For example, in the code sample above, the title for
"testcreate_2" will not be modified since it wasn't supplied in the hash.

=back

=cut

sub attrupdate
{
  my $self = shift;
  my $args = shift; # hashref
  my $request = {};

  $request->{uuid} = $args->{uuid} || $self->{uuid};
  $request->{key} = $args->{key} || $self->{key};
  $request->{access_url} = $args->{access_url} || $self->{access_url};
  $request->{attributes} = $args->{attributes};

  my $req = HTTP::Request->new(POST => $request->{access_url}.'attrupdate');
  $req->content_type('application/x-storable');
  $req->content(freeze($request));
  my $res = $self->{_ua}->request($req);

  if ($res->is_success)
  {
    my $response = thaw($res->content);
    return $response;
  }

  if ($res->code == 403)
  {
    die("Application authentication failed.\n");
  }

  return undef;
}

=cut

=head2 attrdelete

  $hp->attrdelete({ # delete attributes, doesn't return anything
    attributes => [ # this is what we delete.  errors are simply ignored.
      'testcreate_1',
      'testcreate_2',
      'testcreate_3',
    ],
  });

Delete an attribute for your application from heyPass.  This deletes the
definition of an attribute.  This means that it will remove the attribute from
every heyPass user profile and from your application's data store on heyPass.
This is akin to removing a column from a database table.

If you just want to delete a value from an attribute for a single user, use
"write" to store a blank value.  In the future, we may implement a "delete"
API function.

WARNING!  If you do this, all data stored in that attribute for every heyPass
user will be permanently deleted.  There is no going back!  There is no undo!
Make sure you really mean it.

=over 4

=item attributes [required]

An array reference containing a list of attributes to delete.  Any attributes
that don't exist will be ignored from the request.

=back

=cut

sub attrdelete
{
  my $self = shift;
  my $args = shift; # hashref
  my $request = {};

  $request->{uuid} = $args->{uuid} || $self->{uuid};
  $request->{key} = $args->{key} || $self->{key};
  $request->{access_url} = $args->{access_url} || $self->{access_url};
  $request->{attributes} = $args->{attributes};

  my $req = HTTP::Request->new(POST => $request->{access_url}.'attrdelete');
  $req->content_type('application/x-storable');
  $req->content(freeze($request));
  my $res = $self->{_ua}->request($req);

  if ($res->is_success)
  {
    my $response = thaw($res->content);
    return $response;
  }

  if ($res->code == 403)
  {
    die("Application authentication failed.\n");
  }

  return undef;
}

=cut

=head1 TODO

=over 4

=item delete

Add a delete API function to delete an attribute from an individual heyPass
user's profile.  This isn't the same as "attrdelete" which deletes the attribute
from the entire application.

=back

=head1 THANKS

Thanks to Andrew Orner for being our very first guinea pig.  He implemented
heyPass 1 in his pureBB bulletin board system.  Now renamed heyBoard, he is
implementing heyPass 2 to take advantage of the enhanced profile storage
features.  heyPass wouldn't be where it is today without his support.

Thanks to Aditya Gaddam for writing the PHP and Ruby versions of this module.
His work will help ensure PHP and Ruby developers get to use heyPass for their
own applications.  We all appreciate your effort.

Thanks to the hey.nu Network community for putting up with heyPass 1 while
heyPass 2 was in development.  Thanks for testing it out, putting up with the
bugs, and giving your valuable feedback.

=head1 AUTHOR

    Dusty Wilson
    Megagram Managed Technical Services
    hey.nu Network Community Services
    http://heypass.megagram.com/

=head1 COPYRIGHT

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut

1;