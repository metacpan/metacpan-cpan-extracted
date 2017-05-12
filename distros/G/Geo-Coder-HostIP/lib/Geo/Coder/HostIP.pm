package Geo::Coder::HostIP;

use 5.006;
use strict;
use warnings;
use Carp;

use LWP::UserAgent;

our $VERSION = '0.07';

sub new {
    my $c = shift;
    my $pkg = ref $c || $c;
    my $obj = {};
    bless $obj, $pkg;
    my $server = shift || 'api.hostip.info';
    $obj->{_server} = $server;
    $obj->{_ua} = LWP::UserAgent->new;
    $obj->{_agent} = 'Geo::Coder::HostIP/0.1';
    return $obj;
}

sub Agent {
    my $obj = shift;
    my $uaname = shift or return undef;
    $obj->{_agent} = $uaname;
}

sub _request {
    my $obj = shift;
    $obj->{_ua}->agent($obj->{_agent});
    return undef unless $obj->{_server} and $obj->{ip};

    my $res = $obj->{_ua}->get("http://$obj->{_server}/get_html.php?".
                               "ip=$obj->{ip}&position=true");

    if ($res->is_success) {
         return $obj->_parse($res->content);
    }
    else {
         croak $res->status_line;
    }
}

sub FetchIP {
    my $obj = shift;
    my $ip = shift or return undef;
    $obj->{ip} = $ip;
    return $obj->_request;
}

sub FetchName {
    my $obj = shift;
    my $name = shift or return undef;
    my $ip = join ".", unpack('C4', (gethostbyname $obj->{domain})[4]);
    return $obj->FetchIP($obj->{domain});
}

sub FetchRemoteAddr {
    my $obj = shift;
    if (exists $ENV{REMOTE_ADDR} && defined $ENV{REMOTE_ADDR}) {
        return $obj->FetchIP($ENV{REMOTE_ADDR});
    }
    else {
        return undef;
    }
}

sub Lat {
    my $obj = shift;
    return exists $obj->{Latitude} ? $obj->{Latitude} : undef;
}

sub Long {
    my $obj = shift;
    return exists $obj->{Longitude} ? $obj->{Longitude} : undef;
}

sub Latitude {
    my $obj = shift;
    return $obj->Lat;
}

sub Longitude {
    my $obj = shift;
    return $obj->Long;
}

sub City {
    my $obj = shift;
    return exists $obj->{City} ? $obj->{City} : undef;
}

sub Country {
    my $obj = shift;
    return exists $obj->{Country} ? $obj->{Country} : undef;
}

sub CountryCode {
    my $obj = shift;
    return exists $obj->{Country_Code} ? $obj->{Country_Code} : undef;
}

sub State {
    my $obj = shift;
    return exists $obj->{State} ? $obj->{State} : undef;
}

sub Coords {
    my $obj = shift;
    if (exists $obj->{Latitude} and exists $obj->{Longitude}) {
        return wantarray ? ($obj->{Latitude}, $obj->{Longitude}) : 
	                   "Lat: $obj->{Latitude}, Long: $obj->{Longitude}";
    }
    else {
        return undef;
    }
}

sub GoogleMap {
    my $obj = shift;
    my $params = pop;

    if (@_) {
        my $ip = shift;
	$obj->FetchIP($ip);
    }

    unless (    exists $obj->{Latitude} and defined $obj->{Latitude}
            and exists $obj->{Longitude} and defined $obj->{Longitude}
	    and ref $params eq 'HASH' and $params->{apikey}) {
        return undef;
    }

    my $apikey = $params->{apikey};
    my $id = $params->{id} || 'googlemap';
    my $fname = $params->{func_name} || 'load';
    my $width = $params->{width} || 500;
    my $height = $params->{height} || 300;
    my $zoom = $params->{zoom} || 13;

    my $controls = '';
    if ($params->{control}) {
       if ($params->{control} eq 'large') {
           $controls = 'map.addControl(new GLargeMapControl());';
       }
       elsif ($params->{control} eq 'small') {
           $controls = 'map.addControl(new GSmallMapControl());';
       }
       else {
           $controls = 'map.addControl(new GSmallScaleControl());';
       }
    }

    my $scalec = '';
    if ($params->{scalecontrol}) {
        $scalec = 'map.addControl(new GScaleControl());';
    }

    my $typec = '';
    if ($params->{typecontrol}) {
        $typec = 'map.addControl(new GMapTypeControl());';
    }
    
    my $overc = '';
    if ($params->{overviewcontrol}) {
        $overc = 'map.addControl(new GOverviewMapControl());';
    }

    my $lat = $obj->{Latitude} + 0;
    my $long = $obj->{Longitude} + 0;

    return <<"EOF";
<html>
  <head>
    <script src="http://maps.google.com/maps?file=api&amp;v=2&amp;key=$apikey"
      type="text/javascript"></script>
    <script type="text/javascript">

    //<![CDATA[

    function $fname() {
        if (GBrowserIsCompatible()) {
            var map = new GMap2(document.getElementById('$id'));
            $controls
            $scalec
            $typec
            $overc
            map.setCenter(new GLatLng($lat, $long), $zoom);
        }
    }

    //]]>
    </script>
  <!-- {{ADDITIONAL HEAD}} -->
  </head>
  <body onload="$fname()" onunload="GUnload()">
    <div id="$id" style="width: ${width}px; height: ${height}px"></div>
  <!-- {{ADDITIONAL BODY}} -->
  </body>
</html>
EOF
}

sub _parse {
    my $obj = shift;
    my $res = shift or return undef;

    for my $key (qw(Country City Longitude Latitude)) {
        delete $obj->{$key};
    }

    my $content = $res;
    my @rows = split /[\r\n]+/, $content;
    chomp @rows;

    for my $row (@rows) {
        my ($k, $v) = split /\s*:\s*/, $row, 2;
	if ($k eq 'Country') {
	    $v =~ /(.*)\s*\(([^\)]+)\)$/;
	    $obj->{Country} = $1;
	    $obj->{Country_Code} = $2;
	}
	elsif ($k eq 'City') {
	    if ($v =~ /(.*),\s+([A-Z]+)/) {
	        $obj->{City} = $1;
		$obj->{State} = $2;
            }
	}
	elsif ($k eq 'Latitude' or $k eq 'Longitude') {
	    $obj->{$k} = $v + 0;
	}
	else {
	    $obj->{$k} ||= $v;
	}
    }
    if (defined $obj->{Latitude} and defined $obj->{Longitude}) {
        return wantarray ? ($obj->{Latitude}, $obj->{Longitude}) :
	                   "Lat: $obj->{Latitude}, Long: $obj->{Longitude}";
    }
    else {
        return wantarray ? () : 'Coordinates Not Found';
    }
}

1;

__END__

=head1 NAME

Geo::Coder::HostIP - get geocoding info for an IP address

=head1 SYNOPSIS

  use strict;
  use CGI;
  use Geo::Coder::HostIP;
  
  my $cgi = new CGI;
  my $geo = new Geo::Coder::HostIP;
  
  print $cgi->header;
  
  my ($lat, $long);
  if ($cgi->param('ip')) {
      ($lat, $long) = $geo->FetchIP($cgi->param('ip'));
  }
  else {
      ($lat, $long) = $geo->FetchRemoteAddr;
  }
  
  my $zoom = $cgi->param('zoom') || 13;
  
  if (defined $lat && defined $long) {
      print $geo->GoogleMap({apikey => 'reallylongstringthatgooglegivesyou',
                             control => 'small',
                             scalecontrol => 1,
                             typecontrol => 1,
                             overviewcontrol => 1});
  }
  else {
      print "I can't find you.";
  }

=head1 DESCRIPTION

Geo::Coder::HostIP is an Object-Oriented module intended to make use of the
HostIP API documented at www.hostip.info.

It's useful for web stuff, but it's useful for other stuff too, like figuring
out if, for instance, the majority of people hitting your spanish language
webpage are Spanish or Mexican, for instance, and thus deciding whether to
say 'auto' or 'carro'.

This module requires LWP.

=head1 Instantiation

You create a Geo::Coder::HostIP object, which I'm calling 'geo' because it's
a relatively simple thing to call it, but you can call it anything you want.
Except 'menlo' because I hate that word and I don't know why.

new() can be called void. If you want, you can give it one argument to override
the default server of 'api.hostip.info' with something else. However, that
something else had better have the same scripts in the same places with the
same arguments wanted, etc. Else it will break.

At the time of thos writing, it only works in about 40-50% of cases depending
on the IP's locale.

=head1 Public Methods

Several nice convenience methods are supplied, so you can make the module
do the thinking and you can get back to drinking... or whatever. Why is the
rum always gone?

=over 4

=item new($addr=null) (constructor)

As stated above, this creates a new Geo::Coder::HostIP object. That's it.
It doesn't do any getting of infos until you tell it to. This is to make it
so you have to deliberately choose to navigate this great series of tubes.

  my $geo = new Geo::Coder::HostIP;

=item Agent($)

Takes any string and makes that be the UserAgent string used by LWP.

  $book->Agent('MooseCrawler/1.7');

=item FetchIP($)

Takes any string that is an IP address and attempts to retrieve the data
from api.hostip.info for it. If successful, it returns either a list
containing the Latitude and Longitude thus found, or, if called in scalar
context, a string that says "Lat: ###, Long: ###" where the ##s denote the
values thereof.

Latitude and Longitude are returned in decimal format.

Don't try to use private network IP addresses. That's just a bit daft.

  my ($lat, $long) = $geo->FetchIP('64.151.93.244');

If it fails, the list context returns the empty list, and scalar
returns the string "Coordinates Not Found".

Remember that print() implies list mode, not scalar mode, before you just
print right off this!

Also, this populates the data itcan find into the object, up to Country,
Country Code, City, State (US only), Latitude and Longitude.

=item FetchName($) 
    
Works like FetchIP above, but expects a domain name. Returns the same stuff
and populates the properties just the same. Matter of fact, it just gets the
IP address and then passes that on to FetchIP and returns whatever it gets.

  my ($lat, $long) = $geo->FetchName('whatever3d.com');

=item FetchRemoteAddr()

Works like FetchIP above, but automatically uses the value stored in
$ENV{REMOTE_ADDR} if present and defined.

=item Lat(), Latitude()

After something is fetched using any of the above three methods, returns the
latitude numerically. Returns undef if the latitude is not set. Returns 0 if
latitude is set to something non-numeric.

=item Long(), Longitude()

See Lat() above and try and guess really hard.

=item City()

Returns the City property if set, or undef if not.
Doesn't let you set it though. Set the property for that, though that's...
Well, how should I know? You might have a reason.

=item Country()

Gee, guess what this does?

=item CountryCode()

Again... obvious as hell.

=item State()

La la la.

item Coords()

returns the same thing the preceding Fetch*() method would have returned,
but doesn't take an argument and doesn't do any fetching. Rather it uses
the current values in the hash.

item GoogleMap($ip=null, ${apikey, id='googlemap', func_name='load', width=500, height=300, zoom=13, control='small', scalecontrol=0, typecontrol=0, overviewcontrol=0})

Okay, this one's pretty cool... GoogleMap() gives you back HTML code for --
you guessed it. A Google map.

It takes an optional IP address, which it will fetch if provided. Note that if
you do not provide an IP address, do NOT supply 'undef' as an argument! Just
leave it out altogether, otherwise it will depopulate the object.

Next (or first and last and only if you leave out th IP address), it takes a
hashref of parmetres, which MUST contain a true string keyed by 'apikey' or it
will not bother and return undef. Of course, the idea here is that you give it
your google maps API key, so that the results actually work on your page.

This hashref may also contain several other parametres. Among them are height
and width, which will set the height and width of the map in pixels and default
to 300 and 500 respectively, id which will set the HTML element id of the map
itself and defaults to 'googlemap', and fname which will determine the name to
be used for the onLoad JavaScript function in case you want to change it from
the default of 'load'.

Also there's 'zoom' which sets the default zoom, which defaults to 13, about
normal city-level street view.

Next there's control, which can be set to 'large', 'small', or any other true
value. If 'large' the map will get the large google scale/pan control. If
'small' it will get the smaller version, and if set to some other true value
it will get the little scale-only control up in the left upper corner.

Then there are the other controls, which are booleans (defaulting to 0, i.e.
false). If present and true, 'scalecontrol' will add the little scale meter,
'typecontrol' will give the user the buttons that let them switch to aerial
photography view and hybrid type maps, and 'overviewcontrol' will give the
little inset map in the lower right corner that shows how the rest of the map
fits into its surroundings.

You can, of course, parse the HTML resulting and do things to it, or just run a
regex on it to make it different. It does include a BODY and /BODY tag, so you
may want to. The HTMl thus output has two HTML comments embedded in it, which
contain ' {{ADDITIONAL HEAD}} ' and ' {{ADDITIONAL BODY}} ' inside a proper
HTML comment tag, for your convenience in this regard.

=back

=head1 Private Methods

=over 4

=item _request()

Goes and grabs the data and calls _parse if successful.

=item _parse()

Parses out the results of _request

=back

=head1 Properties

=over 4

=item properties

The object is a hashref of properties once populated. These are set by the
_parse() method. You get to these with:

  $geo->{Property_name}

These are case sensitive, capitalised, and potentially contain:
  Country, Country_Code, City, State, Latitude, Longitude

There's also 'ip' which isn't capitalised, and it set whenever you call a
Fetch*() method.

There are also some private properties, which you shouldn't aughtta muck about
with without good reason, including: _server, _agent, and _ua. _server is
the address of the server (as may be set in new()), _agent is the UserAgent
string (as set in Agent()), and _ua is an LWP object.

=back

=head1 HOPES AND DREAMS

=over 4

=item

Make GoogleMap more robust

=item

Add YahooMap and, if they make an API, MapQuestMap

=item

Add GetWeather function. That'd be cool. And maybe some other fun toy methods, like MeasureDistance(ip, ip), and Traceroute(ip) the latter of which might actually do a traceroute on every IP along the way and work out how many miles the packets actually travelled. Altitude() is another thought, and possible to get from public info as long as Latitude and Longitude are populated.

=back

=head1 AUTHOR

As of 0.03 the module is now maintained by Neil Bowers E<lt>neilb@cpan.orgE<gt>.

Dodger - dodger@cpan.org

=head1 SEE ALSO

perl(1).

=head1 REPOSITORY

L<https://github.com/neilb/Geo-Coder-HostIP>

=head1 LICENSE

This is free software;
you can redistribute it and/or modify it under the same terms as Perl itself.

=cut


