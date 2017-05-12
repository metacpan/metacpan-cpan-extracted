package MasonX::Request::WithMulti2Session;

use strict;

use Digest::SHA1 ();
use Time::HiRes;

use base qw(MasonX::Request::WithApache2Session);

use HTML::Mason::Exceptions ( abbr => [ qw( param_error error ) ] );

use Params::Validate qw( validate SCALAR );
Params::Validate::validation_options( on_fail => sub { param_error( join '', @_ ) } );

__PACKAGE__->valid_params
    ( multi_session_args_param =>
      { type => SCALAR,
        default => 'sub_session_id',
        descr => 'The parameter name which contains the sub-session id',
      },

      multi_session_expire =>
      { type    => Params::Validate::SCALAR,
        default => undef,
        descr => 'How long a sub-session stays valid',
      },
    );

sub session
{
    my $self = shift;

    return $self->parent_request->session(@_) if $self->is_subrequest;

    my %p = @_;

    my %super_p = exists $p{session_id} ? ( session_id => $p{session_id} ) : ();
    my $session = $self->SUPER::session(%super_p);

    my %sub_session_p =
        exists $p{sub_session_id} ? ( sub_session_id => $p{sub_session_id} ) : ();
    my $id = $self->sub_session_id(%sub_session_p);

    if ( $p{clone} || $p{new} )
    {
        # forces creation of a new id
        delete $self->{sub_session_id};
        my $new_id = $self->_make_new_sub_session_id;

        if ( $p{clone} )
        {
            # shallow copy of old session
            $session->{sub_sessions}{$new_id} = { %{ $session->{sub_sessions}{$id} } };
        }

        $id = $new_id;
    }

    $session->{sub_session_ids}{$id} = int(time);

    return $session->{sub_sessions}{$id};
}

sub sub_session_id
{
    my $self = shift;
    my %p = validate( @_,
		      { sub_session_id =>
			{ type => SCALAR,
                          optional => 1,
			},
		      } );

    unless ( exists $self->{sub_session_id} )
    {
        my $args = $self->request_args;

        my $args_key = $self->{multi_session_args_param};

        my $session = $self->SUPER::session;
        if ( exists  $p{sub_session_id} )
        {
            unless ( exists $session->{sub_session_ids}{ $p{sub_session_id} } )
            {
                $session->{sub_sessions}{ $p{sub_session_id} } = {};
            }

            $self->{sub_session_id} = $p{sub_session_id};
        }
        elsif ( exists $args->{$args_key} &&
                exists $session->{sub_session_ids}{ $args->{$args_key} } )
        {
            $self->{sub_session_id} = $args->{$args_key};
        }
        else
        {
            $self->_make_new_sub_session_id;
        }
    }

    return $self->{sub_session_id};
}

sub _make_new_sub_session_id
{
    my $self = shift;

    my $session = $self->SUPER::session;

    my $new_id;

    do
    {
        # using Time::HiRes means that we get times with very high
        # floating point resolutions (to 10 or 11 decimal places), so
        # this is a good seed for a hashing algorithm
        $new_id = Digest::SHA1::sha1_hex( time() . {} . rand() . $$ );
    } while ( exists $session->{sub_session_ids}{$new_id} );

    $session->{sub_sessions}{$new_id} = {};

    $self->{sub_session_id} = $new_id;

    return $new_id;
}

sub delete_sub_session
{
    my $self = shift;

    my $session = $self->SUPER::session;

    my %p = validate( @_,
		      { sub_session_id =>
			{ type => SCALAR,
                          optional => 1,
			},
		      } );

    my $sub_id = $p{sub_session_id} ? $p{sub_session_id} : delete $self->{sub_session_id};

    delete $session->{sub_sessions}{$sub_id};
    delete $session->{sub_session_ids}{$sub_id};
}

sub delete_session
{
    my $self = shift;

    $self->SUPER::delete_session;

    delete $self->{sub_session_id};
}

sub DESTROY
{
    my $self = shift;

    return unless defined $self->{multi_session_expire};

    my $session = $self->SUPER::session;

    my $cutoff = int(time) - $self->{multi_session_expire};
    foreach my $id ( keys %{ $session->{sub_session_ids} } )
    {
        if ( $session->{sub_session_ids}{$id} < $cutoff )
        {
            delete $session->{sub_sessions}{$id};
            delete $session->{sub_session_ids}{$id};
        }
    }
}


1;

__END__

=head1 NAME

MasonX::Request::WithMulti2Session - Multiple sub-sessions within one "parent" session

=head1 SYNOPSIS

  PerlSetVar  MasonRequestClass  MasonX::Request::WithMulti2Session

=head1 DESCRIPTION

B<MasonX::Request::WithMulti2Session is experimental ( beta ) and
should only be used in a test environment.>

MasonX::Request::WithMulti2Session is a clone of
MasonX::Request::WithMultiSession
changed to work under a pure mod_perl2 environment. The external
interface is unchanged, see L<MasonX::Request::WithMultiSession>.

The actual changes I made can be found in the distribution in
B<diff/WithMultiSession.diff> ( made with 'diff -Naru' ... ).

A HOWTO for MasonX::Apache2Handler and friends may be found at
L<Mason-with-mod_perl2>.

The following documentation is from MasonX::Request::WithMultiSession. 

This module subclasses C<MasonX::Request::WithApache2Session> in order
to allow multiple "sub-sessions" to exist within one parent session.

This can be quite useful for a web app where you want to allow the
user to open multiple windows, each with a different session, but
session ids are stored in a cookie.

Like C<MasonX::Request::WithApache2Session>, sub-sessions are shared
between a request and any subrequests it creates.

=head1 METHODS

This class has an interface quite similar to that of
C<MasonX::Request::WithApache2Session>.

=over 4

=item * session

The primary interface to this class is through the C<session()>
method.  When this method is called without any parameters, the module
looks for an existing sub-session specified by the sub-session id
argument parameter (which can be in a query string or POST).  This
value can be overridden by explicitly passing a "sub_session_id"
parameter.

If this parameter is found, an existing sub-session is returned.  If
this parameter is not found, a new sub-session is created.

If the C<session()> method is called as C<< session( clone => 1 ) >>
then a new sub-session will be created, and its contents will be the
same as that of the current sub-session.  This is a shallow copy of
the old session hash, so objects and references are shared between
them.

If C<< session( new => 1 ) >> is called, then a new, empty,
sub-session is created.

You can specify the main session id to use via the "session_id"
parameter.

=item * sub_session_id

This method returns the currently active sub-session's id.  Use this
method to put this id into URL parameters, forms, etc. as needed.

If given a "sub_session_id" parameter, it will set the current
sub-session id.

=item * delete_sub_session

By default, this simply defaults the current sub-session.  You can
pass a "sub_session_id" parameter to delete a specific session.

=back

=head2 Parameters

This module takes two parameters besides those inherited from
C<MasonX::Request::WithApache2Session>:

=over 4

=item * multi_session_args_param / MultiSessionArgsParam

This parameter can be used to specify which parameter contains the
sub-session id.  By default, the module will look for a parameter
called "sub_session_id".

=item * multi_session_expire / MultiSessionExpire

This parameter specifies the number of seconds after a sub-session is
accessed until it is purged.  If not specified, then sub-sessions are
never purged.

Sub-sessions expiration is checked when the request object goes out of
scope.

=back

=head1 USAGE

You will need to manually set the sub-session id argument parameter
for each request.  The easiest way to do this is to make sure that all
URLs contain the sub-session id.  This can be done by using a C<<
<%filter> >> block in a top-level autohandler (although this won't
catch redirects), or by making sure all URLs are generated by a single
component/function.

=head1 SUPPORT

Bug reports and requests for help should be sent <mason@beaucox.com>.

=head1 AUTHOR

Beau E. Cox <mason@beaucox.com> L<http://beaucox.com>.

The real authors (I just made mod_perl2 changes) is
Dave Rolsky, <autarch@urth.org>

Version 0.01 as of January, 2004.

=head1 SEE ALSO

My documents, including:
L<HOWTO Run Mason with mod_perl2|Mason-with-mod_perl2>,
L<MasonX::Apache2Handler|Apache2Handler>,
L<MasonX::Request::WithApache2Session|WithApache2Session>.

Original Mason documents, including:
L<HTML::Mason::ApacheHandler|ApacheHandler>,
L<MasonX::Request::WithApacheSession|WithApacheSession>,
L<MasonX::Request::WithMultiSession|WithMultiSession>.

Also see the Mason documentation at L<http://masonhq.com/docs/manual/>.

=cut
