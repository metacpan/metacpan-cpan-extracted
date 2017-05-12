package Log::Saftpresse::Plugin::Postfix::Utils;

use strict;
use warnings;

# ABSTRACT: class with collection of some utility functions
our $VERSION = '1.6'; # VERSION

use Log::Saftpresse::Constants;

our (@ISA, @EXPORT_OK);

BEGIN {
	require Exporter;

	@ISA = qw(Exporter);
	@EXPORT_OK = qw(
		&string_trimmer &said_string_trimmer
		&gimme_domain &postfix_remote &verp_mung
	);
}

# Trim a "said:" string, if necessary.  Add elipses to show it.
# FIXME: This sometimes elides The Wrong Bits, yielding
#        summaries that are less useful than they could be.
sub said_string_trimmer {
    my($trimmedString, $maxLen) = @_;

    while(length($trimmedString) > $maxLen) {
        if($trimmedString =~ /^.* said: /) {
            $trimmedString =~ s/^.* said: //;
        } elsif($trimmedString =~ /^.*: */) {
            $trimmedString =~ s/^.*?: *//;
        } else {
            $trimmedString = substr($trimmedString, 0, $maxLen - 3) . "...";
            last;
        }
    }

    return $trimmedString;
}

# Trim a string, if necessary.  Add elipses to show it.
sub string_trimmer {
    my($trimmedString, $maxLen, $doNotTrim) = @_;

    $trimmedString = substr($trimmedString, 0, $maxLen - 3) . "..."
        if(! $doNotTrim && (length($trimmedString) > $maxLen));
    return $trimmedString;
}

# if there's a real domain: uses that.  Otherwise uses the IP addr.
# Lower-cases returned domain name.
#
# Optional bit of code elides the last octet of an IPv4 address.
# (In case one wants to assume an IPv4 addr. is a dialup or other
# dynamic IP address in a /24.)
# Does nothing interesting with IPv6 addresses.
# FIXME: I think the IPv6 address parsing may be weak

sub postfix_remote {
    $_ = $_[0];
    my($domain, $ipAddr);

    # split domain/ipaddr into separates
    # newer versions of Postfix have them "dom.ain[i.p.add.ress]"
    # older versions of Postfix have them "dom.ain/i.p.add.ress"
    unless((($domain, $ipAddr) = /^([^\[]+)\[((?:\d{1,3}\.){3}\d{1,3})\]/) == 2 ||
           (($domain, $ipAddr) = /^([^\/]+)\/([0-9a-f.:]+)/i) == 2) {
        # more exhaustive method
        ($domain, $ipAddr) = /^([^\[\(\/]+)[\[\(\/]([^\]\)]+)[\]\)]?:?\s*$/;
    }

    # "mach.host.dom"/"mach.host.do.co" to "host.dom"/"host.do.co"
    if($domain eq 'unknown') {
        $domain = $ipAddr;
        # For identifying the host part on a Class C network (commonly
        # seen with dial-ups) the following is handy.
        # $domain =~ s/\.\d+$//;
    } else {
        $domain =~
            s/^(.*)\.([^\.]+)\.([^\.]{3}|[^\.]{2,3}\.[^\.]{2})$/\L$2.$3/;
    }

    return($domain, $ipAddr);
}
*gimme_domain = \&postfix_remote;

# Hack for VERP (?) - convert address from somthing like
# "list-return-36-someuser=someplace.com@lists.domain.com"
# to "list-return-ID-someuser=someplace.com@lists.domain.com"
# to prevent per-user listing "pollution."  More aggressive
# munging converts to something like
# "list-return@lists.domain.com"  (Instead of "return," there
# may be numeric list name/id, "warn", "error", etc.?)
sub verp_mung {
    my ( $level, $addr )= @_;

    if( $level ) {
	    $addr =~ s/((?:bounce[ds]?|no(?:list|reply|response)|return|sentto|\d+).*?)(?:[\+_\.\*-]\d+\b)+/$1-ID/i;
	    if($level > 1) {
		$addr =~ s/[\*-](\d+[\*-])?[^=\*-]+[=\*][^\@]+\@/\@/;
	    }
    }

    return $addr;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Log::Saftpresse::Plugin::Postfix::Utils - class with collection of some utility functions

=head1 VERSION

version 1.6

=head1 AUTHOR

Markus Benning <ich@markusbenning.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 1998 by James S. Seymour, 2015 by Markus Benning.

This is free software, licensed under:

  The GNU General Public License, Version 2, June 1991

=cut
