=head1 NAME

ElephantAgent - the agent that never forgets

=head1 DESCRIPTION

This is the robot agent that never forgets.  One of the major
advantages of the original MOMspider link checker was that it didn't
need to keep checking robots.txt files every time it was started.
This agent does the same by using a disk cache of hosts and status.

Why bother:- just use a cacheing server..  (because we would know to
recall the robots.txt when needed..)

=head2 host format

a host keeps this state

last - time of last visit
count - number of visits
last_robot - time of last robot check
robot_stat - robot status
  (exclude, open, controled)
robots_txt - robot file


This has to be implemented as a complete rewrite of the RobotUA
because that assumes multi-level hashes (can't do with MLDBM) and
because it all directly accesses the contents of its own hash..

It is possible that people will be running several different user
agents in one program (why?) but then wish to share robot exclusion
info between them.

=head2 decision making

There are many decisions to make:-

should I cache this robots.txt?
   only if relatively short, or if we use this site often..
should I recheck a robots.txt
   yes if more than $max_hits to the site
   yes if more than $max_time since last check
   yes if more than $max_size from site
   $max_size = 1000 * $robots_txt_size
   $max_hits = 1000 
   $max_time = three_weeks
(we should generally use head for re-checking)   

package LWP::ElephantUA;
$REVISION=q$Revision: 1.3 $ ; $VERSION = sprintf ( "%d.%02d", $REVISION =~ /(\d+).(\d+)/ );


require LWP::UserAgent;
@ISA = qw(LWP::UserAgent);

require WWW::RobotRules;
require HTTP::Request;
require HTTP::Response;

use Carp ();
use LWP::Debug ();
use HTTP::Status ();
use HTTP::Date qw(time2str);

=head1 NAME

LWP::RobotUA - A class for Web Robots

=head1 SYNOPSIS

  require LWP::RobotUA;
  $ua = new LWP::RobotUA 'my-robot/0.1', 'me@foo.com';
  $ua->delay(10);  # be very nice, go slowly
  ...
  # just use it just like a normal LWP::UserAgent
  $res = $ua->request($req);

=head1 DESCRIPTION

This class implements a user agent that is suitable for robot
applications.  Robots should be nice to the servers they visit.  They
should consult the /robots.txt file to ensure that they are welcomed
and they should not send too frequent requests.

But, before you consider writing a robot take a look at
<URL:http://info.webcrawler.com/mak/projects/robots/robots.html>.

When you use a LWP::RobotUA as your user agent, then you do not really
have to think about these things yourself.  Just send requests as you
do when you are using a normal LWP::UserAgent and this special agent
will make sure you are nice.

=head1 SEE ALSO

L<LWP::UserAgent>

=head1 METHODS

The LWP::RobotUA is a sub-class of LWP::UserAgent and implements the
same methods.  The use_alarm() method also desides whether we will
wait if a request is tried too early (if true), or will return an error
response (if false).

In addition these methods are provided:

=cut


#
# Additional attributes in addition to those found in LWP::UserAgent:
#
# $self->{'delay'}    Required delay between request to the same
#                     server in minutes.
#
# $self->{'visited'}   An hash where the keys are server names and the
#                      value is a hash with these values:
#                          'last'   last fetch time
#                          'count'  number of documents fetched
#
# $self->{'rules'}     A WWW::RobotRules object
#

=head2 $ua = LWP::RobotUA->new($agent_name, $from)

A name and the mail address of the human running the the robot is
required by the constructor.  The name can be changed later though the
agent() method.  The mail address chan be changed with the from()
method.

=cut

sub new
{
    my $class = shift;
    my $name  = shift;
    my $from  = shift;

    Carp::croak('LWP::RobotUA name required') unless $name;
    Carp::croak('LWP::RobotUA from address required') unless $from;

    my $self = new LWP::UserAgent;
    $self = bless $self, $class;

    $self->{'delay'} = 1;   # minutes
    $self->{'agent'} = $name;
    $self->{'from'}  = $from;

    $self->{'rules'} = new WWW::RobotRules $name;
    $self->{'visited'} = { };

    $self;
}

=head2 $ua->delay([$minutes])

Set the minimum delay between requests to the same server.  The
default is 1 minute.

=cut

sub delay { shift->_elem('delay', @_); }

sub agent
{
    my $self = shift;
    my $old = $self->SUPER::agent(@_);
    if (@_) {
	# Changing our name means to start fresh
	$self->{'rules'} = new WWW::RobotRules $self->{'agent'};
	$self->{'visited'} = {};
    }
    $old;
}

=head2 $ua->host_count($hostname)

Returns the number of documents fetched from this server host.

=cut

sub host_count
{
    my($self, $host) = @_;
    return undef unless defined $host;
    if ($self->{'visited'}{$host}) {
	return $self->{'visited'}{$host}{'count'};
    }
    return undef;
}

=head2 $ua->host_wait($hostname)

Returns the number of seconds you must wait before you can make a new
request to this host.

=cut

sub host_wait
{
    my($self, $host) = @_;
    return undef unless defined $host;
    if ($self->{'visited'}{$host}) {
	my $wait = int($self->{'delay'} * 60 -
		       (time - $self->{'visited'}{$host}{'last'}));
	$wait = 0 if $wait < 0;
	return $wait;
    }
    return 0;
}

sub simple_request
{
    my($self, $request, $arg, $size) = @_;

    LWP::Debug::trace('()');

    my $host = $request->url->host;

    # Do we try to access a new server?
    unless ($self->{'visited'}{$host}) {
	LWP::Debug::debug("Host $host is not visited before.");
	$self->{'visited'}{$host}{'count'} = 0;  # avoids infinite recursion
	$self->{'visited'}{$host}{'last'}  = 0;
	# fetch "robots.txt"
	my $robot_url = $request->url->clone;
	$robot_url->path("robots.txt");
	$robot_url->params(undef);
	$robot_url->query(undef);
	LWP::Debug::debug("Requesting $robot_url");
	my $robot_req = new HTTP::Request 'GET', $robot_url;
	# This will be a recursive call
	my $robot_res = $self->request($robot_req);
	if ($robot_res->is_success) {
	    LWP::Debug::debug("Parsing robot rules");
	    $self->{'rules'}->parse($robot_url, $robot_res->content);
	} else {
	    LWP::Debug::debug("No robots.txt file for $host");
	}
    }

    # Check rules
    LWP::Debug::debug("Checking robot rules");
    unless ($self->{'rules'}->allowed($request->url)) {
	return new HTTP::Response
	  &HTTP::Status::RC_FORBIDDEN, 'Forbidden by robots.txt';
    }
    my $wait = $self->host_wait($host);

    if ($wait) {
	LWP::Debug::debug("Must wait $wait seconds");
	if ($self->{'use_alarm'}) {
	    sleep($wait)
	} else {
	    my $res = new HTTP::Response
	      &HTTP::Status::RC_SERVICE_UNAVAILABLE, 'Please, slow down';
	    $res->header('Retry-After', time2str(time + $wait));
	    return $res;
	}
    }

    # Perform the request
    my $res = $self->SUPER::simple_request($request, $arg, $size);

    $self->{'visited'}{$host}{'last'} = time;
    $self->{'visited'}{$host}{'count'}++;

    $res;
}

=head2 $ua->as_string

Returns a text that describe the state of the UA.
Mainly useful for debugging.

=cut

sub as_string
{
    my $self = shift;
    my @s;
    push(@s, "Robot: $self->{'agent'} operated by $self->{'from'}  [$self]");
    push(@s, "    Minimum delay: " . int($self->{'delay'}*60) . "s");
    push(@s, "    Will sleep if too early") if $self->{'use_alarm'};
    push(@s, "    Rules = $self->{'rules'}");
    push(@s, "    Visits");
    for (sort keys %{$self->{'visited'}}) {
	my $e = $self->{visited}{$_};
	push(@s, sprintf "      %-20s: " .
			 localtime($e->{'last'}) . "%4d",
			 $_, $e->{'count'});
    }

    join("\n", @s, '');
}

1;

=head1 AUTHOR

Gisle Aas <aas@sn.no>

=cut
