=head1 NAME

FastRobot - a robot which lets us check how long it will wait

=head1 SYNOPSIS

  use FastRobot
  my $ua=FastRobt::new(....)
  $ua->check_wait

=head1 DESCRIPTION

Just like a RobotUA, but you can see how long it will wait for a given
link and then try another.

=cut

package LWP::FastRobot;
$REVISION=q$Revision: 1.5 $ ; $VERSION = sprintf ( "%d.%02d", $REVISION =~ /(\d+).(\d+)/ );
use Carp;
use LWP::RobotUA;

@ISA=qw(LWP::RobotUA);
$VERSION = sprintf("%d.%02d", q$Revision: 1.5 $ =~ /(\d+)\.(\d+)/);

require WWW::RobotRules;
require HTTP::Request;
require HTTP::Response;

=item $self->robot_check($url)

robot_check - checks whether a request will be allowed by the robot
rules but doesn't actually send a request.  This has the advantage
that it means that the host_wait function is then accurate.

=cut

sub robot_check
{
    my($self, $url) = @_;

    LWP::Debug::trace('()');

    # Do we try to access a new server?
    my $allowed = $self->{'rules'}->allowed($url);

    if ($allowed < 0) {
	LWP::Debug::debug("Host is not visited before, or robots.txt expired.");
	# fetch "robots.txt"
	my $robot_url = $url->clone;
	$robot_url->path("robots.txt");
	$robot_url->query(undef);
	LWP::Debug::debug("Requesting $robot_url");

	# make access to robot.txt legal since this will be a recursive call
	$self->{'rules'}->parse($robot_url, "");

	my $robot_req = new HTTP::Request 'GET', $robot_url;
	my $robot_res = $self->request($robot_req);
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
    }

    return $allowed;

}


=item $ua->host_wait($netloc)

Returns the number of seconds (from now) you must wait before you can
make a new request to this host.

=cut

sub host_wait
{
    my($self, $netloc) = @_;
    print STDERR "host wait called with netloc $netloc\n";
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
  print STDERR "No wait RE: " . $self->{'no_wait'} . "\n";
}

#  =item $ua->short_wait($regex)

#  Sets a regular expression for links for which the robot agent should
#  not wait.  Typically these would be local pages or servers in the same
#  organisation as the link checking is being carried out by.

#  =cut

#  =item $ua->short_delay($regex)

#  Sets the amount of time to wait for 

#  =cut

