package IP::Country::Slow;
use strict;
use Carp;
use Socket qw ( inet_aton inet_ntoa AF_INET );
use IP::Country::Fast;

use vars qw ( $VERSION );
$VERSION = '0.04';

my $singleton = undef;

my $ip_match = qr/^(\d|[01]?\d\d|2[0-4]\d|25[0-5])\.(\d|[01]?\d\d|2[0-4]\d|25[0-5])\.(\d|[01]?\d\d|2[0-4]\d|25[0-5])\.(\d|[01]?\d\d|2[0-4]\d|25[0-5])$/o;
my $private_ip = qr/^(10\.|172\.(1[6-9]|2\d|3[01])\.|192\.168\.)/o; # RFC1918
my $tld_match = qr/\.([a-zA-Z][a-zA-Z])$/o;

my %cache;
my $cache = 1; # cache is switched on

sub new
{
    my $caller = shift;
    unless (defined $singleton){
        my $class = ref($caller) || $caller;
	$singleton = bless {}, $class;
    }
    return $singleton;
}

sub db_time
{
     return 0;
}

sub cache
{
    my $bool = defined $_[1] ? $_[1] : $_[0];
    if ($bool){
	$cache = 1;
    } else {
	$cache = 0;
	%cache = ();
    }
}

sub inet_atocc
{
    my $hostname = $_[1] || $_[0];
    if ($hostname =~ $ip_match){
	# IP address
	return inet_ntocc(inet_aton($hostname));
    } else {
	# assume domain name
	if ($cache && exists $cache{$hostname}){
	    return $cache{$hostname};
	} else {
	    if (my $cc = _get_cc_from_tld($hostname)){
		return $cc;
	    } else {
		my $cc =  IP::Country::Fast::inet_atocc($hostname);
		$cache{$hostname} = $cc if $cache;
		return $cc;
	    }
	}
    }
}

sub inet_ntocc
{
    my $ip_addr = $_[1] || $_[0];
    if ($cache && exists $cache{$ip_addr}){
	return $cache{$ip_addr};
    } else {
	my $ip_dotted = inet_ntoa($ip_addr);
	return undef if $ip_dotted =~ $private_ip;
	if (my $hostname = gethostbyaddr($ip_addr, AF_INET)){
	    if (my $cc = _get_cc_from_tld($hostname)){
		$cache{$ip_addr} = $cc if $cache;
		return $cc;
	    }
	}
	my $cc = IP::Country::Fast::inet_ntocc($ip_addr);
	$cache{$ip_addr} = $cc if $cache;
	return $cc;
    }
}

sub _get_cc_from_tld ($)
{
    my $hostname = shift;
    if ($hostname =~ $tld_match){
	return uc $1;
    } else {
	return undef;
    }
}


1;
__END__

=head1 NAME

IP::Country::Slow - cached lookup of country codes by domain name and IP address

=cut
