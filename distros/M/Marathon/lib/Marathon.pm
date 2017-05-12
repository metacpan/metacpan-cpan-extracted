package Marathon;

use 5.006;
use strict;
use warnings;
use LWP::UserAgent;
use JSON::XS;
use Marathon::App;
use Marathon::Group;
use Marathon::Events;
use Marathon::Deployment;

=head1 NAME

Marathon - An object-oriented Mapper for the Marathon REST API

=head1 VERSION

Version 0.9

=cut

our $VERSION = '0.9';
our $verbose = 0;


=head1 SYNOPSIS

This module is a wrapper around the [Marathon REST API](http://mesosphere.github.io/marathon/docs/rest-api.html), so it can be used without having to write JSON by hand.

For the most common tasks, there is a helper method in the main module. Some additional metods are found in the Marathon::App etc. submodules.

To start, create a marathon object:

    my $m = Marathon->new( url => 'http://my.marathon.here:8080' );

    my $app = $m->get_app('hello-marathon');
    
    $app->instances( 23 );
    $app->update();
    print STDERR Dumper( $app->deployments );
    
    sleep 10;
    
    $app->instances( 1 );
    $app->update( {force => 'true'} ); # should work even if the scaling up is not done yet.

Please report [issues on github](https://github.com/geidies/perl-Marathon)

=head1 SUBROUTINES/METHODS

=head2 new

Creates a Marathon object. You can pass in the URL to the marathon REST interface:
    
    use Marathon;
    my $marathon = Marathon->new( url => 'http://169.254.47.11:8080', verbose => 0 );

The "verbose" parameter makes the module more chatty on STDERR.

=cut

sub new {
    my ($class, %conf) = @_;
    my $url = delete $conf{url} || 'http://localhost:8080/';
    $Marathon::verbose = delete $conf{verbose} || 0;
    my $ua = LWP::UserAgent->new;
    my $self = bless {
      _ua     => $ua,
    };
    $self->_set_url($url);
    return $self;
}

sub _set_url { # void
  my ($self, $url) = @_;
  unless ( $url =~ m,^https?\://, ) {
      $url = 'http://' . $url;
  }
  unless ( $url =~ m,/$, ) {
      $url .= '/';
  }
  $self->{_url} = $url;
}

=head2 get_app( $id )

Returns a Marathon::App as identified by the single argument "id". In case there is no such app, will return undef.

    my $app = $marathon->get_app('such-1');
    print $app->id . "\n";

=cut

sub get_app { # Marathon::App
    my ( $self, $id ) = @_;
    my $api_response = $self->_get_obj('/v2/apps/' . $id);
    return undef unless defined $api_response;
    return Marathon::App->new( $api_response->{app}, $self );
}

=head2 new_app( $config )

Returns a new Marathon::App as described in the $config hash. Example:

    my $app = $marathon->new_app({ id => 'very-1', mem => 4, cpus => 0.1, cmd => "while [ 1 ]; do echo 'wow.'; done" });

This will not (!) start the app in marathon. To do so, call create() on the returned object:

    $app->create();

=cut

sub new_app {
    my ($self, $config) = @_;
    return Marathon::App->new( $config, $self );
}

=head2 get_group( $id )

Works like get_app, just for groups.

=cut

sub get_group { # Marathon::App
    my ( $self, $id ) = @_;
    return Marathon::Group->get( $id, $self );
}

=head2 new_group( $config )

Creates a new group. You can either specify the apps in-line:

    my $group = $marathon->new_group( { id => 'very-1', apps: [{ id => "such-2", cmd => ... }, { id => "such-3", cmd => ... }] } );

Or add them to the created group later:

    my $group = $marathon->new_group( { id => 'very-1' } );
    $group->add( $marathon->new_app( { id => "such-2", cmd => ... } );
    $group->add( $marathon->new_app( { id => "such-3", cmd => ... } );

In any case, new_group will just return a Marathon::Group object, it will not commit to marathon until you call create() on the returned object:

    $group->create();

=cut

sub new_group {
    my ($self, $config) = @_;
    return Marathon::Group->new( $config, $self );
}

=head2 events()

Returns a Marathon::Events objects. You can register callbacks on it and start listening to the events stream. 

=cut

sub events {
    my $self = shift;
    return Marathon::Events->new( $self );
}

=head2 get_tasks( $status )

Returns an array of currently running tasks. If $status is "running" or "staging", will filter and return only those tasks.

=cut

sub get_tasks {
    my ($self, $status) = @_;
    $status = '' unless $status && $status =~ m/^running|staging$/;
    if ( $status ) {
        $status = '?status='.$status;
    }
    my $task_obj = $self->_get_obj_from_json('/v2/tasks'.$status);
    my $task_arrayref = ( defined $task_obj && exists $task_obj->{tasks} && $task_obj->{tasks} ) || [];
    return wantarray ? @{$task_arrayref} : $task_arrayref;
}

=head2 kill_tasks({ tasks => $@ids, scale => bool })

Kills the tasks with the given @ids. Scales if the scale param is true.

=cut

sub kill_tasks {
    my ($self, $args) = @_;
    my $param = $args && $args->{scale} && $args->{scale} && $args->{scale} !~ /false/i ? '?scale=true' : ''; #default is false
    return $self->_put_post_delete( 'POST', '/v2/tasks/delete'.$param, { ids => $args->{tasks} } );
}

=head2 get_deployments

Returns a list of Marathon::Deployment objects with the currently running deployments.

=cut

sub get_deployments {
    my $self = shift;
    my $deployments = $self->_get_obj('/v2/deployments');
    my @depl_objs = ();
    foreach ( @{$deployments} ) {
        push @depl_objs, Marathon::Deployment->new( $_, $self );
    }
    return wantarray ? @depl_objs : \@depl_objs;
}

=head2 kill_deployment( $id, { force => bool } )

Stop the deployment with given id.

=cut

sub kill_deployment {
    my ($self, $id, $args) = @_;
    my $param = $args && $args->{force} && $args->{force} && $args->{force} !~ /false/i ? '?force=true' : ''; #default is false
    return $self->_put_post_delete( 'DELETE', '/v2/deployments/' . $id . $param );
}

sub get_endpoint {
    my ( $self, $path ) = @_;
    my $url = $self->{_url} . $path;
    $url =~ s,/+,/,g;
    $url =~ s,^http:/,http://,;
    return $url;
}

=head2 metrics

returns the metrics returned by the /metrics endpoint, converted from json to perl.

=cut

sub metrics {
    my $self = shift;
    return $self->_get_obj('/metrics');
}

=head2 help

returns the html returned by the /help endpoint.

=cut

sub help { # string (html)
    my $self = shift;
    return $self->_get_html('/help');
}

=head2 logging

returns the html returned by the /logging endpoint.

=cut

sub logging { # string (html)
    my $self = shift;
    return $self->_get_html('/logging');
}

=head2 ping

returns 1 if the master responds to a ping request.

=cut

sub ping { # string (plaintext)
    my $self = shift;
    return $self->_get_html('/ping') =~ m,pong, ? 'pong' : undef;
}

sub _get { # HTTP::Response
    my ( $self, $path ) = @_;
    my $url = $self->get_endpoint( $path );
    my $response = $self->{_ua}->get( $url );
    $self->_response_handler( 'GET', $response );
    return $response;
}

sub _get_html { # string (html) or undef on error
    my ( $self, $path ) = @_;
    my $response = $self->_get($path);
    if ( $response->is_success ) {
        return $response->decoded_content;
    }
    return '';
}

sub _get_obj { # hashref
    my ( $self, $path ) = @_;
    my $response = $self->_get_html($path);
    if ($response) {
        return decode_json $response;
    }
    return undef;
}

sub _get_obj_from_json { # hashref
    my ( $self, $path ) = @_;
    my $response = $self->_put_post_delete('GET', $path);
    if ($response) {
        return decode_json $response;
    }
    return undef;
}

sub _post {
    my ($self, $path, $payload) = @_;
    return $self->_put_post_delete( 'POST', $path, $payload );
}

sub _put {
    my ($self, $path, $payload) = @_;
    return $self->_put_post_delete( 'PUT', $path, $payload );
}

sub _delete {
    my ($self, $path, $payload) = @_;
    return $self->_put_post_delete( 'DELETE', $path, $payload );
}

sub _put_post_delete {
    my ($self, $method, $path, $payload) = @_;
    my $req = HTTP::Request->new( $method, $self->get_endpoint($path) );
    $req->header( 'Accept' => 'application/json' );
    if ( $payload ) {
        $req->header( 'Content-Type' => 'application/json' );
        $req->content( encode_json $payload );
    }
    my $response = $self->{_ua}->request( $req );
    $self->_response_handler( $method, $response );
    return $response->is_success ? $response->decoded_content : undef;
}

sub _response_handler {
    my ( $self, $method, $response ) = @_;
    if ( $verbose ) {
        unless ( $response->is_success ) {
            print STDERR 'Error doing '.$method.' against '. $response->base.': ' . $response->status_line . "\n";
            print STDERR $response->decoded_content ."\n";
        } else {
            print STDERR $response->status_line . "\n"
        }
    }
    return $response;
}

=head1 AUTHOR

Sebastian Geidies, C<< <seb at geidi.es> >>

=head1 BUGS

Please report [issues on github](https://github.com/geidies/perl-Marathon)

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Marathon


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Marathon>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Marathon>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Marathon>

=item * Search CPAN

L<http://search.cpan.org/dist/Marathon/>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2015 Sebastian Geidies.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1; # End of Marathon
