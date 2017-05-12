package Apache::Earlybird;
use strict;

# © 2001 Ronald Florence <ron@18james.com>
# last modified, 23 Dec 2001

# The following line is local; remove or modify as 
# needed for your Apache/mod_perl installation.
use lib qw(/usr/apache/perl5/5.005/sun4-solaris);

use vars qw($VERSION);
use Apache::Constants qw(OK DECLINED FORBIDDEN);
use Mail::Sendmail;
use Net::DNS;
use Cache::FileCache;
use Time::Zone;
use HTTP::Request::Common;
use LWP::UserAgent;

# ------------------------------------------------------------
$VERSION = 1.03;

# URLs to recommend in notifications.
my %security_url = (
   Nimda => 'http://www.microsoft.com/technet/treeview/default.asp?url=/technet/security/topics/Nimda.asp',
   CodeRed => 'http://www.microsoft.com/technet/treeview/default.asp?url=/technet/security/topics/codealrt.asp'
		   );
# address for email to SecurityFocus.com
my $security_focus_address = 'aris-report@securityfocus.com';

# base URL for arin whois queries
my $arin_base = 'http://www.arin.net/cgi-bin/whois.pl?queryinput=';

# optional BCC
my $bcc_address = '';

# default notification interval (24 hours)
my %cache_options = ('default_expires_in' => 86400 );

# $debug = 0 for errors only, 1 for logging email, 2 for max debugging.
my $debug = 0;

# $use_mx = 0 to use the SOA address only, 1 for MX addresses too.
# my $use_mx = 0;

# end of configuration
# ------------------------------------------------------------

sub handler
  {
    my $worm;
    my $r = shift;
    my $remote_ip = $r->connection->remote_ip;
    my $uri = $r->uri;
    if ($uri =~ /default\.ida/)	{ $worm = "CodeRed"; }
    elsif ($uri =~ /\.exe/)	{ $worm = "Nimda"; }
    else 
      {
	$r->warn("Earlybird: unrecognized attack from [$remote_ip].");
	return DECLINED;
      }
    $cache_options{'namespace'} = $worm;
    my $file_cache = new Cache::FileCache(\%cache_options);
    unless ($file_cache)
      {
	$r->log_error("$worm: Could not instantiate FileCache.");
	return DECLINED;
      }

    my $last_visited = $file_cache->get($remote_ip);
    if ($last_visited)
      {
	$r->warn("$worm: Found cached IP [$remote_ip].") if ($debug > 1);
	return FORBIDDEN;
      }
    $file_cache->purge;

    # Send e-mail to SecurityFocus.com
    my $server_name = $r->server->server_hostname;
    my $from_address = $r->server->server_admin;
    my $now = scalar localtime;
    my $time_zone_name = uc tz_name;
    my $sf_message = "$remote_ip\t$now $time_zone_name

-- 
   Apache::Earlybird-$VERSION (mod_perl) on $server_name";

    my %sf_mail = ( 
      To      => $security_focus_address,
      BCC     => $bcc_address,
      From    => $from_address,
      Subject => "$worm infection on '$remote_ip': Automatic report",
      Message => $sf_message
		   );
    if (sendmail %sf_mail)
      {
	$file_cache->set($remote_ip, 1);
	$r->warn("$worm: sent e-mail to SecurityFocus about '$remote_ip'") 
	  if ($debug);
      }
    else
      {
	$file_cache->set($remote_ip, 0);
	$r->warn("$worm: sendmail returned: $Mail::Sendmail::error");
	return DECLINED;
      }

    my $admin_addr;
    my $remote_hostname;

    # Get a hostname and an email address from the SOA of the domain.
    my $res = new Net::DNS::Resolver;
    my $query = $res->search($remote_ip);
    if ($query) 
      {
	foreach my $rr ($query->answer)
	  {
	    next unless $rr->type eq "PTR";
	    $remote_hostname = $rr->rdatastr;
	  }
	chop $remote_hostname;
      }
    else
      {
	my $dns_error = $res->errorstring;
	$r->warn("$worm: PTR lookup on [$remote_ip] failed: $dns_error") 
	  if ($debug > 1);
      }
    if ($remote_hostname) 
      {
	my @zone = split /\./, $remote_hostname;
	my $SOA_query = 0;
	while (!$SOA_query)
	  {
	    $SOA_query = $res->query(join('.', @zone), "SOA");
	    last if !shift @zone;
	  }
	if ($SOA_query)
	  {
	    my $addr = ($SOA_query->answer)[0]->rname;
	    $addr =~ s/\./@/;
	    $admin_addr = $addr . ', ' . do { $addr =~ s/^[^@]+/abuse/; $addr };
	  }
#	if ($use_mx)
#	  {
#	    my @mx;
#	    my @hostname_components = split /\./, $remote_hostname;
#	    while (!@mx) 
#	      {
#		my $host_for_mx_lookup = join '.',  @hostname_components;
#		@mx = mx($res, $host_for_mx_lookup);
#		last if !shift @hostname_components;
#	      }
#	    if (!@mx)
#	      {
#		my $dns_err = $res->errorstring;
#		$r->warn("$worm: no MX record for '$remote_hostname' [$dns_err].") 
#		  if ($debug > 1);
#	      }
#	    my $mx_host = $mx[0]->exchange;
#	    my @webmasters = ('webmaster', 'postmaster', 'abuse');
#	    $admin_addr .= ', ' .  join ', ', map("$_\@$mx_host", @webmasters);
#	  }
      }

    # If we cannot resolve the $remote_ip or the SOA address.
    if (!$admin_addr)
      {
        $remote_hostname = $remote_ip;
	my $ua = LWP::UserAgent->new;
	$ua->agent("Apache::Earlybird/$VERSION");
	$ua->env_proxy;
	my $resp = $ua->request(GET $arin_base . $remote_ip);
	my @arin = split '\n', $resp->content;
	my @noc_urls;
	my @addr;
	for (@arin)
	  {
	    push @noc_urls, /queryinput=(\w*[A-Za-z][^"]+)/;
            push @addr, /\s+([\w.-]+@[\w.-]+)/;
          }
        if (!@addr)
          {
            for (@noc_urls)
              {
                $resp = $ua->request(GET $arin_base . $_);
                @arin = split '\n', $resp->content;
                for (@arin) { push @addr, /\s+([\w.-]+@[\w.-]+)/; }
              }
          }
        if (!@addr) 
          {
            $r->warn("$worm: arin whois lookup failed for $remote_ip")
	       if ($debug > 1);
     	    return FORBIDDEN;
          }
        $admin_addr = join ', ', @addr;
        $admin_addr .= ', ' . join  ', ',  map { s/^[^@]+/abuse/; $_ } @addr;
      }

    my $request = $r->the_request;  
    my $port = $r->get_server_port;
    my $outgoing_message = <<END;
The Microsoft IIS server at 

   $remote_hostname [$remote_ip]

appears to be infected with the $worm worm.  It attempted
to spread to our Apache server at $server_name port $port
on $now $time_zone_name with the request:

   $request

Please investigate and apply the appropriate patch from
$security_url{$worm}

-- 
   Apache::Earlybird-$VERSION (mod_perl) on $server_name
END

    my %mail = ( 
      To      => $admin_addr,
      BCC     => $bcc_address,
      From    => $from_address,
      Subject => "$worm infection on '$remote_hostname': Automatic report",
      Message => $outgoing_message
		);
    if (sendmail %mail)
      {
	$r->warn("$worm: sent email to '$admin_addr'") if ($debug);
	return FORBIDDEN;
      }
    else
      {
	$r->warn("$worm: sendmail returned: $Mail::Sendmail::error");
	return DECLINED;
      }
  }
# All modules must return a true value
1;

__END__
# Below is stub documentation for your module. 

=head1 NAME

    Apache::Earlybird - Responds to worm attacks with e-mail warnings

=head1 SYNOPSIS

    Make sure your Apache is compiled with mod_perl and put the
    following in your httpd.conf:

	PerlModule	Apache::Earlybird

	<LocationMatch "/(root|cmd)\.exe">
	    SetHandler perl-script
	    PerlHandler Apache::Earlybird
	</LocationMatch>

        <Location  /default.ida>
	    SetHandler perl-script
	    PerlHandler Apache::Earlybird
	</Location>

=head1 DESCRIPTION

    The Earlybird gets the worm.  This Perl module should be invoked
    whenever IIS worms attack.  We don't have to worry about such
    attacks on Apache servers on Unix or Linux, but we can be good
    Internet citizens and spare ourselves and others the log clutter
    and lost bandwidth by notifying webmasters or ISPs of infected
    machines.

=head1 LICENSE

    You may distribute this module under the same license as Perl itself.

=head1 AUTHOR

    Ronald Florence <ron@18james.com> 

    Portions of the code are adapted from Apache::CodeRed by Reuven
    M. Lerner <reuven@lerner.co.il> and Apache::MSIISprobe by Nick
    Tonkin <nick@tonkinresolutions.com>.

=head1 SEE ALSO

L<mod_perl>.

=cut
