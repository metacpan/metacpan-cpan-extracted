package Ekahau;
use base 'Ekahau::Base'; our $VERSION = $Ekahau::Base::VERSION;

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2004 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.

use warnings;
use strict;

=head1 NAME

Ekahau - Synchronous interface to Ekahau location sensing system

=head1 SYNOPSIS

The C<Ekahau> class provides a straightforward synchronous interface
to the Ekahau location sensing system's YAX protocol.  The YAX
protocol itself is asynchronous, so this module tries its best to hide
that from you.

This class inherits from L<Ekahau::Base|Ekahau::Base>, and you can use methods from
that class.  An alternative, event-driven interface is provided by
L<Ekahau::Events|Ekahau::Events>.

=head1 DESCRIPTION

This class implements methods for querying the Ekahau Positioning
Engine, and processing the responses.  Each C<Ekahau> object
represents a connection to the Ekahau server.  Some methods send
queries to the server, others receive responses, and still others do
both.  This class tries to hide the asynchronousness of the YAX
protocol from you.

The basic mechanism allows you to send requests, and wait for
responses.  If other responses unrelated to the one you're waiting for
come in, they will be queued and sent to you when you ask for them.
Some methods will first send a request then wait for the response,
handling all of the details internally.

=head2 Constructor

This classes uses L<Ekahau::Base::new|Ekahau::Base/new> as its constructor.

=head2 Methods

=head3 getresponse ( [ $tags ], [ $cmds ] )

Get the next L<Ekahau::Response|Ekahau::Response> matching the given tags and commands.
If you specify neither tags nor commands, the next response will be
returned.  If you specify just one of the two, responses will only be
matched against the one specified.  If you specify both, responses
must match one of the tags, and one of the commands.

Both C<$tags> and C<$cmds> should be list references.

Examples:

    $obj->getresponse();                   # Next response
    $obj->getresponse(['LOC','AREA']);     # Next response with LOC or AREA tag
    $obj->getresponse([],['DEVICE_LIST']); # Next DEVICE_LIST response

=cut

sub getresponse
{
    my $self = shift;
    my ($tags,$cmds)=@_;

    my $tagmap = (($tags and @$tags) ? { map { $_ => 1 } @$tags } : undef);
    my $cmdmap = (($cmds and @$cmds) ? { map { $_ => 1 } @$cmds } : undef);

    # See if we have something on the queue already
    if ($self->{_q})
    {
        foreach my $i (0..$#{$self->{_q}})
        {
	    if (_respmatch($self->{_q}[$i],$tagmap,$cmdmap))
            {
                return splice(@{$self->{_q}},$i,1);
            }
        }
    }

    # Wait until we get something, or the timeout expires.
    my $started = time;
    while(1)
    {
	while (my $resp = $self->getpending)
	{
	    return $resp if (_respmatch($resp,$tagmap,$cmdmap));
	    push @{$self->{_q}},$resp;
	}
	# See if we timed out.
	$self->can_read($self->{_timeout}?($self->{_timeout}-(time-$started)):0)
	    or return undef;
	
	$self->readsome()
	    or return undef;
    }
}

=head3 gettaggedresponse ( @tags )

Get the next L<Ekahau::Response|Ekahau::Response> matching any of the given tags.  This
is exactly equivalent to:

    $self->getresponse([@_]);

=cut

sub gettaggedresponse
{
    my $self = shift;
    $self->getresponse([@_]);
}

sub _respmatch
{
    my($resp,$tagmap,$cmdmap) = @_;
    return ((!$tagmap and !$cmdmap)
	    or (!$cmdmap and $resp->{tag} and $tagmap->{$resp->{tag}})
	    or (!$tagmap and $resp->{cmd} and $cmdmap->{$resp->{cmd}})
	    or ($resp->{cmd} and $resp->{tag} and $tagmap->{$resp->{tag}} and $cmdmap->{$resp->{cmd}}));

}

=head3 get_device_list ( )

Get a list of devices currently detected on the Ekahau system.  The
response is returned as a reference to a list of numeric IDs.  On
error, this method will return C<undef>.

=cut

sub get_device_list
{
    my $self = shift;

    my $tag = $self->request_device_list
	or return undef;
    my $resp = $self->gettaggedresponse($tag)
	or return undef;
    
    if ($resp->error)
    {
	return $self->reterr("GET_DEVICE_LIST failed: ".$resp->error_description);
    }
    elsif ($resp->type ne 'DeviceList')
    {
	return $self->reterr("GET_DEVICE_LIST failed: unexpected response!");
    }

    return [$resp->devices];
}

=head3 get_device_properties ( $device_id )

Get the properties for the device with the given ID.  Returns an
L<Ekahau::Response|Ekahau::Response> object.

=cut

sub get_device_properties
{
    my $self = shift;

    my $tag = $self->request_device_properties(@_)
	or return undef;
    my $resp = $self->gettaggedresponse($tag)
	or return undef;

    if ($resp->error)
    {
	return $self->reterr("GET_DEVICE_PROPERTIES failed: ".$resp->error_description);
    }
    elsif ($resp->type ne 'DeviceProperties')
    {
	return $self->reterr("GET_DEVICE_PROPERTIES failed: unexpected response of type ".$resp->type."!");
    }
    
    $resp;
}

=head3 get_location_context ( $area_id )

Get the properties of the area with the given ID.  Returns an
L<Ekahau::Response|Ekahau::Response> object.

=cut

sub get_location_context
{
    my $self = shift;

    my $tag = $self->request_location_context(@_)
	or return undef;
    my $resp = $self->gettaggedresponse($tag)
	or return undef;

    if ($resp->error)
    {
	$self->{err} = "GET_CONTEXT failed: ".$resp->error_description;
	return undef;
    }
    elsif ($resp->type ne 'LocationContext')
    {
	$self->{err} = "GET_CONTEXT failed: unexpected response!";
	return undef;
    }
    
    $resp;
}

=head3 get_map_image ( $area_id )

Get a map of the area with the given ID.  Returns an
L<Ekahau::Response::MapImage|Ekahau::Response::MapImage> object.

=cut

sub get_map_image
{
    my $self = shift;

    my $tag = $self->request_map_image(@_)
	or return undef;
    my $resp = $self->gettaggedresponse($tag)
	or return undef;

    if ($resp->error)
    {
	return $self->reterr("GET_MAP failed: ".$resp->error_description);
    }
    elsif ($resp->type ne 'MapImage')
    {
	return $self->reterr("GET_MAP failed: unexpected response!");
    }
    
    $resp;
}

=head3 get_all_areas ( )

Returns a list of all logical areas, as an
L<Ekahau::Response::AreaList|Ekahau::Response::AreaList> object.

=cut

sub get_all_areas
{
    my $self = shift;

    my $tag = $self->request_all_areas(@_)
	or return undef;
    my $resp = $self->gettaggedresponse($tag)
	or return undef;

    if ($resp->error)
    {
	return $self->reterr("GET_LOGICAL_AREAS failed: ".$resp->error_description);
    }
    elsif ($resp->type ne 'AreaList')
    {
	return $self->reterr("GET_LOGICAL_AREAS failed: unexpected response!");
    }
    
    $resp;
}


=head3 start_location_track ( [ $properties ], $device)

Start a continuous query tracking the location of the given device.
An optional hash reference containing properties for the query can be
given; see L<Ekahau::Base::start_location_track|Ekahau::Base/start_location_track> for details.

You can get results with L<next_location|/next_location> or L<next_track|/next_track>.

=cut

sub start_location_track
{
    my $self = shift;
    my %p = ref $_[0] ? %{ (shift) } : ();
    $p{Tag} = 'LOC';
    $self->SUPER::start_location_track(\%p,@_);
}

=head3 stop_location_track ($device)

Stop a continuous query tracking the location of the given device.

=cut

sub stop_location_track
{
    my $self = shift;
    
    my $tag = $self->request_stop_location_track(@_)
	or return undef;
    my $resp = $self->gettaggedresponse($tag)
	or return undef;

    if ($resp->error)
    {
	return $self->reterr("STOP_LOCATION_TRACK failed: ".$resp->error_description);
    }
    elsif ($resp->type ne 'StopLocationTrackOK')
    {
	return $self->reterr("STOP_LOCATION_TRACK failed: unexpected response '".$resp->type."!");
    }

    $resp;
}


=head3 next_location ( )

Return the next location for any of the continuous queries started by
calls to L<start_location_track|/start_location_track>.  The returned value will be an
L<Ekahau::Response|Ekahau::Response> object, or C<undef> on error.

=cut

sub next_location
{
    my $self = shift;

    my $r = $self->gettaggedresponse('LOC')
	or return undef;
   
    if ($r->{cmd} ne 'LOCATION_ESTIMATE')
    {
	return $self->reterr("LOCATION_ESTIMATE failed: $r->{cmd} @{$r->{args}}");
    }
    return $r;
}

=head3 start_area_track ( [ $properties ], $device_id )

Start a continuous query tracking the area where the given device is
located.  An optional hash reference containing properties for the
query can be given; see L<Ekahau::Base::start_area_track|Ekahau::Base/start_area_track> for details.

You can get results with L<next_area|/next_area> or L<next_track|/next_track>.

=cut

sub start_area_track
{
    my $self = shift;
    my %p = ref $_[0] ? %{ (shift) } : ();
    $p{Tag} = 'AREA';

    $self->SUPER::start_area_track(\%p,@_);
}

=head3 stop_area_track ($device)

Stop a continuous query tracking the area of the given device.

=cut

sub stop_area_track
{
    my $self = shift;
    
    my $tag = $self->request_stop_area_track(@_)
	or return undef;
    my $resp = $self->gettaggedresponse($tag)
	or return undef;

    if ($resp->error)
    {
	return $self->reterr("STOP_AREA_TRACK failed: ".$resp->error_description);
    }
    elsif ($resp->type ne 'StopAreaTrackOK')
    {
	return $self->reterr("STOP_AREA_TRACK failed: unexpected response '".$resp->type."'!");
    }

    $resp;
}


=head3 next_area ( )

Return the next area for any of the continuous queries started by
calls to L<start_area_track|/start_area_track>.  The returned value will be an
L<Ekahau::Response|Ekahau::Response> object, or C<undef> on error.

=cut

sub next_area
{
    my $self = shift;
    my $r = $self->gettaggedresponse('AREA');
   
    if ($r->{cmd} ne 'AREA_ESTIMATE')
    {
	return $self->reterr("AREA_ESTIMATE failed: $r->{cmd} @{$r->{args}}");
    }
    return $r;
}

=head3 start_track ( [ $properties ], $device_id )

Start tracking both the location and the area of the given device, by
calling the L<start_location_track|/start_location_track> and L<start_area_track|/start_area_track> methods.

An optional hash reference containing properties for the query can be
given.  These properties will be passed on to both queries; if you
need different properties for the two queries call the methods
directly.

Results can be obtained by calling the L<next_track|/next_track> method.

=cut

sub start_track
{
    my $self = shift;

    # Use temp variables so we can return the correct result,
    # but still make sure we start both.
    my $e1 = $self->start_location_track(@_);
    my $e2 = $self->start_area_track(@_);

    return $e1 and $e2;
}

=head3 stop_track ( $device_id )

Stop tracking both the location and the area of the given device, by
calling the L<stop_location_track|/stop_location_track> and L<stop_area_track|/stop_area_track> methods.

=cut

sub stop_track
{
    my $self = shift;

    # Use temp variables so we can return the correct result,
    # but still make sure we start both.
    my $e1 = $self->stop_location_track(@_);
    my $e2 = $self->stop_area_track(@_);

    return $e1 and $e2;
}


=head3 next_track ( )

Return the next location or area for any of the continuous queries
started by calls to L<start_track|/start_track>, L<start_location_track|/start_location_track>, or
L<start_area_track|/start_area_track>.  The returned value will be an
L<Ekahau::Response|Ekahau::Response> object, or C<undef> on error.

=cut

sub next_track
{
    my $self = shift;
    my(%p)=@_;

    return $self->gettaggedresponse('LOC','AREA');
}


1;

=head1 AUTHOR

Scott Gifford E<lt>gifford@umich.eduE<gt>, E<lt>sgifford@suspectclass.comE<gt>

Copyright (C) 2005 The Regents of the University of Michigan.

See the file LICENSE included with the distribution for license
information.


=head1 SEE ALSO

L<Ekahau::Base|Ekahau::Base>, L<Ekahau::Events|Ekahau::Events>.

=cut
