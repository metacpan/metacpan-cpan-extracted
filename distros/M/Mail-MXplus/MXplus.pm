package Mail::MXplus;

use 5.008;
use strict;
use warnings;

#
# since there's only one thing to export, I export 'everything'
#
require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(
	mxplus
) ] );

#our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	mxplus
);




our $VERSION = '0.02';


# the code goes here

use Net::DNS;

sub mxplus {
    my ($domain, $ip) = @_;

    my $res = Net::DNS::Resolver->new;

    my @list;
    my @answer;
    my $rr;
    my $type;
    my $testip;

    # Perform a lookup, without the searchlist
    my $packet = $res->query($domain, 'MX');
    # (returns undef if no MX records)

    if (defined($packet)) {
	@list = ();
	@answer = $packet->answer;
	foreach $rr (@answer) {
	    $type = $rr->type;
	    if ($type eq 'MX') {
		push (@list, $rr->exchange);
	    }
	}
    } else {
	@list = ($domain);
    }

    #truncate the IP to a dotted triplet for easier compare
    $testip = $ip;
    $testip =~ s/\.[0-9]+$/./;

    foreach (@list) {
	#lookup the A record.
	$packet = $res->query($_, 'A');
	if (defined($packet)) {
	    @answer = $packet->answer;
	    foreach $rr (@answer) {
		$type = $rr->type;
		if ($type eq 'A') {
		    #compare it to the IP.
		    if ($rr->address =~ /^$testip/) {
			return "pass";
		    }
		}
	    }
	}
    }

    #if none of those were it, then check the rDNS 
    if ($ip =~ /([0-9]+)\.([0-9]+)\.([0-9]+)\.([0-9]+)/) {
	my $rdns = "$4.$3.$2.$1.in-addr.arpa";
	$packet = $res->query($rdns, 'PTR');
	if (defined($packet)) {
	    @answer = $packet->answer;
	    foreach $rr (@answer) {
		$type = $rr->type;
		if ($type eq 'PTR') {
		    if ($rr->ptrdname =~ /$domain$/) {
			return "pass";
		    }
		}
	    }
	}
    }
    return "fail";
}

1;
__END__

# Below is stub documentation the module.

=head1 NAME

Mail::MXplus - Perl extension for testing if a domain and IP pass the MX+ test

=head1 SYNOPSIS

  use Mail::MXplus;
  mxplus($domain, $ip);

=head1 ABSTRACT

Test if a domain and IP pass the MX+ test
The MX+ test passes if the MX of the domain matches the IP,
or if the rDNS of the IP is a subdomain of the domain (or is the domain)

=head1 DESCRIPTION

Test if a domain and IP pass the MX+ test
The MX+ test passes if the MX of the domain matches the IP,
or if the rDNS of the IP is a subdomain of the domain (or is the domain)

=head1 SEE ALSO

http://www.mxplus.org

=head1 AUTHOR

Scott Nelson

=head1 COPYRIGHT AND LICENSE

Copyright 2005 by Hurricane Electric

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself. 

=cut
