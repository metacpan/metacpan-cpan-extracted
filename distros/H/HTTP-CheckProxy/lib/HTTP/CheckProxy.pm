
package HTTP::CheckProxy;
use strict;
use LWP::UserAgent;

BEGIN {
	use Exporter ();
	use vars qw ($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);
	$VERSION     = 0.4;
	@ISA         = qw (Exporter);
	#Give a hoot don't pollute, do not export more than needed by default
	@EXPORT      = qw ();
	@EXPORT_OK   = qw ();
	%EXPORT_TAGS = ();
}


########################################### main pod documentation begin ##
# Below is the stub of documentation for your module. You better edit it!


=head1 NAME

HTTP::CheckProxy - Perl module for testing for open proxies

=head1 SYNOPSIS

  use HTTP::CheckProxy



=head1 DESCRIPTION

This module uses LWP to test the supplied IP address to see if it will
promiscuosly proxy on port 80. Caution: this can have false alarms if
you are on a network where you are supposed to go through a proxy,
such as AOL -- but are you supposed to be running a webserver on such
a network ?

If you feed this an invalid ip address, LWP will complain.

Note: while there is HTTP::ProxyCheck it is much slower, though it
does a lot of input validation.
HTTP::CheckProxy is intended to be useful in processing lots of 
candidate proxies and in recording useful information. To do this,
make one object and repeatedly invoke the test() method with
different IP addresses.

=head1 USAGE

  my $open_proxy_test = HTTP::CheckProxy->new($ip);
  print "proxy test for $ip returns ".$open_proxy_test->code."\n";
  print ($open_proxy_test->guilty? "guilty" : "innocent");
  $open_proxy_test->test($ip2);
  print "proxy test for $ip2 returns ".$open_proxy_test->code."\n";
  print ($open_proxy_test->guilty? "guilty" : "innocent");

=head1 BUGS



=head1 SUPPORT

Email bugs to the author. 

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

perl(1).

=head1 METHODS

=cut

############################################# main pod documentation end ##

=head2 new

 Usage     : HTTP::CheckProxy->new($ip);
 Purpose   : constructor
 Returns   : object instance
 Argument  : Optional first paramenter:
                name or ip address of candidate proxy. Do not include http:// .
             Optional second parameter: url (including the http://) to try to fetch. If this is invalid or unreachable the results of the test are meaningless, but this is NOT checked.
 Throws    : We should probably throw an exception if the ip address under test is unreachable
 Comments  : 

See Also   : HTTPD::ADS::AbuseNotify for sending complaints about validated proxies and other abuse.

=cut

my $target_url="http://www.hudes.org";

sub new
  {
    my ($class, $ip, $target) = @_;
    my $self = bless ({}, ref ($class) || $class);
    $target_url= $target if defined $target;
    $self->test($ip) if defined $ip;
    return ($self);
  }


{
  my $response;
  sub get_response {
    return $response;
  }
  sub _set_response {
    my ($self,$param) = @_;
    $response = $param || die "OpenProxyDetector - no response to store";
  }
}

=head2 get_proxy_port

 Usage     :  $open_proxy_test->get_proxy_port;
 Purpose   : tell which port successfully proxied 
 Returns   : 16-bit integer port number
 Argument  : none
 Throws    : nothing
 Comments  : only valid when  $open_proxy_test->guilty is TRUE , may be undef otherwise (or have incorrect info if you reused the object)! 
See Also   : HTTPD::ADS::AbuseNotify for sending complaints about validated proxies and other abuse.

=cut

{
 my $port;#the port the proxy answered on
 sub get_proxy_port {
   return $port;
 }
 sub _set_proxy_port {
   my ($self, $param) = @_;
   $port = $param || die "OpenProxyDetector - no port to store";
 }
}

################################################ subroutine header begin ##
=head2 test

 Usage     :  $open_proxy_test->test($ip)
 Purpose   : tries to fetch a known web page via the supplied ip as proxy.
 Returns   : true (proxy fetch successful) or false (it failed to fetch)
 Argument  : IPv4
 Throws    : We should probably throw an exception if the ip address under test is unreachable
 Comments  : Not all open proxies or compromised hosts listen on port 80 and their are other means              than straightforward HTTP to communicate with zombies but this is a start.

See Also   : HTTPD::ADS::AbuseNotify for sending complaints about validated proxies and other abuse.

=cut
################################################## subroutine header end ##

sub  test {
    my $self = shift;
    my $ip = shift ||  die "no ip address supplied to test";
    my @ports = qw/80 8080 8001 scx-proxy dproxy sdproxy funkproxy dpi-proxy proxy-gateway ace-proxy plgproxy csvr-proxy flamenco-proxy awg-proxy trnsprntproxy castorproxy ttlpriceprocy privoxy ezproxy ezproxy-2/;#1080 is SOCKS
    my $port;
    my $response;
    my $browser = LWP::UserAgent->new(
				      timeout =>10, max_size =>2048,
				      requests_redirectable => []
				     );#fixme -- come back later and stuff in a fake agent name
    foreach $port (@ports)
      {
	$browser->proxy("http","http://$ip:".$port);
	$response = $browser->head($target_url);
	last unless defined $response;
	if(! $response->is_error) {#keep going while we don't get a successful proxying
	  $self->_set_proxy_port($port);
	  last;
	}
      }
    $self->_set_response($response);
    return $response->code();
}


=head2 guilty

 Usage     : $open_proxy_test->guilty
 Purpose   : Is in fact the tested host guilty of being an open proxy?
 Returns   : true (its an open proxy) or false (it isn't)
 Argument  : none
 Throws    : nothing
 Comments  : This method checks the return status code of the test. If an error code is returned, esp. code 500, the host is not guilty. If the status code is success, the host is guilty.

 See Also   : HTTPD::ADS::AbuseNotify for sending complaints about validated proxies and other abuse.

=cut

sub guilty {
    my $self = shift;
#we should get an error if its not an open proxy; informational etc. is not the right thing....
    return ! ( ($self->get_response)->is_error);
}

=head2 code

 Usage     : $open_proxy_test->code
 Purpose   : Return the status code of the proxy test
 Returns   : HTTP status code
 Argument  : none
 Throws    : nothing
 Comments  : 

 See Also   : HTTPD::ADS::AbuseNotify for sending complaints about validated proxies and other abuse.
=cut

sub code {
    my $self = shift;
    return ($self->get_response)->code();
}

1; #this line is important and will help the module return a true value
__END__

