=head1 NAME

NoStopRobot - a robot doesn't stop, but remembers where it has been

=head1 SYNOPSIS

  use NoStopRobot
  my $ua=NoStopRobot::new(....)
  $ua->check_wait

=head1 DESCRIPTION

This module implements a user agent which remembers where it has been
and when so that the user can avoid too fast visits, but doesn't
actual implement that wait.

=head1 ROBOT LOGIC

The robot logic implemented here is somewhat more aggressive than that
implemented in WWW::RobotUA.  We never actually sleep in any of the
functions here.  This means that if a request is initiated it will
complete with robot checks and redirects all in one go.

Instead the user should actually implement waits outside the module
using the `host_wait()' method.  The key benefit of this is that it is
possible to check which request can be run first and reorder requests
to work as fast as wanted whilst maintaining good load spread between
different sites.

Secondly (and as a direct consequence), if there are multiple requests
to different sites which end up as redirects to the same site, the
wait time logic will not warn against this.  This is reasonable since
each request can be considered as a separate request to a separate
site.

=head1 IMPLEMENTATION NOTES

Becuase LWP::RobotUA collapses completely when called with URLs other
than HTTP this is implemented over the top of LWP::UserAgent (via
LWP::Auth_UA) rather than as a subclass of LWP::RobotUA.

=cut

package LWP::NoStopRobot;
$REVISION=q$Revision: 1.10 $ ; $VERSION = sprintf ( "%d.%02d", $REVISION =~ /(\d+).(\d+)/ );

use strict;
use warnings;
use Carp;
use LWP::Auth_UA;

use vars qw(@ISA $VERSION);

@ISA=qw(LWP::Auth_UA);
$VERSION = sprintf("%d.%02d", q$Revision: 1.10 $ =~ /(\d+)\.(\d+)/);

require WWW::RobotRules;
require HTTP::Request;
require HTTP::Response;

#=head2 _robot_get
#
#this is the function which actually downloads and checks robot rules.
#
#=cut

sub _robot_get {
  my $self=shift;
  my $url=shift;
  my $allowed;
  die " usage $self->_robot_get(<url>)" unless ref $self and defined $url;
  $url=new URI $url unless ref $url;
  LWP::Debug::trace('()');

  if ( $url->scheme eq "http" ) {
    #other schemes don't have defined robot rules!!! how do we handle??
    # Do we try to access a new server?
    $allowed = $self->{'rules'}->allowed($url);

    LWP::Debug::debug("HTTP URL: checking robots.txt. allowed is "
		      . $allowed);

    if ($allowed < 0) {
      #FIXME https / ftp etc??
      LWP::Debug::debug("Host not visited before, or robots.txt expired.");
      # fetch "robots.txt"
      my $robot_url = $url->clone;
      $robot_url->path("robots.txt");
      $robot_url->query(undef);
      LWP::Debug::debug("Requesting $robot_url");

      # make access to robot.txt legal since this will be a recursive call
      $self->{'rules'}->parse($robot_url, "");

      my $robot_req = new HTTP::Request 'GET', $robot_url;

      #FIXME: consider carefully the following:
      #
      # if we get a redirect then it means that no robots.txt is
      # present.  We only interpret the standard as meaning it must be
      # in the exact location.  The reason for this is that redirects
      # normally mean that the page is not present and send us to the
      # local index page.
      #
      # otherwise we have to accept possible multiple requests just to
      # get the robots.txt.  This either takes indefinite time if we
      # are careful or causes load if we are not.
      #
      #	my $robot_res = $self->request($robot_req);

      my $robot_res = $self->simple_request($robot_req);
      my $fresh_until = $robot_res->fresh_until;
      if ($robot_res->is_success) {
	LWP::Debug::debug("Parsing robot rules");
	$self->{'rules'}->parse($robot_url, $robot_res->content,
				$fresh_until);
      } else {
	LWP::Debug::debug("No robots.txt file found");
	$self->{'rules'}->parse($robot_url, "", $fresh_until);
      }
      # recalculate allowed...
      $allowed = $self->{'rules'}->allowed($url);
      LWP::Debug::debug("Got final allowed value: " . $allowed);

    }
  } else {
    LWP::Debug::debug("can't handle robot rules on " . $url->as_string);
    $allowed=1;
  }
  return $allowed;
}


=item $self->robot_check($url)

robot_check - given a URL carries out all actions needed to check
whether a request to that URL will be allowed by the robot rules but
doesn't actually send a request to the URL its self.  This if the
function host_wait is called then it will accurately reflect the time
before a request can be made to that URL.

=cut

sub robot_check
{
    my($self, $url) = @_;
    my $allowed;

    LWP::Debug::trace('()');

    # Do we try to access a new server?
    $allowed=$self->_robot_get($url);

    return $allowed;

}

=head1 simple_request

simple_request carries out one HTTP request.  It does robot checks to
ensure that the request is permitted, however, in contrast to RobotUA
it never sleeps.  It merely records which sites it visits.

N.B. there is one theoretical hole in this logic.  If multiple sites
are redirected to the same site, it is possible for us to check 

=cut


sub simple_request
{
    my($self, $request, $arg, $size) = @_;

    LWP::Debug::trace('()');
    my $url=$request->url;

    my $allowed;

    $allowed=$self->_robot_get($url);
    # Check rules
    unless ($allowed) {
      LWP::Debug::trace('simple_request() failed due to robot rules');
      return new HTTP::Response
	&HTTP::Status::RC_FORBIDDEN, 'Forbidden by robots.txt';
    }

    my $netloc=_url_to_netloc($url);

 CASE: {
	not defined $netloc and do  {
	  LWP::Debug::debug("_url_to_netloc failed to return host_port() for: ". $url);
	    last;
	};
	#this is not strictly correct english, but iproute2 uses it
	#and so I will :-)
	#fix this till it really checks for a hostname + port
#  	$netloc =~ m/[a-zA-Z0-9].*[a-zA-Z0-9]:[a-zA-Z0-9]+/ or do  {
#  	    die "host_port $netloc is a garbage: " . $url;
#  	    last;
#  	};
	# we would wait here, but we don't
	$self->{'rules'}->visit($netloc);
    }

    # Perform the request
    LWP::Debug::debug("Calling super->simple request");
    my $res = $self->SUPER::simple_request($request, $arg, $size);

  CASE: {
      $res->is_redirect && LWP::Debug::debug( "redirect to"
					      . $res->header('Location') );
      $res->is_success && LWP::Debug::debug( "successful request"
					   . $res->status_line() );
      $res->is_error && LWP::Debug::debug( "error request" 
					   . $res->status_line() );
    }

    $res;
}


sub _url_to_netloc
{
    my $url=shift;

    $url=new URI $url unless ref $url;

    my $scheme=$url->scheme();

    #basically schemes which support host and port / that is server methods
    #FIXME: hardwired lists are BAD.

    #wierd : mailto - could be supported in certain cases
    #excluded : data / file

    $scheme =~
	m/ftp|gopher|http|https|ldap|news|nntp|pop|rlogin|rsync|snews|telnet/
	    or do {
	      LWP::Debug::debug("_url_to_netloc can't deal with $scheme urls");
	      return
	    };

    my $netloc=$url->host_port();

    return $netloc;

}

=item $ua->host_wait($url)

This funciton is like host_wait; but there are two differences.
Firstly, it should be called with a url (string or object).  Secondly,
it should work for any url (actually URI), but will return undef for
urls which can't have a netloc derived from them.

=cut

sub host_wait_url
{
    my($self, $url) = @_;
    LWP::Debug::trace("($url)");
    die " usage $self->_robot_get(<url>)" unless ref $self and defined $url;
    my $netloc=_url_to_netloc($url);
    return undef unless defined $netloc;
    my $host_wait=$self->host_wait($netloc);
    return $host_wait;
}

=item $ua->host_wait($netloc)

Returns the number of seconds (from now) you must wait before you can
make a new request to this host.

=cut

sub host_wait
{
    my($self, $netloc) = @_;
    LWP::Debug::trace("($netloc)");
    return undef unless defined $netloc;
    $self->{'no_wait'} and $netloc=~ m/$self->{'no_wait'}/ && do {
      print STDERR "netloc matches no_wait regex.. zero wait\n";
      return 0;
    };
    my $last = $self->{'rules'}->last_visit($netloc);
    if ($last) {
	my $wait = int($self->{'delay'} * 60 - (time - $last));
	print STDERR "Last visit to netloc at $last: wait $wait secs.\n";
	$wait = 0 if $wait < 0;
	return $wait;
    }
    print STDERR "Never visited netloc don't wait any seconds.\n";
    return 0;
}

=item $ua->no_wait($regex)

Sets a regular expression for links for which the robot agent should
not wait.  Typically these would be local pages or servers in the same
organisation as the link checking is being carried out by.

=cut

sub no_wait {
  my $self=shift;
  $self->{'no_wait'}=shift;
  croak "gimme a regexp" unless $self->{'no_wait'};
  LWP::Debug::trace("No wait RE: " . $self->{'no_wait'} );
}

#  =item $ua->short_wait($regex)

#  Sets a regular expression for links for which the robot agent should
#  not wait.  Typically these would be local pages or servers in the same
#  organisation as the link checking is being carried out by.

#  =cut

#  =item $ua->short_delay($regex)

#  Sets the amount of time to wait for

#  =cut




#--------------------------------------------------------
#-functions straight from robot ua



#  # $Id: NoStopRobot.pm,v 1.10 2002/02/09 16:30:40 mikedlr Exp $

#  package LWP::RobotUA;

#  require LWP::UserAgent;
#  @ISA = qw(LWP::UserAgent);
#  $VERSION = sprintf("%d.%02d", q$Revision: 1.10 $ =~ /(\d+)\.(\d+)/);

#  require WWW::RobotRules;
#  require HTTP::Request;
#  require HTTP::Response;

#  use Carp ();
#  use LWP::Debug ();
#  use HTTP::Status ();
#  use HTTP::Date qw(time2str);
#  use strict;

#  =head1 NAME

#  LWP::RobotUA - A class for Web Robots

#  =head1 SYNOPSIS

#    require LWP::RobotUA;
#    $ua = new LWP::RobotUA 'my-robot/0.1', 'me@foo.com';
#    $ua->delay(10);  # be very nice, go slowly
#    ...
#    # just use it just like a normal LWP::UserAgent
#    $res = $ua->request($req);

#  =head1 DESCRIPTION

#  This class implements a user agent that is suitable for robot
#  applications.  Robots should be nice to the servers they visit.  They
#  should consult the F</robots.txt> file to ensure that they are welcomed
#  and they should not make requests too frequently.

#  But, before you consider writing a robot take a look at
#  <URL:http://info.webcrawler.com/mak/projects/robots/robots.html>.

#  When you use a I<LWP::RobotUA> as your user agent, then you do not
#  really have to think about these things yourself.  Just send requests
#  as you do when you are using a normal I<LWP::UserAgent> and this
#  special agent will make sure you are nice.

#  =head1 METHODS

#  The LWP::RobotUA is a sub-class of LWP::UserAgent and implements the
#  same methods. In addition the following methods are provided:

#  =over 4

#  =cut


#  #
#  # Additional attributes in addition to those found in LWP::UserAgent:
#  #
#  # $self->{'delay'}    Required delay between request to the same
#  #                     server in minutes.
#  #
#  # $self->{'rules'}     A WWW::RobotRules object
#  #


=item $ua = LWP::RobotUA->new($agent_name, $from, [$rules])

Your robot's name and the mail address of the human responsible for
the robot (i.e. you) are required by the constructor.

Optionally it allows you to specify the I<WWW::RobotRules> object to
use.

=cut

sub new
{
    my($class,$name,$from,$rules) = @_;

    Carp::croak('LWP::RobotUA name required') unless $name;
    Carp::croak('LWP::RobotUA from address required') unless $from;

    my $self = new LWP::Auth_UA;
    $self = bless $self, $class;

    $self->{'delay'} = 1;   # minutes
    $self->{'agent'} = $name;
    $self->{'from'}  = $from;
    $self->{'use_sleep'} = 1;

    if ($rules) {
	$rules->agent($name);
	$self->{'rules'} = $rules;
    } else {
	$self->{'rules'} = new WWW::RobotRules $name;
    }

    $self;
}


=item $ua->delay([$minutes])

Set the minimum delay between requests to the same server.  The
default is 1 minute.

=item $ua->use_sleep([$boolean])

Get/set a value indicating whether the UA should sleep() if requests
arrive too fast (before $ua->delay minutes has passed).  The default is
TRUE.  If this value is FALSE then an internal SERVICE_UNAVAILABLE
response will be generated.  It will have an Retry-After header that
indicates when it is OK to send another request to this server.

=cut

sub delay     { shift->_elem('delay',     @_); }
sub use_sleep { shift->_elem('use_sleep', @_); }

sub agent
{
    my $self = shift;
    my $old = $self->SUPER::agent(@_);
    if (@_) {
	# Changing our name means to start fresh
	$self->{'rules'}->agent($self->{'agent'}); 
    }
    $old;
}


=item $ua->rules([$rules])

Set/get which I<WWW::RobotRules> object to use. 

=cut

sub rules {
    my $self = shift;
    my $old = $self->_elem('rules', @_);
    $self->{'rules'}->agent($self->{'agent'}) if @_;
    $old;
}


=item $ua->no_visits($netloc)

Returns the number of documents fetched from this server host. Yes I
know, this method should probably have been named num_visits() or
something like that. :-(

=cut

sub no_visits
{
    my($self, $netloc) = @_;
    $self->{'rules'}->no_visits($netloc);
}

*host_count = \&no_visits;  # backwards compatibility with LWP-5.02


#  =item $ua->host_wait($netloc)

#  Returns the number of seconds (from now) you must wait before you can
#  make a new request to this host.

#  =cut

#  sub host_wait
#  {
#      my($self, $netloc) = @_;
#      return undef unless defined $netloc;
#      my $last = $self->{'rules'}->last_visit($netloc);
#      if ($last) {
#  	my $wait = int($self->{'delay'} * 60 - (time - $last));
#  	$wait = 0 if $wait < 0;
#  	return $wait;
#      }
#      return 0;
#  }



#  sub simple_request
#  {
#      my($self, $request, $arg, $size) = @_;

#      LWP::Debug::trace('()');

#      # Do we try to access a new server?
#      my $allowed = $self->{'rules'}->allowed($request->url);

#      if ($allowed < 0) {
#  	LWP::Debug::debug("Host is not visited before, or robots.txt expired.");
#  	# fetch "robots.txt"
#  	my $robot_url = $request->url->clone;
#  	$robot_url->path("robots.txt");
#  	$robot_url->query(undef);
#  	LWP::Debug::debug("Requesting $robot_url");

#  	# make access to robot.txt legal since this will be a recursive call
#  	$self->{'rules'}->parse($robot_url, ""); 

#  	my $robot_req = new HTTP::Request 'GET', $robot_url;
#  	my $robot_res = $self->request($robot_req);
#  	my $fresh_until = $robot_res->fresh_until;
#  	if ($robot_res->is_success) {
#  	    my $c = $robot_res->content;
#  	    if ($robot_res->content_type =~ m,^text/, && $c =~ /Disallow/) {
#  		LWP::Debug::debug("Parsing robot rules");
#  		$self->{'rules'}->parse($robot_url, $c, $fresh_until);
#  	    }
#  	    else {
#  		LWP::Debug::debug("Ignoring robots.txt");
#  		$self->{'rules'}->parse($robot_url, "", $fresh_until);
#  	    }

#  	} else {
#  	    LWP::Debug::debug("No robots.txt file found");
#  	    $self->{'rules'}->parse($robot_url, "", $fresh_until);
#  	}

#  	# recalculate allowed...
#  	$allowed = $self->{'rules'}->allowed($request->url);
#      }

#      # Check rules
#      unless ($allowed) {
#  	return new HTTP::Response
#  	  &HTTP::Status::RC_FORBIDDEN, 'Forbidden by robots.txt';
#      }

#      my $netloc = $request->url->host_port;
#      my $wait = $self->host_wait($netloc);

#      if ($wait) {
#  	LWP::Debug::debug("Must wait $wait seconds");
#  	if ($self->{'use_sleep'}) {
#  	    sleep($wait)
#  	} else {
#  	    my $res = new HTTP::Response
#  	      &HTTP::Status::RC_SERVICE_UNAVAILABLE, 'Please, slow down';
#  	    $res->header('Retry-After', time2str(time + $wait));
#  	    return $res;
#  	}
#      }

#      # Perform the request
#      my $res = $self->SUPER::simple_request($request, $arg, $size);

#      $self->{'rules'}->visit($netloc);

#      $res;
#  }


=item $ua->as_string

Returns a string that describes the state of the UA.
Mainly useful for debugging.

=cut

sub as_string
{
    my $self = shift;
    my @s;
    push(@s, "Robot: $self->{'agent'} operated by $self->{'from'}  [$self]");
    push(@s, "    Minimum delay: " . int($self->{'delay'}*60) . "s");
    push(@s, "    Will sleep if too early") if $self->{'use_sleep'};
    push(@s, "    Rules = $self->{'rules'}");
    join("\n", @s, '');
}

1;

#  =back

#  =head1 SEE ALSO

#  L<LWP::UserAgent>, L<WWW::RobotRules>

#  =head1 COPYRIGHT

#  Copyright 1996-2000 Gisle Aas.

#  This library is free software; you can redistribute it and/or
#  modify it under the same terms as Perl itself.

=cut
