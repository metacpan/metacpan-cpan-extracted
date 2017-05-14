# Mail::Verify.pm
# $Id: Verify.pm,v 1.4 2002/06/09 15:42:32 petef Exp $
# Copyright (c) 2001 Pete Fritchman <petef@databits.net>.  All rights
# reserved.  This program is free software; you can redistribute it and/or
# modify it under the same terms as Perl itself.

package Mail::Verify;

=head1 NAME

Mail::Verify - Utility to verify an email address

=head1 SYNOPSIS

    use Mail::Verify;

=head1 DESCRIPTION

C<Mail::Verify> provides a function CheckAddress function for verifying email
addresses.  First the syntax of the email address is checked, then it verifies
that there is at least one valid MX server accepting email for the domain.  Using
L<Net::DNS> and L<IO::Socket> a list of MX records (or, falling back on a hosts
A record) are checked to make sure at least one SMTP server is accepting
connections.

=head1 ERRORS

Here are a list of return codes and what they mean:

=item 0

The email address appears to be valid.

=item 1

No email address was supplied.

=item 2

There is a syntaxical error in the email address.

=item 3

There are no DNS entries for the host in question (no MX records or A records).

=item 4

There are no live SMTP servers accepting connections for this email address.

=head1 EXAMPLES

This example shows obtaining an email address from a form field and verifying
it.

  use CGI qw/:standard/;
  use Mail::Verify;
  my $q = new CGI;
  [...]
  my $email = $q->param("emailaddr");
  my $email_ck = Mail::Verify::CheckAddress( $email );
  if( $email_ck ) {
      print '<h1>Form input error: Invalid email address.</h1>';
  }
  [...]

=cut

use strict;
use IO::Socket;
use Net::DNS;

my $VERSION = "0.02";
my $DEBUG = "0";

sub Version { $VERSION }

sub CheckAddress {
    my $addr = shift;
    return 1 unless $addr;

    my ($rr, @mxhosts, @mxrr, $resolver, $dnsquery, $livesmtp, $mx);
    my ($testsmtp);

    # First, we check the basic syntax of the email address.
    my ($user, $domain, $extra);
    ($user, $domain, $extra) = split /\@/, $addr;
    return 2 if $extra;
    @mxrr = Net::DNS::mx( $domain );
    # Get the A record for each MX RR
    foreach $rr ( @mxrr ) {
	push( @mxhosts, $rr->exchange );
    }
    if( ! @mxhosts ) { # check for an A record...
	$resolver = new Net::DNS::Resolver;
	$dnsquery = $resolver->search( $domain );
	return 3 unless $dnsquery;
	foreach $rr ($dnsquery->answer) {
	    next unless $rr->type eq "A";
	    push( @mxhosts, $rr->address );
	}
	return 3 unless @mxhosts;
    }
    # DEBUG: see what's in @mxhosts
    if( $DEBUG ) {
	foreach( @mxhosts ) {
	    $mx = $_;
	    print STDERR "\@mxhosts -> $mx\n";
	}
    }
    # make sure we have a living smtp server on at least one of @mxhosts
    $livesmtp = 0;
    foreach $mx (@mxhosts) {
	$testsmtp = IO::Socket::INET->new(	Proto=>"tcp",
						PeerAddr=> $mx,
						PeerPort=> 25,
						Timeout => 10
					);
	if( $testsmtp ) {
	    $livesmtp = 1;
	    close $testsmtp;
	}
    }
    if( ! $livesmtp ) {
	return 4;
    }
    return 0;
}

1;
