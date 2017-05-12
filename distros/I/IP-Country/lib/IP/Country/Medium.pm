package IP::Country::Medium;
use strict;
use Carp;
use Socket qw ( inet_aton inet_ntoa AF_INET );
use IP::Country::Fast;

use vars qw ( $VERSION );
$VERSION = '0.05';

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

sub db_time
{
    return 0;
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
	    if ($hostname =~ $tld_match){
		return uc($1);
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
	return undef if ($ip_dotted =~ $private_ip);

	if (my $cc = IP::Country::Fast::inet_ntocc($ip_addr)){
	    return $cc;
	} elsif (gethostbyaddr($ip_addr, AF_INET) =~ $tld_match){
	    my $cc = uc($1);
	    $cache{$ip_addr} = $cc if $cache;
	    return $cc;
	} else {
	}
    }
    return undef;
}

1;
__END__

=head1 NAME

IP::Country::Medium - cached lookup of country codes by IP address and domain name

=head1 SYNOPSIS

  use IP::Country::Medium;

=head1 DESCRIPTION

See documentation for IP::Country. In addition, IP::Country::Medium objects have
a cache() method, which controls whether hostname->cc lookups are cached (on by
default).

=over 4

=item $ic-E<gt>cache(BOOLEAN)

By default, the module caches results of country-code lookups. This feature 
can be switched off by setting cache to a false value (zero, empty string or 
undef), and can be switched on again by setting cache to a true value (anything
which isn't false).

  $ic->cache(0); # clears and disables cache
  $ic->cache(1); # enables the cache

The cache is formed at the class level, so any change in caching in one object
will affect all objectcs of this class. Turning off the cache also clears the
cache.

=back

=cut
