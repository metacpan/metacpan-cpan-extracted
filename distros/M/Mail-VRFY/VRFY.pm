# Mail::VRFY.pm
# $Id: VRFY.pm,v 1.01 2014/05/21 21:09:18 jkister Exp $
# Copyright (c) 2004-2014 Jeremy Kister.
# Released under Perl's Artistic License.

$Mail::VRFY::VERSION = "1.01";

=head1 NAME

Mail::VRFY - Utility to verify an email address

=head1 SYNOPSIS

  use Mail::VRFY;

  my $code = Mail::VRFY::CheckAddress($emailaddress);

  my $code = Mail::VRFY::CheckAddress(addr    => $emailaddress,
                                      method  => 'extended',
                                      timeout => 12,
                                      debug   => 0);

  my $english = Mail::VRFY::English($code);

	
=head1 DESCRIPTION

C<Mail::VRFY> was derived from Pete Fritchman's L<Mail::Verify>.
Lots of code has been plucked.  This package attempts to be
completely compatibile with Mail::Verify.

C<Mail::VRFY> provides a C<CheckAddress> function for verifying email
addresses.  Lots can be checked, according to the C<method> option,
as described below.

C<Mail::VRFY> differs from L<Mail::Verify> in that:

A.  More granular control over what kind of checks to run
    (via the method option).

B.  Email address syntax checking is much more stringent.

C.  After making a socket to an authoritative SMTP server,
    we can start a SMTP conversation, to ensure the
    mailserver does not give a failure on RCPT TO.

D.  More return codes.

=head1 CONSTRUCTOR

=over 4

=item CheckAddress( [ADDR] [,OPTIONS] );

If C<ADDR> is not given, then it may instead be passed as the C<addr>
option described below.

C<OPTIONS> are passed in a hash like fashion, using key and value
pairs.  Possible options are:

B<addr> - The email address to check

B<method> - Which method of checking should be used:

   syntax - check syntax of email address only (no network testing).

   compat - check syntax, DNS, and MX connectivity (i.e. Mail::Verify)

   extended - compat + talk SMTP to see if server will reject RCPT TO

B<timeout> - Number of seconds to wait for data from remote host (Default: 12).
   this is a per-operation timeout, meaning there is a separate timeout on
   a DNS query, and each smtp conversation.

B<debug> - Print debugging info to STDERR (0=Off, 1=On).

=back

=head1 RETURN VALUE

Here are a list of return codes and what they mean:

=over 4

=item 0 The email address appears to be valid.

=item 1 No email address was supplied.

=item 2 There is a syntactical error in the email address.

=item 3 There are no MX or A DNS records for the host in question.

=item 4 There are no SMTP servers accepting connections.

=item 5 All SMTP servers are misbehaving and wont accept mail.

=item 6 All the SMTP servers temporarily refused mail.

=item 7 One SMTP server permanently refused mail to this address.

This module provides an English sub that will convert the code to
English for you.

=back

=head1 EXAMPLES

  use Mail::VRFY;
  my $email = shift;
  unless(defined($email)){
    print "email address to be tested: ";
    chop($email=<STDIN>);
  }
  my $code = Mail::VRFY::CheckAddress($email);
  my $english = Mail::VRFY::English($code);
  if($code){
    print "Invalid email address: $english  (code: $code)\n";
  }else{
    print "$english\n";
  }

=head1 CAVEATS

A SMTP server can reject RCPT TO at SMTP time, or it can accept all
recipients, and send bounces later.  All other things being equal,
Mail::VRFY will not detect the invalid email address in the latter case.

Greylisters will cause you pain; look out for return code 6.  Some
users will want to deem email addresses returning code 6 invalid,
others valid, and others will set up a queing mechanism to try again
later.

=head1 RESTRICTIONS

Email address syntax checking does not conform to RFC2822, however, it
will work fine on email addresses as we usually think of them.
(do you really want:

"Foo, Bar" <test((foo) b`ar baz)@example(hi there!).com>

to be considered valid ?)

=head1 AUTHOR

Jeremy Kister : http://jeremy.kister.net./

=cut

package Mail::VRFY;

use strict;
use IO::Socket::INET;
use IO::Select;
use Net::DNS;
use Sys::Hostname::Long;

sub Version { $Mail::VRFY::VERSION }

sub English {
	my $code = shift;
	my @english = ( 'Email address seems valid.',
	                'No email address supplied.',
	                'Syntax error in email address.',
	                'No MX or A DNS records for this domain.',
	                'No advertised SMTP servers are accepting mail.',
	                'All advertised SMTP servers are misbehaving and wont accept mail.',
	                'All advertised SMTP servers are temporarily refusing mail.',
	                'One Advertised SMTP server permanently refused mail.',
	              );
	return $english[$code] || "Unknown code: $code";
}

sub CheckAddress {
	my %arg;
	if(@_ % 2){
		my $addr = shift;
		%arg = @_;
		$arg{addr} = $addr;
	}else{
		%arg = @_;
	}
	return 1 unless $arg{addr};
	if(exists($arg{timeout})){
		warn "using timeout of $arg{timeout} seconds\n" if( $arg{debug} == 1 );
	}else{
		$arg{timeout} = 12;
		warn "using default timeout of 12 seconds\n" if( $arg{debug} == 1 );
	}

	if(exists($arg{from})){
		warn "using specified envelope sender address: $arg{from}\n" if( $arg{debug} == 1 );
	}

	my ($user,$domain,@mxhosts);

	# First, we check the syntax of the email address.
	if(length($arg{addr}) > 256){
		 warn "email address is more than 256 characters\n" if( $arg{debug} == 1 );
		 return 2;
	}
	if($arg{addr} =~ /^(([a-z0-9_\.\+\-\=\?\^\#\&]){1,64})\@((([a-z0-9\-]){1,251}\.){1,252}[a-z0-9]{2,6})$/i){
		# http://data.iana.org/TLD/tlds-alpha-by-domain.txt  says all tlds >=2 && <= 6
		# we don't support the .XN-- insanity
		$user = $1;
		$domain = $3;
		if(length($domain) > 255){
			warn "domain in email address is more than 255 characters\n" if( $arg{debug} == 1 );
			return 2;
		}
	}else{
		 warn "email address does not look correct\n" if( $arg{debug} == 1 );
		 return 2;
	}
	return 0 if($arg{method} eq 'syntax');

	my $dnscheck = eval {
		local $SIG{ALRM} = sub { die "Timeout.\n"; };
		alarm($arg{timeout});
		my @mxrr = Net::DNS::mx( $domain );
		# Get the A record for each MX RR
		foreach my $rr (@mxrr) {
			push( @mxhosts, $rr->exchange );
		}
		unless(@mxhosts) { # check for an A record...
			my $resolver = Net::DNS::Resolver->new();
			my $dnsquery = $resolver->search( $domain );
			return 3 unless $dnsquery;
			foreach my $rr ($dnsquery->answer) {
				next unless $rr->type eq "A";
				push( @mxhosts, $rr->address );
			}
			return 3 unless @mxhosts;
		}
		if($arg{debug} == 1){
			foreach( @mxhosts ) {
				warn "\@mxhosts -> $_\n";
			}
		}
	};
	alarm(0);

	if($@){
		warn "problem resolving in the DNS: $@\n" if( $arg{debug} == 1 );
		return 3;
	}

	return $dnscheck unless(@mxhosts);

	my $misbehave=0;
	my $tmpfail=0;
	my $livesmtp=0;
	foreach my $mx (@mxhosts) {
		my $sock = IO::Socket::INET->new(Proto=>'tcp',
		                                 PeerAddr=> $mx,
		                                 PeerPort=> 25,
		                                 Timeout => $arg{timeout}
		                                );
		if($sock){
			warn "connected to ${mx}\n" if( $arg{debug} == 1 );
			$livesmtp=1;
			if($arg{method} eq 'compat'){
				close $sock;
				return 0;
			}		

			my $select = IO::Select->new;
			$select->add($sock);

			my @banner = _getlines($select,$arg{timeout});
			if(@banner){
				if($arg{debug} == 1){
					print STDERR "BANNER: ";
					for(@banner){  print STDERR " $_"; }
					print STDERR "\n";
				}
				unless($banner[-1] =~ /^220\s/){
					print $sock "QUIT\r\n"; # be nice
					close $sock;
					$misbehave=1;
					warn "$mx misbehaving: bad banner\n" if( $arg{debug} == 1 );
					next;
				}
			}else{
				warn "$mx misbehaving while retrieving banner\n" if( $arg{debug} == 1 );
				$misbehave=1;
				next;
			}

			my $me = hostname_long();
			print $sock "HELO $me\r\n";
			my @helo = _getlines($select,$arg{timeout});
			if(@helo){
				if($arg{debug} == 1){
					print STDERR "HELO: ";
					print STDERR for(@helo);
					print STDERR "\n";
				}
				unless($helo[-1] =~ /^250\s/){
					print $sock "QUIT\r\n"; # be nice
					close $sock;
					$misbehave=1;
					warn "$mx misbehaving: bad reply to HELO\n" if( $arg{debug} == 1 );
					next;
				}
			}else{
				warn "$mx misbehaving while retrieving helo\n" if( $arg{debug} == 1 );
				$misbehave=1;
				next;
			}

			print $sock "MAIL FROM:<$arg{from}>\r\n";
			my @mf = _getlines($select,$arg{timeout});
			if(@mf){
				if($arg{debug} == 1){
					print STDERR "MAIL FROM: ";
					print STDERR for(@mf);
					print STDERR "\n";
				}
				unless($mf[-1] =~ /^250\s/){
					print $sock "QUIT\r\n"; # be nice
					close $sock;
					$misbehave=1;
					warn "$mx misbehaving: bad reply to MAIL FROM\n" if( $arg{debug} == 1 );
					next;
				}
			}else{
				warn "$mx misbehaving while retrieving mail from\n" if( $arg{debug} == 1 );
				$misbehave=1;
				next;
			}

			print $sock "RCPT TO:<$arg{addr}>\r\n";
			my @rt = _getlines($select,$arg{timeout});
			print $sock "QUIT\r\n"; # be nice
			close $sock;
			if(@rt){
				if($arg{debug} == 1){
					print STDERR "RECIPIENT TO: ";
					print STDERR for(@rt);
					print STDERR "\n";
				}
				if($rt[-1] =~ /^250\s/){
					# host accepted
					return 0;
				}elsif($rt[-1] =~ /^4\d{2}/){
					# host temp failed, greylisters go here.
					$tmpfail=1;
				}elsif($rt[-1] =~ /^5\d{2}/){
					# host rejected
					return 7;
				}else{
					$misbehave=1;
					warn "$mx misbehaving: bad reply to RCPT TO\n" if( $arg{debug} == 1 );
					next;
				}
			}else{
				$misbehave=1;
				warn "$mx not behaving correcly while retrieving rcpt to\n" if( $arg{debug} == 1 );
				next;
			}
		}
	}
	return 4 unless($livesmtp);
	return 5 if($misbehave && !$tmpfail);
	return 6 if($tmpfail);
	return 0;
}

sub _getlines {
	my $select = shift || die "_getlines syntax error 1";
	my $timeout = shift || die "_getlines syntax error 2";
	my @lines;
	if(my ($pending) = $select->can_read($timeout)){
		while(<$pending>){
			if(/^\d+\s/){
				chomp;
				push @lines, $_;
				last;
			}else{
				push @lines, $_;
			}
		}
	}
	return(@lines);
}

1;
