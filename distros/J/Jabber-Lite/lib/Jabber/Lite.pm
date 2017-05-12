###################################################################
# Jabber::Lite
# $Id: Jabber::Lite.pm,v 1.64 2007/01/29 20:44:34 bc Exp bc $
# Copyright (C) 2005-2007 Bruce Campbell <beecee@cpan.zerlargal.org>
# ( For my mail sorting, replace the above 'beecee' with the name
#   of the module, eg 'Jabber::Lite' or 'Jabber-Lite' )
#
# This is a perl library intended to be a small and light implementation
# of Jabber libraries.  Nearly a third of this file is documentation of
# one sort or another.
#
# What you should be able to do with this library:
#	Connect to a Jabber server.
#	Send and receive packets.
#	Create new packets.
#	List attributes on packets.
#	List tags on packets.
#
# This library implements a progressive XML parser within itself; it 
# does not use an seperate parser which your perl installation may not
# be able to install.  
#
# This library is fairly dumb.  It doesn't understand anything other than
# ASCII, and its correctness checks are limited.  Unicode is right out.
# Basically, this is a Jabber library where the most complicated thing
# being dealt with is the base64-encoded stuff in SASL authentication.
#
###########################################################################
#
#


=head1 NAME

Jabber::Lite - Standalone library for communicating with Jabber servers.

=head1 SYNOPSIS

  use Jabber::Lite;

  my $jlobj = Jabber::Lite->new();

  $jlobj->connect( %args );
  $jlobj->authenticate( %args );
  my $stillgoing = 1;
  while( $stillgoing ){
	my $tval = $jlobj->process();
	if( $tval == 1 ){
		my $curobj = $jlobj->get_latest();

		# Process based on the object.

	}elsif( $tval < 0 ){
		$stillgoing = 0;
	}
  }

=head1 GOALS

Jabber::Lite is intended to be a pure perl library for interacting with
Jabber servers, and be able to run under any version of perl that has
the Sockets library.

=head1 DESCRIPTION

Jabber::Lite is, as the name implies, a small 'lite' library for dealing
with Jabber servers, implemented entirely in perl.  Whilst it is small, 
it does try to be fairly complete for common tasks.  

Whats in the box?  Jabber::Lite is able to connect to a Jabber server,
read from the socket, and supply XML objects to the application as
the application reads them.  Its function calls are mostly compatible
with Jabber::NodeFactory and Jabber::Connection.  
Surprisingly, it can also function as a stand-alone XML parser (which
was not the author's original intent, but hey, it works).

Whats not in the box?  Any requirement for a recent perl version, UTF-8
support, as well as a B<fully> XML-compliant Parser.

Applications using this library will need to be aware that this 
library uses a combination of 'pull' and 'push' methods of supplying 
XML objects.  Handlers for given object types can be put in place, 
however if an object is not fully handled by a Handler, the object
will 'block' further objects until the Application retrieves it.  Read 
the notes on ->process and ->get_latest() for further details.

The inbuilt parser, fully implemented in perl, is more properly termed an
XML Recogniser.  If you want a fully compliant XML Parser, look elsewhere.
This one recognises just enough XML for its purposes ;)

=cut

# Do proxy thing as per Matt Sergeant's article:
# http://www.perl.com/pub/a/2002/08/07/proxyobject.html?page=3
# This may reduce some memory usage.

package Jabber::Lite;

use strict;
our $AUTOLOAD;

BEGIN {
	eval "use Scalar::Util qw(weaken);";
	if ($@) {
		$Jabber::Lite::WeakRefs = 0;
	} else {
		$Jabber::Lite::WeakRefs = 1;
	}
}

sub new {
	my $class = shift;
	no strict 'refs';
	my $impl = $class . "::Impl";
	my $this = $impl->new(@_);
	if ($Jabber::Lite::WeakRefs) {
		return $this;
	}
	my $self = \$this;
	return bless $self, $class;
}

sub AUTOLOAD {
	my $method = $AUTOLOAD;
	$method =~ s/.*:://; # strip the package name
	no strict 'refs';
	*{$AUTOLOAD} = sub {
		my $self = shift;
		my $olderror = $@; # store previous exceptions
		my $obj = eval { $$self };
		if ($@) {
			if ($@ =~ /Not a SCALAR reference/) {
				croak("No such method $method in " . ref($self));
			}
			croak $@;
		}
		if ($obj) {
			# make sure $@ propogates if this method call was the 
			# result of losing scope because of a die().
			if ($method =~ /^(DESTROY|del_parent_link)$/) {
				$obj->$method(@_);
				$@ = $olderror if $olderror;
				return;
			}
			return $obj->$method(@_);
		}
	};
	goto &$AUTOLOAD;
}

# sub DESTROY { my $self = shift; warn("Lite::DESTROY $self\n") }

# Now for the actual package.
package Jabber::Lite::Impl;
use constant r_HANDLED => -522201;
use Exporter;

use vars qw/@ISA $VERSION @EXPORT @EXPORT_OK %EXPORT_TAGS/;
@ISA=qw(Exporter);

@EXPORT = qw(r_HANDLED);


%EXPORT_TAGS = (
  'handled' => [qw(r_HANDLED)],
	);

my $con;
push @EXPORT_OK, @$con while (undef, $con) = each %EXPORT_TAGS;

$VERSION = "0.8";

use IO::Socket::INET;
use IO::Select;

sub DESTROY { 
	my $self = shift; 
	# warn("Impl::DESTROY $self\n");

	# Remove references to this instance.  If it is being called
	# manually, may trigger garbage collection of other objects.
	$self->hidetree();

}

=head1 METHODS

The methods within have been organised into several categories, listed here
for your searching pleasure:

=over

=item Initialisation

=item Resolving

=item Connecting

=item Authenticating

=item Dealing with <stream:features>

=item Handling Packets

=item So Long, and Thanks for all the <fish/>

=item These are a few of my incidental things

=item Object common

=item Object detailed and other stuff.

=back


=cut

=head1 METHODS - Initialisation

=cut

=head2 new

Returns a new instance of the object.  Takes a hash of arguments which
are passed straight to ->init();

=cut

sub new {

	my ($class, %args) = @_;
	my $self = {};

	bless $self, $class ;

	$self->init( %args );

	return( $self);

}

=head2 init

(Re-)initialises data stored on the object, removing most references.
Used by ->new() to ensure that there is no 'bad' stuff around.  Takes a
hash of values including:

=over

=item readsize

The number of bytes to request (but not expect) from the socket at any one
time.  Defaults to 1500 to ensure that an ethernet packet will be read in
one call.  Do not set this excessively high.  Likewise, setting it too low 
will result in excessive polls.

=item disconnectonmax

A boolean indicating whether to disconnect on exceeding maxobjectsize bytes, 
maxnamesize or maxobjectdepth in a single object.  The default, 0, will 
continue to read and parse the object, but will not save more of the object's 
data or attributes into memory.

=item maxobjectsize

The maximum number of bytes allowed in a single object.  There is no default.
This is intended as protection against an excessively large packet.

=item maxobjectdepth

The maximum number of subtags allowed in a single object.  There is no
default.  

=item maxnamesize

The maximum length of a single tag name, eg, the 'foo' in '<foo/>'.  There 
is no default.  Note that this is applied against every tag, not just the
parent tag.  This is intended as protecting against a really long
<taaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaag>, which may still consume
memory if the maxobject size is exceeded and disconnectonmax is left at 0.

=item debug

A debug qualifier.  If set to '1', will show all debug messages.  If set to
a comma-seperated string, will show all debug messages generated by those
subroutines.

=back

The various 'max' settings are enforced by ->do_read.  Calling ->parse_more
directly will not incur the dubious protections afforded by this.

=cut

sub init {

	my $self = shift;
	my %args = (	readsize => 1500,
			disconnectonmax => 0,
			@_ );

	# First clear the object.
	foreach my $kkey ( keys %{$self} ){
		delete( $self->{"$kkey"} );
	}

	# Then apply any arguments.
	my %validargs = ( "readsize", "1",
			  "debug", "1",
			  "disconnectonmax", "1",
			  "maxobjectsize", "1",
			  "maxnamesize", "1",
			  "maxobjectdepth", "1",
			 );

	# Run through the possible known args, overwriting any that
	# already exist.
	foreach my $kkey( keys %args ){
		next unless( defined( $validargs{"$kkey"} ) );
		$self->{"_$kkey"} = $args{"$kkey"};
	}

	# Clear the handlers.
	%{$self->{'handlers'}} = ();

}

=head1 METHODS - Resolving

Before connecting, you may need to resolve something in order to find
out where to point the connection methods to.  Heres some methods
for resolving.

=head2 resolve

Deals with the intricacies of figuring out what you need to connect to.
Understands SRV records, and how things can resolve differently depending
on whether you want a server or client connection.  Takes a hash of 'Domain',
a 'Timeout' value (in seconds) and a 'Type' of 'client' or 'server'.  
Returns a boolean success value of 1 (success) or 0 (failure).

Note that no DNSSEC or TSIG verification is done.

=cut

sub resolve {
	my $self = shift;
	my %args = (	Domain => undef,
			Type => 'client',
			Protocol => 'tcp',
			Timeout => 90,
			@_,
			);

	# We just dump it all to bgresolve.
	$self->bgresolve( %args );

	# Loop until we do not have '-1' as the result.  bgresolve takes
	# care of any timeouts.
	my $curresult = $self->bgresolved;
	while( $curresult == -1 ){
		$curresult = $self->bgresolved;

		select( undef, undef, undef, 0.1 );
	}

	return( $curresult );
}
	

=head2 resolved

Returns a list of what the last ->resolve request actually resolved to.
This is an ordered-by-priority, randomised-by-weight @list of 
'IP.address,port'.  If there is no ',port', then no port information
was present in the DNS, and the application's own idea of default
port should be used.

The ordering is done according to the method set out in 
RFC2782(DNS SRV Records).  Of particular note is page 3, where a 
randomisation function is applied to the ordering of SRV RRs with 
equal priority.  Thus, each time this function is called, it may 
return a different ordering of IPs.  

=cut

sub resolved {
	my $self = shift;

	# Do the ordering of hosts in this function.
	# The results have been stored in a hash: 
	#	$self->{'_resolved'}{'hostname'}
	# Each of these contains another hash, of @'srv' and $'address',
	# amongst others.
	my @list = ();

	# Run through the hosts, and see if any have 'srv' records.  There 
	# should only be one, and it holds indirections to other hosts.
	my $srvrec = undef;
	foreach my $host( keys %{$self->{'_resolved'}} ){
		next unless( defined( $self->{'_resolved'}{$host}{'srv'} ) );
		$srvrec = $host;
	}

	if( ! defined( $srvrec ) ){
		foreach my $host( keys %{$self->{'_resolved'}} ){
			next unless( defined( $self->{'_resolved'}{$host}{'address'} ) );
			next if( $self->{'_resolved'}{$host}{'address'} =~ /^\s*$/ );
			push @list, $self->{'_resolved'}{$host}{'address'};
		}
	}else{
		# Run through the srv listing in order.
		my %uhosts = ();
		foreach my $prio ( sort { $a <=> $b } keys %{$self->{'_resolved'}{$srvrec}{'srv'}} ){
			# Collect all of the weights.
			my %weights = ();
			my $wghtcnt = scalar @{$self->{'_resolved'}{$srvrec}{'srv'}{$prio}};
			my $wghthigh = 0;
			foreach my $wghtrec( @{$self->{'_resolved'}{$srvrec}{'srv'}{$prio}} ){
				next unless( $wghtrec =~ /^\s*(\d+)\s+(\d+)\s+(\S+)\s*$/ );
				my $wghtnum = $1;
				my $port = $2;
				my $host = $3;
				if( $wghtnum > $wghthigh ){
					$wghthigh = $wghtnum;
				}
			}

			# Run through again, now that we know the highest
			# weight.
			my $posmax = 0;
			foreach my $wghtrec( @{$self->{'_resolved'}{$srvrec}{'srv'}{$prio}} ){
				next unless( $wghtrec =~ /^\s*(\d+)\s+(\d+)\s+(\S+)\s*$/ );
				my $wghtnum = $1;
				my $port = $2;
				my $host = $3;

				# Work out a position for this weight, between
				# 0 and $wghtcnt (inclusive).
				my $wghtpos = abs( int( rand( $wghtcnt + 1 ) + ( $wghthigh - $wghtnum ) ) );
				my $trycnt = 0;
				while( defined( $weights{"$wghtpos"} ) && $trycnt < $wghtcnt ){
					$wghtpos = abs( int( rand( $wghtcnt + 1 ) + ( $wghthigh - $wghtnum ) ) );
					$trycnt++;
				}

				# Did the loop exit due to success, or because
				# of too many iterations?
				if( defined( $weights{"$wghtpos"} ) ){
					# Count up until we find one.
					$wghtpos = 0;
					while( defined( $weights{"$wghtpos"} ) ){
						$wghtpos++;
					}
				}

				# Save the port and host.
				$weights{"$wghtpos"} = "$port $host";

				if( $wghtpos > $posmax ){
					$posmax = $wghtpos;
				}	
				# print "Found SRV $srvrec and priority $prio and weight $wghtnum and pos $wghtpos and port $port and host $host\n";
			}

			# Now output the hosts seen in the semi-random
			# order chosen.
			foreach my $weightkey ( sort { $b <= $a } keys %weights ){
				next unless( defined( $weights{"$weightkey"} ) );
				next unless( $weights{"$weightkey"} =~ /^\s*(\d+)\s+(\S+)\s*$/ );
				my $port = $1;
				my $host = $2;
				next unless( defined( $self->{'_resolved'}{$host}{'address'} ) );
				next if( $self->{'_resolved'}{$host}{'address'}  =~ /^\s*$/ );
				# addresses can be multiple!
				foreach my $address( @{$self->{'_resolved'}{$host}{'address'}} ){
					# Only output a given IP and port combination once.
					next if( defined( $uhosts{$port . $address} ) );
					push @list, $address . "," . $port;
					$uhosts{$port . $address}++;
				}
			}
		}
	}
	return( @list );
}

=head2 bgresolve

As per ->resolve, but submit in the background.  This returns 1 if the query
could be submitted, and 0 if not.
( Actually, ->resolve is simply a wrapper around ->bgresolve and ->bgresolved )

=cut

sub bgresolve {
	my $self = shift;
	my %args = (	Domain => undef,
			Type => 'client',
			Protocol => 'tcp',
			Timeout => 90,
			@_,
			);

	my $retval = 0;

	# Wipe out previous resolution records.
	delete( $self->{'_resolved'} );
	delete( $self->{'_queries'} );

	if( ! defined( $args{"Timeout"} ) ){
		$args{"Timeout"} = 90;
	}elsif( $args{"Timeout"} !~ /^\s*\d+\s*$/ ){
		$args{"Timeout"} = 90;
	}elsif( $args{"Timeout"} < 11 ){
		# Try to stop the application from shooting off its own foot.
		$args{"Timeout"} = 11;
	}

	# If we have all of a domain, a type and a protocol, then we can
	# make a query.
	if( defined( $args{"Domain"} ) && defined( $args{"Type"} ) && defined( $args{"Protocol"} ) && $self->_got_Net_DNS() ){
		# Set up the initial query.
		my $res = Net::DNS::Resolver->new();
		$res->retry(2);
		$res->retrans(5);
		$res->tcp_timeout( $args{"Timeout"} - 1 );

		# udp_timeout is effectively the #retries * #retransmissions,
		# which we've set to 2 * 5 == 10.

		# No spaces in $qname.
		$args{"Type"} =~ s/\s*//g;
		$args{"Protocol"} =~ s/\s*//g;
		$args{"Domain"} =~ s/\s*//g;
		my $qname = "_xmpp-" . $args{"Type"} . "._" . $args{"Protocol"} . "." . $args{"Domain"};

		# Make sure the query makes sense.
		if( $qname =~ /^_xmpp-(server|client)\._([^\.]+)\.(\S+)$/i ){

			# Send it.
			my $sock = $res->bgsend( $qname, "SRV", "IN" );

			# Store it.
			my $sname = $args{"Domain"} . ";1";
			$self->{'_queries'}{";;base"} = $args{"Domain"};
			$self->{'_queries'}{";;q1"} = $sname;
			$self->{'_queries'}{";;start"} = time;
			$self->{'_queries'}{";;end"} = $self->{'_queries'}{";;start"} + $args{"Timeout"};
			$self->{'_queries'}{";;res"} = $res;
			$self->{'_queries'}{"$sname"}{"start"} = $self->{'_queries'}{";;start"};
			$self->{'_queries'}{"$sname"}{"sock"} = $sock;
			$self->{'_queries'}{"$sname"}{"qname"} = $qname;
			$self->{'_queries'}{"$sname"}{"qtype"} = "SRV";

			# Increment the return value.
			$retval++;
		}


		# If the query was for a 'server' type, send off a second
		# query for '_jabber._tcp.HOST' in case the first query
		# fails.  This should cut down on the wait time.  This code
		# should be removed when that portion of XMPP-CORE gets
		# relegated to 'do not use'.
		$qname = "_jabber._" . $args{"Protocol"} . "." . $args{"Domain"};
		if( $qname =~ /^_jabber\._([^\.]+)\.(\S+)$/i && $args{"Type"} =~ /^server$/i ){
			# Send it.
			my $sock = $res->bgsend( $qname, "SRV", "IN" );

			# Store it.
			my $sname = $args{"Domain"} . ";2";
			$self->{'_queries'}{";;res"} = $res;
			$self->{'_queries'}{";;q2"} = $sname;
			$self->{'_queries'}{"$sname"}{"start"} = $self->{'_queries'}{";;start"};
			$self->{'_queries'}{"$sname"}{"sock"} = $sock;
			$self->{'_queries'}{"$sname"}{"qname"} = $qname;
			$self->{'_queries'}{"$sname"}{"qtype"} = "SRV";

			# Increment the return value.
			$retval++;
		}

	}

	# Return true or false.
	if( $retval > 0 ){
		return( 1 );
	}else{
		return( 0 );
	}
}


=head2 bgresolved

Checks to see whether the last ->bgresolve request completed.  Only one
request in the background can be ongoing at a time.  Returns -1 if the
resolution is still pending, 0 if the resolution failed, and 1 if the
resolution was successful.  ->resolved can then be called to retrieve
the list.

=cut

sub bgresolved {
	my $self = shift;

	my $retval = -1;

	# The resolving chain goes something like:
	#	Look up the SRV records for '_xmpp-TYPE._PROTOCOL.HOST' .
	#	If successful: 
	#		look up in turn the A or AAAA records for the
	#		hostnames mentioned in the SRV records.
	#	If unsuccessful and TYPE is 'server':
	#		look up the SRV records for '_jabber._PROTOCOL.HOST'
	#		If successful:
	#			look up in turn the A or AAAA records for
	#			the hostnames mentioned in the SRV records
	#	If unsuccessful so far in looking up SRV records:
	#		look up the A or AAAA records for the 'HOST'
	#
	#	If unsuccessful in resolving hostnames supplied by SRV records:
	#		treat resolution as unsuccessful.

	# _xmpp-client._tcp.example.com.
	# _xmpp-server._tcp.example.com.
	# jabberserverhostname. 86400 A jabberserverip
	# _xmpp-server._tcp.jabberserverhostname. 86400 IN SRV 5 0 5269 jabberserverhostname.
	# _xmpp-client._tcp.jabberserverhostname. 86400 IN SRV 5 0 5222 jabberserverhostname.
	# _jabber._tcp.jabberserverhostname. 86400 IN SRV 5 0 5269 jabberserverhostname.
	# 
	# SRV lookups (RFC2781) say:
	#        Do a lookup for QNAME=_service._protocol.target, QCLASS=IN,
	#        QTYPE=SRV.
	#
	#        If the reply is NOERROR, ANCOUNT>0 and there is at least one
	#        SRV RR which specifies the requested Service and Protocol in
	#        the reply:
	#
	#            If there is precisely one SRV RR, and its Target is "."
	#            (the root domain), abort.


	# Does 'abort' in the above mean 'do not continue with SRV processing,
	# but attempt to resolve the HOST via A or AAAA queries',
	# 'do not continue with processing this QNAME', or 'do not continue
	# with resolving the original HOST' ?  For example, what happens if 
	# _xmpp-server._tcp.HOST fails in this way, but _jabber._tcp.HOST has 
	# usable information in it?  

	# See what the basename is.  Then see if basename;1 has completed.
	my $bname = $self->{'_queries'}{';;base'};
	my $res = $self->{'_queries'}{';;res'};
	my $q1 = $self->{'_queries'}{';;q1'};
	my $q2 = $self->{'_queries'}{';;q2'};
	my $srvcompleted = 0;
	my $srvabort = 0;

	if( defined( $bname ) && defined( $res ) && defined( $q1 ) ){
		# There is a query.  See if we have exceeded our timeout
		# value.
		my $q1pkt = undef;
		my $q2pkt = undef;
		my $colsrv = 0;
		if( $self->{'_queries'}{';;end'} < time ){
			$retval = 0;
		}elsif( ! defined( $self->{'_queries'}{$q1}{'completed'} ) && defined( $self->{'_queries'}{$q1}{'start'} ) ){
			# See if the first query has completed.
			my $q1sock = $self->{'_queries'}{$q1}{'sock'};
			if( $res->bgisready( $q1sock ) ){
				# It is.  Read in the value.
				$q1pkt = $res->bgread( $q1sock );
				$q1sock = undef;
				delete( $self->{'_queries'}{$q1}{'sock'} );
				$self->{'_queries'}{$q1}{'completed'} = time;
				$colsrv++;
			}
		}elsif( defined( $q2 ) && ! defined( $self->{'_queries'}{$q2}{'completed'} ) && defined( $self->{'_queries'}{$q2}{'start'} ) ){
			# There is a second query, which must be collected
			# to avoid memory leakage.
			my $q2sock = $self->{'_queries'}{$q2}{'sock'};
			if( $res->bgisready( $q2sock ) ){
				$q2pkt = $res->bgread( $q2sock );
				$q2sock = undef;
				delete( $self->{'_queries'}{$q2}{'sock'} );
				$self->{'_queries'}{$q2}{'completed'} = time;
				$colsrv++;
			}
		}

		# If the first one was completed, then set a flag for later.
		if( defined( $self->{'_queries'}{$q1}{'completed'} ) && defined( $self->{'_queries'}{$q1}{'start'} ) ){
			$srvcompleted++;
		}

		# If we collected a SRV result this time, then the return
		# value is -1, as we're about to send off another few 
		# queries.
		if( $colsrv ){
			$retval = -1;

			# If we collected the q2 result, check whether the
			# q1 result was successful.  If it was, throw out the
			# q2 result, as its just extra.
			my $wrkpkt = $q1pkt;
			if( defined( $q2pkt ) && defined( $self->{'_queries'}{$q1}{';;success'} ) ){
				$q2pkt = undef;
			}elsif( defined( $q2pkt ) ){
				$wrkpkt = $q2pkt;
			}

			# Did we actually get a packet?  It could be undef
			# if q2pkt was something, but q1 was successful.
			if( defined( $wrkpkt ) ){
				# Take it apart.
				my @answers = $wrkpkt->answer;

				# Count how many there are.
				my $ancount = scalar @answers;

				foreach my $answer( @answers ){
					next unless( $answer->type eq 'SRV' );
					my $prio = $answer->priority;
					my $wght = $answer->weight;
					my $port = $answer->port;
					my $target = $answer->target;

					# If there is just one answer, and
					# the target is '.', then mark this
					# one as failed and continue.
					if( $ancount == 1 && $target eq '.' ){
						# Was this q1?
						if( defined( $q1pkt ) ){
							$self->{'_queries'}{$q1}{'fail'}++;
						}else{
							$self->{'_queries'}{$q2}{'fail'}++;
						}
					}elsif( $prio =~ /^\s*\d+\s*$/ && $wght =~ /^\s*\d+\s*$/ && $port =~ /^\s*\d+\s*$/ && $target =~ /^\S{2,}$/ ){
						my $qname = $self->{'_queries'}{$q1}{'qname'};
						if( defined( $q1pkt ) ){
							# Success.
							$self->{'_queries'}{$q1}{'success'}++;
						}else{
							# Success.
							$self->{'_queries'}{$q1}{'success'}++;
							$qname = $self->{'_queries'}{$q2}{'qname'};
						}

						# Add the result to the 
						# '_resolved' hash as 
						# appropriate.
						push @{$self->{'_resolved'}{$qname}{'srv'}{$prio}}, $answer->weight . " " . $port . " " . $target;

						# Start queries for 'A' and
						# 'AAAA'.  Should these go
						# into the _queries or 
						# _resolved hash ?  _queries,
						# as that gets cleaned out
						# and the keys time gets shorter
						my $sname = $target . ";1";
						if( ! defined( $self->{'_queries'}{$sname} ) ){
							my $sock = $res->bgsend( $target, "IN", "AAAA" );
							$self->{'_queries'}{"$sname"}{"start"} = time;
							$self->{'_queries'}{"$sname"}{"sock"} = $sock;
							$self->{'_queries'}{"$sname"}{"qname"} = $target;
							$self->{'_queries'}{"$sname"}{"qtype"} = "AAAA";
						}
						$sname = $target . ";2";
						if( ! defined( $self->{'_queries'}{$sname} ) ){
							my $sock = $res->bgsend( $target, "IN", "A" );
							$self->{'_queries'}{"$sname"}{"start"} = time;
							$self->{'_queries'}{"$sname"}{"sock"} = $sock;
							$self->{'_queries'}{"$sname"}{"qname"} = $target;
							$self->{'_queries'}{"$sname"}{"qtype"} = "A";
						}
					}
				}
			}
		}else{		# colsrv.
			$retval = -1;
			# Run through the normal queries that we've got, 
			# and see if any came back.
			my %todel = ();
			my $foundcount = 0;
			foreach my $sname ( keys %{$self->{'_queries'}} ){
				next unless( $sname =~ /\;\d+$/ );
				next unless( defined( $self->{'_queries'}{$sname}{'qtype'} ) );
				next unless( $self->{'_queries'}{$sname}{'qtype'} =~ /^(A|AAAA)$/ );
				$foundcount++;
				my $sock = $self->{'_queries'}{"$sname"}{"sock"};
				my $dpkt = undef;
				if( defined( $sock ) ){
					if( $res->bgisready( $sock ) ){
						$dpkt = $res->bgread( $sock );
					}
				}
				# Store the socket again.
				$self->{'_queries'}{"$sname"}{"sock"} = $sock;

				# Run through the packet.
				if( defined( $dpkt ) ){
					$todel{"$sname"}++;
					my @answers = $dpkt->answers;
					foreach my $answer( @answers ){
						next unless( defined( $answer ) );
						next unless( $answer->type =~ /^(a|aaaa)$/i );
						push @{$self->{'_resolved'}{$self->{'_queries'}{"$sname"}{"qname"}}{'address'}}, $answer->address;
					}
				}
			}

			# Run through the queries that have been collected.
			foreach my $delkey( keys %todel ){
				delete( $self->{'_queries'}{$delkey} );
			}

			if( $foundcount == 0 && $srvcompleted == 1 ){
				$retval = 1;
			}
		}
	}

	#
	#            Else, for all such RR's, build a list of (Priority, Weight,
	#            Target) tuples
	#
	#            Sort the list by priority (lowest number first)
	#
	#            Create a new empty list
	#
	#            For each distinct priority level
	#                While there are still elements left at this priority
	#                level
	#                    Select an element as specified above, in the
	#                    description of Weight in "The format of the SRV
	#                    RR" Section, and move it to the tail of the new
	#                    list
	#
	#            For each element in the new list
	#
	#                query the DNS for address records for the Target or
	#                use any such records found in the Additional Data
	#                section of the earlier SRV response.
	#
	#                for each address record found, try to connect to the
	#               (protocol, address, service).
	#
	#        else
	#
	#            Do a lookup for QNAME=target, QCLASS=IN, QTYPE=A
	#
	#            for each address record found, try to connect to the
	#           (protocol, address, service)
	#

}
	

=head1 METHODS - Connecting

Before jabbering at other entities, you need to connect to a remote host.

=head2 connect

Connect to a Jabber server.  Only one connection at a time is supported
on any given object.  Returns 0 if unsuccessful, 1 if successful.

Takes a hash of values as follows:

=over 4

=item Host

The Host (name or IP address) to connect to.  Default is no host, and
thus no connection.  Note that if a name of the Host is used, then 
gethostbyname will be implicitly used by IO::Socket::INET, blocking the
application whilst doing so.  Calling applications may wish to avail
themselves of the ->resolve methods listed earlier to avoid this.

=item Port

The port to connect to on the remote host.  Defaults to 5222.

=item Domain

The domain to request on the remote Host.  Defaults to the value of
the Host option.  The meaning of this depends on the connection type
(StreamXMLNS).  If connecting as a client, refers to the domain that the
Username and Password credentials belong to.  If connecting as a 
component, refers to the domain that this connection wants to bind as.

=item UseSSL

Initiate a SSL/TLS connection immediately on connecting, for example, if
you are connecting to a server which offers SSL on an alternative port.
Defaults to 0.  This is used internally to redo the connection.

=item UseTLS

Negotiate a TLS connection if <starttls> is listed as one of the connection
features, and IO::Socket::SSL is available.  Defaults to 1, as everyone likes 
encryption.

=item MustEncrypt

The connection must be encrypted before considering the connection to be
opened.  This defaults to 0.  If this is set to 1, and IO::Socket::SSL is not
available, the connection will fail.

=item JustConnect

This simply opens a connection and returns without having sent any packets,
except for any required to initiate SSL if requested.  The calling program 
is responsible for sending any initial packets down the link, and 
responding to any packets received.  Defaults to 0.

=item JustConnectAndStream

This simply opens a connection and sends the initial '<stream:stream>' tag,
then returns.  The default is 0.  It is used internally for a number of 
things, each time a new '<stream:stream>' tag needs to be sent, which is
surprisingly often (once when connect, once after TLS is negotiated, and
once after SASL has been negotiated).

=item AllowRedirect

This checks to see if the server domain returned to us is the same as the
Domain that was requested.  The default, 1, allows this check to be skipped.

=item StreamXMLNS

The type of connection that we're telling the server this is.  Defaults
to 'jabber:client'.  For component connections, use 'jabber:component:accept',
and for servers, use 'jabber:server'.  Or use the C<ConstXMLNS> method 
documented towards the end (use 'client' or 'component').

=item StreamXMLLANG

The default language used over the connection, as per xml:lang.  Defaults
to undef (not sent).

=item StreamId

A client-initiated Identifier.  RFC3920 4.4 says that the stream id
SHOULD only be used from the receiving entity to the intiating entity.  
However, some applications may think otherwise.  Defaults to undef (not sent).

=item Timeout

The number of seconds to hang around whilst waiting for a connection to
succeed.  Defaults to 30.  Note that the time taken for connect may be
more than this, as the same value is used in the connection, SSL
negotiation and waiting for the remote server to respond phases.

Note that during the SSL negotiation, the application will block, due to 
the perl SSL libraries not obviously supporting a backgroundable method.

=item Version

The version to declare to the remote Jabber server.  The default, '1.0',
attempts to steer the conversation along the lines of RFC3920, xmpp-core.

=item SSL*

Any option beginning with 'SSL' will be passed to IO::Socket::SSL as-is,
which may be useful if you are expecting to exchange certificate 
information.  No values are set up by default.

=item OwnSocket

A boolean which indicates that a socket has previously been created by
methods unknown to this library, and stored via ->socket().  Thus, 
->connect doesn't actually have to do a TCP connection, and can just
continue on with the connection methods.

=back

Note for people with their own connection requirements: The ->connect
method is comparitively simple (ha!); just initiating a TCP connection and
setting up handlers to negotiate TLS.  Those wishing to set up their
own connection handlers are welcome to do so, but search this library's
code for the string 'grok incomplete' before doing so.

=cut

sub connect {
	my $self = shift;

	$self->debug( "connect: Starting up\n" );
	my %args = (	Host => undef,
			Port => 5222,
			Domain => undef,
			UseSSL => 0,		# Initiate SSL right away.
			UseTLS => 1,		# If found a <starttls> tag,
						# take them up on it.
			MustEncrypt => 0,	# Connection must be encrypted
						# before proceeding
			JustConnect => 0,	# Just connect, ok.
			JustConnectAndStream => 0, # Just connect and send the
						# opening <stream:stream> tag.
			AllowRedirect => 1,	# The domain that the server
						# returns must be the same
						# as the domain we supplied.
			StreamXMLNS => $self->ConstXMLNS( "client" ),
			StreamXMLLANG => undef,	# Default language.
			StreamId => undef,	# Client-side Id.  Optional.
			Timeout => 30,		# Various timeouts
			Version => "1.0",	# What version do we support?
			OwnSocket => 0,		# We have our own socket.
			_redo => 0,		# Used internally to renegotiate
						# due to SSL/TLS starting up.
			_connectbg => 0,	# Used internally as handover
						# from bgconnect.
			@_,
			);


	# Only one connection at a time.
	my $cango = 0;
	if( ! $args{"_redo"} ){

		if( ! $self->{"OwnSocket"} ){
			if( defined( $self->socket ) ){
				$self->disconnect();
			}
		}
		
		$self->{'_is_connected'} = undef;
		$self->{'_is_eof'} = undef;

		# Do you grok incomplete tags?  A stream to a Jabber server
		# is completely within a '<stream:stream>' tag, just a very
		# big one.  The problem is that this parser will only return
		# a complete tag, meaning that ordinarily, it would not
		# indicate that it had completed an object until the
		# server disconnected us, supplying the closing
		# '</stream:stream>' text.  By setting a tag name within
		# the '_expect-incomplete' hash, the parser will consider
		# the tag to be complete as soon as it sees a '>' character,
		# and will assume it was '/>' instead.  This makes logging on 
		# work much better.
		$self->{'_expect-incomplete'}{"stream:stream"} = 1;
		$self->debug( "connect: setting up incomplete as " . $self->{'_expect-incomplete'} . " X\n" );

		# Attempt to connect to the host.
		# Background connecting can be done via the tricks
		# shown in Cache::Memcached library, which supports
		# background connections.

		# Alternatively, we can forgo supplying the PeerAddr and
		# PeerPort when creating the socket, and continually
		# invoke the socket's ->connect method until it returns
		# something other than EINPROGRESS.  Thus, we get 
		# TCP connections in the background.  Yay!
		my $socket = undef;
		if( $args{"OwnSocket"} ){
			$socket = $self->socket();
		}else{
			$socket = new IO::Socket::INET ( PeerAddr => $args{"Host"},
						PeerPort => $args{"Port"},
						Proto => "tcp",
						MultiHomed => 1,
						Timeout => $args{"Timeout"},
						Blocking => 0,
						);
		}

		# Were we able to connect; ie, do we have a socket?
		if( defined( $socket ) ){
			$cango = 1;

			$self->{'_is_connected'} = 1;
			$self->{'_is_encrypted'} = undef;
			$self->{'_is_authenticated'} = undef;
			$self->{'_ask_encrypted'} = undef;

			# Save it.  Also sets up the IO::Select construct.
			$self->socket( $socket );
		}

	}elsif( defined( $self->socket() ) ){
		$cango = 1;
	}

	if( $cango ){
		# Start up SSL or TLS as required.
		# Has SSL been requested?
		if( ( $args{"UseSSL"} || $args{"MustEncrypt"} ) && ! $self->_check_val( '_is_encrypted') ){
			# Start SSL.
			my $gotssl = $self->_got_IO_Socket_SSL();

			if( $gotssl ){
				# We have to hand over the socket to the
				# IO::Socket::SSL library for conversion.
				$gotssl = 0;
				my %SSLHash = ();
				foreach my $kkey( keys %args ){
					next unless( $kkey =~ /^SSL/ );
					$SSLHash{"$kkey"} = $args{"$kkey"};
				}

				$self->debug( "connect: Starting up SSL\n" );
				my $newsock = IO::Socket::SSL->start_SSL( $self->socket,
								%SSLHash,
								);
				if( defined( $newsock ) ){
					$self->socket( $newsock );
					$gotssl = 1;
					$self->{'_is_encrypted'} = 1;
					$self->debug( "connect: Successfully started SSL\n" ) ;
				}else{
					$self->debug( "connect: Could not start SSL\n" );
				}
			}

			# If we could not open the ssl libraries or negotiate
			# an SSL connection, see if we consider this a failure.
			if( ! $gotssl && $args{"MustEncrypt"} ){
				$cango = 0;

				# Disconnect.
				# print STDERR "NO SSL AND MUST ENCRYPT!\n";
				$self->abort();
			}
		}
	}

	# Were we asked just to connect?
	if( $args{"JustConnect"} ){
		return( $cango );
	}

	# print STDERR "CONNECT1 HAS $cango\n";

	# Can we still go?  
	if( $cango ){
		# Output the initial tags.
		# RFC3920 11.4 says that implementations SHOULD supply
		# the opening text declaration (xml version/encoding)
		my $xmlobj = $self->newNode( "?xml" );
		$xmlobj->attr( "version", "1.0" );
		$self->send( $xmlobj );

		if( ! defined( $args{"Domain"} ) ){
			$args{"Domain"} = $args{"Host"};
		}

		my $streamobj = $self->newNode( "stream:stream", $args{"StreamXMLNS"} );
		$streamobj->attr( "xmlns:stream", $self->ConstXMLNS( "stream" ) );
		$streamobj->attr( "to", $args{"Domain"} );
		$streamobj->attr( "version", $args{"Version"} );

		if( defined( $args{"StreamXMLLANG"} ) ){
			$streamobj->attr( "xml:lang", $args{"StreamXMLLANG"} );
		}
		if( defined( $args{"StreamId"} ) ){
			$streamobj->attr( "id:lang", $args{"StreamId"} );
		}

		# We must send this object without a closing '/'.
		$cango = $self->send( $streamobj->toStr( GenClose => 0 ) );
	}

	# print STDERR "CONNECT2 HAS $cango\n";

	# Were we asked just to connect and send the initial stream headers?
	if( $args{"JustConnectAndStream"} ){
		return( $cango );
	}

	# We possibly have output the stream header.  Now, we have to wait
	# for a response.  Were we able to write?
	my $robj = undef;
	if( $cango ){
		# Set up the initial handlers.  This makes the whole connection
		# process read much better
		$self->register_handler( '?xml', sub { $self->_connect_handler(@_) }, "connect" );
		$self->register_handler( 'stream:stream', sub { $self->_connect_handler( @_ ) }, "connect" );
		$self->register_handler( 'stream:error', sub { $self->_connect_handler( @_ ) }, "connect" );
		$self->register_handler( 'stream:features', sub { $self->_connect_handler( @_ ) }, "connect" );
		$self->register_handler( 'proceed', sub { $self->_connect_starttls( @_ ) }, "connect" );
		$self->register_handler( 'failure', sub { $self->_connect_starttls( @_ ) }, "connect" );

		# Save the original args.
		%{$self->{'_connectargs'}} = %args;

		# Set some variables.
		$self->{'_is_connected'} = 1;
		$self->{'_is_authenticated'} = undef;
		$self->{'_connect_jid'} = undef;
		$self->{'confirmedns'} = undef;
		$self->{'streamid'} = undef;
		$self->{'streamversion'} = undef;
		$self->{'streamxmlns'} = undef;
		$self->{'streamxml:lang'} = undef;
		$self->{'streamstream:xmlns'} = undef;
		$self->{'stream:error'} = undef;
		$self->{'stream:features'} = undef;

		%{$self->{'authmechs'}} = ();

		# Wait until the connection checker finishes.
		if( ! $args{"_connectbg"} ){
			my $endtime = time + $args{"Timeout"};
			my $stillgoing = 1;
			while( $stillgoing ){
				$stillgoing = 0 if( time > $endtime );
				$self->debug( "connect: invoking bgconnected\n" );
				my $tval = $self->bgconnected( RunProcess => 1 );
				if( $tval >= 0 ){
					$cango = $tval;
					$stillgoing = 0;
				}else{
					select( undef, undef, undef, 0.01 );
				}
			}
		}
	}
	# print STDERR "CONNECT3 HAS $cango\n";

	if( ! $cango ){
		# print STDERR "CONNECT HAS NO CANGO!\n";
		$self->abort();
	}

	$self->debug( "connect: returning $cango\n" );
	return( $cango );
}

=head2 bgconnect

The ->bgconnect method is just the same as the ->connect method, except it 
returns straight away.  Use the ->bgconnected method to test for an answer
to that 4am question, am I connected or not?

Returns 1 if the TCP connection could be started, and 0 if not.  If this
method returns 0, you probably have bigger problems.

Note: The ->bgconnect method just calls ->connect with the background 
flag set.

=cut

sub bgconnect {
	my $self = shift;
	return( $self->connect( @_, "_connectbg" => 1 ) );
}

=head2 bgconnected

This tests to see whether the current connection has succeeded.  It 
returns -1 if not yet, 0 if failed (and socket has been closed) and
1 if successful.  It takes a hash of:

	RunProcess - Invoke ->process internally
	ProcessTime - time to pass to ->process (default 0 )

If RunProcess is not specified, you will have to invoke ->process()
seperately.

=cut

sub bgconnected {
	my $self = shift;
	my %args = ( RunProcess => 0,
			ProcessTime => 0,
			@_,
			);

	my $retval = -1;

	if( $args{"RunProcess"} ){
		$self->debug( "bgconnected: invoking process\n" );
		my $tval = $self->process( $args{"ProcessTime"} );
		$self->debug( "bgconnected: invoked process - $tval\n" );
		if( $tval == 1 ){
			my $objthrowaway = $self->get_latest();
			$objthrowaway->hidetree;
		}
	}

	$self->debug( "bgconnected: invoked\n" );

	# Test a few variables.
	if( $self->is_eof() ){
		$self->debug( "bgconnected: found eof\n" );
		# print STDERR ( "bgconnected: found eof\n" );
		$retval = 0;
	}elsif( $self->is_connected() > 0 ){
		$retval = 1;
		# If we wanted encryption, did we get encryption?
		if( $self->{'_connectargs'}{"MustEncrypt"} && ! $self->is_encrypted() ){
			$self->debug( "wanted encryption but no encryption\n");
			$retval = -1;

		# Have we asked for encryption to be started?
		}elsif( $self->_check_val( '_ask_encrypted' ) && ! $self->is_encrypted() ){
			$self->debug( " asked for encryption but no encryption\n" );
			$retval = -1;
		}

		# If we have got a reply host?
		if( $retval == 1 && $self->_check_val( "confirmedns" ) ){
			if( ! $self->{'_connectargs'}{"AllowRedirect"} ){
				if( lc( $self->{'confirmedns'} ) ne lc( $self->{'_connectargs'}{"Domain"} ) ){
					$self->debug( " domain mismatch\n" );
					# print STDERR ( "bgconnected: domain mismatch\n" );
					$retval = 0;
				}
			}
		}else{
			$self->debug( " retval is not 1 and we do not have a confirmedns yet\n");
			$retval = -1;
		}

		# All servers MUST provide a stream id value.
		if( $retval == 1 && ! $self->_check_val( 'streamid' ) ){
			$self->debug( " no streamid yet");
			$retval = -1;
		}

		# All 1.x servers MUST provide the stream:features tag.
		if( $retval == 1 && $self->_check_val( 'streamversion' ) ){
			if( $self->{'streamversion'} >= 1.0 && ! $self->_check_val( 'stream:features' ) ){
				$self->debug( " streamversion >= 1.0 but no stream:features yet");
				$retval = -1;
			}
		}

		# When using encryption or compression, it is possible that 
		# the encryption engine has not completely sent out the last 
		# packet that we sent.  Lets kick it.
		if( $retval == -1 ){
			if( ! defined( $self->{'_connecting_prod'} ) ){
				$self->{'_connecting_prod'} = time;
			}elsif( $self->{'_connecting_prod'} < ( time - 5 ) ){
				$self->debug( "prodding the connection" );
				$self->send( "\n" );
				$self->{'_connecting_prod'} = time;
			}
		}
	}else{
		$self->debug( " default set to 0\n");
		# print STDERR ( "bgconnected: default set to 0\n");
		$retval = 0;
	}

	$self->debug( " returning $retval\n");
	return( $retval );
}

=head1 METHODS - Authenticating

It helps if the remote server knows who you are.

=head2 authenticate

Attempt to authenticate to the Jabber server over a connected socket.  
It takes a hash of:

=over 4

=item Username

The username to authenticate as.

=item Password

The password to use.

=item Resource

Specify a resource method to use.  If a Resource is not specified, a 
default value of 'Jabber::Lite' is used.  Note that the Resource 
accepted by the server may be different; use ->connect_jid() to find
out what the server considers the Resource to be.

=item Domain

The domain to use if the authentication method requires it.  Defaults
to the value specified for ->connect().

=item ComponentSecret

The secret to use if authenticating as a component, or if the chosen
authentication method requires just a password, not a username.

=item Method

The preferred authentication method to use.  Either 'sasl' or 
'jabber:iq:auth'.  The default is 'jabber:iq:auth' (JEP-0078), unless 
the server has supplied a list of authentication mechanisms as per 
xmpp-core (RFC3920), in which case 'sasl' is used.

=item Mechanism

A preferred mechanism to use for authentication.  The library will try
to use any available mechanisms that are considered more secure than 
the one supplied, but should not try mechanisms that are considered 
less secure.  The mechanisms available, in order of highest security
to lowest, are:

=over 4

=item anonymous

=item digest-md5

=item plain

=back

=item DoBind

A boolean indicating whether to bind the nominated resource if so
requested by the remote server.  The default, 1, is for applications 
that do not wish to deal with this step, or for people for whom 
urn:ietf:params:xml:ns:xmpp-bind is at a significant altitude.  
If you know what you are doing, set this to 0, and be sure to read 
the ->bind() method.  Note that if the server requires binding, and 
this is not done, the server will most probably return a '<not-authorized>'
stanza back and disconnect (so says RFC3920 section 7).

=item DoSession

A boolean indicating whether to initiate a session if so requested
by the remote server.  The default, 1, is for applications that
do not wish to deal with this step, or for people for whom
urn:ietf:params:xml:ns:xmpp-session is at a significant altitude.
If you know what you are doing, set this to 0, and be sure to read
the ->session() method.  Note that if the server requires sessions, and
this is not done, the server will most probably return a '<not-authorized>'
stanza back and disconnect (so says RFC3921 section 3).

=item RandomResource

A boolean indicating whether a random Resource identifier can be used
in the case of conflicts.  Defaults to 0.

=back

It returns 1 on success, and 0 on failure.

=cut

sub authenticate {
	my $self = shift;
	my %args = (	Username => undef,
			Password => undef,
			Resource => undef,
			ComponentSecret => undef,
			Domain => $self->{'_connectargs'}{'Domain'},
			Method => undef,
			Mechanism => undef,
			Timeout => 30,
			Idval => rand(65535) . $$ . rand(65536),
			DoBind => 1,
			DoSession => 1,
			AllowRandom => 0,
			_authbg => 0,
			@_,
			);

	my $retval = 0;

	if( ! defined( $args{"Resource"} ) ){
		# set a default value.
		$args{"Resource"} = "Jabber::Lite";
	}

	# See if we should add jabber:iq:auth method, in addition to 
	# what the server supplied.
	if( defined( $args{"Method"} ) ){
		if( $args{"Method"} eq "jabber:iq:auth" ){
			$self->{'authmechs'}{"jabber:iq:auth"} = "1";
		}
	}

	# This sets up a number of handlers to perform the authentication.
	# Set up the initial behaviour.
	$self->{'_ask_handshake'} = undef;
	$self->{'_got_handshake'} = undef;
	$self->{'_ask_iq_auth'} = undef;
	$self->{'_got_iq_auth'} = undef;
	$self->{'_started_auth'} = undef;
	$self->{'_done_auth_sasl'} = undef;
	$self->{'_auth_failed'} = undef;
	$self->{'_auth_finished'} = undef;
	$self->{'saslclient'} = undef;

	# Store the orginal arguments.  bgconnected wipes these when
	# it returns success or failure to avoid leakage.
	%{$self->{'_authenticateargs'}} = %args;

	# Prime listauths to send the initial packet asking for authentication
	# methods, if jabber:iq:auth is one of the options, and we haven't
	# been explicitly constrained to use sasl.  Yes, this does mean that
	# we might send an unneeded packet, but we don't care.
	my $doask = 1;
	if( defined( $args{"Method"} ) ){
		if( $args{"Method"} eq "sasl" ){
			$doask = 0;
		}
	}

	# Do not ask the question if we're authenticating as a 
	# component.
	if( defined( $args{"ComponentSecret"} ) && $self->_check_val( 'streamxmlns' ) ){
		# Make sure the server is expecting a component connection.
		if( $self->{'streamxmlns'} eq $self->ConstXMLNS( 'component' ) ){
			$doask = 0;
			# Request component authorisation.
			$self->{'_ask_handshake'} = time;
		}
	}

	# Ask away.
	if( $doask ){
		# print STDERR "AUTHENTICATE IS ASKING FOR AUTHS\n";
		$self->listauths( Want => 'dontcare', Username => $args{"Username"}, JustAsk => 1 );

		# If we did ask, set up a handler for the response.
		if( $self->_check_val( '_ask_iq_auth' ) ){
			$self->debug( "Asked for auths, setting up handler" );
			# print STDERR ( "Asked for auths, setting up handler" );
			$self->register_handler( "iq", sub { $self->_listauths_handler( @_ ) }, "authenticate" );
		}
	}

	# Exit if we've been told to.  Client will invoke bgauthenticated
	# themselves.
	if( $self->{'_authbg'} ){
		$self->debug( "client to execute bgauthenticated\n");
		return( -1 );
	}

	# Wait for bgauthenticate to do its work.
	my $stillgoing = 1;
	my $endtime = time + $args{"Timeout"};
	while( $stillgoing ){
		$stillgoing = 0 if( time > $endtime );

		$self->debug( "looping on bgauthenticated\n");
		my $tval = $self->bgauthenticated( RunProcess => 1 );

		if( $tval == 0 ){
			$stillgoing = 0;
			# print STDERR "BGAUTHENTICATED RETURNED 0!\n";
			$retval = 0;
		}elsif( $tval == 1 ){
			$stillgoing = 0;
			$retval = 1;
			$self->{'_is_authenticated'}++;
		}else{
			select( undef, undef, undef, 0.01 );
		}
	}

	return( $retval );
}
			

=head2 bgauthenticate

This accepts the same arguments as ->authenticate(), but returns after
sending the initial packets required to start the authentication 
steps.

Note: This method will block on older servers where ->listauths() has to
ask for a packet.

=cut

sub bgauthenticate {
	my $self = shift;
	return( $self->authenticate( @_, "_authbg" => 1 ) );
}

=head2 bgauthenticated

This tests to see whether the current authentication steps have succeeded.  
It returns -1 if not yet, 0 if failed and 1 if successful.  It takes a 
hash of:

	RunProcess - Invoke ->process internally
	ProcessTime - time to pass to ->process (default 0 )

If RunProcess is not specified, you will have to invoke ->process()
seperately.

=cut

sub bgauthenticated {
	my $self = shift;
	my %args = ( RunProcess => 0,
			ProcessTime => 0,
			@_,
			);

	my $retval = 1;

	my $authas = "client";

	if( $args{"RunProcess"} ){
		$self->debug( "invoking process\n");
		my $tval = $self->process( $args{"ProcessTime"} );
		$self->debug( "invoked process - $tval\n");
		if( $tval == 1 ){
			my $objthrowaway = $self->get_latest();
			$objthrowaway->hidetree;
		}elsif( $tval < 0 ){
			# print STDERR "BGAUTHENTICATED GOT $tval FROM process\n";
			$retval = 0;
		}
	}

	# Start considering the options.  Client authentication.
	my %availableauths = ();
	if( $self->_check_val( '_ask_iq_auth' ) ){
		if( ! $self->_check_val( '_got_iq_auth' ) ){
			$retval = -1;
		}
	}

	# Component checking.
	if( $retval && $self->_check_val( '_ask_handshake' ) ){
		$authas = "component";
		if( ! $self->_check_val( '_started_auth' ) ){
			$self->{'_started_auth'} = time;

			# This is JEP 114 stuff.
			my $handshake = $self->newNode( 'handshake' );
			my $gotdsha1 = $self->_got_Digest_SHA1();
			if( $gotdsha1 ){
				$handshake->data( lc( Digest::SHA1::sha1_hex( $self->{'streamid'} . $self->{'_authenticateargs'}{'ComponentSecret'} ) ) );
			}
			$self->send( $handshake );
			$self->register_handler( "handshake", sub { $self->_bgauthenticated_handler( @_ ) }, "authenticate" );
		}

		if( $self->_check_val( '_got_handshake' ) ){
			# XXXX - This is possibly incorrect.  
			# print STDERR "bgauthenticated: _got_handshake set, setting _auth_finished and retval to 1\n";
			$self->{'_auth_finished'} = 1;
			$retval = 1;
		}elsif( $self->_check_val( 'stream:error' ) ){
			$self->{'_auth_finished'} = 0;
			# If the wrong secret was supplied, then we disconnect.
			$self->debug( "GOT stream:error" );
			$retval = 0;
		}else{
			$retval = -1;
		}
	}

	if( $retval == 1 && ! $self->_check_val( '_started_auth' ) ){
		%availableauths = $self->listauths( Want => 'hash' );

		my $chosenauth = undef;
		my %rauths = ();
		my $somesasl = 0;

		# Strain out the auths that are not suitable.
		foreach my $kkey( keys %availableauths ){
			my $tkey = lc( $kkey );
			$self->debug( " Found auth $kkey\n");
			# print STDERR ( " Found auth $kkey\n");

			my $jiqauth = 0;

			if( defined( $self->{'_authenticateargs'}{"Method"} ) ){
				my $mtest = lc( $self->{'_authenticateargs'}{"Method"} );
				next unless( $kkey =~ /^$mtest\-/ );

				$jiqauth = 1 if( $kkey eq "jabber:iq:auth" );
			}

			if( defined( $self->{'_authenticateargs'}{"Mechanism"} ) ){
				my $mtest = lc( $self->{'_authenticateargs'}{"Mechanism"} );

				# Remap the name if preferring jabber:iq:auth
				# TODO 0.9 - Check this logic.
				# if( $jiqauth ){
					# $mtest = "token" if( $mtest eq "anonymous" );
					# $mtest = "digest" if( $mtest eq "digest-md5" );
					# $mtest = "password" if( $mtest eq "plain" );
# 
				# }
				next unless( $kkey =~ /^[^\-\]\-$mtest$/ );
			}

			# Bypass the 'sequence' tag; we catch the 'token' tag 
			# instead.
			next if( $tkey =~ /^jabber:iq:auth\-sequence$/i );

			# Get a score for the auth.
			$rauths{lc($tkey)}++;

			# print STDERR " Using $tkey?\n";

			if( $tkey =~ /^sasl\-/ ){
				$somesasl++;
			}
		}

		# Prepare possible packets to send.
		my $saslxmlns = $self->ConstXMLNS( "xmpp-sasl" );
		my $saslpkt = $self->newNode( "auth", $saslxmlns );

		my $idval = rand(65535) . $$ . rand(65536);
		my $iqpkt = $self->newNode( "iq" );
		$iqpkt->attr( 'type', 'set' );
		$iqpkt->attr( 'to', $self->{'_authenticateargs'}{"Domain"} );
		$iqpkt->attr( 'id', $idval );
		my $querytag = $iqpkt->insertTag( 'query', "jabber:iq:auth" );
		my $utag = $querytag->insertTag( 'username' );
		$utag->data( $self->{'_authenticateargs'}{"Username"} );
		my $rtag = $querytag->insertTag( 'resource' );
		$rtag->data( $self->{'_authenticateargs'}{"Resource"} );

		# See what libraries have been installed.  Try to load
		# both Digest::SHA1 and Authen::SASL.  If we can't load
		# Authen::SASL, then we fall back on Digest::SHA1, then
		# to plain, if we haven't eliminated it by a supplied
		# Method or Mechanism, and the server has provided
		# the 'plain' mechanism.  Phew.
		my $gotdsha1 = $self->_got_Digest_SHA1();
		my $gotasasl = $self->_got_Authen_SASL();
		my $gotmba64 = $self->_got_MIME_Base64();

		# Run through the auths known or approved.
		my $sendsasl = 0;
		my $sasl = undef;
		my $sendiq = 0;
		my $usedauth = undef;

		# We let Authen::SASL do the work.
		if( $somesasl && $gotasasl && $gotmba64 ){
			my @mechs = ();
			foreach my $kkey( keys %rauths ){
				next unless( $kkey =~ /^sasl\-(\S+)$/i );
				push @mechs, uc( $1 );
			}

			# Set up the Authen::SASL handle.  Copied from
			# XML::Stream
			$sasl = Authen::SASL->new( mechanism => join( " ", @mechs ),
						   callback => {
							authname => $self->{'_authenticateargs'}{"Username"} . "@" . $self->{'_authenticateargs'}{"Domain"},
							user => $self->{'_authenticateargs'}{"Username"},
							pass => $self->{'_authenticateargs'}{"Password"},
							},
						);
			$self->{'_saslclient'} = $sasl->client_new();

			my $first_step = $self->{'_saslclient'}->client_start();
			my $first_step64 = MIME::Base64::encode_base64( $first_step, "" );
			$saslpkt->attr( 'mechanism', $self->{'_saslclient'}->mechanism() );
			$saslpkt->data( $first_step64 );

			$sendsasl++;

		}elsif( defined( $rauths{"jabber:iq:auth-token"} ) && $gotdsha1 && 1 == 2 ){
			# zero knowledge.  We snarf the original values.
			# Copied from Jabber::Connection.  This code does not 
			# work against my server, so is disabled.
			$sendiq++;
			$usedauth = "jabber:iq:auth-zerok";
			my $htag = $querytag->insertTag( 'hash' );
			my $hval = DIGEST::SHA1::sha1_hex( $self->{'Password'} );
			my $seq = $availableauths{"jabber:iq:auth-sequence"};
			my $token = $availableauths{"jabber:iq:auth-token"};
			$self->debug( " Got seq of $seq and $token X\n");
			$hval = Digest::SHA1::sha1_hex( $hval . $token );
			# Aie! Keep hashing until sequence decremented to 0??
			$hval = Digest::SHA1::sha1_hex( $hval ) while( $seq-- );
			$htag->data( $hval );

		}elsif( defined( $rauths{"jabber:iq:auth-digest"} ) && $gotdsha1 ){
			# digest
			$sendiq++;
			$usedauth = "jabber:iq:auth-digest";
			my $dtag = $querytag->insertTag( 'digest' );
			$dtag->data( Digest::SHA1::sha1_hex( $self->{'streamid'} . $self->{'_authenticateargs'}{"Password"} ) );
		}elsif( defined( $rauths{"jabber:iq:auth-password"} ) ){
			# plain password.
			$sendiq++;
			$usedauth = "jabber:iq:auth-plain";
			my $ptag = $querytag->insertTag( 'password' );
			$ptag->data( $self->{'_authenticateargs'}{"Password"} );
		}

		if( $sendsasl ){		
			$self->debug( "bgauthenticate: Sending sasl packet: " . $saslpkt->toStr . "\n" ) if( $self->_check_val( '_debug' ) );
			$self->send( $saslpkt );
			$self->{'_started_auth'} = "sasl";
			$retval = -1;
			$self->register_handler( "failure", sub { $self->_bgauthenticated_handler( @_ ) }, "authenticate" );
			$self->register_handler( "success", sub { $self->_bgauthenticated_handler( @_ ) }, "authenticate" );
			$self->register_handler( "challenge", sub { $self->_bgauthenticated_handler( @_ ) }, "authenticate" );

		}elsif( $sendiq ){
			$self->debug( "bgauthenticate: Sending iq packet: " . $iqpkt->toStr . "\n" ) if( $self->_check_val( '_debug' ) );
			# print STDERR "Sending " . $iqpkt->toStr . "\n";
			$self->send( $iqpkt );
			$self->{'_started_auth'} = "iq-auth";

			# Say that we attempted authentication.
			$self->{'_sent_iq_auth'} = $idval;
			$retval = -1;

			# Set up a handler for this.
			$self->register_handler( "iq", sub { $self->_bgauthenticated_handler( @_ ) }, "authenticate" );
		}else{
			# We haven't been able to choose an authentication method.
			$self->debug( "INDECISIVE RE AUTH METHODS" );
			$retval = 0;
		}

	}elsif( $retval == 1 && $self->_check_val( '_started_auth' ) && $self->_check_val( "_sent_iq_auth" ) && $authas eq "client" ){
		# See if the value is set.

		if( $retval == 1 && $self->_check_val( '_auth_finished' ) ){
			$retval = $self->{'_auth_finished'};

		}

	}elsif( $retval == 1 && $self->_check_val( '_started_auth' ) && $authas eq "client" && ! $self->_check_val( '_auth_failed' ) ){

		# Check to see if we are waiting on the server to
		# reissue the <stream:stream> tag.
		if( $self->_check_val( '_need_auth_stream' ) ){
			if( $self->bgconnected != 1 ){
				$self->debug( "Waiting on auth stream" );
				$retval = -1;
			}
		}

		# Now, check to see if we need to set up resource binding.
		# if( $retval == 1 && ! $self->_check_val( '_need_auth_bind' ) && ! $self->_check_val( '_auth_finished' ) ){
		if( $retval == 1 && ! $self->_check_val( '_need_auth_bind' ) ){
			# Do we need to do the binding?
			if( $self->{'_authenticateargs'}{"DoBind"} ){
				$retval = $self->bind( Process => "if-required", Resource => $self->{'_authenticateargs'}{"Resource"}, AllowRandom => $self->{'_authenticateargs'}{"RandomResource"}, _bindbg => 1 );
			}else{
				$self->{'_done_auth_bind'} = 1;
			}
			$self->debug("Waiting on bind result" );
			$retval = -1;
		}elsif( $retval == 1 && $self->_check_val( '_need_auth_bind' ) && ! $self->_check_val( '_done_auth_bind' ) ){
			# Have we got the results from the bind back?
			$retval = -1;
			$self->debug( " checking result of bgbinded\n");
			if( $self->bgbinded() == 1 ){
				$retval = 1;
			}
		}

		# How about sessions?
		$self->debug( "About to check on session? retval is $retval, _need_auth_session is " . $self->_check_val( '_need_auth_session' ) . ", _auth_finished is " . $self->_check_val( '_auth_finished' ) . " E " );
		# if( $retval == 1 && ! $self->_check_val( '_need_auth_session' ) && ! $self->_check_val( '_auth_finished' ) ){
		if( $retval == 1 && ! $self->_check_val( '_need_auth_session' ) ){
			# Do we need to do the binding?
			$self->debug( " need session?" );
			if( $self->{'_authenticateargs'}{"DoSession"} ){
				$retval = $self->session( Process => "if-required", _sessionbg => 1 );
			}else{
				$self->{'_done_auth_session'} = 1;
			}
			$self->debug("Waiting on session result" );
			$retval = -1;
		# }elsif( $retval == 1 && $self->_check_val( '_need_auth_session' ) && ! $self->_check_val( '_auth_finished' ) ){
		}elsif( $retval == 1 && $self->_check_val( '_need_auth_session' ) ){
			# Have we got the results from the bind back?
			$retval = -1;
			$self->debug( " checking result of bgsessioned\n");
			if( $self->bgsessioned() == 1 ){
				$retval = 1;
			}
		}

		if( $retval == 1 && $self->_check_val( '_auth_finished' ) ){
			$retval = $self->{'_auth_finished'};

			# Make sure we record that we were authenticated.
			if( $retval > 0 ){
				$self->{'_is_authenticated'} = 1;
			}

		}elsif( ! $self->_check_val( '_auth_finished' ) ){
			# print STDERR "BGAUTHENTICATED IS UNKNOWN\n";
			$self->debug( "unknown condition - retval is 1 but _auth_finished is not set" );
			$retval = -1;
		}
	}elsif( $retval == 1 && $self->_check_val( '_started_auth' ) && $authas eq "client" && $self->_check_val( '_auth_failed' ) ){
		$retval = 0;
		$self->{'_is_authenticated'} = undef;
	}

	if( $retval >= 0 ){
		# Success or failure.  

		# Set the connect jid if required.
		if( $retval > 0 && ! defined( $self->{'_connect_jid'} ) ){
			# Save the connect_jid.
			$self->{'_connect_jid'} = $self->{'_authenticateargs'}{'Username'} . "@" . $self->{'_authenticateargs'}{"Domain"};
			if( defined( $self->{'_authenticateargs'}{"Resource"} ) ){
				$self->{'_connect_jid'} .= "/" . $self->{'_authenticateargs'}{"Resource"};
			}
		}

		# Delete the authenticate args
		delete( $self->{'_authenticateargs'} );
	}

	$self->debug( "Returning with $retval" );
	return( $retval );
}

sub _bgauthenticated_handler {
	my $self = shift;
	my $node = shift;
	my $persisdata = shift;

	my $retval = undef;

	$self->debug( "invoked\n" );
	my $sendtype = $self->{'_started_auth'};

	if( defined( $node ) && defined( $sendtype ) ){
		my $saslxmlns = $self->ConstXMLNS( 'xmpp-sasl' );

		if( $node->name eq 'handshake' ){
			# Handshake is empty if all good.
			if( $self->_check_val( '_ask_handshake' ) ){
				$self->{'_got_handshake'} = time;
				$retval = r_HANDLED;
			}
			$self->debug( "got " . $node->toStr . " X \n" ) if( $self->_check_val( '_debug' ) );
		}elsif( $sendtype eq "iq-auth" && $node->name eq 'iq' ){
			my $idval = $self->{'_sent_iq_auth'};
			$self->debug( "got back iq result - want $idval" );
			# print STDERR ( "got back iq result (" . $node->attr('id') . ") - want $idval " . $node->toStr . "\n" );
			if( defined( $idval ) ){
				if( $node->attr('id') eq $idval ){
					$retval = r_HANDLED;
					if( $node->attr('type') eq 'result' ){
# XXXX - check for error here??
						$self->debug( "got back iq result - auth successful?" );
						$self->{'_auth_finished'} = 1;
						$self->{'_connect_jid'} = $self->{'_authenticateargs'}{'Username'} . "@" . $self->{'_authenticateargs'}{"Domain"};
						if( defined( $self->{'_authenticateargs'}{"Resource"} ) ){
							$self->{'_connect_jid'} .= "/" . $self->{'_authenticateargs'}{"Resource"};
						}
					}else{
						# Not successful.
						$self->debug( "got back iq something, auth not successful." );
						$self->{'_auth_finished'} = 0;
						$self->{'_auth_failed'} = 1;
					}
				}
			}

			# No?  Maybe its the next step in the sasl 
			# authentication.
		}elsif( $sendtype eq "sasl" ){
			if( ( $node->name eq 'failure' || $node->name eq 'abort' ) && $node->xmlns() eq $saslxmlns ){
				# Failed to authenticate.  Return 0 to
				# the caller; note that the connection
				# is still in place (RFC3920 6.2).
				# 'abort' is slightly odd here, in that
				# we are the initiating entity, but
				# just in case we're talking to some
				# braindead server...
				$self->{'_auth_finished'} = 0;
				$self->{'_done_auth_sasl'} = 1;
				$self->{'_auth_failed'} = 1;
				$retval = r_HANDLED;
			}elsif( $node->name eq 'success' && $node->xmlns() eq $saslxmlns ){
				# We've succeeded.
				$self->{'_auth_finished'} = 1;
				$self->{'_done_auth_sasl'} = 1;
				$self->{'_auth_failed'} = undef;
				$retval = r_HANDLED;

				# We need to resend the initial 
				# '<stream:stream>' header (RFC3920 6.2) again.
				# If we've done SSL, that means that we'll have
				# done 3 so far.  We re-use bgconnected to test
				# for the appearance of the <stream:features> 
				# tag again;  Remember that those connect 
				# handlers are still set up.
				$self->{'stream:features'} = undef;

				# Implementation bug: Missing the domain 
				# ('to') from the <stream:stream> tag after 
				# successful SASL authentication results in 
				# jabberd2's c2s component dying.  
				$self->connect( '_redo' => 1, JustConnectAndStream => 1, Domain => $self->{'_authenticateargs'}{"Domain"} );
				$self->{'_need_auth_stream'} = 1;

			}elsif( $node->name eq 'challenge' && $node->xmlns() eq $saslxmlns ){
				$retval = r_HANDLED;
				my $ctext64 = $node->data();
				my $ctext = MIME::Base64::decode_base64( $ctext64 );
				my $rtext = "";
				# XML::Stream notes that a challenge
				# containing 'rspauth=' is essentially
				# a no-op; we've successfully authed.
				# Authen::SASL whinges about it though.
				if( $ctext !~ /rspauth\=/ ){
					$rtext = $self->{'_saslclient'}->client_step( $ctext );
				}
				my $rtext64 = MIME::Base64::encode_base64( $rtext , "" );
				my $saslpkt = $self->newNode( 'response', $saslxmlns );
				$saslpkt->data( $rtext64 );
				$self->send( $saslpkt );
			}
		}
	}

	return( $retval );
}

=head2 auth

This is the Jabber::Connection compatibility call.  It takes 1 or 3 arguments,
being either the shared password (for use when connecting as a component),
or the username, password and resource.  It returns 1 if successful, 0
if unsuccessful.  

=cut

sub auth {
	my $self = shift;
	my $username = shift;
	my $password = shift;
	my $resource = shift;

	my $retval = 0;

	if( ! defined( $password ) ){
		$retval = $self->authenticate( ComponentSecret => $username );
	}else{
		$retval = $self->authenticate(	Username => $username,
						Password => $password,
						Resource => $resource,
						);
	}

	return( $retval );
}

=head2 AuthSend

This is the Net::XMPP::Protocol/Net::Jabber::Component compatibility call.  
It takes a hash of 'username', 'password' and 'resource', or "secret" and 
returns a @list of two values, being a success ('ok')/failure string, and 
a message.  Note that apart from 'ok', the success/failure string may not 
be the same as returned by the Net::XMPP libraries.

=cut

sub AuthSend {
	my $self = shift;
	my %args = (	username => undef,
			password => undef,
			resource => undef,
			secret => undef,
			@_,
			);

	my $retval = "not ok";
	my $retmsg = "Reason unknown";

	my $tval = $self->authenticate(	Username => $args{"username"},
					Password => $args{"password"},
					Resource => $args{"resource"},
					ComponenetSecret => $args{"secret"},
					);

	if( $tval == 1 ){
		$retval = "ok";
		$retmsg = "authentication successful, happy jabbering";
	}elsif( $tval == 0 ){
		$retval = "not ok";
		$retmsg = "authenticate returned 0";
	}

	return( $retval, $retmsg );
}

=head1 METHODS - Dealing with <stream:features>

Some incidental things.

=head2 stream_features

This method returns the latest <stream:features> tag received from the
server, or undef.  It is used internally by the ->bind and ->session methods.

Note that during the ->connect() and ->authenticate() phases, certain of
these features may get 'used', and thus not returned by the server the
next time it issues a <stream:features> tag.

=cut

sub stream_features {
	my $self = shift;

	return( $self->{'stream:features'} );
}

=head2 listauths

This method lists the authentication methods available either to the library
or provided by this Jabber server by way of <stream:features>.  An optional 
hash may be provided, where 'Ask' triggers the asking of the server for 
authentication information according to the 'jabber:iq:auth' namespace 
(JEP-0078), with the optional 'Username' being supplied as required.

The return value is either an @array or %hash of possible authentication 
methods and mechanisms depending on the 'Want' option ('array' or 'hash'), 
arranged as per 'method-mechanism', eg 'sasl-digest-md5' or 
'jabber:iq:auth-plain'.  

This method should be called after ->connect(), obviously.

Note: If Ask (or JustAsk) is specified, this method will call ->process, 
until it gets the reply it is expecting.  If other packets are expected
during this time, use ->register_handler to set up callbacks for them,
making sure that any <iq> packets in the
'jabber:iq:auth' namespace (<query> subtag) are not swallowed.

=cut

# This method gets called by ->authenticate, and is mainly useful
# for finding out jabber:iq:auth methods.
sub listauths {
	my $self = shift;
	my %args = ( Username => undef,
			Domain => $self->{'_connectargs'}{'Domain'},
			Ask => 0,		# Whether to ask the server.
			JustAsk => 0,		# Used by ->authenticate.
			Want => 'hash',		# The return type.
			Timeout => 30,		# How long to wait for
						# a valid answer.
			_internalvar => 0,	# Preparation to doing
						# a handler-based method.
			HaveAsked => 0,		# This is not used yet.
			Idval => rand(65535) . $$ . rand(65536),
			@_,
			);

	my @retarr = ();
	my %rethash = ();
	my %retint = ();

	# Run through the listings that we have cached.  If we have
	# a Username, and 'jabber:iq:auth' is in the listing, set up
	# a handler and send off a question.
	my $stillgoing = 1;
	my $havesent = $args{"HaveAsked"};
	my $gotans = 0;

	# Work out a random identifier if required.
	my $idval = $args{"Idval"};
	my $endtime = time + $args{"Timeout"};
	my $deliqauth = 0;
	while( $stillgoing && time < $endtime ){
		$stillgoing = 0;
		foreach my $thisauth ( keys %{$self->{'authmechs'}} ){
			$self->debug( " Found auth $thisauth\n" );
			if( $thisauth eq 'jabber:iq:auth' ){
				if( ( $args{"Ask"} || $args{"JustAsk"} ) && ! $havesent ){
					# Send off the query.
					my $sendpkt = $self->newNode( "iq" );
					$sendpkt->attr( 'type', 'get' );
					$sendpkt->attr( 'id', $idval );
					$sendpkt->attr( 'to', $args{"Domain"} );
					my $querytag = $sendpkt->insertTag( 'query', 'jabber:iq:auth' );
					if( defined( $args{"Username"} ) ){
						my $utag = $querytag->insertTag( 'username' );
						$utag->data( $args{"Username"} );
					}
					$self->{'_ask_iq_auth'} = $idval;
					$self->debug( "Asking about authentication methods" );
					$havesent = $self->send( $sendpkt );
					$stillgoing = 1 if( ! $self->{"JustAsk"} );
					$self->{'_authask'} = $idval;
				}elsif( $args{"Ask"} && $havesent && ! $gotans ){
					$stillgoing = 1;

					# Invoke ->process to see if we got 
					# something.

					# XXXX This is the only place we
					# collect an object directly during the
					# authentication process, and thats
					# only if 'JustAsk' is not specified.
					$self->debug( "looping for result\n");
					my $tval = $self->process( 1 );
					my $tobj = undef;
					my $querytag = undef;
					if( $tval == 1 ){
						$tobj = $self->get_latest();
					}

					# We hand the processing off to the
					# normal handler function for this
					# packet type manually.  This is only 
					# relevant if 'Ask' is specified.
					if( defined( $tobj ) ){
						my $tval = $self->_listauths_handler( $tobj, undef );
						if( defined( $tval ) ){
							if( $tval eq r_HANDLED ){
								$gotans++;
								$deliqauth++;
							}
						}
						$tobj->hidetree;
					}
				}
			}else{
				$rethash{"$thisauth"} = $self->{"authmechs"}{"$thisauth"};
			}
		}
	}

	# Delete the 'jabber:iq:auth' string from the available authentication
	# mechanisms, to avoid retriggering the same query/response pattern 
	# if this is used later.  Would probably screw something up then.
	if( $deliqauth ){
		delete( $self->{'authmechs'}{'jabber:iq:auth'} );
	}

	# Find out if an @array is wanted in response.
	if( $args{"Want"} eq "array" ){
		foreach my $thisauth( keys %rethash ){
			$self->debug( " Array? Sending back $thisauth as " . $rethash{"$thisauth"} . " X \n" );
			push @retarr, $thisauth;
		}
		return( @retarr );
	}elsif( $args{"Want"} eq "hash" ){
		foreach my $thisauth( keys %rethash ){
			$self->debug( " Hash? Sending back $thisauth as " . $rethash{"$thisauth"} . " X \n" );
		}
		return( %rethash );
	}
}

sub _listauths_handler {
	my $self = shift;
	my $node = shift;
	my $persisdata = shift;
	my $retval = undef;
	my $gotans = 0;

	$self->debug( "invoked\n" );
	my $idval = $self->{'_ask_iq_auth'};
	if( defined( $node ) && defined( $idval ) ){
		my $querytag = undef;
		if( $node->name() eq 'iq' && $node->attr('id') eq $idval ){
			if( $node->attr( 'type' ) eq 'result' ){
				# Get the query tag.
				$querytag = $node->getTag( 'query', 'jabber:iq:auth' );
				$gotans++;
			}elsif( $node->attr( 'type' ) eq 'error' ){
				# Don't we need to set something for negative?
				$self->{'_got_iq_auth'} = time;
				$retval = r_HANDLED;
			}
		}

		# Run through the list that we
		# received in response.
		if( defined( $querytag ) ){
			$retval = r_HANDLED;
			foreach my $cnode( $querytag->getChildren() ){
				$self->debug( "Received back " . $cnode->name . "\n" );
				next if( lc($cnode->name) =~ /^(username|resource)$/i );
				$self->{"authmechs"}{"jabber:iq:auth-" . lc( $cnode->name() )}++;
				# Special case.
				if( lc($cnode->name) =~ /^(token|sequence)$/i ){
					$self->{"authmechs"}{"jabber:iq:auth-" . lc( $cnode->name() )} = $cnode->data();
				}
				# $deliqauth++;
				$self->{'_got_iq_auth'} = time;
			}
		}
	}
	return( $retval );
}

=head2 session

Starts a session with the remote server, if required by the <stream:features>
packet.  Called internally by ->authenticate() if DoSession is set as the 
default '1'.  Takes an optional hash of:

=over 4

=item Process

A string of either 'if-required' or 'always', indicating whether to always
do so, or just if required to do so.

=back

Returns 1 if successful, 0 otherwise. 

=cut

sub session {
	my $self = shift;
	my %args = (	Process => "if-required",
			Timeout => 60,
			_sessionbg => 0,
			@_,
			);

	my $retval = 0;

	# See if we have to do this.
	my $doso = 0;
	if( $args{"Process"} eq "if-required" ){
		my $stag = $self->stream_features();
		if( defined( $stag ) ){
			my $btag = $stag->getTag( "session", $self->ConstXMLNS( "xmpp-session" ) );
			if( defined( $btag ) ){
				# We got the tag.  We must do this.
				$doso = 1;
			}
		}
	}elsif( $args{"Process"} eq "always" ){
		# We don't care.
		$doso = 1;
	}

	# Do we get to go? 
	my $stillgoing = 0;
	if( $doso ){

		# Send the initial packet.
		my $idval = rand(65535 . time );
		my $iqpkt = $self->newNode( 'iq' );
		$iqpkt->attr( 'id', $idval );
		$iqpkt->attr( 'type', 'set' );
		$iqpkt->attr( 'to', $self->{'_authenticateargs'}{"Domain"} );
		my $bindtag = $iqpkt->insertTag( 'session', $self->ConstXMLNS( 'xmpp-session' ) );

		$self->{'_need_auth_session'} = $idval;
		$self->{'_done_auth_session'} = undef;
		$stillgoing = $self->send( $iqpkt );
		$self->register_handler( 'iq', sub { $self->_session_handler(@_) }, "authenticate" );
		%{$self->{'_sessionargs'}} = %args;
	}

	if( $doso && $stillgoing ){
		if( ! $args{"_sessionbg"} ){
			my $endtime = time + $args{"Timeout"};

			while( $stillgoing ){
				$stillgoing = 0 if( time > $endtime );
				my $tval = $self->bgsessioned( RunProcess => 1 );
				if( $tval >= 0 ){
					$stillgoing = 0;
					$retval = $tval;
				}
			}
		}else{
			$retval = -1;
		}
	}

	return( $retval );
}

=head2 bgsessioned

Checks to see if the session establishment has completed,
returning -1 on still going, 0 on refused and 1 on success.

=cut

sub bgsessioned {
	my $self = shift;
	my %args = ( RunProcess => 0,
			ProcessTime => 0,
			@_,
			);

	my $retval = -1;

	if( $args{"RunProcess"} ){
		$self->debug( " invoking process\n" );
		my $tval = $self->process( $args{"ProcessTime"} );
		$self->debug( " invoked process - $tval\n" );
		if( $tval == 1 ){
			my $objthrowaway = $self->get_latest();
			$objthrowaway->hidetree;
		}
	}

	if( $self->_check_val( '_done_auth_session' ) ){
		$retval = $self->{'_done_auth_session'};
	}
	return( $retval );
}

sub _session_handler {
	my $self = shift;
	my $node = shift;
	my $persisdata = shift;

	$self->debug( "invoked\n" );
	my $retval = undef;
	my $idval = $self->{'_need_auth_session'};

	if( defined( $node ) && defined( $idval ) ){
		if( $node->name() eq 'iq' ){
			if( $node->attr( 'id' ) eq $idval ){
				$retval = r_HANDLED;
				$self->{'_done_auth_session'} = 1;

				# XXXX This needs fixing up.
				if( $node->attr( 'type' ) eq 'result' ){
					# Search for the session and jid tag.
					my $btag = $node->getTag( "session", $self->ConstXMLNS( "xmpp-session" ) );
					if( defined( $btag ) ){
						# Finished.
					}
				}elsif( $node->attr( 'type' ) eq 'error' ){
					# What error?
					my $etag = $node->getTag( "error" );
					if( defined( $etag ) ){
						my $notallowed = $etag->getTag( 'not-allowed' );
						my $conflict = $etag->getTag( 'conflict' );
						my $badreq = $etag->getTag( 'bad-request' );
						if( ( $etag->type eq 'modify' && defined( $badreq ) ) || ( $etag->type eq 'cancel' && defined( $conflict ) ) ){
						}elsif( $etag->type eq 'cancel' ){
							# Foo.
						}
					}
				}
			}
		}
	}

	# Mild cleanup.
	if( $retval == 1 ){
		delete( $self->{'_sessionargs'} );
	}

	return( $retval );
}

=head2 bind

Binds a Resource value to the connection, if required by the <stream:features>
packet.  Called internally by ->authenticate() if DoBind is set as the 
default '1'.  Takes an optional hash of:

=over 4

=item Process

A string of either 'if-required' or 'always', indicating whether to always
do so, or just if required to do so.

=item Resource

A Resource string to use.

=item AllowRandom

Start using a random resource if the requested Resource was rejected by
the server.

=back

Returns 1 if successful, 0 otherwise.  If successful, will update the
value used by ->connect_jid().

=cut

sub bind {
	my $self = shift;
	my %args = (	Process => "if-required",
			Resource => undef,
			AllowRandom => 0,
			Timeout => 60,
			_bindbg => 0,
			@_,
			);

	my $retval = 0;

	# See if we have to do this.
	my $doso = 0;
	if( $args{"Process"} eq "if-required" ){
		my $stag = $self->stream_features();
		if( defined( $stag ) ){
			# <bind xmlns='urn:ietf:params:xml:ns:xmpp-bind'/>
			my $btag = $stag->getTag( "bind", $self->ConstXMLNS( "xmpp-bind" ) );
			if( defined( $btag ) ){
				# We got the tag.  We must do this.
				$doso = 1;
			}else{
				$self->debug( "No bind tag - ?" . $stag->toStr . " $stag" );
			}
		}else{
			$self->debug( "No stream:features?" );
		}
	}elsif( $args{"Process"} eq "always" ){
		# We don't care.
		$doso = 1;
	}

	# Do we get to go? 
	my $stillgoing = 0;
	if( $doso ){

		$self->debug( "Performing bind based on " . $args{"Process"} );

		# Send the initial packet.
		my $idval = rand(65535 . time );
		my $iqpkt = $self->newNode( 'iq' );
		$iqpkt->attr( 'id', $idval );
		$iqpkt->attr( 'type', 'set' );
		$iqpkt->attr( 'to', $self->{'_authenticateargs'}{"Domain"} );
		my $bindtag = $iqpkt->insertTag( 'bind', $self->ConstXMLNS( 'xmpp-bind' ) );
		if( defined( $args{"Resource"} ) ){
			my $rtag = $bindtag->insertTag( 'resource' );
			$rtag->data( $args{"Resource"} );
		}

		$self->{'_need_auth_bind'} = $idval;
		$self->{'_done_auth_bind'} = undef;
		$stillgoing = $self->send( $iqpkt );
		$self->register_handler( 'iq', sub { $self->_bind_handler(@_) }, "authenticate" );
		%{$self->{'_bindargs'}} = %args;
	}else{
		$self->debug( "Not performing bind based on " . $args{"Process"} );
	}

	if( $doso && $stillgoing ){
		if( ! $args{"_bindbg"} ){
			my $endtime = time + $args{"Timeout"};

			while( $stillgoing ){
				$stillgoing = 0 if( time > $endtime );
				my $tval = $self->bgbinded( RunProcess => 1 );
				if( $tval >= 0 ){
					$stillgoing = 0;
					$retval = $tval;
				}
			}
		}else{
			$retval = -1;
		}
	}

	return( $retval );
}

=head2 bgbind

Background version of bind.  Takes the same arguments as the ->bind() call.

=cut

sub bgbind {
	my $self = shift;
	return( $self->bind( @_, _bindbg => 1 ) );
}

=head2 bgbinded

Technically this should be 'bgbound', but for consistency with other 'bg'
methods, its named this way.  Checks to see if the binding has completed,
returning -1 on still going, 0 on refused and 1 on success.

=cut

sub bgbinded {
	my $self = shift;
	my %args = ( RunProcess => 0,
			ProcessTime => 0,
			@_,
			);

	my $retval = -1;

	if( $args{"RunProcess"} ){
		$self->debug( " invoking process\n" );
		my $tval = $self->process( $args{"ProcessTime"} );
		$self->debug( " invoked process - $tval\n" );
		if( $tval == 1 ){
			my $objthrowaway = $self->get_latest();
			$objthrowaway->hidetree;
		}
	}

	if( $self->_check_val( '_done_auth_bind' ) ){
		$retval = $self->{'_done_auth_bind'};
	}
	return( $retval );
}

sub bgbound {
	my $self = shift;
	return( $self->bgbinded( @_ ) );
}

sub _bind_handler {
	my $self = shift;
	my $node = shift;
	my $persisdata = shift;

	$self->debug( "invoked\n" );
	my $retval = undef;
	my $idval = $self->{'_need_auth_bind'};

	if( defined( $node ) && defined( $idval ) ){
		if( $node->name() eq 'iq' ){
			if( $node->attr( 'id' ) eq $idval ){
				$retval = r_HANDLED;
				if( $node->attr( 'type' ) eq 'result' ){
					# Search for the bind and jid tag.
					my $btag = $node->getTag( "bind", $self->ConstXMLNS( "xmpp-bind" ) );
					$self->{'_done_auth_bind'} = 1;
					if( defined( $btag ) ){
						my $jtag = $btag->getTag( 'jid' );
						if( defined( $jtag ) ){
							$self->{'_connect_jid'} = $jtag->data();
						}
					}
				}elsif( $node->attr( 'type' ) eq 'error' ){
					# What error?
					my $etag = $node->getTag( "error" );
					if( defined( $etag ) ){
						my $notallowed = $etag->getTag( 'not-allowed' );
						my $conflict = $etag->getTag( 'conflict' );
						my $badreq = $etag->getTag( 'bad-request' );
						if( ( $etag->type eq 'modify' && defined( $badreq ) ) || ( $etag->type eq 'cancel' && defined( $conflict ) ) ){
							# Ok, we send in another
							# one if possible.
							$idval = rand(65535 . time );
							$self->{'_need_auth_bind'} = $idval;
							my $iqpkt = $self->newNode( 'iq' );
							$iqpkt->attr( 'id', $idval );
							$iqpkt->attr( 'type', 'set' );
							$iqpkt->attr( 'to', $self->{'_authenticateargs'}{"Domain"} );
							my $bindtag = $iqpkt->insertTag( 'bind', $self->ConstXMLNS( 'xmpp-bind' ) );

							# If Random is set, we
							# use a random number,
							# otherwise we trust
							# to the server.
							if( $self->{'_bindargs'}{"AllowRandom"} ){
								my $rtag = $bindtag->insertTag( 'resource' );
								$rtag->data( int( rand( 65535 ) ) );
							}
							$self->send( $iqpkt );
						}elsif( $etag->type eq 'cancel' ){
							# Remaining type is 'not-allowed'.
							$self->{'_done_auth_bind'} = 1;
						}
					}
				}
			}
		}
	}

	# Mild cleanup.
	if( defined( $retval ) ){ 
		if( $retval == r_HANDLED ){
			delete( $self->{'_bindargs'} );
		}
	}

	return( $retval );
}


=head1 METHODS - Handling Packets

=head2 clear_handlers

This clears any handlers that have been put on the object.  Some 
applications may wish to do this after the standard ->connect
and ->authenticate methods have returned successfully, as these
use handlers to do their jobs.  

Alternatively, specifying a 'Class' of 'connect' and 'authenticate'
will remove just the handlers created by ->connect and ->authenticate
respectively.

WARNING: The standard ->connect and ->authenticate (and/or their 
bg varients) require their configured handlers to be in place.  Do
not execute ->clear_handlers between ->connect and ->authenticate,
lest your application suddenly fail to work.

This takes a hash of optional arguments, being 'Type' and 'Class'.  
The 'Type' is the same as the Type supplied to 'register_handler', and
if supplied, will delete all callbacks of that Type.  The 'Class' is
the same as the optional Class supplied to 'register_handler', and if
supplied, will delete all callbacks of that class.

=cut

sub clear_handlers {
	my $self = shift;
	my %args = (	Type	=> undef,
			Class	=> undef,
			@_,
			);

	# Delete a specific class and type.
	if( defined( $args{"Class"} ) && defined( $args{"Type"} ) ){
		if( defined( $self->{'handlers'}{$args{"Type"}}{$args{"Class"}} ) ){
			delete( $self->{'handlers'}{$args{"Type"}}{$args{"Class"}} );
		}

	# Delete a specific type.
	}elsif( defined( $args{"Type"} ) && ! defined( $args{"Class"} ) ){
		delete( $self->{'handlers'}{$args{"Type"}} );

	# Delete a specific class.
	}elsif( defined( $args{"Class"} ) && ! defined( $args{"Type"} ) ){
		# Delete all handlers of this class from all object
		# types.
		foreach my $type( keys %{$self->{'handlers'}} ){
			next unless( defined( $type ) );
			next if( $type =~ /^\s*$/ );
			next unless( defined( $self->{'handlers'}{$type}{$args{"Class"}} ) );
			delete( $self->{'handlers'}{$type}{$args{"Class"}} );
		}

	# No arguments, delete all.
	}else{
		delete( $self->{'handlers'} );
	}
	return( 1 );
}

=head2 register_handler

Record a packet type and a subroutine to be invoked when the matching
packet type is received.  Multiple handlers for the same packet type
can be registered.  Each of these handlers is called in succession with
the received packet until one returns the constant C<r_HANDLED> .

Each handler is invoked with two arguments; the object representing
the current packet, and a value received from calls to previous handlers.
so-called 'parcel' or 'persistent' data.  The return value is either
the C<r_HANDLED> constant or parcel/persistent data to be handed to the
next handler.

Note: See notes regarding handlers under ->process.

Note: The ->connect and ->authenticate methods use handlers to function.

Note: A third argument can be supplied to indicate the 'class' of this handler,
for usage with ->clear_handlers.  If not supplied, defaults to 'user'.

=cut

sub register_handler {
	my $self = shift;

	my $ptype = shift;
	my $process = shift;
	my $class = shift;

	if( ! defined( $class ) ){
		$class = "user";
	}

	my $retval = 0;
	if( defined( $ptype ) && defined( $process ) ){
		$retval++;
		push @{$self->{'handlers'}{$ptype}{$class}}, $process;
		$self->debug( "$ptype is $process in class $class" );
	}

	return( $retval );
}

=head2 register_interval

Records a time interval and a subroutine to be invoked when the appropriate
time period has elapsed.  Takes a hash of:

=over 4

=item Interval

The frequency which this subroutine should be executed, in seconds.

=item Sub

A reference to the actual subroutine.  Since I keep forgetting how to
do so myself, if you want to call an object-based method with your
working object, you do so via 'Sub => sub { $objname->some_method(@_) }'

=item Argument

If supplied, will be supplied as the second argument.

=item Once

A boolean as to whether this routine should be executed just once 
(after Interval seconds).  Defaults to 0.

=item Now

A boolean as to whether this routine's first execution should be the 
next time ->process() is invoked, or after Interval seconds have 
elapsed.  Defaults to 0.

=back

The subroutine is invoked with a single argument of the current connection 
object (in case you want to send something), and the value of the 'Argument'
hash if supplied.

Note: These are executed as a side-effect of running ->process().  If you
do not regularly invoke ->process() (or via ->start()), these timeouts will
not be invoked.  Executing ->process() from within the handler may cause 
odd things to happen.

=cut

sub register_interval {
	my $self = shift;

	my %args = (	Interval => -1,
			Sub => undef,
			Argument => undef,
			Once => 0,
			Now => 0,
			@_,
			);

	my $retval = 0;

	if( $args{"Interval"} != -1 && defined( $args{"Sub"} ) ){
		$self->debug( "Adding " . $args{"Sub"} . " with interval of " . $args{"Interval"} );
		# Set things up.  Get a unique value.
		my $tlook = rand( 65535 );
		while( defined( $self->{'timebeats'}{"$tlook"} ) ){
			$tlook = rand( 65535 );
		}

		# Save stuff.
		$self->{'timebeats'}{"$tlook"}{"interval"} = $args{"Interval"};
		$self->{'timebeats'}{"$tlook"}{"sub"} = $args{"Sub"};
		$self->{'timebeats'}{"$tlook"}{"once"} = $args{"Once"};
		$self->{'timebeats'}{"$tlook"}{"arg"} = $args{"Argument"};

		my $initialinterval = $args{"Interval"};

		if( $args{"Now"} ){
			$initialinterval = 0;
		}

		$retval = $self->_beat_addnext( Key => $tlook, Interval => $initialinterval, Once => $self->{'timebeats'}{"$tlook"}{"once"} );
	}

	return( $retval );
}

=head2 register_beat

This is the Jabber::Connection compatibility call, and takes two arguments,
a time interval and a subroutine.  Invokes ->register_interval .

=cut

sub register_beat {
	my $self = shift;

	my $argint = shift;
	my $argsub = shift;

	return( $self->register_interval( Interval => $argint, Sub => $argsub ) );
}

=head2 process

For most applications, this is the function to use.  It checks to see if 
anything is available to be read on the socket, reads it in, and returns
a success (or otherwise) value.  It takes an optional timeout argument,
for how long the ->can_read() call can hang around for (default 0).

The values returned, which MUST be checked on each call, are:

	-2: Invalid XML was read.

	-1: EOF was reached.

	 0: No action.  Data may or may not have been read.

	 1: A complete object has been read, and is available for
	    retrieval via get_latest().

	 2: A complete object was read, but was eaten 
	    by a defined handler.

Note that after a complete object has been read, any further calls to 
->process() will not create additional objects until the current complete
object has been retrieved via ->get_latest().  This does not apply if the
object was eaten/accepted by a defined handler.

Note: ->process() is a wrapper around ->can_read() and ->do_read(), but 
it executes handlers as well.  ->process will return after every packet
read (imho, a better behaviour than simply reading from the socket until
the remote end stops sending us data).

=cut

sub process {
	my $self = shift;

	my $arg = shift;

	my $dval = $self->_check_val( '_debug' );
	if( $dval ){
		$dval = $self->{'_debug'};
	}
	if( ! defined( $arg ) ){
		$arg = 0;
	}else{
		$self->debug( " Got arg of $arg\n" ) if( $dval );
	}

	my $retval = 0;

	# See if we can process anything.
	if( $self->can_read( $arg ) ){
		$self->debug( " can_read yes, invoking do_read()\n" ) if( $dval );
		$retval = $self->do_read();
		if( $retval == -1 ){
			# print STDERR "RETVAL -1 THANKS TO DO_READ\n";
		}
	}elsif( defined( $self->{'_pending'} ) ){
		# Yes, we go process something if there is still pending text.
		$self->debug( " can_read no, pending yes, invoking do_read()\n" ) if( $dval );
		$retval = $self->do_read( PendingOnly => 1 );
		if( $retval == -1 ){
			# print STDERR "RETVAL -1 THANKS TO DO_READ PENDING\n";
		}
	}elsif( $self->is_eof() ){
		$self->debug( " can_read no, pending no, eof yes\n" ) if( $dval );
		$retval = -1;
		# print STDERR "SET RETVAL TO -1 AS IS_EOF\n";
	}else{
		$self->debug( " can_read no, pending no, eof no\n" ) if( $dval );
		# Is there currently an object?
		if( defined( $self->{'_curobj'} ) ){
			if( $self->{'_curobj'}->is_complete() ){
				$self->{'_is_complete'} = 1;
				$retval = 1;
			}
		}
	}

	$self->debug( " retval is $retval\n" ) if( $dval );
	# Process the handlers defined.  We make two passes; one for the
	# current packet, and one for the timeouts.
	if( $retval == 1 && defined( $self->{'handlers'} ) ){
		# 
		my $tobj = $self->get_latest;
		my $curname = $tobj->name();
		$self->debug( " considering handler for $tobj ($curname)\n" ) if( $dval );

		my $stillgoing = 1;
		if( defined( $self->{'handlers'}{$curname} ) ){
			# Run through it.
			# Run through the various classes.
			# The connect and authenticate handlers must be 
			# run first, as any client code might incorrectly
			# say that they've handled it.
			my %uclass = ();
			foreach my $thisclass( "connect", "authenticate", keys %{$self->{'handlers'}{$curname}} ){
				next unless( $stillgoing );
				next unless( defined( $thisclass ) );
				next if( $thisclass =~ /^\s*$/ );
				next if( defined( $uclass{"$thisclass"} ) );
				$self->debug( "Checking handlers for $curname of class $thisclass" ) if( $dval );
				$uclass{"$thisclass"}++;
				next unless( exists( $self->{'handlers'}{$curname}{$thisclass} ) );
				$self->debug("Handler for $curname and $thisclass" ) if( $dval );
				my $persisdata = undef;
				my $loop = 0;
				my $maxhandlers = scalar( @{$self->{'handlers'}{$curname}{$thisclass}} );
				while( $loop < $maxhandlers && $stillgoing ){
					eval {
						$self->debug( "handing $tobj and " . ( defined( $persisdata ) ? $persisdata : "undef" ) . " to $curname handler $loop\n" ) if( $dval );
						$persisdata = ${$self->{'handlers'}{$curname}{$thisclass}}[$loop]->( $tobj, $persisdata );
					};

					if( defined( $persisdata ) ){
						if( $persisdata eq r_HANDLED ){
							$stillgoing=0;
						}
					}

					$self->debug( " Got $loop and $maxhandlers - $stillgoing\n" ) if( $dval );
					$loop++;
				}
			}
		}

		# If we're still here, the packet wasn't handled.
		# Put it back in the object.
		if( $stillgoing ){
			$self->copy_latest( $tobj );
			$retval = 1;
		}else{
			$tobj->hidetree;
			$retval = 2;
		}
		$self->debug( " Back to here\n" ) if( $dval );
	}

	# Lets process the timeouts.  These do not affect the
	# return value.  We only run one timeout at a time.
	if( defined( $self->{'heartbeats'} ) ){
		if( defined( ${$self->{'heartbeats'}}[0] ) ){
			# XXXX - bug in inserting things into heartbeats?
			# print STDERR "check heartbeats - " . time . " " . ${$self->{'heartbeats'}}[0] . "\n";
			if( time > ${$self->{'heartbeats'}}[0] ){
				$self->debug( "Found heartbeats - " . time . " " . ${$self->{'heartbeats'}}[0] ) if( $dval );
				# print STDERR "Found heartbeats - " . time . " " . ${$self->{'heartbeats'}}[0] . "\n";
				my $plook = ${$self->{'heartbeats'}}[0];
				splice( @{$self->{'heartbeats'}}, 0, 1 );
				my $tlook = $self->{'timepend'}{"$plook"};
				delete( $self->{'timepend'}{"$plook"} );

				# Re-add this one as appropriate.
				if( defined( $self->{'timebeats'}{"$tlook"} ) ){
					$self->_beat_addnext( Key => $tlook, Interval => $self->{'timebeats'}{"$tlook"}{"interval"}, Once => $self->{'timebeats'}{"$tlook"}{"once"}, Argument => $self->{'timebeats'}{"$tlook"}{"arg"} );

					# Execute this one.
					eval {
						$self->debug( "Executing sub" ) if( $dval );
						$self->{'timebeats'}{"$tlook"}{"sub"}->( $self, $self->{'timebeats'}{"$tlook"}{"arg"} );
						$self->debug( "Finished Executing sub" ) if( $dval );
					};
				}
			}
		}
	}

	$self->debug( "returning $retval\n" ) if( $dval );
	if( $retval == -1 ){
		# Abort as theres nothing more to be read.
		# print STDERR "ABORTING AS RETVAL IS -1\n";
		$self->abort();
	}
	return( $retval );	
}

=head2 send

Sends either text or an object down the connected socket.  Returns
a count of the number of bytes read.  Will return '-1' if an error
occured and the text was not sent.

Note that if you send non-XML data (gibberish or incomplete), thats
your problem, not mine.

=cut

sub send {

	my $self = shift;
	my $arg = shift;
	my $retval = 0;
	# print "$self: send: $arg\n";
	if( defined( $self->socket() ) ){

		# Can the socket be written to?
		$retval = -1;
		my $nwritable = $self->can_write();

		# Is the socket still connected?  can_write() does not
		# detect this condition.
		my $amconnected = 0;
		if( defined( $self->socket->connected ) ){
			$amconnected = 1;
		}

		# IO::Socket::SSL does not have send; I missed this when
		# changed from syswrite.
		my $usesend = 1;

		if( ! defined( $self->{'_checked_send_ability'} ) ){
			my $tsock = $self->socket();
			my $tref = ref( $tsock );
			if( $tref =~ /SSL/ ){
				# Does it have send?
				if( $amconnected && $nwritable ){
					eval {
						$self->socket->send( " " );
					};
					if( $@ ){
						# We got an error.
						$usesend = 0;
					}
					$self->{'_checked_send_ability'} = $usesend;
				}
			}
		}else{
			$usesend = $self->{'_checked_send_ability'};
		}


		# Deal with either the public or hidden class.	
		my $tref = ref( $arg );	
		if ( ( $tref eq 'Jabber::Lite' || $tref eq 'Jabber::Lite::Impl' ) && $nwritable && $amconnected ) {
			# print "OBJECT is " . $arg->toStr . "\n";
			# print "WRI";
			if( $usesend ){
				$retval = $self->socket->send( $arg->toStr );
			}else{
				$retval = $self->socket->syswrite( $arg->toStr );
			}
			$self->debug( "Sent off $arg" );
			# print "TE $retval - $@\n";
		}elsif( $nwritable && $amconnected ) {
			# print "object is " . $arg . "\n";
			# print "wri";
			if( $usesend ){
				$retval = $self->socket->send( $arg );
			}else{
				$retval = $self->socket->syswrite( $arg );
			}
			# print "te (" . $arg . ") $retval - $@\n";
			$self->debug( "Sent off $arg" );
		}else{
			$self->debug( "socket is not writable or is disconnected." );
			$self->abort();
		}
		$self->{'_lastsendtime'} = time;
		eval {
			$self->socket->autoflush(1);
		};
	}
	return( $retval );
}


=head1 METHODS - So Long, and Thanks for all the <fish/>

=head2 disconnect

Disconnect from the Jabber server by sending the closing tags and then
closing the connection.  Note that no closing '</presence>' tag is sent,
but the closing </stream:stream> tag is sent.

=cut

sub disconnect {
	my $self = shift;
	my $retval = 0;
	if( defined( $self->socket() ) ){
		# Send the closing tags.
		# We don't bother with preparing an object here.
		$self->send( "</stream:stream>\n" );

		# Invoke abort();
		# print STDERR "ABORTING VIA DISCONNECT!\n";
		$retval = $self->abort();
	}
	return( $retval );
}


=head2 abort

Close the connection abruptly.  If the connection is not to a Jabber server,
use abort() instead of disconnect().

=cut

sub abort {
	my $self = shift;
	my $retval = 0;
	$self->debug( "aborting!\n" );
	# print STDERR "ABORTING!\n";
	if( defined( $self->socket() ) ){
		if( defined( $self->{'_select'} ) ){
			$self->{'_select'}->remove( $self->socket() );
		}

		my $tref = ref( $self->socket );
		if( $tref ){
			if( $tref =~ /SSL/ ){
				# IO::Socket::SSL says that it has the 
				# possibility of blocking unless the
				# SSL_no_shutdown argument is specified.
				# Some servers may not like this behaviour.
				$self->socket->close( SSL_no_shutdown => 1 );
			}else{
				close( $self->socket() );
			}
			delete( $self->{'_checked_send_ability'} );
		}else{
			close( $self->socket() );
			delete( $self->{'_checked_send_ability'} );
		}
		$self->{'_socket'} = undef;
		$retval++;
	}

	foreach my $todel( '_is_connected', '_is_encrypted', '_is_authenticated', '_connect_jid', '_is_eof', '_select', '_socket', '_pending' ){
		$self->{$todel} = undef;
		delete( $self->{$todel} );
	}
	return( $retval );
}

=head1 METHODS - These are a few of my incidental things

=head2 socket

Returns (or sets) the socket that this object is using.  This is provided 
to support a parent program designed around its own IO::Select() loop.  
A previously opened socket/filehandle can be supplied as the argument.

Note: The library uses sysread() and send/syswrite() as required.  Passing
in filehandles that do not support these functions is probably a bad
idea.

Note: There is some juggling of sockets within the ->connect method
when SSL starts up.  Whilst a select() on the original, or parent socket
will probably still work, it would probably be safer to not include
the socket returned by ->socket() in any select() until the ->connect()
and ->authenticate methods have returned.

=cut

sub socket {
	my $self = shift;
	my $arg = shift;
	# print STDERR "SOCKET HAS $arg\n";
	if( defined( $arg ) ){
		$self->{'_socket'} = $arg;
		delete( $self->{'_checked_send_ability'} );

		# Set up an IO::Select object.
		$self->{'_select'} = new IO::Select;
		$self->{'_select'}->add( $arg );

		# Assume that this is not at EOF initially.
		$self->{'_is_eof'} = undef;
	}

	if( defined( $self->{'_socket'} ) ){
		return( $self->{'_socket'} );
	}else{
		return( undef );
	}
}

=head2 can_read

Checks to see whether there is anything further on the socket.  Returns
1 if there is data to be read, 0 otherwise.

=cut

sub can_read {
	my $self = shift;
	my $arg = shift;
	if( ! defined( $arg ) ){
		$arg = 0;
	}
	my $retval = 0;
	if( defined( $self->{'_select'} ) ){
		$self->debug( " invoking io:select\n" );
		my @readhans = $self->{'_select'}->can_read($arg);
		if( scalar @readhans > 0 ){
			$retval = 1;
		}
		$self->debug( " invoked io:select returning $retval\n" );
	}
	return( $retval );
}

=head2 can_write

Checks to see whether the socket can be written to.  Returns
1 if so, 0 otherwise.

=cut

sub can_write {
	my $self = shift;
	my $arg = shift;
	if( ! defined( $arg ) ){
		$arg = 0;
	}
	my $retval = 0;
	if( defined( $self->{'_select'} ) ){
		$self->debug( " invoking io:select\n" );
		my @readhans = $self->{'_select'}->can_write($arg);
		if( scalar @readhans > 0 ){
			$retval = 1;
		}
		$self->debug( " invoked io:select returning $retval\n" );
	}
	return( $retval );
}

=head2 do_read

Reads in the latest text from the socket, and submits it to
be added to the current XML object.  Returns:

=over 4

=item -2 if the parsing indicated invalid XML, 

=item -1 if the socket reached EOF,

=item 0 if the socket was ok and data was read happily.

=item 1 if there is a complete object (use ->get_latest() )

=back

Applications MUST check the return value on each call.  Takes a hash
of optional arguments, the most important being:

	PendingOnly (default 0) - Only process the pending data, do not
	attempt to read from the socket.

->do_read also checks the maxobjectsize, maxobjectdepth and maxnamesize.

->do_read also checks the likely size of the object as it is being read.  If
it is larger than the maxobjectsize value passed to ->new/->init, the 
appropriate behaviour will be taken.  Note that if the behaviour chosen
is to continue parsing but not save (the default), then an attack consisting
of <foo><foo><foo> repeated ad nauseum will still eventually exhaust memory.

This is because to properly parse the object, the parser must know at which
point the object is at, meaning that the name of each <tag> must be stored.

=cut

sub do_read {
	my $self = shift;
	my %args = ( PendingOnly => 0,
			@_,
			);
	my $socket = $self->socket();
	my $retval = -1;

	my $save_to_memory = 1;

	if( defined( $socket ) && ! $self->is_eof() && ! $args{"PendingOnly"} ){
		$retval = 0;
		my $buf = "";
		my $tval = sysread( $socket, $buf, $self->{'_readsize'} );

		# Some slight parsing to preload the is_eof function.
		$self->{'_justreadcount'} = 0;
		if( ! defined( $tval ) ){
			# An error occurred.  We assume that
			# this is eof.
			$self->{'_is_eof'} = 1;
			# print STDERR "SYSREAD RETURNED UNDEF\n";
			$retval = -1;
		}elsif( $tval == 0 ){
			# This is EOF.
			$self->{'_is_eof'} = 1;
			# print STDERR "SYSREAD RETURNED 0\n";
			$retval = -1;
		}elsif( $tval > 0 ){
			# We did get some bytes.  First add it
			# to the pending buffer.
			$self->debug( "Read in $buf" );
			$self->{'_pending'} .= $buf;

			# We just read something.  Not EOF.
			$self->{'_is_eof'} = undef;

			# How many bytes did we just read?
			$self->{'_justreadcount'} = $tval;

			# Running total.
			$self->{'_totalreadcount'} += $tval;

			# Update the time of last read.  Useful for
			# the calling program.
			$self->{'_lastreadtime'} = time;

			# Increment the count of bytes read since the
			# last time an object was cleared.  This is not
			# quite the same as the number of bytes in an
			# object.
			$self->{'_curobjbytes'} += $tval;

			# Have we exceeded the allowable count of bytes read?
			if( defined( $self->{'_maxobjectsize'} ) ){
				if( $self->{'_curobjbytes'} > $self->{'_maxobjectsize'} ){
					# We must do the appropriate action.
					# disconnect
					if( $self->{'_disconnectonmax'} ){
						# Bye bye.
						$self->debug( "Exceeded maxobjectsize (" . $self->{'_maxobjectsize'} . ") with " . $self->{'_curobjbytes'} . ", disconnecting\n" );
						# print STDERR "ABORTING VIA EXCESS MEMORY\n";
						$self->abort();
					}else{
						$save_to_memory=0;
					}
				}
			}
		}
	}

	# If there is data in the pending variable, we have
	# to deal with it.  This includes things that we just read.

	if( defined( $self->{'_pending'} ) ){
		# $self->debug( "Current pending is " . $self->{'_pending'} . "\n" );

		# Then see if we have to create an object.
		if( ! defined( $self->{'_curobj'} ) ){

			# See if we have enough data to
			# create an object.
			my ( $tobj, $tval, $rtext ) = $self->create_and_parse( $self->{'_pending'} );
			if( defined( $tobj ) ){
				$self->{'_curobj'} = $tobj;

				# Record when the object started being received.
				# Useful for the calling program.
				$self->{'_lastobjectstart'} = time;
				if( length( $rtext ) > 0 ){
					$self->{'_pending'} = $rtext;
				}else{
					delete( $self->{'_pending'} );
				}

				# Check for completeness.
				if( $self->{'_curobj'}->is_complete() ){
					$self->{'_is_complete'} = 1;
					$retval = 1;
				}
			}else{ 
				# No object was created.  Thus, we are between
				# objects, and what was read is solely 
				# whitespace.  We've possibly also read a '<'
				# character at the end.  So, we delete any
				# whitespace, decrement the curobjbytes count
				# by that amount, and save the pending again.
				# create_and_parse will swallow whitespace
				# as well.
				if( $self->{'_pending'} =~ /^(\s*)(<)?$/sm ){
					$self->{'_curobjbytes'} -= length( $1 );
					$self->{'_pending'} = $2 || undef;
				}else{
					# Caution, possible memory leakage
					# issue here.  It shouldn't be anything
					# but whitespace.
					$self->{'_pending'} = $rtext;
					if( $tval == -2 ){
						$self->debug( "tval is -2 ?" );
						$retval = $tval;
					}
				}
			}

			# Return XML parse errors to the caller.
			if( $tval == -2 ){
				$retval = -2;
			}

		# See if we have an object that is not marked
		# as being complete.  If we have an object that
		# is marked as being complete, we leave the text
		# that we read in the _pending variable.
		}elsif( ! defined( $self->{'_is_complete'} ) ){
			my( $tval, $rtext ) = $self->{'_curobj'}->parse_more( $self->{'_pending'} );
			if( length( $rtext ) > 0 ){
				$self->{'_pending'} = $rtext;
			}else{
				# We have to delete it as we
				# use its 'defined' value to
				# determine whether we enter 
				# this function when no data
				# was read.  Nice bricktext.
				delete( $self->{'_pending'} );
			}

			# Check for completeness.
			if( $self->{'_curobj'}->is_complete() ){
				$self->{'_is_complete'} = 1;
				$retval = 1;

				# Record when the last object was received.
				# Useful for the calling program.
				$self->{'_lastobjecttime'} = time;
			}

			# Detect XML parse errors.
			if( $tval == -2 ){
				$retval = -2;
			}
		}
	}

	# Return what we have.
	return( $retval );
}

=head2 is_eof

Sees whether the socket is still around, based on the last
call to ->do_read().  Returns 1 if the socket is at EOF, 0
if the socket not at EOF.

=cut

sub is_eof {
	my $self = shift;
	return( $self->_check_val( '_is_eof' ) );
}

=head2 is_authenticated

Returns 1 or 0 whether this connection has been authenticated yet.

=cut

sub is_authenticated {
	my $self = shift;
	return( $self->_check_val( '_is_authenticated' ) );
}

=head2 is_connected 

Returns 1 or 0 whether this connection is currently connected.

=cut

sub is_connected {
	my $self = shift;
	my $retval = $self->_check_val( '_is_connected' );
	$self->debug( "Returning $retval" );
	# print "is_connected $self: Returning $retval X\n";
	return( $retval );
}

=head2 is_encrypted 

Returns 1 or 0 whether this connection is currently encrypted.

=cut

sub is_encrypted {
	my $self = shift;
	return( $self->_check_val( '_is_encrypted' ) );
}

=head2 connect_jid

Returns the JID currently associated with this connection, or undef.

=cut

sub connect_jid {
	my $self = shift;
	return( $self->{'_connect_jid'} );
}

# Helper function, not documented.
# Checks to see whether the nominated value has been defined.
sub _check_val {
	my $self = shift;
	my $arg = shift;
	if( defined( $self->{"$arg"} ) ){
		return( 1 );
	}else{
		return( 0 );
	}
}


# Helper function, not documented.
# Alters the pending time tables.
sub _beat_addnext {
	my $self = shift;
	my %args = (	Key => undef,
			Interval => undef,
			Once => 0,
			FirstOnce => 0,
			@_,
			);

	my $retval = 0;
	if( defined( $args{"Key"} ) && defined( $args{"Interval"} ) ){
		# See if this is a once one?
		if( ! $args{"Once"} || ( $args{"Once"} && $args{"FirstOnce"} ) ){
			# Lets see now.  Work out the next time it
			# should be triggered.
			my $nexttime = time + $args{"Interval"};

			# Find out where it should be inserted.
			my $stillgoing = 1;
			my $loopinsert = 0;
			while( $stillgoing && defined( ${$self->{'heartbeats'}}[$loopinsert] ) ){
				if( $nexttime < ${$self->{'heartbeats'}}[$loopinsert] ){
					$stillgoing = 0;
				}else{
					$loopinsert++;
				}
			}

			# We have a place to insert it.  See whether this would
			# conflict with an existing value.  
			my $orignext = $nexttime;
			while( defined( $self->{'timepend'}{"$nexttime"} ) ){
				$nexttime = $orignext + rand(1);
			}

			# Insert it into the quick check.  The loop we've just
			# done insures that its before any value that is 'just'
			# higher than the number we've done.  Thus, the 
			# ones with short intervals only have to go through
			# a small number of checks, whilst the ones with 
			# longer intervals go through a longer number of
			# checks, but we only have to take that hit when on
			# those intervals.
			splice( @{$self->{'heartbeats'}}, $loopinsert, 0, $nexttime );

			# Insert it into the main list.  As we're checking
			# the timeout to execute via a changing numeric check,
			# we have this indirection to lookup the actual
			# subroutine (and the next interval)
			$self->{'timepend'}{"$nexttime"} = $args{"Key"};

			$retval++;
		}
	}
	return( $retval );
}

=head2 _connect_starttls handler

This is a helper function (for ->connect) for the starting up of TLS/SSL 
via the <starttls> tag. 

=cut

sub _connect_starttls {
	my $self = shift;

	my $node = shift;
	my $persisdata = shift;
	my $tlsxmlns = $self->ConstXMLNS( 'xmpp-tls' );

	my $retval = undef;

	if( defined( $node ) ){
		if( $node->name() eq "proceed" && $node->xmlns() eq $tlsxmlns ){
			# Re-invoke ->connect to get SSL running.  We need
			# to slurp the original SSL* args out though.
			my %SSLHash = ();
			foreach my $kkey( keys %{$self->{'_connectargs'}} ){
				next unless( $kkey =~ /^(SSL|Version|Domain)/ );
				$SSLHash{"$kkey"} = $self->{'_connectargs'}{"$kkey"};
			}
			$self->connect( '_redo' => 1, JustConnectAndStream => 1, UseSSL => 1, MustEncrypt => 1, %SSLHash );
			$retval = r_HANDLED;
		}elsif( $node->name() eq "failure" && $node->xmlns() eq $tlsxmlns ){
			# We have sent a '<starttls>', but the other side has
			# sent us a '<failure>' tag.  RFC3920 5.2 #5 states
			# that the receiving entity (thats us) MUST terminate
			# both the XML stream and the underlying TCP connection.
			$self->disconnect();
			$retval = r_HANDLED;

		}
	}

	return( $retval );
}

=head2 _connect_handler handler

This is a helper function (for ->connect) for the handling of some initial
tags.

=cut

sub _connect_handler {
	my $self = shift;
	my $node = shift;
	my $persisdata = shift;

	my $retval = undef;
	my $cango = 1;

	$self->debug( "invoked\n" );

	if( defined( $node ) ){
		my $nodename = lc( $node->name() );
		$self->debug( " Got $node($nodename) and " . ( defined( $persisdata ) ? $persisdata : "undef" ) . " X\n" );

		if( $nodename eq '?xml' ){
			# RFC3920 11.4 says that applications MUST deal with
			# the opening text declaration.  We don't unfortunately,
			# and we don't pass it back to the caller.  This is 
			# something for 0.9 .
			$retval = r_HANDLED;
			$self->xml_version( value => $node->attr( "version" ) );
			$self->xml_encoding( value => $node->attr( "encoding" ) );
		}elsif( $nodename eq 'stream:stream' ){
			$retval = r_HANDLED;

			if( defined( $node->attr( 'from' ) ) ){
				$self->{'confirmedns'} = $node->attr( 'from' );
				# See if we allow such redirection.
				# if( ! $args{"AllowRedirect"} ){
				if( ! $self->{'_connectargs'}{"AllowRedirect"} ){
					if( lc( $self->{'confirmedns'} ) ne lc( $self->{'_connectargs'}{"Domain"} ) ){
						$cango = 0;
					}
				}
			}
			if( defined( $node->attr( 'id' ) ) ){
				$self->{'streamid'} = $node->attr( 'id' );
			}

			# RFC3920 - 4.4.1 item 4.  Version defaults to 0.0
			if( defined( $node->attr( 'version' ) ) ){
				$self->{'streamversion'} = $node->attr( 'version' );
			}else{
				$self->{'streamversion'} = "0.0";
				$self->{'authmechs'}{"jabber:iq:auth"} = "1";
			}
			if( defined( $node->xmlns() ) ){
				$self->{'streamxmlns'} = $node->xmlns();
			}
			if( defined( $node->attr( 'stream:xmlns' ) ) ){
				$self->{'streamstream:xmlns'} = $node->attr( 'stream:xmlns' );
			}
			if( defined( $node->attr( 'xml:lang' ) ) ){
				$self->{'streamxml:lang'} = $node->attr( 'xml:lang' );
			}
		}elsif( $nodename eq 'stream:error' ){
			$retval = r_HANDLED;
			# Create a new node, as the previous one gets bits of it
			# automagically destroyed at the end.
			$self->{'stream:error'} = $self->newNodeFromStr( $node->toStr );
			$self->disconnect();
		}elsif( $nodename eq 'stream:features' ){
			$retval = r_HANDLED;

			# Create a new node, as the previous one gets bits of it
			# automagically destroyed at the end.
			$self->{'stream:features'} = $self->newNodeFromStr( $node->toStr );

			# Run through the list, and initiate tls if required.
			my $tlsxmlns = $self->ConstXMLNS( "xmpp-tls" );
			my $ssltag = $node->getTag( "starttls", $tlsxmlns );
			if( defined( $ssltag ) && $self->{'_connectargs'}{"UseTLS"} && ! $self->is_encrypted() ){
				$self->debug( " Got ssltag\n" );
				# We can issue a <starttls> tag, then wait for
				# a <proceed> or <failure> tag.  If it is
				# a <proceed>, we reinvoke ourselves with
				# UseSSL, MustEncrypt and _redo set, and
				# return with that.

				# Flip into single character mode, so we
				# don't swallow any initial SSL characters.
				# my $oldreadsize = $self->{'_readsize'};
				# $self->{'_readsize'} = 1;

				my $sendsslproceed = $self->newNode( "starttls", $tlsxmlns );
				$self->send( $sendsslproceed );
				$self->{'_ask_encrypted'} = 1;
				$self->{'stream:features'} = undef;
			}else{
				# Run through the list of what we have.  We're
				# after the auth mechanisms, and possibly the
				# auth tag.
				foreach my $snode( $node->getChildren() ){
					if( lc($snode->name()) eq "auth" ){
						if( lc( $snode->xmlns ) eq $self->ConstXMLNS( "iq-auth" ) ){
							$self->{'authmechs'}{"jabber:iq:auth"} = "1";
						}
					}elsif( $snode->name() eq "mechanisms" ){
						foreach my $cnode( $snode->getChildren() ){
							next unless( $cnode->name() eq "mechanism" );
							$self->{'authmechs'}{'sasl-' . lc($cnode->data())} = "1";
						}
					}
				}
			}
		}
	}

	$self->debug( " returning $retval X\n" );
	return( $retval );
}

=head2 xml_version

This returns the version supplied by the last <?xml?> tag received.

=cut

sub xml_version {
	my $self = shift;
	my %args = ( @_ );
	if( exists( $args{"value"} ) ){
		$self->{'_xml_version'} = $args{"value"};
	}
	return( $self->{'_xml_version'} );
}

=head2 xml_encoding

This returns the encoding supplied by the last <?xml?> tag received.

=cut

sub xml_encoding {
	my $self = shift;
	my %args = ( @_ );
	if( exists( $args{"value"} ) ){
		$self->{'_xml_encoding'} = $args{"value"};
	}
	return( $self->{'_xml_encoding'} );
}

############################################################################
# Functions for the object as XML document holder.  OO style, so we
# continually create sub-objects as required.

=head1 METHODS - Object common

These are for the library as XML parser, creating new objects, reading
attributes etc.

=head2 get_latest

Returns the latest complete object or undef.  This function is only
valid on the parent connection object.

WARNING: This is a destructive process; a second call will return undef
until another object has been read.

=cut

sub get_latest {
	my $self = shift;

	my $retval = undef;
	if( defined( $self->{'_curobj'} ) ){
		if( $self->{'_curobj'}->is_complete() ){
			$retval = $self->{'_curobj'};
			$self->{'_curobj'} = undef;
			$self->{'_curobjbytes'} = 0;
			$self->{'_is_complete'} = undef;
		}else{
			$self->{'_is_complete'} = undef;
		}
	}elsif( defined( $self->{'_is_complete'} ) ){
		# Cope with stray things.
		$self->{'_is_complete'} = undef;
	}

	$self->debug( "returning $retval\n" );
	return( $retval );
}

=head2 copy_latest

This returns a copy of the latest object, whether or not it is
actually complete.  An optional argument may be supplied, which
will be used to replace the current object.

WARNING: This may return objects which are incomplete, and may not
make too much sense.  Supplying an argument which is not of this
class may produce odd results.

=cut

sub copy_latest {
	my $self = shift;

	my $retval = undef;
	my $arg = shift;
	if( defined( $arg ) ){
		$self->debug( " putting back $arg\n" );
		$self->{'_curobj'} = $arg;
	}
	if( defined( $self->{'_curobj'} ) ){
		$retval = $self->{'_curobj'};
	}

	return( $retval );
}

=head2 clear_latest

This clears the latest object.

=cut

sub clear_latest {
	my $self = shift;

	$self->{'_curobj'} = undef;
}

=head2 newNode 

Creates a new Node or tag, and returns the object thus created.  Takes
two arguments, being a required name for the object, and an optional
xmlns value.  Returns undef if a name was not supplied.

A previously created object can be supplied instead.

=cut

sub newNode {
	my $self = shift;
	my $arg = shift;

	my $retobj = undef;

	if( defined( $arg ) ){

		# First argument could be a reference, hopefully
		# to one of us.
		my $tref = ref( $arg );
		if( $tref ){
			$retobj = $arg;
		}else{	
			$retobj = Jabber::Lite->new();
			$retobj->name( $arg );
		}

		my $xmlns = shift;

		if( defined( $xmlns ) ){
			$retobj->xmlns( $xmlns );
		}

		# If we have debug set, set it on the child.
		$retobj->{'_debug'} = $self->{'_debug'};

	}

	# my @calledwith = caller(1);
	# my $lineno = $calledwith[2];
	# my $fname = $calledwith[1];
	# print STDERR "$self: newNode called from line $lineno $fname, returning $retobj\n";

	return( $retobj );
}

=head2 newNodeFromStr

Creates a new Node or tag from a supplied string, and returns the object 
thus created.  Takes a single argument, being the string for the object.
Returns undef if a string was not supplied.

Note: If there was more than one object in the string, the remaining 
string is tossed away; you only get one object back.

=cut

sub newNodeFromStr {
	my $self = shift;
	my $str = shift;

	my ($retobj, $success, $rtext ) = $self->create_and_parse( $str );

	if( $success == 1 ){
		return( $retobj );
	}else{
		return( undef );
	}
}

=head2 insertTag

Inserts a tag into the current object.  Takes the same arguments as
->newNode, and returns the object created.

=cut

sub insertTag {
	my $self = shift;

	my $retobj = $self->newNode( @_ );
	# print STDERR "insertTag called on $self, going to return $retobj\n";

	if( defined( $retobj ) ){
		my $nextnum = 0;
		if( defined( $self->{'_curobjs'} ) ){
			$nextnum = scalar @{$self->{'_curobjs'}};
		}
		if( ! defined( $nextnum ) ){
			$nextnum = 0;
		}elsif( $nextnum =~ /\D/ ){
			$nextnum = 0;
		}

		# Set the parent.  This is enclosed in an eval
		# in case it is a different reference type.
		eval {
			# print STDERR "Setting parent on $retobj to be $self\n";
			$retobj->parent( $self );
		};

		# Store it.
		${$self->{'_curobjs'}}[$nextnum] = $retobj;

	}

	return( $retobj );
}


=head2 name

Returns, or sets, the name of the object.  Takes an optional argument for
the new name.

Note: No checking or escaping is done on the supplied name.

=cut

sub name {
	my $self = shift;
	my $arg = shift;
	if( defined( $arg ) ){
		$self->{'_name'} = $arg;
		$self->debug( "Setting my name to $arg X" );
	}

	return( $self->{'_name'} );
}

=head2 is_complete

Return 1 or 0 whether the current object is complete.

=cut

sub is_complete {
	my $self = shift;
	if( defined( $self->{'_is_complete'} ) ){
		$self->debug( " 1\n" );
		return( 1 );
	}else{
		$self->debug( " 0\n" );
		return( 0 );
	}
}

=head2 getChildren

Return an @array of subobjects.

=cut

sub getChildren {
	my $self = shift;
	return( @{$self->{'_curobjs'}} );
}

=head2 getTag

Return a specific child tag if it exists.  Takes the name of the tag,
and optionally the xmlns value of the tag (first found wins in the case
of duplicates).

=cut

sub getTag {
	my $self = shift;

	my $wantname = shift;
	my $wantxmlns = shift;

	my $retobj = undef;
	if( defined( $self->{'_curobjs'} ) && defined( $wantname ) ){
		my $maxobjs = scalar( @{$self->{'_curobjs'}} );
		my $loop = 0;
		while( $loop < $maxobjs && ! defined( $retobj ) ){
			if( defined( ${$self->{'_curobjs'}}[$loop] ) ){
				if( ${$self->{'_curobjs'}}[$loop]->name() eq $wantname ){
					$self->debug( " $loop matches $wantname X\n" );
					if( defined( $wantxmlns ) ){
						if( ${$self->{'_curobjs'}}[$loop]->xmlns() eq $wantxmlns ){
							$self->debug( " $loop matches $wantxmlns X\n" );
							$retobj = ${$self->{'_curobjs'}}[$loop];
						}
					}else{
						$retobj = ${$self->{'_curobjs'}}[$loop];
					}
				}
			}
			$loop++;
		}
	}
				

	return( $retobj );
}

=head2 listAttrs

Return an @array of attributes on the current object.

=cut

sub listAttrs {
	my $self = shift;

	my @retarray = ();

	foreach my $attribname( keys %{$self->{'_attribs'}} ){
		next unless( defined( $attribname ) );
		next if( $attribname =~ /^\s*$/s );
		push @retarray, $attribname;
	}
	return( @retarray );

}

=head2 attr

Return or set the contents of an attribute.  Takes an attribute name
as the first argument, and the optional attribute contents (replacing
anything there) as the second argument.

=cut

sub attr {
	my $self = shift;

	my $attribname = shift;
	my $attribvalue = shift;

	if( defined( $attribvalue ) && defined( $attribname ) ){
		$self->debug( " Storing in $attribname - $attribvalue X\n" );
		$self->{'_attribs'}{"$attribname"} = $attribvalue;
	}elsif( defined( $attribname ) ){
		if( defined( $self->{'_attribs'}{"$attribname"} ) ){
			$attribvalue = $self->{'_attribs'}{"$attribname"};
		}else{
			$attribvalue = undef;
		}
	}else{
		$attribvalue = undef;
	}

	return( $attribvalue );
}

=head2 xmlns

Sets or returns the value of the xmlns attribute.

=cut

sub xmlns {
	my $self = shift;
	return( $self->attr( 'xmlns', @_ ) );
}

=head2 data

Returns or sets the data associated with this object.  Take an optional
argument supplying the data to replace any existing data.  Performs 
encoding/decoding of common XML escapes.

=cut

sub data {
	my $self = shift;

	my $dstr = shift;

	if( defined( $dstr ) ){
		# Do some encoding on the string.
		$self->{'_data'} = $self->encode( $dstr );

	}

	# Need to do some decoding stuff.
	return( $self->decode( $self->{'_data'} ) );
}

=head2 rawdata

The same as ->data(), but without the encodings/decodings used.  Make sure
anything that you add doesn't include valid XML tag characters, or something
else will break.

=cut

sub rawdata {
	my $self = shift;

	my $dstr = shift;

	if( defined( $dstr ) ){
		$self->{'_data'} = $dstr;
	}

	return( $self->{'_data'} );
}

=head2 parent

Returns the parent object of the current object, or undef.

=cut

sub parent {
	my $self = shift;

	if( @_ ){
		if( $Jabber::Lite::WeakRefs ){
			Scalar::Util::weaken($self->{'_parent'} = shift);
			# warn( "$self: Set SUW parent to " . $self->{'_parent'} . "\n" );
		}else{
			# warn( "$self: Set parent to " . $self->{'_parent'} . "\n" );
			$self->{'_parent'} = shift;
		}
	}else{
		# warn( "$self: Unset parent on " . $self->name . "\n" );
	}

	return( $self->{'_parent'} );
}

# Hidden method to remove it; the name is MaGiC in AUTOLOAD.
sub del_parent_link {
	my $self = shift;
	$self->{'_parent'} = undef;
}

=head2 hide

Remove references to the current object from the parent object, effectively
deleting it.  Returns 1 if successful, 0 if no valid parent.  If there are
any child-objects, removes references to this object from them.

=cut

sub hide {
	my $self = shift;

	my $retval = 0;
	if( defined( $self->parent() ) ){
		$retval = $self->parent->hidechild( $self );
	}

	if( defined( $self->{'_curobjs'} ) ){
		my $numchild = scalar @{$self->{'_curobjs'}};
		if( defined( $numchild ) ){
			while( $numchild > 0 ){
				$numchild--;
				# warn( "$self: Invoking parent dereference on $numchild\n" );
				# This duplicates hide() and hidechild(), but
				# we don't want to jump through too many
				# hoops right now.
				${$self->{'_curobjs'}}[$numchild]->del_parent_link( undef );
				${$self->{'_curobjs'}}[$numchild] = undef;
				delete( ${$self->{'_curobjs'}}[$numchild] );
			}
		}
	}

	return( $retval );
}

=head2 hidechild

Remove references to a child object.  Takes an argument of a child object
to delete.  Returns 1 if successful, 0 if not.

=cut

sub hidechild {
	my $self = shift;
	my $arg = shift;
	my $match = $arg;

	my $retval = 0;

	# Run through all of the objects to find a match.
	my %todel = ();
	if( defined( $match ) && defined( $self->{'_curobjs'} ) ){
		my $loop = 0;
		my $maxval = scalar( @{$self->{'_curobjs'}} );
		while( $loop < $maxval ){
			if( defined( ${$self->{'_curobjs'}}[$loop] ) ){ 
				if( ${$self->{'_curobjs'}}[$loop] == $match ){
					$todel{"$loop"}++;
				}
			}else{
				$todel{"$loop"}++;
			}
			$loop++;
		}
	}

	# Work through the list, descending (as splice changes the
	# list offsets).
	foreach my $offset( sort { $b <=> $a } keys %todel ){
		next unless( defined( $offset ) );
		next if( $offset =~ /\D/ );

		splice( @{$self->{'_curobjs'}}, $offset, 1 );
		$retval++;
	}

	# Finally, check whether it is '_curobj' .
	if( defined( $self->{'_curobj'} ) && defined( $match ) ){
		if( $self->{'_curobj'} == $match ){
			$self->{'_curobj'} = undef;
			$retval++;
		}
	}

	return( $retval );
}

=head2 hidetree

This routine removes references to this object, and to objects below it.
In certain versions of perl, this may assist with cleanup.

=cut

# ->hidetree is in two parts.  This is the first part, which invokes the
# recursive routine and then removes the reference to ourselves from our
# parent.
sub hidetree {
	my $self = shift;

	$self->hidetree_recurse();
	return( $self->hide() );
}

# This is the second part.  It avoids the recursing routine on each
# child object from querying the current object again to remove 
# itself, as is done by ->hide.
sub hidetree_recurse {
	my $self = shift;

	# Go through our children objects and invoke this routine.
	if( defined( $self->{'_curobjs'} ) ){
		my $loop = scalar( @{$self->{'_curobjs'}} );
		while( $loop > 0 ){
			$loop--;
			if( defined( ${$self->{'_curobjs'}}[$loop] ) ){
				# Recurse.
				${$self->{'_curobjs'}}[$loop]->hidetree_recurse();
				# Delete the reference to us.
				${$self->{'_curobjs'}}[$loop]->del_parent_link();
			}
			delete( ${$self->{'_curobjs'}}[$loop] );
		}
	}

}

=head2 toStr

Returns the object in a single string.  Takes an optional hash consisting
of 'FH', being a filehandle reference to send output to instead (useful if
you aren't wanting to copy the object into a local variable), and 
'GenClose', which defaults to 1 and ensures that the first tag has the
proper '/' character when closing the tag.  

If set to '0', '<stream>' will be output instead of '<stream/>', a highly
important distinction when first connecting to Jabber servers (remember that
a Jabber connection is really one long '<stream>' tag ).

=cut

# Note - since this is a recursive call, there are probably too many
# tests to see whether we have a filehandle.  A slight performance
# increase could probably be gained by duplicating the code in 
# a seperate function, but that means that two locations for output
# need to be maintained.

sub toStr {
	my $self = shift;
	my %args = ( FH => undef,
			GenClose => 1,
			@_, );
	my $fh = $args{"FH"};
	my $doend = 0;

	my $dval = $self->_check_val( '_debug' );
	if( $dval ){
		$dval = $self->{'_debug'};
	}

	if( ! $args{"GenClose"} ){
		$doend = 1;
	}

	# Return a string representation of this object.
	my $retstr = "";
	my $usefh = 0;
	my $mustend = 0;
	if( defined( $fh ) ){
		$usefh = 1;
	}

	# $self->debug( "toStr starting\n") if( $dval );
	if( ! $usefh ){
		$retstr = "<" . $self->name();
	}else{
		print $fh "<" . $self->name();
	}

	# See if this is actually processing instructions etc.
	if( $self->name() =~ /^\[CDATA\[/ ){
		if( ! $usefh ){
			$retstr .= $self->{'_cdata'} . "]]";
		}else{
			print $fh $self->{'_cdata'} . "]]";
		}
		$doend = 1;
	}elsif( $self->name() =~ /^\!/ ){
		$mustend = 1;

		# doctype stuff is special.  When we see the
		# pattern '\[\s*\]' within, that means that we
		# insert, at that point, the 'next' subtag object,
		# and so forth.  Annoying stuff.
		my $tstr = "";
		my $tloop = -1;
		my $tstrlength = -1;
		my $stillgoing = 0;
		if( defined( $self->{'_doctype'} ) ){
			$tstrlength = length( $self->{'_doctype'} );
			$stillgoing = 1;
		}

		my $nexttag = 0;
		my $foundopen = -5;
		while( $tloop < $tstrlength && $stillgoing ){
			$tloop++;
			my $thischar = substr( $self->{'_doctype'}, $tloop, 1 );
			if( $thischar eq '[' ){
				$tstr .= $thischar;
				$foundopen = $tloop;
				# Find the next subtag offset.
				if( defined( $self->{'_curobjs'} ) ){
					if( defined( ${$self->{'_curobjs'}}[$nexttag] ) ){
						$tstr .= ${$self->{'_curobjs'}}[$nexttag]->toStr();
						$nexttag++;
					}
				}
			}elsif( $foundopen >= 0 && $thischar !~ /^(\s*|\])$/ ){
				$tstr .= "]";
				$foundopen = -5;
				$tstr .= $thischar;
			}elsif( $foundopen >= 0 && $thischar eq ']' ){
				$foundopen = -5;
				$tstr .= $thischar;
			}elsif( $foundopen < 0 ){
				$tstr .= $thischar;
			}
		}

		if( ! $usefh ){
			$retstr .= $tstr;
		}else{
			print $fh $tstr;
		}
		$doend = 1;
	}elsif( $self->name() =~ /^\?/ ){
		if( defined( $self->{'_processinginstructions'} ) ){
			if( ! $usefh ){
				$retstr .= " " . $self->{'_processinginstructions'};
			}else{
				print $fh " " . $self->{'_processinginstructions'};
			}
		}
		$mustend = 1;
		$doend = 1;
	}

	if( defined( $self->{'_attribs'} ) ){
		if( ! $usefh ){
			foreach my $attribname ( $self->listAttrs ){
				my $attribvalue = $self->attr( $attribname );

				# $retstr .= " " . $attribname . "=\"" . $attribvalue . "\"";
				$retstr .= " " . $attribname . "=\'" . $attribvalue . "\'";
			}
		}else{
			foreach my $attribname ( $self->listAttrs ){
				my $attribvalue = $self->attr( $attribname );

				print $fh " " . $attribname . "=\"" . $attribvalue . "\"";
			}
		}
	}

	$self->debug( "toStr now have $retstr\n" ) if( $dval );

	my $gotmore = 0;
	if( defined( $self->{'_data'} ) ){
		$self->debug( "toStr has _data\n") if( $dval );
		$gotmore++;
	}elsif( defined( $self->{'_curobjs'} ) ){
		$self->debug( "toStr has _cur_objs\n" ) if( $dval );
		if( ( scalar @{$self->{'_curobjs'}} ) > 0 ){
			$gotmore++;
		}
	}
	$self->debug( "toStr G $gotmore M $mustend D $doend\n") if( $dval );

	# Close off the start tag.
	if( ! $gotmore || $mustend ){
		# Complete end of tag.
		if( $self->name() =~ /^\?/ ){
			if( ! $usefh ){
				$retstr .= '?';
			}else{
				print $fh '?';
			}
		}
		if( $doend ){
			if( ! $usefh ){
				$retstr .= '>';
			}else{
				print $fh '>';
			}
		}else{
			if( ! $usefh ){
				$retstr .= '/>';
			}else{
				print $fh '/>';
			}
		}
	}else{
		# There are more tags to insert.
		if( ! $usefh ){
			$retstr .= ">";
		}else{
			print $fh ">";
		}

		# Start running through the list of stuff.  Subtags first.
		if( defined( $self->{'_curobjs'} ) ){
			my $numobjs = scalar @{$self->{'_curobjs'}};

			my $loop = 0;
			if( ! $usefh ){
				while( $loop < $numobjs ){
					$retstr .= ${$self->{'_curobjs'}}[$loop]->toStr();
					$loop++;
				}
			}else{
				while( $loop < $numobjs ){
					${$self->{'_curobjs'}}[$loop]->toStr( FH => $fh );
					$loop++;
				}
			}
		}

		# Now for the data.  No encoding on the output.
		if( defined( $self->{'_data'} ) ){
			if( ! $usefh ){
				$retstr .= $self->rawdata();
			}else{
				print $fh $self->rawdata();
			}
		}

		# Now finish off.
		if( $doend ){
			if( ! $usefh ){
				$retstr .= ">";
			}else{
				print $fh ">";
			}
		}else{
			if( ! $usefh ){
				$retstr .= '</' . $self->name() . ">";
			}else{
				print $fh '</' . $self->name() . ">";
			}
		}
	}	

	$self->debug( "toStr ending with $retstr\n" ) if( $dval );
	# print STDERR "$self returning X $retstr X\n";
	chomp( $retstr );

	# Clean up the return.
	$retstr =~ s/^\s*</</gs;
	$retstr =~ s/>\s*$/>/gs;
	return( $retstr );
}

=head2 GetXML

This is the Net::XMPP::Stanza compatibility call, and simply invokes 
->toStr.  Note for Ryan: where is ->GetXML actually documented?

=cut

sub GetXML {
	my $self = shift;
	return( $self->toStr( @_ ) );
}

=head1 METHODS - Object detailed and other stuff.

=head2 create_and_parse

Creates and returns a new instance of an object.  Invoked by ->do_read() and
->parse_more().  Takes as an optional argument some text to parse.

Returns the new object (or undef), a success value, and any unprocessed text.
Success values can be one of:

	-2 Invalid XML
	0 No errors
	1 Complete object

=cut

sub create_and_parse {
	my $self = shift;

	my $str = shift;

	$self->debug( " Invoked with $str X\n" );

	my $retobj = undef;
	my $retstr = "";
	my $retval = 0;

	# We expect to find '<text/>' or '<text>' or '<text blah="sdf"/>'
	# or '<text blah="sdf">'

	# See if there is a complete word.
	if( defined( $str ) ){
		my $tagstr = "";
		my $isend = 0;
		my $curstatus = "unknown";
		my $gotlength = 0;
		my $gotfull = 0;
		# Match '<name.*>' or '<name.*/>'.
		# All parsing is done by parse_more.
		if( $str =~ /^(\s*<(\S+.*))$/s ){
			$gotlength = length( $1 );
			$tagstr = $2;
			$curstatus = "name";
		}

		# Prepare the string to return.
		if( $gotlength > 0 ){

			# Return the string minus the stuff we just read.
			$retstr = substr( $str, $gotlength );

			# Process the tag string.  We just look for
			# the first bit of text giving the name, then
			# we pass the rest of the processing to 
			# parse_more.

			# Create the object.  Use a null string at first.
			$retobj = $self->newNode( "" );

			# Set the status indicator on this object
			# for later usage.
			$retobj->{'_cur_status'} = $curstatus;

			# Copy the list of tags we expect to be incomplete.
			if( defined( $self->{'_expect-incomplete'} ) ){
				$retobj->{'_expect-incomplete'} = $self->{'_expect-incomplete'};
			}
				
			my $tval = 0;
			my $rtext = "";

			# Pass it off to parse_more.
			( $tval, $rtext ) = $retobj->parse_more( $tagstr );
			# $self->debug( "parse_more returned $tval, $rtext X" );

			# There shouldn't be anything left in
			# rtext.  What do we do if there is?
			# Add it to the text to be returned,
			# and processed later.
			if( length( $rtext ) > 0 ){
				$retstr = $rtext;
			}else{
				$retstr = "";
			}

			# Return what this one received.
			$retval = $tval;

		}elsif( $str =~ /^\s*$/sm ){
			# Swallow whitespace.
			$retstr = "";
		}else{
			# XML Parse error; there are characters and they
			# are not whitespace or object start.  Bad.
			$retstr = $str;
			$retval = -2;
		}
	}

	$self->debug( " Returning $retobj, $retval, $retstr\n" );
	# Return the object and the string to return.
	return( $retobj, $retval, $retstr );
}

=head2 parse_more

Parses some text and adds it to an existing object.  Creates further
sub-objects as appropriate.  Returns a success value, and any unprocessed
text.  Success values can be one of:

	-2 if a parsing error was found.
	0 if no obvious bugs were found.
	1 if a complete object was found.

The parser, such as it is, will sometimes return text to be prepended with
any new text.  If the calling application does not keep track of the 
returned text and supply it the next time, the parser's behaviour is 
undefined.  Most applications will be invoking ->parse_more() via 
->do_read or ->process(), so this situation will not come up.

This needs 

An optional second argument can be supplied which, if 1, will inhibit the 
saving of most text to memory.  This is used by do_read to indicate that an
excessively-large object is being read.

=cut

sub parse_more {
	my $self = shift;

	my $str = shift;

	my $dval = $self->_check_val( '_debug' );
	if( $dval ){
		$dval = $self->{'_debug'};
	}
	if( defined( $self->name() ) ){
		$self->debug( " " . $self->name() . " Invoked with $str\n" ) if( $dval );
	}else{
		$self->debug( " (no name) Invoked with $str\n" ) if( $dval );
	}

	my $retval = 0;
	my $retstr = "";

	# Make sure that we have something to work on.
	if( ! defined( $str ) ){
		return( $retval, $retstr );
	}elsif( $str =~ /^$/ ){
		return( $retval, $retstr );
	}

	# What is our current status?
	my $curstatus = "subtag";
	if( defined( $self->{'_cur_status'} ) ){
		$curstatus = $self->{'_cur_status'};
	}

	# Keep looping until we run out of text.
	my $pmloop = 5;

	while( $pmloop > 0 && length( $str ) > 0 ){
		$pmloop--;

		$self->debug( " $pmloop status of $curstatus\n" ) if( $dval );

		# First possible - adding to the name.  The text received
		# is a continuation of the name.
		if( $curstatus eq "name" ){
			if( $str =~ /^(\S+)(\s+.*)?$/s ){
				my $namefurther = $1;
				$str = $2;

				# Deal with 'dfgdg><dljgdlgj>', which could be
				# read as a continuation of the name.
				if( $namefurther =~ /^([^\/]*\/>)(.*)$/s ){
					$namefurther = $1;

					# This juggling is to avoid a warning.
					my $r2 = $2;
					my $ostr = $str;
					$str = "";
					if( defined( $r2 ) ){
						$str = $r2;
					}
					if( defined( $ostr ) ){
						$str .= $ostr;
					}
				}elsif( $namefurther =~ /^([^>]*>)(.*)$/s ){
					$namefurther = $1;

					# This juggling is to avoid a warning.
					my $r2 = $2;
					my $ostr = $str;
					$str = "";
					if( defined( $r2 ) ){
						$str = $r2;
					}
					if( defined( $ostr ) ){
						$str .= $ostr;
					}
				}
		
				# Add it to the current name.	
				$self->{'_name'} .= $namefurther;

				# See if we've incorporated a possible end tag into
				# this.  We do the test on the completed name instead
				# of the string received in case we received the
				# '/' during the previous call.
				# We send it back if we did.
				if( $self->{'_name'} =~ /^\!\-\-(.*)$/s ){
					# Start processing a comment.
					$curstatus = "comment";
					$self->{'_name'} = '!--';
					$str = $1 . $str;

				}elsif( $self->{'_name'} =~ /^(\!\[CDATA\[)(.*)$/ ){
					$curstatus = "cdata";
					$self->{'_name'} = $1;
					$str = $2 . $str;

				}elsif( $self->{'_name'} =~ /\/$/s ){
					# Possible start of '/>' .  Send it back.
					# If its actually 'sdlfk//sdf', it'll be
					# properly parsed next time.
					chop( $self->{'_name'} );
					$str = '/' . $str;
					$curstatus = "name";

				}elsif( $self->{'_name'} =~ /\/>$/s ){
					# Definitely bad.  Chop off the last 
					# two characters.
					chop( $self->{'_name'} );
					chop( $self->{'_name'} );

					# Then mark ourselves as being complete.
					$self->{'_is_complete'} = 1;
					$retval = 1;
					$curstatus = "complete";

				}elsif( $self->{'_name'} =~ /\?>$/s && $self->{'_name'} =~ /^\?/ ){
					# This is 'processing instructions'.
					chop( $self->{'_name'} );
					chop( $self->{'_name'} );
					$curstatus = "complete";

				}elsif( $self->{'_name'} =~ />$/s ){
					# name is 'sdfj>'.  Means that we've reached
					# the end of the tag name, but not the end
					# of the tag.  Remove the '>', and indicate
					# what we've got.
					chop( $self->{'_name'} );
					$curstatus = "subtag";

					if( $self->{'_name'} =~ /^\!/ ){
						$curstatus = "complete";
					}

					# This point is good for checking
					# whether this name matches the
					# one specified as 'expect-incomplete'.
					if( defined( $self->{'_expect-incomplete'} ) ){
						if( defined( $self->{'_expect-incomplete'}{$self->{'_name'}} ) ){
							$curstatus = "complete";
						}
					}

				}elsif( defined( $str ) ){
					# We've got a space.  The name has been 
					# completed.
					$curstatus = "attribs";

					# See if this is special stuff.
					if( $self->{'_name'} =~ /^\!/ ){
						$curstatus = "doctype";
					}elsif( $self->{'_name'} =~ /^\?/s ){
						$curstatus = "processinginstructions";
					}elsif( $self->{'_name'} =~ /^(\!\[CDATA\[)(.*)$/ ){
						$curstatus = "cdata";
						$self->{'_name'} = $1;
						$str = $2 . $str;
					}

				}elsif( ! defined( $str ) ){
					$str = "";
				}

				$self->debug( " ($curstatus) Remaining is $str X\n" ) if( $dval );


			# A space, indicating the end of the name tag, and onto the
			# attributes.
			}elsif( $str =~ /^\s+(\S+.*)$/s ){
				$str = $1;
				$curstatus = "attribs";
			}

			# Check for comments.  Second check in case we missed 
			# something.
			if( $curstatus eq "attribs" ){
				if( $self->{'_name'} =~ /^\!\-\-(.*)$/s ){
					# Start processing a comment.
					$curstatus = "comment";
					$str = $1 . $str;
				}elsif( $self->{'_name'} =~ /^\!/ ){
					$curstatus = "doctype";
				}elsif( $self->{'_name'} =~ /^\?/s ){
					$curstatus = "processinginstructions";
				}elsif( $self->{'_name'} =~ /^(\!\[CDATA\[)(.*)$/ ){
					$curstatus = "cdata";
					$self->{'_name'} = $1;
					$str = $2 . $str;
				}
			}

			# Finally, check for a valid name.
			if( $curstatus ne "name" ){
				if( $self->{'_name'} !~ /^[A-Za-z][A-Za-z0-9\-\_\:\.]*$/ ){
					if( $self->{'_name'} !~ /^(\?|\!)(\S+)/ ){
						# Invalid XML!
						$retval = -2;
						$retstr = $str;
						return( $retval, $retstr );
					}
				}
			}
		}

		# The string is (or is now) text that is stuff with the doctype
		# declaration.
		if( $curstatus =~ /^(doctype|processinginstructions|cdata)/ ){
			my $strlength = ( length( $str ) - 1 );

			my $loop = -1;
			my $stillgoing = 1;
			my $prevquery = -5;

			while( $loop < $strlength && $stillgoing ){
				$loop++;
				my $thischar = substr( $str, $loop, 1 );
				if( $curstatus eq "doctype" ){
					if( $thischar eq '[' ){
						$curstatus = "subtag";
						$stillgoing = 0;
						$self->{'_doctype'} .= $thischar;
						next;
					}elsif( $thischar eq '>' ){
						$curstatus = "complete";
						$stillgoing = 0;
						next;
					}else{
						$self->{'_doctype'} .= $thischar;
						next;
					}
				}elsif( $curstatus eq "processinginstructions" ){
					if( $thischar eq '>' ){
						$self->{'_processinginstructions'} .= $thischar;
						# See if this is the end pattern?
						if( $self->{'_processinginstructions'} =~ /\?>$/s ){
							$self->{'_processinginstructions'} =~ s/\?>$//sg;
							# chomp( $self->{'_processinginstructions'} );
							$self->debug( " PI is " . $self->{'_processinginstructions'} . " X " . $str . " X\n" ) if( $dval );
							# $loop++;
							$curstatus = "complete";
							$stillgoing = 0;
						}
						next;
					}elsif( $thischar eq '?' ){
						$prevquery = '?';
						$self->{'_processinginstructions'} .= $thischar;
					}else{
						$self->{'_processinginstructions'} .= $thischar;
					}
				}elsif( $curstatus eq "cdata" ){
					if( $thischar eq '>' ){
						$self->{'_cdata'} .= $thischar;
						# See if this is the end pattern?
						if( $self->{'_cdata'} =~ /\]\]>$/s ){
							chomp( $self->{'_processinginstructions'} );
							chomp( $self->{'_processinginstructions'} );
							chomp( $self->{'_processinginstructions'} );
							$curstatus = "complete";
							$stillgoing = 0;
						}
					}else{
						$self->{'_cdata'} .= $thischar;
					}
				}
			}

			# Supply the remaining text to return.
			if( $loop < $strlength ){
				# Remember that $loop is the character that we
				# have read, and $strlength has been decremented
				# already.  So adding 1 to $loop is ok.
				$str = substr( $str, ( $loop + 1 ) );
			}else{
				$str = "";
			}
		}

		# The string is (or is now) text that is possibly attribute text.
		# It gets split up based on spaces.
		if( $curstatus =~ /^attrib/ ){

			# The attribute text looks like 'dsfkl="dfg dg" dlgkj="dg"',
			# with a possible end character as well.  At first glance,
			# we can split between seperate attribute name=value pairs
			# by using whitespace, however whitespace within the 
			# attribute value is possibly significant.  We _must_ keep
			# it in place.  The next method of doing this is character
			# by character, which is a royal pain in the ass to do.
			# Since we don't know how big the string is, using 
			# split( // ) simply duplicates the string.  Ugg.
			# So we continually use substr to peek at each character 
			# in turn.
			my $strlength = ( length( $str ) - 1 );

			my $loop = -1;

			my $stillgoing = 1;
			my $prevforslash = -5;	# Need for a numeric comparison.
			my $prevbacslash = -5;	# Need for a numeric comparison.
			my $whitestart = -5;	# Need for a numeric comparison.
			my $prevquery = -5;	# Need for a numeric comparison.

			while( $loop < $strlength && $stillgoing ){
				$loop++;

				# What are we currently doing?  Adding to a current
				# attribute or just waiting for a new attribute?
				# $curstatus is one of:
				#	attribs	- toss out whitespace, wait for
				#		  next attribute or end marker.
				#	attrib-n - Finishing up a name, stored in
				#		   '_cur_attrib_name'.  Look for '='.
				#	attrib-s-fooble - Looking for a seperator
				#			  character to save in 
				#			  '_cur_attrib_end'
				#	attrib-v-fooble - Adding data to an attribute,
				#			  saving everything except for
				#			  the value in '_cur_attrib_end'
				#
				my $thischar = substr( $str, $loop, 1 );

				if( $curstatus eq "attribs" ){
					# Is this whitespace?
					if( $thischar =~ /^\s*$/s ){
						# Yup.  Ignore it.
						if( $whitestart < 0 ){
							$whitestart = $loop;
						}
						next;
					}elsif( $thischar eq '/' ){
						# Possible start of end.  We ignore
						# it as it cannot be the start of
						# an attribute name.
						$prevforslash = $loop;
						$whitestart = -5;
						next;
					}elsif( $thischar eq '?' && $self->{'_name'} =~ /^\?/  ){
						# Possible start of end when dealing
						# with 'processinginstructions'.
						$prevquery = $loop;
						$whitestart = -5;
						next;
					}elsif( $thischar eq '>' ){

						# End of the tag name.  See if this
						# is the actual end, or start of
						# subtags, based on the value of 
						# $prevforslash.
						$stillgoing = 0;

						# Is '/ >' the same as '/>' ?  Have
						# kept $whitestart updated in case	
						# it is.
						if( $prevforslash == ( $loop - 1 ) ){
							$curstatus = "complete";
						}elsif( $prevquery == ( $loop - 1 ) && $self->{'_name'} =~ /^\?(.*)$/s ){
							# processing instructions.  This
							# gets treated as a tag on its
							# own.
							$curstatus = "complete";
						}elsif( $prevquery != ( $loop - 1 ) && $self->{'_name'} =~ /^\?(.*)$/s ){
							# Current tag is the
							# processing instructions,
							# which can only be
							# closed by the '?>' 
							# construct.  So, we 
							# ignore this.
							$stillgoing = 1;
						}elsif( $self->{'_name'} =~ /^\!(\S+)$/s ){
							$curstatus = "complete";
						}else{
							$curstatus = "subtag";
						}
						next;

					# First character of an attribute name can
					# be a letter, underscore or colon.
					}elsif( $thischar =~ /^[A-Za-z\_\:]$/s ){
						# Start of an attribute name.
						$curstatus = "attrib-n";
						$self->{'_cur_attrib_name'} = $thischar;
						next;
					}else{
						# Invalid character.  Do we complain
						# about this, or do we silently drop
						# it?
						$whitestart = -5;

						# We complain.
						$retval = -2;
						$stillgoing = 0;
						next;
					}

				#	attrib-n - Finishing up a name, stored 
				#	in '_cur_attrib_name'.  Look for '='.
				}elsif( $curstatus eq "attrib-n" ){
					# We add to the name, finishing when either
					# whitespace (value is stored as 'undef'),
					# or '=' is found.
					if( $thischar eq '=' ){
						$curstatus = "attrib-s-" . $self->{'_cur_attrib_name'};
						$self->{'_attribs'}{$self->{'_cur_attrib_name'}} = undef;
						$self->{'_cur_attrib_name'} = undef;
						next;
					}elsif( $thischar =~ /^\s+$/s ){
						$curstatus = "attribs";
						$self->{'_attribs'}{$self->{'_cur_attrib_name'}} = undef;
						$self->{'_cur_attrib_name'} = undef;
						next;
					}else{
						$self->{'_cur_attrib_name'} .= $thischar;
						next;
					}

				#	attrib-s-fooble - Looking for a 
				#			  seperator character 
				#			  to save in 
				#			  '_cur_attrib_end'
				}elsif( $curstatus =~ /^attrib-s-(\S+)$/ ){
					my $tname = $1;
					if( $thischar =~ /^(\"|\')$/s ){
						$self->{'_cur_attrib_end'} = $thischar;
						$curstatus = "attrib-v-" . $tname;
					}elsif( $thischar =~ /^\s+$/s ){
						next;
					}
		
				#	attrib-v-fooble - Adding data to an 
				#			  attribute, saving 
				#			  everything except
				#			  for the value in 
				#			  '_cur_attrib_end'
				}elsif( $curstatus =~ /^attrib-v-(\S+)$/s ){
					my $tname = $1;

					if( $thischar eq $self->{'_cur_attrib_end'} ){
						# Code for escaping the quote.  This
						# isn't valid XML though, so it is
						# commented out.
						# if( $prevbacslash == ( $loop - 1 ) ){
							# $self->{'_attribs'}{$tname} .= $thischar;
						# }else{
							$curstatus = "attribs";

						# XXXX - Attribute Value
						# Normalisation - 3.3.3
							next;
						# }
					}elsif( $thischar eq "\\" ){
						# We store this just in case.
						$prevbacslash = $loop;
						$self->{'_attribs'}{$tname} .= $thischar;
						next;
					}elsif( $thischar eq '<' ){
						# 3.1 - Attribute Values
						# MUST NOT contain a '<'
						# character.
						$retval = -2;
						$retstr = $str;
						return( $retval, $retstr );
						next;
					}else{
						$prevbacslash = -5;
						$self->{'_attribs'}{$tname} .= $thischar;
						next;
					}
				}
			}
			
			# Now, we retrieve the text to be returned.  This is based on
			# the $loop value, to retrieve the text further passed that.

			$self->debug( "End of loop: $curstatus $loop, $strlength, $str X\n" ) if( $dval );
			if( $loop < $strlength ){
				# Remember that $loop is the character that we
				# have read, and $strlength has been decremented
				# already.  So adding 1 to $loop is ok.
				$str = substr( $str, ( $loop + 1 ) );
			}elsif( $prevforslash == $loop ){
				$str = '/';
			}else{
				$str = "";
			}

			$self->debug( " seeing whether curstatus ($curstatus) is subtag and name (" . $self->name() . ") is in incomplete\n" ) if( $dval );
			if( $curstatus eq 'subtag' ){
				# This point is good for checking
				# whether this name matches the
				# one specified as 'expect-incomplete'.
				if( defined( $self->{'_expect-incomplete'} ) ){
					$self->debug( " curstatus is subtag, and incomplete is " . $self->{'_expect-incomplete'} . "\n" ) if( $dval );
					$self->debug( " incomplete hash exists\n" ) if( $dval );
					if( defined( $self->{'_expect-incomplete'}{$self->{'_name'}} ) ){
						$self->debug( " incomplete matches\n" ) if( $dval );
						$curstatus = "complete";
					}
				}else{
					$self->debug( " curstatus is subtag, and incomplete is undef" ) if( $dval );
				}
			}

		}

		# The processing of the subtag setting.  This reads as being
		# 'subtag' if we're about to enter the first subtag, and
		# 'subtag-num-foo' if we're in a particular subtag.  Subtags
		# are stored in @{$self->{'_curobjs'}{'foo'}}, and numbered
		# offsets.  Each subtag is essentially another copy of this,
		# with its own data.
		my $canparse = 1;
		my $numloops = 5;
		while( $curstatus =~ /^subtag/s && $canparse && $retval != -2 && $numloops > 0 ){
			$numloops--;

			# No sense parsing the unparsable.
			if( length( $str ) < 1 ){
				$canparse = 0;
				next;
			}

			# Subtag or end tag.
			my $istag = 1;
			if( $curstatus eq 'subtag' ){
				# Everything we read in here until the next
				# '<' character is treated as data on this
				# object.
				my $strlength = length( $str ) - 1;
				my $loop = -1;
				my $stillgoing = 1;

				my $tagstarts = -5;
				while( $loop < $strlength && $stillgoing ){
					# Only thing significant at this point
					# is the '<' character.
					$loop++;
					my $thischar = substr( $str, $loop, 1 );
					# XXXX should also check for '&' escapes
					# This may mean pushing them back.
					if( $thischar eq '&' ){
						# We must have a full escape,
						# which means terminated by a
						# ';' character.
						my $rstr = substr( $str, $loop );
						if( $rstr =~ /^\&(\#[0-9]+|\#x[A-Fa-f0-9]+|[A-Fa-z][A-Fa-f0-9\-\_\:\.]*|[a-z]+);(.*)$/s ){
							my $entlookup = $1;
							# my $remaining = $2;
							my $rtext = $self->expandEntity( $entlookup );
							if( ! defined( $rtext ) ){
								# Invalid XML.
								$retval = -2;
								$retstr = $rstr;
								return( $retval, $retstr );
							}else{
								$self->{'_data'} .=  $rtext;
							}
							# Continue processing where we left off.
							$loop += length( '&' . $entlookup . ';' );

						}elsif( $rstr =~ /^\&[^;]*\s+/ ){
							# Invalid XML
							$retval = -2;
							$retstr = $rstr;
							return( $retval, $retstr );
						}else{
							# Insufficient data
							# Push it back.
							$self->debug( "pushing back on $thischar as $rstr is not a complete html escape." ) if( $dval );
							$stillgoing = 0;
						}
					
					}elsif( $thischar ne '<' ){
						$self->{'_data'} .= $thischar;
					}else{
						# End of processing for now.
						$stillgoing = 0;
					}
				}

				# The loop has ended.  Sort out the remaining
				# string.  We want the last character we looked at,
				# as it is significant.
				if( $loop <= $strlength && $stillgoing == 0 ){
					$str = substr( $str, $loop );
				}else{
					$str = "";
				}

				# We're expecting '</' or '<'.
				$strlength = length( $str );
				if( $strlength < 2 ){
					# Insufficient data.  We must know whether
					# the next two characters are '</' or not.
					# Punt till next time.
					$istag = 0;
					$canparse = 0;
				}else{
					# Sufficient data to be sure.
					if( $str =~ /^<\//s ){
						$curstatus = "endname";
						$str = substr( $str, 2 );
						$self->{'_cur_endname'} = "";
					}else{
						$curstatus = "subtag";
						$istag = 1;
					}
				}
			}

			# Once again with feeling.
			if( $curstatus eq 'subtag' && $istag ){

				# We're creating a new object.
				my ( $tobj, $tval, $rtext ) = $self->create_and_parse( $str );
				if( defined( $tobj ) ){

					# Keep the remaining portion.
					$str = $rtext;

					# Whats the next scalar value of this one?
					my $nextnum = 0;
					if( defined( $self->{'_curobjs'} ) ){
						$nextnum = scalar @{$self->{'_curobjs'}};
					}

					# Set the parent.
					$tobj->parent( $self );

					# Store it.
					${$self->{'_curobjs'}}[$nextnum] = $tobj;

					# Store the status.
					$curstatus = "subtag-" . $nextnum;

					$self->debug( "setting7 status to $curstatus - nextnum is $nextnum X\n" ) if( $dval );

					# If this one was considered to be complete,
					# change back to waiting for the next one.
				
					# Check for completeness.
					if( $tobj->is_complete() ){
						$curstatus = "subtag";
						$retval = 0;
						if( ! defined( $self->{'_name'} ) ){
							# print STDERR "I have no name and I must scream\n";
							$self->debug( "I have no name?  This is odd." ) if( $dval );
						}elsif( $self->{'_name'} =~ /^\?/ ){
							$curstatus = "processinginstructions";
						}elsif( $self->{'_name'} =~ /^\!/ ){
							$curstatus = "doctype";
						}
						$self->debug( " found complete, back to $curstatus - returning $rtext X\n" ) if( $dval );
					}
				}

				# Did we get something invalid?
				if( $tval == -2 ){
					$retval = -2;
				}

				# Try removing the reference here.
				$tobj = undef;
			}

			# Add the remaining text to the given subtag.
			if( $curstatus =~ /^subtag\-(\d+)$/s  ){
				my $offnum = $1;
				my $strlength = length( $str );

				if( $retval != -2 && defined( ${$self->{'_curobjs'}}[$offnum] ) && $strlength > 0 ){
					my( $tval, $rtext ) = ${$self->{'_curobjs'}}[$offnum]->parse_more( $str );
					$str = $rtext;
					if( $tval == -2 ){
						$retval = -2;
						$canparse = 0;
					}

					# Was this one complete?
					if( ${$self->{'_curobjs'}}[$offnum]->is_complete() ){
						# It was.  Go back to looking for
						# additional stuff to add to this
						# object.
						$curstatus = "subtag";
						$self->debug( " setting8 status to $curstatus - offnum is $offnum X\n" ) if( $dval );
						# Are we actually elsewhere?
						if( $self->{'_name'} =~ /^\?/ ){
							$curstatus = "processinginstructions";
						}elsif( $self->{'_name'} =~ /^\!/ ){
							$curstatus = "doctype";
						}
					}elsif( length( $str ) < 2 ){
						$canparse = 0;
					}
				}
			}
		}

		# Finally, see if we're closing an end tag.
		if( $curstatus eq 'endname' ){
			# The name that we're closing is in '_cur_endname', and
			# must match name(), eventually.  We loop through
			# the string looking for '>'.
			my $strlength = length( $str ) - 1;
			my $loop = -1;
			my $stillgoing = 1;
			while( $loop < $strlength && $stillgoing ){
				$loop++;
				my $thischar = substr( $str, $loop, 1 );
				if( $thischar eq '>' ){
					# Does it match?
					if( $self->{'_cur_endname'} eq $self->name() ){
						$curstatus = "complete";
						$retval = 1;
					}else{
						# Does not match.  Invalid XML.
						$retval = -2;
					}
					$stillgoing = 0;
					
				}elsif( $thischar =~ /^\s+$/s ){
					$retval = -2;
					$stillgoing = 0;
				}else{
					$self->{'_cur_endname'} .= $thischar;
				}
			}

			# Get the remaining text.
			$str = substr( $str, $loop + 1 );
		}


		# Digest comments.
		if( $curstatus eq 'comment' ){
			$self->debug( " - comment with $str X\n" ) if( $dval );
			# Throw out stuff except for '-->'.  Push back any '-' 
			# characters, but no more than two.
			if( $str =~ /(\-\-)([^>]+.*)$/s ){
				$self->debug( "doubledash found with no >\n" ) if( $dval );
				# '--' must not appear within a comment
				# except when closing a comment.
				# section 2.5.
				$retval = -2;
				$retstr = $2;
				return( $retval, $retstr );
			}elsif( $str =~ /^([^>]+)>(.*)$/s ){
				$self->debug( "closing > found\n" ) if( $dval );
				my $doq = $1;
				$str = $2;
				if( $doq =~ /\-\-$/ ){
					$curstatus = "complete";
					$retval = 1;
				}
			}elsif( $str =~ /^(.*)(\-{1,2})$/s ){
				$str = $2;
			}else{
				$str = "";
			}
		}

		# Digest processing instructions
		if( $curstatus eq 'processinginstructions' ){
			# Throw out stuff except for '?>'.  Push back any '?' 
			# characters, but no more than one.
			if( $str =~ /^([^>]+)>(.*)$/s ){
				my $doq = $1;
				$str = $2;
				if( $doq =~ /\?$/ ){
					$curstatus = "complete";
				}
			}elsif( $str =~ /^(.*)(\?)$/s ){
				# Push back '?' characters.
				$str = $2;
			}else{
				$str = "";
			}
		}

		if( $curstatus eq 'complete' ){

			# Do check on the data stuff.
			$self->{'_is_complete'} = 1;
			$pmloop = 0;

			# Do the doctype parsing.  This isn't as robust
			# as it could be.
			if( $self->{'_name'} =~ /^!ENTITY$/ ){
				if( $self->{'_doctype'} =~ /^\s*(\S+)\s+(\S+.*)\s*$/ ){
					my $ename = $1;
					my $evalue = $2;
					if( $evalue =~ /^\"/ ){
						$evalue =~ s/^\"//g;
						$evalue =~ s/\"$//g;
					}elsif( $evalue =~ /^\'/ ){
						$evalue =~ s/^\'//g;
						$evalue =~ s/\'$//g;
					}
					$self->{'_entities'}{"$ename"} = $evalue;
				}
			}
		}else{
			$self->{'_is_complete'} = undef;
		}
	}

	# Record our current status.
	$self->{'_cur_status'} = $curstatus;

	# Patch up.
	if( $curstatus eq "complete" && $retval >= 0 ){
		$self->{'_is_complete'} = 1;
		$retval = 1;
	}

	$self->debug( " Returning ($curstatus) $retval and $str\n" ) if( $dval );
	# print STDERR "$self: Returning ($curstatus) $retval and $str\n" ;
	return( $retval, $str );
}

=head2 _curstatus 

Returns the current status of the parser on the current object.  
Used by the ->connect method, but may be useful in debugging the
parser.

=cut

sub _curstatus {

	my $self = shift;

	my $retval = "";
	if( defined( $self->{'_cur_status'} ) ){
		$retval = $self->{'_cur_status'};
	}elsif( defined( $self->{'_curobj'} ) ){
		$retval = $self->{'_curobj'}->_curstatus();
	}
	return( $retval );
}

=head2 encode

When passed a string, returns the string with appropriate XML escapes
put in place, eg '&' to '&amp;', '<' to '&lt;' etc.

=cut

# encode and decode copied from Jabber::NodeFactory;
sub encode {
	my $self = shift;

	my $data = shift;

	$data =~ s/&/&amp;/g;
	$data =~ s/</&lt;/g;
	$data =~ s/>/&gt;/g;
	$data =~ s/'/&apos;/g;
	$data =~ s/"/&quot;/g;

	return $data;

}

=head2 decode

When passed a string, returns the string with the XML escapes reversed,
eg '&amp;' to '&' and so forth.

=cut

sub decode {
	my $self = shift;

	my $data = shift;

	$data =~ s/&amp;/&/g;
	$data =~ s/&lt;/</g;
	$data =~ s/&gt;/>/g;
	$data =~ s/&apos;/'/g;
	$data =~ s/&quot;/"/g;

	return $data;

}

=head2 expandEntity

When passed an '&' escape string, will return the text that it expands
to, based on both a set of predefined escapes, and any escapes that may
have been _previously_ defined within the document.  Will return undef
if it cannot expand the string.  

This function is non-intuitive, as it will replace 'amp' with 'amp', but
'pre-defined-escape' with 'text that was declared in the <!ENTITY>
declaration for pre-defined-escape'.  Its prime usage is in the storage
of hopefully-compliant-XML data into the object, and is used as part
of the data verification routines.

=cut

sub expandEntity {
	my $self = shift;

	my $retval = undef;

	# XXXX - This ties into the doctype declarations, which are all
	# stored right at the parent object (no sense copying them).  So
	# we go all the way back up to the parent to expand the string, even
	# if it is simply 'amp'.
	if( defined( $self->parent ) ){
		return( $self->parent->expandEntity( @_ ) );
	}else{
		my $arg = shift;

		# 4.6 of XML-core
		my %predefents = ( "lt",	"lt",
				   "gt",	"gt",
				   "amp",	"amp",
				   "apos",	"apos",
				   "quot",	"quot",
				);

		if( defined( $predefents{"$arg"} ) ){
			$retval = $predefents{"$arg"};

		# WARNING - This does not properly handle Unicode.
		}elsif( $arg =~ /^#(\d+)$/ ){
			# Numeric reference.  Grumble.
			$retval = chr( $1 );
		}elsif( $arg =~ /^#x([A-Fa-f0-9])+$/ ){
			# Hexadecimal reference.
			$retval = chr( 0x . $arg );

		# Maybe its something that has been defined?
		}elsif( defined( $self->{'_entities'}{"$arg"} ) ){
			$retval = $self->{'_entities'}{"$arg"};
		}
	}

	return( $retval );
}

=head2 ConstXMLNS 

This helper function keeps several xmlns strings in one place, to make for
easier (sic) upgrading.  It takes one argument, and returns the result of
that argument's lookup.

=cut

sub ConstXMLNS {
	my $self = shift;

	my $arg = shift;

	# Copied from XML::Stream
	my %xmlnses = ( 'client',	"jabber:client",
			'component',	"jabber:component:accept",
			'server',	"jabber:server",
			'iq-auth',	"http://jabber.org/features/iq-auth",
			'stream',	"http://etherx.jabber.org/streams",
			'xmppstreams',	"urn:ietf:params:xml:ns:xmpp-streams",
			'xmpp-bind',	"urn:ietf:params:xml:ns:xmpp-bind",
			'xmpp-sasl',	"urn:ietf:params:xml:ns:xmpp-sasl",
			'xmpp-session',	"urn:ietf:params:xml:ns:xmpp-session",
			'xmpp-tls',	"urn:ietf:params:xml:ns:xmpp-tls",
			);

	return( $xmlnses{"$arg"} );
}

=head2 _got_Net_DNS

Helper function to load Net::DNS into the current namespace.

=cut

sub _got_Net_DNS {
	my $self = shift;

	my $retval = 0;

	eval {
		require Net::DNS;
		$retval++;
	};

	$self->debug( " returning $retval\n" );
	return( $retval );
}

=head2 _got_Digest_SHA1

Helper function to load Digest::SHA1 into the current namespace.

=cut

sub _got_Digest_SHA1 {
	my $self = shift;

	my $retval = 0;

	eval {
		# Eric Hacker found a problem where these 'use' lines within
		# the 'eval' were being acted on on the program load; not
		# execution.
		# use Digest::SHA1 qw(sha1_hex);
		require Digest::SHA1;
		$retval++;
	};

	$self->debug( " returning $retval\n" );
	return( $retval );
}

=head2 _got_Digest_MD5

Helper function to load Digest::MD5 into the current namespace.

=cut

sub _got_Digest_MD5 {
	my $self = shift;

	my $retval = 0;

	eval {
		require Digest::MD5;
		$retval++;
	};

	$self->debug( " returning $retval\n" );
	return( $retval );
}

=head2 _got_Authen_SASL

Helper function to load Authen::SASL into the current namespace.

=cut

sub _got_Authen_SASL {
	my $self = shift;

	my $retval = 0;

	eval {
		require Authen::SASL;
		$retval++;
	};

	$self->debug( " returning $retval\n" );
	return( $retval );
}

=head2 _got_MIME_Base64

Helper function to load MIME::Base64 into the current namespace.

=cut

sub _got_MIME_Base64 {
	my $self = shift;

	my $retval = 0;

	eval {
		require MIME::Base64;
		$retval++;
	};

	$self->debug( " returning $retval\n" );
	return( $retval );
}

=head2 _got_IO_Socket_SSL

Helper function to load IO::Socket::SSL into the current namespace.

=cut

sub _got_IO_Socket_SSL {
	my $self = shift;

	my $retval = 0;

	eval {
		require IO::Socket::SSL;
		$retval++;
	};

	$self->debug( " returning $retval\n" );
	return( $retval );
}

=head2 debug

Debug is vor finding de bugs!

Prints the supplied string, along with some other useful information, to
STDERR, if the initial object was created with the debug flag.

=cut

sub debug {
	my $self = shift;
	my $arg = shift;

	chomp( $arg );

	# This check is repeated in some functions, to avoid the
	# overhead of invoking ->debug as they are called very frequently.
	my $dval = $self->_check_val( '_debug' );
	if( $dval ){
		$dval = $self->{'_debug'};

		# Do this before invoking caller(); saves oodles of time.
		if( $dval eq "0" ){
			return( 0 );
		}
	}else{
		return( 0 );
	}

	my @calledwith = caller(1);
	my $callingname = $calledwith[3];
	my $callingpkg = $calledwith[0];
	my $lineno = $calledwith[2];
	my $selfref = ref( $self );
	if( $selfref eq $callingpkg ){
		$callingname =~ s/^$callingpkg\:\://g;
	}else{
		$callingname =~ s/^.*://g;
	}

	my $cango = 0;
	if( $dval eq "1" ){
		$cango++;
	}elsif( $dval =~ /(^|,)$callingname(,|$)/ ){
		$cango++;
	}
	print STDERR "DEBUG: $lineno " . time . " $dval:" . $self . "->$callingname: " . $arg . "\n" if( $cango );
	return( $cango );
}

=head2 version

Returns the major version of the library.

=cut

sub version {
	return( $VERSION );
}

=head1 HISTORY

September 2005: During implementation of a Jabber-based project,
the author encountered a machine which for political reasons, could not
be upgraded to a version of perl which supported a current version of
various Jabber libraries.  After getting irritated with having to build
a completely new standalone perl environment, together with the ~10 meg, 
no 11, no 12, no 15 (etc), footprint of libraries required to support 
XML::Parser, the desire for a lightweight Jabber library was born.

December 2005: The author, merrily tossing large chunks of data through
his Jabber servers, discovered that XML::Parser does not deal with
large data sizes in a graceful fashion.

January 2006: The author completed a version which would, at least, not 
barf on most things.

January through September 2006: Being busy with other things, the author
periodically ran screaming from memory leakage problems similar to 
XML::Parser..  Finally, a casual mention in one of the oddest places 
lead the author to a good explanation of how Perl does not deal with
circular dependencies.

=head1 PREREQUISITES / DEPENDENCIES

IO::Socket::INET, IO::Select .  Thats it.  Although, if you want encryption
on your connection, SASL support or reasonable garbage collection in various
versions of perl, there are soft dependencies on:

=over 4

=item IO::Socket::SSL

Library for handling SSL/TLS encryption.

=item MIME::Base64

This is used for some authentication methods.

=item Authen::SASL

SASL magic.  Hooray.

=item Digest::SHA1

This is used for some authentication methods.

=item Scalar::Util

Helps with memory management, saving this library from being caught in
the hell of circular dependencies, which in turn avoids circular 
dependencies from making the use of this library hell on memory, which if I
remember avoids the circular dependency hell.

=back

=head1 BUGS

Perl's garbage collection is at times rather dubious.  A prime example
is when you have double-linked lists, otherwise known as circular 
references.  Since both objects refer to each other (in recording
parent <-> child relationships), perl does not clean them up until the
end of the program.  Whilst this library does do some tricks to get around
this in newer versions of perl, involving proxy objects and 
'weaken' from Scalar::Util , this library may leak memory in older versions
of perl.  Invoking ->hidetree on a retrieved object before it falls out
of scope is recommended (the library does this on some internal objects,
perhaps obsessively).  Note that you may need to create a copy of a
object via newNodeFromStr/toStr due to this.

=head1 AUTHOR

Bruce Campbell, Zerlargal VOF, 2005-7 .  See http://cpan.zerlargal.org/Jabber::Lite

=head1 COPYRIGHT

Copyright (c) 2005-7 Bruce Campbell.  All rights reserved.  
This program is free software; you can redistribute it and/or 
modify it under the same terms as Perl itself.

=head1 BLATANT COPYING

I am primarily a Sysadmin, and like Perl programmers, Sysadmins are lazy
by nature.  So, bits of this library were copied from other, existing 
libraries as follows:

	encode(), decode() and some function names: Jabber::NodeFactory.
	ConstXMLNS(), SASL handling: XML::Stream

=cut


1;
