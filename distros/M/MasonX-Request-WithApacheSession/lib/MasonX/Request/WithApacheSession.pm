package MasonX::Request::WithApacheSession;

use 5.005;
use strict;

use vars qw($VERSION @ISA);

$VERSION = '0.31';

use Apache::Session::Wrapper 0.13;

use HTML::Mason 1.16;
use HTML::Mason::Exceptions ( abbr => [ qw( param_error error ) ] );
use HTML::Mason::Request;

use Params::Validate qw(:all);
Params::Validate::validation_options( on_fail => sub { param_error( join '', @_ ) } );

# This may change later
@ISA = qw(HTML::Mason::Request);


#
# This is a bit of a hack, ideally we could do this:
#
#   __PACKAGE__->contained_objects( class  => 'Apache::Session::Wrapper',
#                                   prefix => 'session_',
#                                 );
#
# and let Class::Container sort it all out.  We'd also need a way to
# override some of the contained class's defaults.
#
my $wrapper_p = Apache::Session::Wrapper->valid_params;

{
    my %p = map { ( "session_$_" => $wrapper_p->{$_} ) } keys %$wrapper_p;
    foreach my $k ( grep { exists $p{$_}{depends} } keys %p )
    {
        my %new = %{ $p{$k} };

        my @d = ref $new{depends} ? @{ $new{depends} } : $new{depends};
        $new{depends} = [ map { ( "session_$_" ) } @d ];

        $p{$k} = \%new;
    }

    $p{session_cookie_name}{default} = 'MasonX-Request-WithApacheSession-cookie';

    # We'll always provide this, so the user doesn't need to.
    delete $p{session_param_name}{depends};

    __PACKAGE__->valid_params
        ( # This is for backwards compatibility, it's been renamed to
          # param_name
          session_args_param =>
          { type => SCALAR,
            optional => 1,
            descr => 'Name of the parameter to use for session tracking',
          },
          %p,
        );
}

sub new
{

    my $class = shift;

    $class->alter_superclass( $HTML::Mason::ApacheHandler::VERSION ?
                              'HTML::Mason::Request::ApacheHandler' :
                              $HTML::Mason::CGIHandler::VERSION ?
                              'HTML::Mason::Request::CGI' :
                              'HTML::Mason::Request' );

    my $self = $class->SUPER::new(@_);

    return $self if $self->is_subrequest;

    # backwards compatibility
    $self->{session_param_name} =
        $self->{session_args_param} if exists $self->{session_args_param};

    my %extra;
    if ( $self->can('apache_req') )
    {
        %extra = ( header_object => $self->apache_req,
                   param_object  => $self->apache_req,
                 );
    }
    elsif ( $self->can('cgi_process') )
    {
        %extra = ( header_object => $self->cgi_request,
                   param_object  => $self->cgi_object,
                 );
    }

    $self->{apache_session_wrapper} =
        Apache::Session::Wrapper->new
            ( %extra,
              map { $_ => $self->{"session_$_"} }
              grep { exists $self->{"session_$_"} }
              keys %$wrapper_p
            );

    return $self;
}

sub wrapper
{
    $_[0]->is_subrequest
    ? $_[0]->parent_request->wrapper
    : $_[0]->{apache_session_wrapper}
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

    $self->wrapper->cleanup_session;

    return wantarray ? @r : $r[0];
}

BEGIN
{
    foreach my $meth ( qw( session delete_session ) )
    {
        no strict 'refs';
        *{$meth} = sub { shift->wrapper->$meth(@_) };
    }
}


1;

__END__

=head1 NAME

MasonX::Request::WithApacheSession - Add a session to the Mason Request object

=head1 SYNOPSIS

In your F<httpd.conf> file:

  PerlSetVar  MasonRequestClass            MasonX::Request::WithApacheSession
  PerlSetVar  MasonSessionCookieDomain     .example.com
  PerlSetVar  MasonSessionClass            Apache::Session::File
  PerlSetVar  MasonSessionDirectory        /tmp/sessions/data
  PerlSetVar  MasonSessionLockDirectory    /tmp/sessions/locks

Or when creating an ApacheHandler object:

  my $ah =
      HTML::Mason::ApacheHandler->new
          ( request_class => 'MasonX::Request::WithApacheSession',
            session_cookie_domain  => '.example.com',
            session_class          => 'Apache::Session::File',
            session_directory      => '/tmp/sessions/data',
            session_lock_directory => '/tmp/sessions/locks',
          );

In a component:

  $m->session->{foo} = 1;
  if ( $m->session->{bar}{baz} > 1 ) { ... }

=head1 DESCRIPTION

This module integrates C<Apache::Session> into Mason by adding methods
to the Mason Request object available in all Mason components.

Any subrequests created by a request share the same session.

=head1 USAGE

To use this module you need to tell Mason to use this class for
requests.  This can be done in one of two ways.  If you are
configuring Mason via your F<httpd.conf> file, simply add this:

  PerlSetVar  MasonRequestClass  MasonX::Request::WithApacheSession

If you are using a F<handler.pl> file, simply add this parameter to
the parameters given to the ApacheHandler constructor:

  request_class => 'MasonX::Request::WithApacheSession'

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
simply passed through to C<Apache::Session::Wrapper>.  For this
reason, you are advised to familiarize yourself with the
C<Apache::Session::Wrapper> documentation before attempting to
configure this module.

If you are creating your own Interp/ApacheHandler/CGIHandler object in
a script or module, you should pass this object the parameters
intended for C<Apache::Session::Wrapper>, prefixed with "session_".
So to set the "class" parameter for C<Apache::Session::Wrapper>, you
pass in a "session_class" parameter.

If you are configuring Mason via your F<httpd.conf> file, you should
pass the "StudlyCaps" version of the name, prefixed by "MasonSession".
So the "class" parameter would be "MasonSessionClass".

A few examples:

=over 4

=item * class becomes session_class / MasonSessionClass

=item * always_write becomes session_always_write / MasonSessionAlwaysWrite

=back

When running under ApacheHandler or CGIHandler, this module takes care
of passing the "header_object" and "param_object" parameters to
C<Apache::Session::Wrapper>.  These will be the C<Apache::Request> or
C<CGI.pm> objects, as applicable.

The "cookie_name" parameter defaults to
"MasonX-Request-WithApacheSession-cookie" when you use this module,
instead of "Apache-Session-Wrapper-cookie".

Finally, for backwards compatiblity, this module accepts a
"session_args_param" parameter, which corresponds to the "param_name"
parameter for C<Apache::Session::Wrapper>.

=head1 SUPPORT

As can be seen by the number of parameters above, C<Apache::Session>
has B<way> too many possibilities for me to test all of them.  This
means there are almost certainly bugs.

Bug reports and requests for help should be sent to the mason-users
list.  See http://www.masonhq.com/resources/mailing_lists.html for
more details.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 MAINTAINER

Brad Lhotsky, <blhotsky@cpan.org>

=head1 SEE ALSO

HTML::Mason

=cut
