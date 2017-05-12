package MasonX::Request::WithApache2Session;

use 5.005;
use strict;

use vars qw($VERSION @ISA);

$VERSION = '0.04';

use Apache::Session;
use Apache::RequestRec;
use Apache::RequestUtil;

use HTML::Mason 1.16;
use HTML::Mason::Exceptions ( abbr => [ qw( param_error error ) ] );
use HTML::Mason::Request;

use Data::Dumper;

use Exception::Class ( 'HTML::Mason::Exception::NonExistentSessionID' =>
		       { isa => 'HTML::Mason::Exception',
			 description => 'A non-existent session id was used',
			 fields => [ 'session_id' ] },
		     );

use Params::Validate qw(:all);
Params::Validate::validation_options( on_fail => sub { param_error( join '', @_ ) } );

# This may change later
@ISA = qw(HTML::Mason::Request);

my %params =
    ( session_always_write =>
      { type => BOOLEAN,
	default => 1,
	descr => 'Whether or not to force a write before the session goes out of scope' },

      session_allow_invalid_id =>
      { type => BOOLEAN,
	default => 1,
	descr => 'Whether or not to allow a failure to find an existing session id' },

      session_args_param =>
      { type => SCALAR,
	default => undef,
	descr => 'Name of the parameter to use for session tracking' },

      session_use_cookie =>
      { type => BOOLEAN,
	default => 0,
	descr => 'Whether or not to use a cookie to track the session' },

      session_cookie_name =>
      { type => SCALAR,
	default => 'MasonX-Request-WithApache2Session-cookie',
	descr => 'Name of cookie used by this module' },

      session_cookie_expires =>
      { type => UNDEF | SCALAR,
	default => '+1d',
	descr => 'Expiration time for cookies' },

      session_cookie_domain =>
      { type => UNDEF | SCALAR,
	default => undef,
	descr => 'Domain parameter for cookies' },

      session_cookie_path =>
      { type => SCALAR,
	default => '/',
	descr => 'Path for cookies' },

      session_cookie_secure =>
      { type => BOOLEAN,
	default => 0,
	descr => 'Are cookies sent only for SSL connections?' },

      session_cookie_resend =>
      { type => BOOLEAN,
	default => 1,
	descr => 'Resend the cookie on each request?' },

      session_class =>
      { type => SCALAR,
	descr => 'An Apache::Session class to use for sessions' },

      session_data_source =>
      { type => SCALAR,
	optional => 1,
	descr => 'The data source when using MySQL or PostgreSQL' },

      session_user_name =>
      { type => UNDEF | SCALAR,
	default => undef,
	descr => 'The user name to be used when connecting to a database' },

      session_password =>
      { type => UNDEF | SCALAR,
	default => undef,
	descr => 'The password to be used when connecting to a database' },

      session_lock_data_source =>
      { type => SCALAR,
	optional => 1,
	descr => 'The data source when using MySQL or PostgreSQL' },

      session_lock_user_name =>
      { type => UNDEF | SCALAR,
        default => undef,
	descr => 'The user name to be used when connecting to a database' },

      session_lock_password =>
      { type => UNDEF | SCALAR,
	default => undef,
	descr => 'The password to be used when connecting to a database' },

      session_handle =>
      { type => OBJECT,
        optional => 1,
	descr => 'An existing database handle to use' },

      session_lock_handle =>
      { type => OBJECT,
        optional => 1,
	descr => 'An existing database handle to use' },

      session_commit =>
      { type => BOOLEAN,
        default => 1,
	descr => 'Whether or not to auto-commit changes to the database' },

      session_transaction =>
      { type => BOOLEAN,
	default => 0,
	descr => 'The Transaction flag for Apache::Session' },

      session_directory =>
      { type => SCALAR,
	default => undef,
	descr => 'A directory to use when storing sessions' },

      session_lock_directory =>
      { type => SCALAR,
	default => undef,
	descr => 'A directory to use for locking when storing sessions' },

      session_file_name =>
      { type => SCALAR,
	optional => 1,
	descr => 'A DB_File to use' },

      session_store =>
      { type => SCALAR,
	optional => 1,
	descr => 'A storage class to use with the Flex module' },

      session_lock =>
      { type => SCALAR,
	optional => 1,
	descr => 'A locking class to use with the Flex module' },

      session_generate =>
      { type => SCALAR,
	default => 'MD5',
	descr => 'A session generator class to use with the Flex module' },

      session_serialize =>
      { type => SCALAR,
	optional => 1,
	descr => 'A serialization class to use with the Flex module' },

      session_textsize =>
      { type => SCALAR,
	optional => 1,
	descr => 'A parameter for the Sybase storage module' },

      session_long_read_len =>
      { type => SCALAR,
	optional => 1,
	descr => 'A parameter for the Oracle storage module' },

      session_n_sems =>
      { type => SCALAR,
	optional => 1,
	descr => 'A parameter for the Semaphore locking module' },

      session_semaphore_key =>
      { type => SCALAR,
	optional => 1,
	descr => 'A parameter for the Semaphore locking module' },

      session_mod_usertrack_cookie_name =>
      { type => SCALAR,
	optional => 1,
	descr => 'The cookie name used by mod_usertrack' },

      session_save_path =>
      { type => SCALAR,
	optional => 1,
	descr => 'Path used by Apache::Session::PHP' },

    );

__PACKAGE__->valid_params(%params);

# What set of parameters are required for each session class.
# Multiple array refs represent multiple possible sets of parameters
my %Apache2SessionParams =
    ( Flex     => [ [ qw( store lock generate serialize ) ] ],
      MySQL    => [ [ qw( data_source user_name password
                          lock_data_source lock_user_name lock_password ) ],
		    [ qw( handle lock_handle ) ] ],
      Postgres => [ [ qw( data_source user_name password commit ) ],
		    [ qw( handle commit ) ] ],
      File     => [ [ qw( directory lock_directory ) ] ],
      DB_File  => [ [ qw( file_name lock_directory ) ] ],

      PHP      => [ [ qw( save_path ) ] ],
    );

$Apache2SessionParams{Oracle} =
      $Apache2SessionParams{Sybase} =
      $Apache2SessionParams{Postgres};

my %OptionalApache2SessionParams =
    ( Sybase => [ [ qw( textsize ) ] ],
      Oracle => [ [ qw( long_read_len ) ] ],
    );

my %Apache2SessionFlexParams =
    ( store =>
      { MySQL    => [ [ qw( data_source user_name password ) ],
		      [ qw( handle ) ] ],
	Postgres => $Apache2SessionParams{Postgres},
	File     => [ [ qw( directory ) ] ],
	DB_File  => [ [ qw( file_name ) ] ],
      },
      lock =>
      { MySQL     => [ [ qw( lock_data_source lock_user_name lock_password ) ],
		       [ qw( lock_handle ) ] ],
	File      => [ [ ] ],
	Null      => [ [ ] ],
	Semaphore => [ [ ] ],
      },
      generate =>
      { MD5          => [ [ ] ],
	ModUniqueId  => [ [ ] ],
	ModUsertrack => [ [ qw( mod_usertrack_cookie_name )  ] ],
      },
      serialize =>
      { Storable => [ [ ] ],
	Base64   => [ [ ] ],
	UUEncode => [ [ ] ],
      },
    );

$Apache2SessionFlexParams{store}{Oracle} =
      $Apache2SessionFlexParams{store}{Sybase} =
      $Apache2SessionFlexParams{store}{Postgres};

my %OptionalApache2SessionFlexParams =
    ( Sybase => { store => [ qw( textsize ) ] },
      Oracle => { store => [ qw( long_read_len ) ] },
    );

sub _studly_form
{
    my $string = shift;
    $string =~ s/(?:^|_)(\w)/\U$1/g;
    return $string;
}

my %StudlyForm =
    ( map { $_ => _studly_form($_) }
      map { ref $_ ? @$_ :$_ }
      map { @$_ }
      ( values %Apache2SessionParams ),
      ( values %OptionalApache2SessionParams ),
      ( map { values %{ $Apache2SessionFlexParams{$_} } }
	keys %Apache2SessionFlexParams ),
      ( map { values %{ $OptionalApache2SessionFlexParams{$_} } }
	keys %OptionalApache2SessionFlexParams ),
    );

# why Apache::Session does this I do not know
$StudlyForm{textsize} = 'textsize';

sub new
{

    my $class = shift;

    $class->alter_superclass( $MasonX::Apache2Handler::VERSION ?
                              'MasonX::Request::Apache2Handler' :
                              $HTML::Mason::CGIHandler::VERSION ?
                              'HTML::Mason::Request::CGI' :
                              'HTML::Mason::Request' );

    my $self = $class->SUPER::new(@_);

    return if $self->is_subrequest;

    $self->_check_session_params;
    $self->_set_session_params;

    eval "require Apache::Session::$self->{session_class_piece}";
    die $@ if $@;

    $self->_make_session;

    $self->_bake_cookie
        if $self->{session_use_cookie} && ! $self->{session_cookie_is_baked};

    return $self;
}

sub _check_session_params
{
    my $self = shift;

    $self->{session_class_piece} = $self->{session_class};
    $self->{session_class_piece} =~ s/^Apache::Session:://;

    my $sets = $Apache2SessionParams{ $self->{session_class_piece} }
	or param_error "Invalid session class: $self->{session_class}";

    my $complete = $self->_check_sets($sets);

    param_error "Not all of the required parameters for your chosen session class ($self->{session_class}) were provided."
	unless $complete;

    if ( $self->{session_class_piece} eq 'Flex' )
    {
	foreach my $key ( keys %Apache2SessionFlexParams )
	{
	    my $subclass = $self->{"session_$key"};
	    my $sets = $Apache2SessionFlexParams{$key}{$subclass}
		or param_error "Invalid class for $key: $self->{$key}";

	    my $complete = $self->_check_sets($sets);

	    param_error "Not all of the required parameters for your chosen $key class ($subclass) were provided."
		unless $complete;
	}
    }
}

sub _check_sets
{
    my $self = shift;
    my $sets = shift;

    foreach my $set (@$sets)
    {
	return 1
	    if ( grep { exists $self->{"session_$_"} } @$set ) == @$set;
    }

    return 0;
}

sub _set_session_params
{
    my $self = shift;

    my %params;

    $self->_sets_to_params
	( $Apache2SessionParams{ $self->{session_class_piece} },
	  \%params );

    $self->_sets_to_params
	( $OptionalApache2SessionParams{ $self->{session_class_piece} },
	  \%params );


    if ( $self->{session_class_piece} eq 'Flex' )
    {
	foreach my $key ( keys %Apache2SessionFlexParams )
	{
	    my $subclass = $self->{"session_$key"};
	    $params{ $StudlyForm{$key} } = $subclass;

	    $self->_sets_to_params
		( $Apache2SessionFlexParams{$key}{$subclass},
		  \%params );

	    $self->_sets_to_params
		( $OptionalApache2SessionFlexParams{$key}{$subclass},
		  \%params );
	}
    }

    $self->{session_params} = \%params;

    if ( $self->{session_use_cookie} )
    {
        if ( $self->can('apache_req') )
        {
            eval { require Apache::Cookie; Apache::Cookie->can('bake'); };
            unless ($@)
            {
                $self->{cookie_class} = 'Apache::Cookie';
                $self->{new_cookie_args} =
		    [ $self->apache_req->can( 'env' ) ?
		      $self->apache_req->env : $self->apache_req ];
            }
        }

        unless ( $self->{cookie_class} )
        {
            require CGI::Cookie;
            $self->{cookie_class} = 'CGI::Cookie';
            $self->{new_cookie_args} = [];
        }
    }
}

sub _sets_to_params
{
    my $self = shift;
    my $sets = shift;
    my $params = shift;

    foreach my $set (@$sets)
    {
	foreach my $key (@$set)
	{
	    if ( exists $self->{"session_$key"} )
	    {
		$params->{ $StudlyForm{$key} } =
		    $self->{"session_$key"};
	    }
	}
    }
}

sub _make_session
{
    my $self = shift;
    my %p = validate( @_,
		      { session_id =>
			{ type => SCALAR,
                          optional => 1,
			},
		      } );

    return if
        defined $p{session_id} && $self->_try_session_id( $p{session_id} );

    if ( defined $self->{session_args_param} )
    {
        my $id = $self->_get_session_id_from_args;

        return if defined $id && $self->_try_session_id($id);
    }

    if ( $self->{session_use_cookie} )
    {
        my $id = $self->_get_session_id_from_cookie;

        if ( defined $id && $self->_try_session_id($id) )
        {
            $self->{session_cookie_is_baked} = 1
                unless $self->{session_cookie_resend};

            return;
        }
    }

    # make a new session id
    $self->_try_session_id(undef);
}

sub _get_session_id_from_args
{
    my $self = shift;

    my $args = $self->request_args;

    return $args->{ $self->{session_args_param} }
        if exists $args->{ $self->{session_args_param} };

    return undef;
}

sub _try_session_id
{
    my $self = shift;
    my $session_id = shift;

    return 1 if ( $self->{session} &&
                  defined $session_id &&
                  $self->{session_id} eq $session_id );

    my %s;
    {
	local $SIG{__DIE__};
	eval
	{
	    tie %s, "Apache::Session::$self->{session_class_piece}",
                $session_id, $self->{session_params};
	};

        if ($@)
        {
            $self->_handle_tie_error( $@, $session_id );
            return;
        }
    }

    untie %{ $self->{session} } if $self->{session};

    $self->{session} = \%s;
    $self->{session_id} = $s{_session_id};

    $self->{session_cookie_is_baked} = 0;

    return 1;
}

sub _get_session_id_from_cookie
{
    my $self = shift;

    my %c = $self->{cookie_class} eq 'Apache::Cookie' ?
	$self->{cookie_class}->fetch
	( $self->apache_req->can( 'env' ) ?
	  $self->apache_req->env : $self->apache_req ) :
	$self->{cookie_class}->fetch ;

    return $c{ $self->{session_cookie_name} }->value
        if exists $c{ $self->{session_cookie_name} };

    return undef;
}

sub _handle_tie_error
{
    my $self = shift;
    my $err = shift;
    my $session_id = shift;

    if ( $err =~ /Object does not exist/ )
    {
        return if $self->{session_allow_invalid_id};

        HTML::Mason::Exception::NonExistentSessionID->throw
            ( error => "Invalid session id: $session_id",
                  session_id => $session_id );
    }
    else
    {
        die $@;
    }
}

sub _bake_cookie
{
    my $self = shift;

    my $expires = shift || $self->{session_cookie_expires};

    my $domain = $self->{session_cookie_domain};

    my $cookie =
        $self->{cookie_class}->new
            ( @{ $self->{new_cookie_args} },
              -name    => $self->{session_cookie_name},
              -value   => $self->{session_id},
              -expires => $expires,
              ( defined $domain ?
                ( -domain  => $domain ) :
                ()
              ),
              -path    => $self->{session_cookie_path},
              -secure  => $self->{session_cookie_secure},
            );

    if ( $cookie->can('bake') )
    {
        # Apache::Cookie
        $cookie->bake;
    }
    else
    {
        if ( $self->can('apache_req') )
        {
            # works when we're a subclass of
            # MasonX::Request::Apache2Handler
            $self->apache_req->err_headers_out->{'Set-Cookie'} = $cookie;
        }
        elsif ( $self->can('cgi_request') )
        {
            # works when we're a subclass of
            # HTML::Mason::Request::CGIHandler
            $self->cgi_request->headers_out->{ 'Set-Cookie' } = $cookie;
        }
        else
        {
            # no way to set headers!
            die "Cannot set cookie headers when using CGI::Cookie without any object to set them on.";
        }
    }

    # always set this even if we skipped actually setting the cookie
    # to avoid resending it.  this keeps us from entering this method
    # over and over
    $self->{session_cookie_is_baked} = 1
        unless $self->{session_cookie_resend};
}

sub exec
{
    my $self = shift;

    return $self->SUPER::exec(@_)
        if $self->is_subrequest;

    my @r;

    if (wantarray)
    {
	@r = $self->SUPER::exec(@_);
    }
    else
    {
	$r[0] = $self->SUPER::exec(@_);
    }

    $self->_cleanup_session;

    return wantarray ? @r : $r[0];
}

sub session
{
    my $self = shift;

    return $self->parent_request->session(@_) if $self->is_subrequest;

    if ( ! $self->{session} || @_ )
    {
        $self->_make_session(@_);

        $self->_bake_cookie
            if $self->{session_use_cookie} && ! $self->{session_cookie_is_baked};
    }

    return $self->{session};
}

sub delete_session
{
    my $self = shift;

    return unless $self->{session};

    my $session = delete $self->{session};

    (tied %$session)->delete;

    delete $self->{session_id};

    $self->_bake_cookie('-1d') if $self->{session_use_cookie};
}

sub _cleanup_session
{
    my $self = shift;

    if ( $self->{session_always_write} )
    {
	if ( $self->{session}->{___force_a_write___} )
	{
	    $self->{session}{___force_a_write___} = 0;
	}
	else
	{
	    $self->{session}{___force_a_write___} = 1;
	}
    }

    untie %{ $self->{session} };
}

1;

__END__

=head1 NAME

MasonX::Request::WithApache2Session - Add a session to the Mason Request object

=head1 SYNOPSIS

In your F<httpd.conf> file:

  PerlSetVar  MasonRequestClass         MasonX::Request::WithApache2Session
  PerlSetVar  MasonSessionCookieDomain  .example.com
  PerlSetVar  MasonSessionClass         Apache::Session::MySQL
  PerlSetVar  MasonSessionDataSource    dbi:mysql:somedb

Or when creating an Apache2Handler object:

  my $ah =
      MasonX::Apache2Handler->new
          ( request_class => 'MasonX::Request::WithApache2Session',
            session_cookie_domain => '.example.com',
            session_class         => 'Apache::2Session::MySQL',
            session_data_source   => 'dbi:mysql:somedb',
          );

In a component:

  $m->session->{foo} = 1;
  if ( $m->session->{bar}{baz} > 1 ) { ... }

=head1 DESCRIPTION

B<MasonX::Request::WithApache2Session is experimental ( beta ) and
should only be used in a test environment.>

MasonX::Request::WithApache2Session is a clone of
MasonX::Request::WithApacheSession
changed to work under a pure mod_perl2 environment. The external
interface is unchanged, see L<MasonX::Request::WithApacheSession>.

The actual changes I made can be found in the distribution in
B<diff/WithApacheSession.diff> ( made with 'diff -Naru' ... ).

A HOWTO for MasonX::Apache2Handler and friends may be found at
L<Mason-with-mod_perl2>.

The following documentation is from MasonX::Request::WithApacheSession, 

This module integrates C<Apache::Session> into Mason by adding methods
to the Mason Request object available in all Mason components.

Any subrequests created by a request share the same session.

=head1 USAGE

To use this module you need to tell Mason to use this class for
requests.  This can be done in one of two ways.  If you are
configuring Mason via your F<httpd.conf> file, simply add this:

  PerlSetVar  MasonRequestClass  MasonX::Request::WithApache2Session

If you are using a F<handler.pl> file, simply add this parameter to
the parameters given to the ApacheHandler constructor:

  request_class => 'MasonX::Request::WithApache2Session'

=head1 METHODS

This class adds two methods to the Request object.

=over 4

=item * session

This method returns a hash tied to the C<Apache::Session> class.

=item * delete_session

This method deletes the existing session from persistent storage.  If
you are using the built-in cookie mechanism, it also deletes the
cookie in the browser.

=back

=head1 CONFIGURATION

This module accepts quite a number of parameters, most of which are
simply passed through to C<Apache::Session>.  For this reason, you are
advised to familiarize yourself with the C<Apache::Session>
documentation before attempting to configure this module.

=head2 Generic Parameters

=over 4

=item * session_class / MasonSessionClass  =>  class name

The name of the C<Apache::Session> subclass you would like to use.

This module will load this class for you if necessary.

This parameter is required.

=item * session_always_write / MasonSessionAlwaysWrite  =>  boolean

If this is true, then this module will ensure that C<Apache::Session>
writes the session.  If it is false, the default C<Apache::Session>
behavior is used instead.

This defaults to true.

=item * session_allow_invalid_id / MasonSessionAllowInvalidId  =>  boolean

If this is true, an attempt to create a session with a session id that
does not exist in the session storage will be ignored, and a new
session will be created instead.  If it is false, a
C<HTML::Mason::Exception::NonExistentSessionID> exception will be
thrown instead.

This defaults to true.

=back

=head2 Cookie-Related Parameters

=over 4

=item * session_use_cookie / MasonSessionUseCookie  =>  boolean

If true, then this module will use C<Apache::Cookie> to set and read
cookies that contain the session id.

The cookie will be set again every time the client accesses a Mason
component unless the C<session_cookie_resend> parameter is false.

=item * session_cookie_name / MasonSessionCookieName  =>  name

This is the name of the cookie that this module will set.  This
defaults to "MasonX-Request-WithApacheSession-cookie".
Corresponds to the C<Apache::Cookie> "-name" constructor parameter.

=item * session_cookie_expires / MasonSessionCookieExpires  =>  expiration

How long before the cookie expires.  This defaults to 1 day, "+1d".
Corresponds to the "-expires" parameter.

=item * session_cookie_domain / MasonSessionCookieDomain  =>  domain

This corresponds to the "-domain" parameter.  If not given this will
not be set as part of the cookie.

If it is undefined, then no "-domain" parameter will be given.

=item * session_cookie_path / MasonSessionCookiePath  =>  path

Corresponds to the "-path" parameter.  It defaults to "/".

=item * session_cookie_secure / MasonSessionCookieSecure  =>  boolean

Corresponds to the "-secure" parameter.  It defaults to false.

=item * session_cookie_resend / MasonSessionCookieResend  =>  boolean

By default, this parameter is true, and the cookie will be sent for
I<every request>.  If it is false, then the cookie will only be sent
when the session is I<created>.  This is important as resending the
cookie has the effect of updating the expiration time.

=back

=head2 URL-Related Parameters

=over 4

=item * session_args_param / MasonSessionArgsParam  =>  name

If set, then this module will first look for the session id in the
query string or POST parameter with the specified name.

If you are also using cookies, then the module checks in the request
arguments I<first>, and then it checks for a cookie.

The session id is available from C<< $m->session->{_session_id} >>.

=back

=head2 Apache::Session-related Parameters

These parameters are simply passed through to C<Apache::Session>.

=over 4

=item * session_data_source / MasonSessionDataSource  =>  DSN

Corresponds to the C<DataSource> parameter given to the DBI-related
session modules.

=item * session_user_name / MasonSessionUserName  =>  user name

Corresponds to the C<UserName> parameter given to the DBI-related
session modules.

=item * session_password / MasonSessionPassword  =>  password

Corresponds to the C<Password> parameter given to the DBI-related
session modules.

=item * session_handle =>  DBI handle

Corresponds to the C<Handle> parameter given to the DBI-related
session modules.  This cannot be set via the F<httpd.conf> file,
because it needs to be an I<actual Perl variable>, not the I<name> of
that variable.

=item * session_lock_data_source / MasonSessionLockDataSource  =>  DSN

Corresponds to the C<LockDataSource> parameter given to
C<Apache::Session::MySQL>.

=item * session_lock_user_name / MasonSessionLockUserName  =>  user name

Corresponds to the C<LockUserName> parameter given to
C<Apache::Session::MySQL>.

=item * session_lock_password / MasonSessionLockPassword  =>  password

Corresponds to the C<LockPassword> parameter given to
C<Apache::Session::MySQL>.

=item * session_lock_handle  =>  DBI handle

Corresponds to the C<LockHandle> parameter given to the DBI-related
session modules.  As with the C<session_handle> parameter, this cannot
be set via the F<httpd.conf> file.

=item * session_commit / MasonSessionCommit =>  boolean

Corresponds to the C<Commit> parameter given to the DBI-related
session modules.

=item * session_transaction / MasonSessionTransaction  =>  boolean

Corresponds to the C<Transaction> parameter.

=item * session_directory / MasonSessionDirectory  =>  directory

Corresponds to the C<Directory> parameter given to
C<Apache::Session::File>.

=item * session_lock_directory / MasonSessionLockDirectory  =>  directory

Corresponds to the C<LockDirectory> parameter given to
C<Apache::Session::File>.

=item * session_file_name / MasonSessionFileName  =>  file name

Corresponds to the C<FileName> parameter given to
C<Apache::Session::DB_File>.

=item * session_store / MasonSessionStore  =>  class

Corresponds to the C<Store> parameter given to
C<Apache::Session::Flex>.

=item * session_lock / MasonSessionLock  =>  class

Corresponds to the C<Lock> parameter given to
C<Apache::Session::Flex>.

=item * session_generate / MasonSessionGenerate  =>  class

Corresponds to the C<Generate> parameter given to
C<Apache::Session::Flex>.

=item * session_serialize / MasonSessionSerialize  =>  class

Corresponds to the C<Serialize> parameter given to
C<Apache::Session::Flex>.

=item * session_textsize / MasonSessionTextsize  =>  size

Corresponds to the C<textsize> parameter given to
C<Apache::Session::Sybase>.

=item * session_long_read_len / MasonSessionLongReadLen  =>  size

Corresponds to the C<LongReadLen> parameter given to
C<Apache::Session::MySQL>.

=item * session_n_sems / MasonSessionNSems  =>  number

Corresponds to the C<NSems> parameter given to
C<Apache::Session::Lock::Semaphore>.

=item * session_semaphore_key / MasonSessionSemaphoreKey  =>  key

Corresponds to the C<SemaphoreKey> parameter given to
C<Apache::Session::Lock::Semaphore>.

=item * session_mod_usertrack_cookie_name / MasonSessionModUsertrackCookieName  =>  name

Corresponds to the C<ModUsertrackCookieName> parameter given to
C<Apache::Session::Generate::ModUsertrack>.

=item * session_save_path / MasonSessionSavePath  =>  path

Corresponds to the C<SavePath> parameter given to
C<Apache::Session::PHP>.

=back

=head1 HOW COOKIES ARE HANDLED

When run under the ApacheHandler module, this module attempts to first
use C<Apache::Cookie> for cookie-handling.  Otherwise it uses
C<CGI::Cookie> as a fallback.

If it ends up using C<CGI::Cookie> then it can only set cookies if it
is running under either the ApacheHandler or the CGIHandler module.
Otherwise, the C<MasonX::Request::WithApacheSession> request object
has no way to get to an object which can take the headers.  In other
words, if there's no C<$r>, there's nothing with which to set headers.

=head1 SUPPORT

As can be seen by the number of parameters above, C<Apache::Session>
has B<way> too many possibilities for me to test all of them.  This
means there are almost certainly bugs.

Bug reports and requests for help should be sent to the mason-users
list.  See http://www.masonhq.com/resources/mailing_lists.html for
more details.

=head1 AUTHOR

Beau E. Cox <mason@beaucox.com> L<http://beaucox.com>.

The real authors (I just made mod_perl2 changes) is
Dave Rolsky, <autarch@urth.org>

Version 0.01 as of January, 2004.

=head1 SEE ALSO

My documents, including:
L<HOWTO Run Mason with mod_perl2|Mason-with-mod_perl2>,
L<MasonX::Apache2Handler|Apache2Handler>,
L<MasonX::Request::WithMulti2Session|WithMulti2Session>,

Original Mason documents, including:
L<HTML::Mason::ApacheHandler|ApacheHandler>,
L<MasonX::Request::WithApacheSession|WithApacheSession>,
L<MasonX::Request::WithMultiSession|WithMultiSession>.

Also see the Mason documentation at L<http://masonhq.com/docs/manual/>.

=cut
