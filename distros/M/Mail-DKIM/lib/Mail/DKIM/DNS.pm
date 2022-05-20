package Mail::DKIM::DNS;
use strict;
use warnings;
our $VERSION = '1.20220520'; # VERSION
# ABSTRACT: performs DNS queries for Mail::DKIM

# Copyright 2007, 2012 Messiah College. All rights reserved.
# Jason Long <jlong@messiah.edu>


# This class contains a method to perform synchronous DNS queries.
# Hopefully some day it will have a method to perform
# asynchronous DNS queries.

use Net::DNS;
our $TIMEOUT = 10;
our $RESOLVER;

sub resolver {
    if (@_) {
        $RESOLVER = $_[0];
    }
    return $RESOLVER;
}

sub enable_EDNS0 {

    # enable EDNS0, set acceptable UDP packet size to a
    # conservative payload size that should fit into a single
    # packet (MTU less the IP header size) in most cases;
    # See also draft-andrews-dnsext-udp-fragmentation
    # and RFC 3542 section 11.3.

    my $res = Net::DNS::Resolver->new();
    $res->udppacketsize( 1280 - 40 );
    resolver($res);
}

# query- returns a list of RR objects
#   or an empty list if the domain record does not exist
#       (e.g. in the case of NXDOMAIN or NODATA)
#   or throws an error on a DNS query time-out or other transient error
#       (e.g. SERVFAIL)
#
# if an empty list is returned, $@ is also set to a string explaining
# why no records were returned (e.g. "NXDOMAIN").
#
sub query {
    my ( $domain, $type ) = @_;

    if ( !$RESOLVER ) {
        $RESOLVER = Net::DNS::Resolver->new()
          or die "Internal error: can't create DNS resolver";
    }

    my $rslv = $RESOLVER;

    #
    # perform the DNS query
    #   if the query takes too long, we should generate an error
    #
    my $resp;
    my $remaining_time = alarm(0);    # check time left, stop the timer
    my $deadline = time + $remaining_time;
    my $E;
    eval {
        local $SIG{__DIE__};

        # set a timeout, 10 seconds by default
        local $SIG{ALRM} = sub { die "DNS query timeout for $domain\n" };
        alarm $TIMEOUT;

        # the query itself could cause an exception, which would prevent
        # us from resetting the alarm before leaving the eval {} block
        # so we wrap the query in a nested eval {} block
        my $E2;
        eval {
            local $SIG{__DIE__};
            $resp = $rslv->send( $domain, $type );
            1;
        } or do {
            $E2 = $@;
        };
        alarm 0;
        if ($E2) { chomp $E2; die "$E2\n" }    # no line number here
        1;
    } or do {
        $E = $@;    # the $@ only makes sense if eval returns a false
    };
    alarm 0;

    # restart the timer if it was active
    if ( $remaining_time > 0 ) {
        my $dt = $deadline - time;

        # make sure the timer expiration will trigger a signal,
        # even at the expense of stretching the interval by one second
        alarm( $dt < 1 ? 1 : $dt );
    }
    if ($E) { chomp $E; die $E }    # ensure a line number

    # RFC 2308: NODATA is indicated by an answer with the RCODE set to NOERROR
    # and no relevant answers in the answer section.  The authority section
    # will contain an SOA record, or there will be no NS records there.
    # NODATA responses have to be algorithmically determined from the
    # response's contents as there is no RCODE value to indicate NODATA.
    # In some cases to determine with certainty that NODATA is the correct
    # response it can be necessary to send another query.

    if ($resp) {
        my $header = $resp->header;
        if ($header) {

            # NOERROR, NXDOMAIN, SERVFAIL, FORMERR, REFUSED, ...
            my $rcode = $header->rcode;

            $@ = $rcode;
            if ( $rcode eq 'NOERROR' ) {

                # may or may not contain RRs in the answer sect
                my @result = grep { lc $_->type eq lc $type } $resp->answer;
                $@ = 'NODATA' if !@result;
                return @result;    # possibly empty
            }
            elsif ( $rcode eq 'NXDOMAIN' ) {
                return;            # empty list, rcode in $@
            }
        }
    }
    if ( $rslv->errorstring eq 'NOERROR' ) {
        return;
    }
    if ( $rslv->errorstring =~ /\bno error\b/ ) {
        return;
    }
    die 'DNS error: ' . $rslv->errorstring . "\n";
}

# query_async() - perform a DNS query asynchronously
#
#   my $waiter = query_async('example.org', 'TXT',
#                        Callbacks => {
#                                Success => \&on_success,
#                                Error => \&on_error,
#                                },
#                            );
#   my $result = $waiter->();
#
sub query_async {
    my ( $domain, $type, %prms ) = @_;

    my $callbacks = $prms{Callbacks} || {};
    my $on_success = $callbacks->{Success} || sub { $_[0] };
    my $on_error   = $callbacks->{Error}   || sub { die $_[0] };

    my $waiter = sub {
        my @resp;
        my $rcode;
        eval {
            local $SIG{__DIE__};
            @resp = query( $domain, $type );
            $rcode = $@;
            1;
        } or do {
            return $on_error->($@);
        };
        $@ = $rcode;
        return $on_success->(@resp);
    };
    return $waiter;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Mail::DKIM::DNS - performs DNS queries for Mail::DKIM

=head1 VERSION

version 1.20220520

=head1 DESCRIPTION

This is the module that performs DNS queries for L<Mail::DKIM>.

=head1 CONFIGURATION

This module has a couple configuration settings that the caller
may want to use to customize the behavior of this module.

=head2 $Mail::DKIM::DNS::TIMEOUT

This global variable specifies the maximum amount of time (in seconds)
to wait for a single DNS query to complete. The default is 10.

=head2 Mail::DKIM::DNS::resolver()

Use this global subroutine to get or replace the instance of
L<Net::DNS::Resolver> that Mail::DKIM uses. If set to undef (the default),
then a brand new default instance of L<Net::DNS::Resolver> will be
created the first time a DNS query is needed.

You will call this subroutine if you want to specify non-default options
to L<Net::DNS::Resolver>, such as different timeouts, or to enable use
of a persistent socket. For example:

  # first, construct a custom DNS resolver
  my $res = Net::DNS::Resolver->new(
                    udp_timeout => 3, tcp_timeout => 3, retry => 2,
                 );
  $res->udppacketsize(1240);
  $res->persistent_udp(1);

  # then, tell Mail::DKIM to use this resolver
  Mail::DKIM::DNS::resolver($res);

=head2 Mail::DKIM::DNS::enable_EDNS0()

This is a convenience subroutine that will construct an appropriate DNS
resolver that uses EDNS0 (Extension mechanisms for DNS) to support large
DNS replies, and configure Mail::DKIM to use it. (As such, it should NOT
be used in conjunction with the resolver() subroutine described above.)

  Mail::DKIM::DNS::enable_EDNS0();

Use of EDNS0 is recommended, since it reduces the need for falling back to TCP
when dealing with large DNS packets. However, it is not enabled by default
because some Internet firewalls which do deep inspection of packets are not able
to process EDNS0-enabled packets. When there is a firewall on a path to a DNS
resolver, the EDNS0 feature should be specifically tested before enabling.

=head1 AUTHORS

=over 4

=item *

Jason Long <jason@long.name>

=item *

Marc Bradshaw <marc@marcbradshaw.net>

=item *

Bron Gondwana <brong@fastmailteam.com> (ARC)

=back

=head1 THANKS

Work on ensuring that this module passes the ARC test suite was
generously sponsored by Valimail (https://www.valimail.com/)

=head1 COPYRIGHT AND LICENSE

=over 4

=item *

Copyright (C) 2013 by Messiah College

=item *

Copyright (C) 2010 by Jason Long

=item *

Copyright (C) 2017 by Standcore LLC

=item *

Copyright (C) 2020 by FastMail Pty Ltd

=back

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
