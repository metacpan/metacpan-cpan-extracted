# $Id: DNS.pm,v 1.10 2009/08/02 21:24:40 dk Exp $
package IO::Lambda::DNS;
use vars qw($DEBUG $TIMEOUT $RETRIES @ISA);
@ISA = qw(Exporter);
@EXPORT_OK = qw(dns);
%EXPORT_TAGS = ( all => \@EXPORT_OK);
$TIMEOUT = 4.0; # seconds
$RETRIES = 4;   # times

use strict;
use Socket;
use Net::DNS::Resolver;
use IO::Lambda qw(:all);

# given the options, returns new dns lambda
sub new
{
	shift;

	# get the options
	my @ctx;
	my $timeout  = $TIMEOUT;
	my $retries  = $RETRIES;
	my %opt;
	for ( my $i = 0; $i < @_; $i++) {
		if ( $i == 0 or $i == $#_ or not defined($_[$i])) {
			# first or last or undef parameter in no way can be an option
			push @ctx, $_[$i];
		} elsif ( $_[$i] =~ /^(timeout|deadline)$/) {
			$timeout  = $_[++$i];
		} elsif ( $_[$i] eq 'retry') {
			$retries  = $_[++$i];
		} elsif ( $_[$i] =~ /^(
			nameservers|recurse|debug|config_file|
			domain|port|srcaddr|srcport|retrans|
			usevc|stayopen|igntc|defnames|dnsrch|
			persistent_tcp|persistent_udp|dnssec
		)$/x) {
			$opt{$_[$i]} = $_[$i + 1];
			$i++;
		} else {
			push @ctx, $_[$i];
		}
	}

	my $simple_query = (( 1 == @ctx) and not ref($ctx[0]));

	# proceed
lambda {
	my $obj  = Net::DNS::Resolver-> new( %opt);
	my $bg_obj = $obj-> bgsend( @ctx);
	return "send error: " . $obj-> errorstring unless $bg_obj;

	my $sock = $bg_obj;
	context $sock, $timeout;
readable {
	unless ( shift) {
		return 'connect timeout' if $retries-- <= 0;
		return this-> start; # restart the whole lambda
	}

	my $err = unpack('i', getsockopt($sock, SOL_SOCKET, SO_ERROR));
	if ( $err) {
		$! = $err;
		return "socket error: $!";
	}
	return again unless $obj-> bgisready($bg_obj);

	my $packet = $obj-> bgread( $bg_obj);
	undef $sock;
	undef $bg_obj;
	
	return "recv error: " . $obj-> errorstring unless $packet;

	if ( $simple_query) {
		# behave like inet_aton, return single IP address
		for ( $packet-> answer) {
			return $_-> address if $_-> type eq 'A';
		}
		return 'response doesn\'t contain an IP address';
	}

	return $packet;
}}}

sub dns(&) { IO::Lambda::DNS-> new(context)-> condition(shift, \&dns, 'dns') }

1;

__DATA__

=pod

=head1 NAME

IO::Lambda::DNS - DNS queries lambda style

=head1 DESCRIPTION

The module provides access to asynchronous DNS queries through L<Net::DNS>.
Two function doing the same operation are featured: constructor C<new> and
condition C<dns>.

=head1 SYNOPSIS

   use strict;
   use IO::Lambda::DNS qw(:all);
   use IO::Lambda qw(:all);
   
   # simple async query
   my $reply = IO::Lambda::DNS-> new( "www.site.com" )-> wait;
   print (($reply =~ /^\d/) ? "Resolved to $reply\n" : "Error: $reply\n");

   # parallel async queries
   lambda {
      for my $site ( map { "www.$_.com" } qw(google yahoo perl)) { 
         context $site, 'MX', timeout => 0.25; 
         dns { print shift-> string if ref($_[0]) }
      }
   }-> wait;

=head2 OPTIONS

Accepted options specific to the module are C<timeout> or C<deadline> (in
seconds) and C<retry> (in times).  All other options, such as C<nameservers>,
C<dnssec> etc etc are passed as is to the C<Net::DNS::Resolver> constructor.
See its man page for details.

=head2 USAGE

=over

=item new

Constructor C<new> accepts Net::DNS-specific options (see L<OPTIONS> above) and
query, and returns a lambda. The lambda accepts no parameters, and returns
either an IP address or a response object (depending on the call syntax, see
below), or an error string.

   new ($CLASS, %OPTIONS, $HOSTNAME) :: () -> ($IP_ADDRESS|$ERROR)

In the simple case, accepts C<$HOSTNAME> string, and returns also a string, either
an IP address or an error. To distinguish between these use C< /^\d/ > regexp,
because it is guaranteed that no error message will begin with a digit, and no IP
address will begin with anything other than a digit.

   new (%OPTIONS, ($PACKET | $HOSTNAME, $TYPE)) :: () -> ($RESPONSE|$ERROR)

In the complex case, accepts either C<Net::DNS::Packet> object, or C<$HOSTNAME>
and C<$TYPE> strings, where the latter can be one of C<A>, C<MX>, etc DNS query
type. See L<Net::DNS::Resolver/bgsend> for the exact syntax.

Returns either a C<Net::DNS::RR> object or an error string.

=item dns

Condition wrapper over C<new>.

   dns (%OPTIONS, $HOSTNAME) -> $IP_ADDRESS|$ERROR
   dns (%OPTIONS, ($PACKET | $HOSTNAME $TYPE)) -> $RESPONSE|$ERROR

=back

=head1 SEE ALSO

L<IO::Lambda>, L<Net::DNS::Resolver>.

=head1 AUTHOR

Dmitry Karasik, E<lt>dmitry@karasik.eu.orgE<gt>.

=cut
