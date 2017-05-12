
package HTTPD::ADS::OpenProxyDetector;
use strict;
use LWP::UserAgent;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = 0.2;
	@ISA         = qw (Exporter);
	#Give a hoot don't pollute, do not export more than needed by default
	@EXPORT      = qw ();
	@EXPORT_OK   = qw ();
	%EXPORT_TAGS = ();
}


########################################### main pod documentation begin ##
# Below is the stub of documentation for your module. You better edit it!


=head1 NAME

HTTPD::ADS::OpenProxyDetector - Determine if a ip address is an open proxy, log in database

=head1 SYNOPSIS

  use HTTPD::ADS::OpenProxyDetector



=head1 DESCRIPTION

This module uses LWP to test the supplied IP address to see if it will
promiscuosly proxy on port 80. Caution: this can have false alarms if
you are on a network where you are supposed to go through a proxy,
such as AOL -- but are you supposed to be running a webserver on such
a network ?


=head1 USAGE
$test_result = HTTPD::ADS::OpenProxyDetector->test($ip);



=head1 BUGS



=head1 SUPPORT



=head1 AUTHOR

	Dana Hudes
	CPAN ID: DHUDES
	dhudes@hudes.org
	http://www.hudes.org

=head1 COPYRIGHT

This program is free software licensed under the...

	The General Public License (GPL)
	Version 2, June 1991

The full text of the license can be found in the
LICENSE file included with this module.


=head1 SEE ALSO

HTTPD::ADS, LWP, perl(1).

=cut

############################################# main pod documentation end ##


################################################ subroutine header begin ##

=head2 test

 Usage     : test($ip)
 Purpose   : tries to fetch a known web page via the supplied ip as proxy.
 Returns   : true (proxy fetch successful) or false (it failed to fetch)
 Argument  : IPv4
 Throws    : We should probably throw an exception if the ip address under test is unreachable
 Comments  : Not all open proxies or compromised hosts listen on port 80 and their are other means 
             than straightforward HTTP to communicate with zombies but this is a start.

See Also   : HTTPD::ADS::AbuseNotify for sending complaints about validated proxies and other abuse.

=cut

################################################## subroutine header end ##


sub new
{
	my ($class, $ip) = @_;

	my $self = bless ({}, ref ($class) || $class);
	$self->test($ip);
	return ($self);
}

{
    my $response;
sub get_response {
    return $response;
}
sub _set_response {
    my ($self,$param) = @_;
    $response = $param || die "OpenPrexyDetector - no response to store";
}
}
sub  test {
    my $self = shift;
    my $ip = shift ||  die "no ip address supplied to test";
    my $browser = LWP::UserAgent->new(timeout =>10, max_size =>2048, requests_redirectable => []);#fixme -- come back later and stuff in a fake agent name
	$browser->proxy("http","http://$ip");
    my $response =  $browser->head("http://www.hudes.org/");
    $self->_set_response($response);
    return $response->code();
}

sub guilty {
    my $self = shift;
#we should get an error if its not an open proxy; informational etc. is not the right thing....
    return ! ( ($self->get_response)->is_error);
}

sub code {
    my $self = shift;
    return ($self->get_response)->code();
}

1; #this line is important and will help the module return a true value
__END__

