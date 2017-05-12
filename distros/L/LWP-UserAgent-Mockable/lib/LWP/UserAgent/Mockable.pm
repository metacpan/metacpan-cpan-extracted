package LWP::UserAgent::Mockable;

use warnings;
use strict;

use Hook::LexWrap;
use LWP::UserAgent;
use Safe::Isa '$_isa';
use Storable qw( dclone nstore retrieve );

our $VERSION = '1.18';

my $instance = __PACKAGE__->__instance;
sub __instance {
    my ( $class ) = @_;

    if ( not defined $instance ) {
        $instance = bless {
            action          => undef,
            file            => undef,
            current_request => undef,
            actions         => [],
            callbacks       => {},
            wrappers        => {},
        }, $class;

        my $action = defined $ENV{ LWP_UA_MOCK }
          ? lc $ENV{ LWP_UA_MOCK }
          : 'passthrough';

        $instance->reset( $action, $ENV{ LWP_UA_MOCK_FILE } );
    }

    return $instance;
}

sub reset {
    my ( $class, $action, $file ) = @_;

    if ( scalar @{ $instance->{ actions } } ) {
        die "Can't reset state whilst pending actions.  Need to call finish first";
    }

    if ( not defined $action ) {
        $action = "passthrough";
    }

    if ( $action !~ /^(playback|record|passthrough)/ ) {
        die "Action must be one of 'passthrough', 'playback' or 'record'";
    }

    if ( $action ne 'passthrough' and not defined $file ) {
        die "No file defined.  Should point to file you wish to record to or playback from";
    }

    $instance->{ wrappers } = {};
    $instance->{ action } = $action;
    $instance->{ file } = $file;
    $instance->{ callbacks } = {};

    $instance->__reset;
}

sub __reset {
    my ( $self ) = @_;

    my ( $action, $file, $callbacks, $wrappers )
      = @{ $self }{ qw( action file callbacks wrappers ) };

    if ( $action eq 'playback' ) {
        local $Storable::Eval = 1;

        $self->{ actions } = retrieve( $file );

        $wrappers->{ pre } = wrap 'LWP::UserAgent::simple_request',
            pre     => sub {
                my ( $wrapped, $request ) = @_;

                my $current = shift @{ $self->{ actions } };
                if ( not defined $current ) {
                    die "No further HTTP requests exist.  You possibly need to re-record the LWP session";
                }

                my $response = $current->{ response };

                if ( $callbacks->{ playback_validation } ) {
                    my $mock_request = $current->{ request };

                    $callbacks->{ playback_validation }( $request, $mock_request );
                }

                if ( $callbacks->{ playback }) {
                    $response = $callbacks->{ playback }( $request, $response );

                    if ( not $response->$_isa( 'HTTP::Response' ) ) {
                        die "playback callback didn't return an HTTP::Response object";
                    }
                }

                $_[ -1 ] = $response;
            };
    } else {
        $wrappers->{ pre } = wrap 'LWP::UserAgent::simple_request',
            pre     => sub {
                my ( $wrapped, $request ) = @_;

                $self->{ current_request } = $request;

                if ( $callbacks->{ pre_record } ) {
                    $_[ -1 ] = $callbacks->{ pre_record }( $request );

                    if ( not $_[ -1 ]->$_isa( 'HTTP::Response' ) ) {
                        die "pre-record callback didn't return an HTTP::Response object";
                    }
                }
            };

        # It's intentional that wrap is called separately for this.  We want the
        # post action to always be called, even if the pre-action short-circuits
        # the request.  Otherwise, would need to duplicate the storing logic.
        # This does mean that, when both pre- and post-record callbacks are being
        # used, that the post-callback will take precedence.

        $wrappers->{ post } = wrap 'LWP::UserAgent::simple_request',
            post    => sub {
                my $response = $_[ -1 ];
                if ( $callbacks->{ record }) {
                    $response = $callbacks->{ record }(
                        $self->{ current_request },
                        $response
                    );

                    if ( not $response->$_isa( 'HTTP::Response' ) ) {
                        die "record callback didn't return an HTTP::Response object";
                    }
                }

                if ( $action eq 'record' ) {
                    local $Storable::Eval = 1;
                    local $Storable::Deparse = 1;

                    my $cloned = dclone {
                        request     => $self->{ current_request },
                        response    => $response
                    };

                    push @{ $self->{ actions } }, $cloned;
                }
            };
    }
}

sub finished {
    my ( $class ) = @_;

    my $action = $instance->{ action };

    if ( $action eq 'record' ) {
        local $Storable::Deparse = 1;
        local $Storable::Eval = 1;

        nstore $instance->{ actions }, $instance->{ file };
    } elsif ( $action eq 'playback' and scalar @{ $instance->{ actions } } ) {
        warn "Not all HTTP requests have been played back.  You possibly need to re-record the LWP session";
    }

    $instance->{ actions } = [];
    $instance->{ action } = 'passthrough';
    $instance->{ file } = undef;

    $instance->reset;
}

sub set_playback_callback {
    my ( $class, $cb ) = @_;

    $instance->__set_cb( playback => $cb );
}

sub set_record_callback {
    my ( $class, $cb ) = @_;

    $instance->__set_cb( record => $cb );
}

sub set_record_pre_callback {
    my ( $class, $cb ) = @_;

    $instance->__set_cb( pre_record => $cb );
}

sub set_playback_validation_callback {
    my ( $class, $cb ) = @_;

    $instance->__set_cb( playback_validation => $cb );
}

sub __set_cb {
    my ( $self, $type, $cb ) = @_;

    $self->{ callbacks }{ $type } = $cb;
}

1;

__END__

=encoding UTF-8

=head1 NAME

LWP::UserAgent::Mockable - Permits recording, and later playing back of LWP requests.

=head1 SYNOPSIS

In your test code:

    # setup env vars to control behaviour, allowing them to be
    # overridden from command line.  In current case, do before
    # loading module, so will be actioned on.

    BEGIN {
        $ENV{LWP_UA_MOCK}      ||= 'playback';
        $ENV{LWP_UA_MOCK_FILE} ||= "$0-lwp-mock.out";
    }

    use LWP;
    use LWP::UserAgent::Mockable;

    # setup a callback when recording, to allow modifying the response

    LWP::UserAgent::Mockable->set_record_callback( sub {
        my ( $request, $response ) = @_;

        print "GOT REQUEST TO: " . $request->uri;
        $response->content( lc( $response->content ) );

        return $response;
    } );

    # perform LWP request, as normal

    my $ua = LWP::UserAgent->new;
    my $res = $ua->get( "http://gmail.com" );
    print $res->content;

    # when the LWP work is done, inform LWP::UserAgent::Mockable
    # that we're finished.  Will trigger any behaviour specific to
    # the action being done, such as saving the recorded session.

    END {
        # END block ensures cleanup if script dies early
        LWP::UserAgent::Mockable->finished;
    }

To run the tests:

    # Store data
    LWP_UA_MOCK=record prove t/my-test.t

    # Use stored data
    prove t/my-test.t  # playback is default in example
    # or
    LWP_UA_MOCK=playback prove t/my-test.t

    # Re-record stored data
    LWP_UA_MOCK=record prove t/my-test.t

    # Ignore stored data
    LWP_UA_MOCK=passthrough prove t/my-test.t

=head1 DESCRIPTION

This module adds session record and playback options for LWP requests, whilst
trying to introduce as little clutter as necessary.

When in record mode, all LWP requests and responses will be captured in-memory,
until the finished method is called, at which point they will then be written
out to a file.  In playback mode, LWP responses are short-circuited, to instead
return the responses that were previously dumped out.  If neither of the above
actions are requested, this module does nothing, so LWP requests are handled as
normal.

Most of the control of this module is done via environment variables, both to
control the action being done (LWP_UA_MOCK env var, allowed values being
'record', 'playback', 'passthrough' (the default) ), and to control the file
that is used for storing or replaying the responses (LWP_UA_MOCK_FILE env var,
not used for 'passthrough' mode).

The only mandatory change to incorporate this module is to call the 'finished'
method, to indicate that LWP processing is completed.  Other than that, LWP
handling can be done as-normal.

As the initial impetus for this module was to allow mocking of external HTTP
calls within unit tests, a couple of optional callback (one for each action of
the valid action types), to allow for custom handling of responses, or to modify
the response that is returned back to the client (this is useful for simulating
the requested system being down, or when playing back, to modify the mocked
response to reflect expected dynamic content).

=head2 Methods

As there is only a singleton instance of LWP::UserAgent::Mockable, all methods
are class methods.

=over 4

=item finished() - required

Informs LWP::UserAgent::Mockable that no further requests are expected, and
allow it to do any post-processing that is required.

When in 'record' mode, this will cause the playback file (controlled by
LWP_UA_MOCK_FILE env var) to be created.  When in 'playback' mode, this will
issue a warning if there is still additional mocked responses that haven't been
returned.

=item set_record_callback( <sub {}> ) - optional

=item set_playback_callback( <sub {}> ) - optional

These optional methods allow custom callbacks to be inserted, when performing
the relevant actions.  The callback will be invoked for each LWP request, AFTER
the request has been actioned (see set_record_pre_callback for a method o
short-circuiting the LWP fetch).  They will be passed in 2 parameters, an
L<HTTP::Request> and an L<HTTP::Response> object.  For the record callback
(which is used for both 'record' and 'passthrough' mode) the request will be
the L<HTTP::Request> object used to perform the request, and the response the
L<HTTP::Response> result from that.  In playback mode, the request will be the
L<HTTP::Request> object used to perform the request, and the response the mocked
response object.

When the callbacks are being used, they're expected to return an
L<HTTP::Response> object, which will be treated as the actual reply from the
call being made.  Failure to do do will result in a fatal error being raised.

To clear a callback, call the relevant method, passing in no argument.

=item set_record_pre_callback( <sub {}> ) - optional

This callback is similar to set_record_callback, except that it will
short-circuit the actual fetching of the remote URL.  Only a single parameter
is passed through to this callback, that being the L<HTTP::Request> object.
It's expected to construct an return an L<HTTP::Response> object (or subclass
thereof).  Should anything other than an L<HTTP::Response> subclass be
returned, a fatal error will be raised.

This callback will be invoked for both 'record' and 'passthrough' modes.
Note that there is no analagous callback for 'playback' mode.

To clear the callback, pass in no argument.

=item set_playback_validation_callback( <sub {}> ) - optional

This callback allows validation of the received request.  It receives two
parameters, both L<HTTP::Request>s, the first being the actual request made,
the second being the mocked request that was received when recording a session.
It's up to the callback to do any validation that it wants, and to perform any
action that is warranted.

As with other callbacks, to clear, pass in no argument to the method.

=item reset( <action>, <file> ) - optional

Reset the state of mocker, allowing the action and file operation on to change.
Will also reset all callbacks.  Note that this will raise an error, if called
whilst there are outstanding requests, and the B<finished> method hasn't been
called.

=back

=head1 CAVEATS

The playback file generated by this is not encrypted in any manner.  As it's
only using L<Storable> to dump the file, it's easy to get at the data contained
within, even if the requests are going to HTTPS sites.  Treat the playback file
as if it were the original data, security-wise.

=head1 SEE ALSO

=over

=item * L<LWP::UserAgent> - The class being mocked.

=item * L<Test::LWP::UserAgent>

=item * L<HTTP::Request>

=item * L<HTTP::Response>

=back

=head1 AUTHOR

Mark Morgan, C<< <makk384@gmail.com> >>

=head1 CONTRIBUTORS

Michael Jemmeson, C<< <michael.jemmeson at cpan.org> >>

Kit Peters, C<< <popefelix at cpan.org> >>

Mohammad S. Anwar, C<< <mohammad.anwar at yahoo.com> >>

Slaven Rezić, C<< <SREZIC at cpan.org> >>

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/mjemmeson/LWP-UserAgent-Mockable/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/mjemmeson/LWP-UserAgent-Mockable>

    git clone git://github.com/mjemmeson/LWP-UserAgent-Mockable.git

=head1 COPYRIGHT & LICENSE

Copyright 2009 Mark Morgan, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
