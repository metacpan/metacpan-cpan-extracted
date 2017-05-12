package Ekahau::Server::Test;
use base 'Ekahau::Server'; our $VERSION = $Ekahau::Server::VERSION;
use base 'Exporter';

# Written by Scott Gifford <gifford@umich.edu>
# Copyright (C) 2004 The Regents of the University of Michigan.
# See the file LICENSE included with the distribution for license
# information.

use warnings;
use strict;
use bytes;

=head1 NAME

Ekahau::Server::Test - Creates a test Ekahau server

=head1 SYNOPSIS

This class is used to create a "mock" Ekahau server for testing the
Ekahau client.

Because this class is used only for testing, it is not documented.

=cut

use Ekahau::Response::Error qw(:codes);
use Ekahau::License;


our @EXPORT_OK = qw(static_area static_location);

use constant DEFAULT_PASSWORD => 'Llama';
use constant DEFAULT_TICK => 2;

our @devices = (
		{ 
		    props => {
			'ECLIENT.WLAN_TECHNOLOGY' => 0,
			'ECLIENT.WLAN_MODEL' => 'Agere',
			'ECLIENT.COMMON_INTERNALNAME' => 'Wlan_Agere.dll',
			'NETWORK.MAC' => '00:10:C6:6A:12:3E',
			'GROUP' => 'ECLIENT',
			'NETWORK.DNS_NAME' => '141.212.55.129',
			'ECLIENT.COMMON_OS_VER' => '4.21.1088',
			'ECLIENT.COMMON_CLIENTID' => '000ea544c3f5ac51cc7e140b5d8',
			'NETWORK.IP-ADDRESS' => '141.212.55.129',
			'ECLIENT.COMMON_CLIENT_VER' => '3.2.198',
		    },
		    location_track => static_location({
			accurateX => 100,
			accurateY => 100,
			accurateContextId => '12345',
			accurateExpectedError => 1,
			latestX => 100,
			latestY => 100,
			latestContextId => 'ctx1',
			latestExpectedError => 1,
			speed => 10,
			heading => 180,
		    }),
		    area_track => static_area([
					       {
						   name => 'area51',
						   probability => '100.00',
						   contextId => '12345',
						   polygon => '100;75;150&100;75;150',
						   property1 => 'value1',
					       }]),
		},
		);
						   
		       

our %contexts = (
    12345 => {
	name => 12345,
	address => "building/floor1",
	mapScale => '10.00',
	property1 => 'value1',
    },
);

our %maps = (
    12345 => 'Pretend this is a PNG map file',
    23456 => 'All work and no play makes Jack a dull boy',
);
		     

sub new
{
    my $class = shift;
    my(%p)=@_;

    my $self = $class->SUPER::new(@_);
    $self->errhandler_deconstructed;
    $self->{_devices}=$p{Devices} || \@devices;
    $self->{_contexts}=$p{Contexts} || \%contexts;
    $self->{_maps}=$p{Maps} || \%maps;
    $self->{_password} = $p{Password} || DEFAULT_PASSWORD;
    $self->{_tick} = $p{Tick} || DEFAULT_TICK;
    if ($p{LicenseFile})
    {
	$self->{_license} = Ekahau::License->new(LicenseFile => $p{LicenseFile})
	    or return $self->reterr("Error processing LicenseFile '$p{LicenseFile}': ".Ekahau::License->lasterr);
    }
    $self->errhandler_constructed;
}

sub run
{
    my $self = shift;

    $self->{auth_state} = 0;
    $self->{_rand_str} = 'blahblahblah';
    $self->command(['HELLO',1,$self->{_rand_str}]);

    my $lasttick = time;
    while(1)
    {
	my $started_waiting = time;
	$self->{_timeout} = 1;
	warn "Waiting for response\n"
	    if ($ENV{VERBOSE});
	my $resp = $self->nextresponse();
	my $now = time;
	if (($now - $lasttick) >= $self->{_tick})
	{
	    $self->handle_tick;
	    $lasttick = $now;
	}
	if (!$resp)
	{
	    if ($self->{auth_state} < 1)
	    {
		if ((time - $started_waiting) < $self->{_timeout})
		{
		    $self->auth_failure(EKAHAU_ERR_AUTH_TIMEOUT);
		    $self->abort;
		    exit(0);
		}
	    }
	    next;
	}


	if (uc $resp->{cmd} eq 'CLOSE')
	{
	    $self->handle_close($resp);
	    return;
	}
	elsif (uc $resp->{cmd} eq 'HELLO')
	{
	    $self->handle_hello($resp);
	}
	elsif (uc $resp->{cmd} eq 'TALK')
	{
	    $self->handle_talk($resp);
	}
	elsif ($self->{auth_state} < 1)
	{
	    warn "Not authorized for this command\n"
		if ($ENV{VERBOSE});
	    # This is a fatal error.
	    return $self->auth_failure(EKAHAU_ERR_MALFORMED_REQUEST);
	}
	elsif (uc $resp->{cmd} eq 'GET_DEVICE_LIST')
	{
	    $self->handle_devlist($resp);
	}
	elsif (uc $resp->{cmd} eq 'GET_DEVICE_PROPERTIES')
	{
	    $self->handle_devprop($resp);
	}
	elsif (uc $resp->{cmd} eq 'GET_LOGICAL_AREAS')
	{
	    $self->handle_getla($resp);
	}
	elsif (uc $resp->{cmd} eq 'GET_CONTEXT')
	{
	    $self->handle_getctx($resp);
	}
	elsif (uc $resp->{cmd} eq 'GET_MAP')
	{
	    $self->handle_getmap($resp);
	}
	elsif (uc $resp->{cmd} eq 'START_LOCATION_TRACK')
	{
	    $self->handle_loctrack($resp);
	}
	elsif (uc $resp->{cmd} eq 'START_AREA_TRACK')
	{
	    $self->handle_areatrack($resp);
	}
	elsif (uc $resp->{cmd} eq 'STOP_LOCATION_TRACK')
	{
	    $self->handle_stoploctrack($resp);
	}
	elsif (uc $resp->{cmd} eq 'STOP_AREA_TRACK')
	{
	    $self->handle_stopareatrack($resp);
	}
	else
	{
	    warn "Didn't recognize command '$resp->{cmd}'\n";
	}
    }
}

sub handle_close
{
    my $self = shift;
    my($resp)=@_;

    $self->abort();
}

sub handle_hello
{
    my $self = shift;
    my($resp)=@_;

    if ($resp->{args}[0] != 1)
    {
	# Should do better errors.
	die "Bad protocol version\n";
    }
    $self->{hello} = $resp;
}

sub handle_talk
{
    my $self = shift;
    my($resp)=@_;
    if (!$self->{hello})
    {
	return $self->auth_failure(EKAHAU_ERR_MALFORMED_REQUEST);
    }

    if ($resp->{args}[0] ne 'yax' or
	$resp->{args}[1] != 1 or
	$resp->{args}[2] ne 'yax1' or
	$resp->{args}[3] ne 'MD5') 
    { 
	return $self->auth_failure(EKAHAU_ERR_UNSUPPORTED_PROTOCOL);
    }
    
    if ($resp->{args}[4] eq '') 
    {
	# Anonymous Login
	if (!$self->{hello}{params}{password} or $self->{hello}{params}{password} ne $self->{_password}) 
	{
	    return $self->auth_failure(EKAHAU_ERR_AUTHENTICATION_FAILED);
	}
	$self->command(['TALK','yax',1,'yax1','MD5','blahblahblah'])
	    or die "Couldn't send TALK response\n";
	$self->{auth_state} = 1;
    }
    else
    {
	# License Login
	if (!$self->{_license})
	{
	    return $self->auth_failure(EKAHAU_ERR_AUTHENTICATION_FAILED);
	}

	my $digest = $self->{_license}->talk_str(HelloStr => $self->{_rand_str},
						 Password => $self->{_password});
	if (!$digest or $digest ne $resp->{args}[4])
	{
	    return $self->auth_failure(EKAHAU_ERR_AUTHENTICATION_FAILED);
	}
	
	$digest = $self->{_license}->talk_str(HelloStr => $self->{hello}{args}[1],
					      Password => $self->{_password});

	$self->command(['TALK','yax',1,'yax1','MD5',$digest])
	    or die "Couldn't send TALK response\n";
	$self->{auth_state} = 2;
    }
    
}

sub auth_failure
{
    my $self = shift;
    my($reason) = @_;
    $self->command(['FAILURE',$reason]);
    undef;
}

sub handle_devlist
{
    my $self = shift;
    my($resp)=@_;
    $self->reply($resp,'DEVICE_LIST',{ map { ($_ => [{}]) } 1..@{$self->{_devices}}});
}

sub handle_devprop
{
    my $self = shift;
    my($resp)=@_;
    my $whichdev = $resp->{args}[0];
    
    if (defined($whichdev) and $whichdev =~ /^\d+$/ and (my $dev = $self->{_devices}[$whichdev-1]))
    {
	$self->reply($resp,['DEVICE_PROPERTIES',$whichdev],$dev->{props});
    }
    else
    {
	$self->reply($resp,['GET_DEVICE_PROPERTIES_FAILED'],
		    {errorCode  => -601,
		     errorLevel => 3});

    }
}

sub handle_getla
{
    my $self = shift;
    my($resp)=@_;

    $self->reply($resp,'AREALIST',{ AREA => [ values %{$self->{_contexts}} ] });
}

sub handle_getctx
{
    my $self = shift;
    my($resp)=@_;
    my $whichctx = $resp->{args}[0];
    if (defined($whichctx) and (my $ctx = $self->{_contexts}{$whichctx}))
    {
	$self->reply($resp,['CONTEXT',$whichctx],$ctx);
    }
    else
    {
	$self->reply($resp,['CONTEXT_NOT_FOUND',$whichctx],{});
    }
}

sub handle_getmap
{
    my $self = shift;
    my($resp)=@_;

    my $whichmap = $resp->{args}[0];
    if ($whichmap and $self->{_maps}{$whichmap})
    {
	$self->reply($resp,['MAP',$whichmap],{ type => 'png', data => \$self->{_maps}{$whichmap} });
    }
    else
    {
	$self->reply($resp,['MAP_NOT_FOUND',$whichmap],{});
    }
}

sub handle_loctrack
{
    my $self = shift;
    my($req)=@_;
    my $dev;

    eval {
	$dev = $req->{args}[0]
	    or die "no dev";
	$dev =~ /^\d+$/
	    or die "bad dev";
	my $loctrack = $self->{_devices}[$dev-1]{location_track}
	    or die "no locator";
	
	push(@{$self->{loctrack}},{req => $req, dev => $dev, track => $loctrack});
	warn "Starting location tracking of '$dev'\n"
	    if ($ENV{VERBOSE});
    };
    if ($@)
    {
	$self->reply($req,['START_LOCATION_TRACK_FAILED',defined($dev)?$dev:'?'],
		    {errorCode  => -600,
		     errorLevel => 2});
    }
    
}

sub handle_stoploctrack
{
    my $self = shift;
    my($req)=@_;
    my $dev;

    eval {
	$dev = $req->{args}[0]
	    or die "no dev";
	$dev =~ /^\d+$/
	    or die "bad dev";
	my $deleted;
	
	foreach my $i (0..$#{$self->{loctrack}})
	{
	    if ($self->{loctrack}[$i]{dev} == $dev)
	    {
		# Remove that element
		$deleted = splice(@{$self->{loctrack}},$i,1);
		warn "Stopped location tracking of '$dev'\n"
		    if ($ENV{VERBOSE});
		last;
	    }
	}
	$deleted
	    or die "no such dev";
    };
    if ($@)
    {
	$self->reply($req,'STOP_LOCATION_TRACK_FAILED',
		    {errorCode  => -600,
		     errorLevel => 2});
    }
    else
    {
	$self->reply($req,['STOP_LOCATION_TRACK_OK',defined($dev)?$dev:'?'],{});
    }
}


sub handle_areatrack
{
    my $self = shift;
    my($req)=@_;
    my $dev;

    eval {
	$dev = $req->{args}[0]
	    or die "no dev";
	$dev =~ /^\d+$/
	    or die "bad dev";
	my $track = $self->{_devices}[$dev-1]{area_track}
	    or die "no area tracker";
	push(@{$self->{areatrack}},{req => $req, dev => $dev, track => $track});
	warn "Starting area tracking of '$dev'\n"
	    if ($ENV{VERBOSE});
    };
    if ($@)
    {
	$self->reply($req,['START_AREA_TRACK_FAILED',defined($dev)?$dev:'?'],
		    {errorCode  => -600,
		     errorLevel => 2});
    }
    
}

sub handle_stopareatrack
{
    my $self = shift;
    my($req)=@_;
    my $dev;

    eval {
	$dev = $req->{args}[0]
	    or die "no dev";
	$dev =~ /^\d+$/
	    or die "bad dev";
	my $deleted;

	foreach my $i (0..$#{$self->{areatrack}})
	{
	    if ($self->{areatrack}[$i]{dev} == $dev)
	    {
		# Remove that element
		$deleted = splice(@{$self->{areatrack}},$i,1);
		warn "Stopped area tracking of '$dev'\n"
		    if ($ENV{VERBOSE});
		last;
	    }
	}
	$deleted
	    or die "no such dev";	
    };
    if ($@)
    {
	$self->reply($req,'STOP_AREA_TRACK_FAILED',
		    {errorCode  => -600,
		     errorLevel => 2});
    }
    else
    {
	$self->reply($req,['STOP_AREA_TRACK_OK',defined($dev)?$dev:'?'],{});
    }
}

sub handle_tick
{
    my $self = shift;

    foreach my $track (@{$self->{loctrack}})
    {
	$track->{track}->($self,$track->{dev},$track->{req});
    }
    foreach my $track (@{$self->{areatrack}})
    {
	$track->{track}->($self,$track->{dev},$track->{req});
    }
}

sub static_location
{
    my($loc)=@_;

    sub {
	my($self,$dev,$req)=@_;
        my $now = time;
	$self->reply($req,['LOCATION_ESTIMATE',$dev],
                     {%$loc,
                      accurateTime => $now, 
                      latestTime => $now,
		     });
    };
}

sub static_area
{
    my($area) = @_;
    sub {
	my($self,$dev,$req)=@_;
        my $numresp = $req->{params}{'EPE.NUMBER_OF_AREAS'} || 1;
	if ($numresp > @$area)
	{
	    my $ta = { %{$area->[$#{$area}]} };
	    $ta->{probability} = 0;
	    foreach my $i (scalar(@$area)..$numresp)
	    {
		push(@$area,$ta);
	    }
	}

	$self->reply($req,['AREA_ESTIMATE',$dev],
                     {
			 AREA => [@{$area}[0..$numresp-1] ],
		     });
    };
}

package Ekahau::Server::Test::Listener;
use base 'Ekahau::Server::Listener';

sub accept
{
    my $self = shift;
    my $obj = $self->SUPER::accept(@_,'Ekahau::Server::Test')
	or return undef;
    $obj->{_password}=$self->{_password}||Ekahau::Server::Test::DEFAULT_PASSWORD;
    $obj;
}

package Ekahau::Server::Test::Background;
use base 'Ekahau::Server::Test';

use Symbol;
use Socket;

sub start
{
    my $class = shift;

    my $server_side = gensym;
    my $client_side = gensym;

    socketpair($server_side, $client_side, AF_UNIX, SOCK_STREAM, PF_UNSPEC)
	or return undef;

    my $server = $class->new(Socket => $server_side,
			     Timeout => 10,
			     @_
			     )
	or return undef;

    if (!defined(my $fork = fork))
    {
	return undef;
	die "fork error: $!\n";
    }
    elsif (!$fork)
    {
	eval {
	    # Child
	    close($client_side);
	    delete $ENV{VERBOSE};
	    $ENV{VERBOSE}=$ENV{VERBOSE_SERVER}
	        if($ENV{VERBOSE_SERVER});
	    $server->run;
	    exit(0);
	};
	warn $@
	    if ($@);
	exit(-1);
    }
    
    close($server_side);
    return $client_side;
}

=head1 AUTHOR

Scott Gifford E<lt>gifford@umich.eduE<gt>, E<lt>sgifford@suspectclass.comE<gt>

Copyright (C) 2005 The Regents of the University of Michigan.

See the file LICENSE included with the distribution for license
information.

=cut

1;
