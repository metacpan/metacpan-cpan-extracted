# HTTP Host; implements hostname and IP address standards 
#
# subclass of HTTP:Part; see that for interface requirements
#

package IDS::DataSource::HTTP::Host;

use strict;
use warnings;
use Carp qw(carp confess);
use base qw(IDS::DataSource::HTTP::Part);
use IDS::Utils qw(split_value);

$IDS::DataSource::HTTP::Host::VERSION     = "1.0";

sub empty {
    my $self  = shift;
    undef $self->{"data"}, $self->{"tokens"};
}

sub parse {
    my $self  = shift;
    my $hostname = $self->{"data"}; # convenience
    my (@tokens, $valid, $reason, $hostpat);

    $self->mesg(1, *parse{PACKAGE} .  "::parse: host '$hostname'");

    $reason = "";
    if ($hostname =~ /^[\.\d]+$/) {
	$self->mesg(2, *parse{PACKAGE} .  "::parse: IP addr");
        if (${$self->{"params"}}{"recognize_hostnames"}) {
            if ($hostname =~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/) {
		$valid = 1;
	    } else {
		$reason = "IP addr has bad form.";
		$valid = 0;
	    }

	    if ($valid && !(valid_ip_octet($1) && valid_ip_octet($2) &&
                            valid_ip_octet($3) && valid_ip_octet($4))) {
	        $valid = 0;
		$reason = "  IP addr has bad octet.";
	    }

            if ($valid && ${$self->{"params"}}{"lookup_hosts"}) {
                my @results = gethostbyaddr($hostname, "AF_INET");
                if ($#results <= 3) {
		    $valid = 0;
		    $reason = "IP addr fails DNS lookup.";
		}
            }
	    if ($valid) {
		push @tokens, "Valid IP address";
	    } else {
		my $pmsg = *parse{PACKAGE} .  "::parse: In " .
			 ${$self->{"params"}}{"source"} .
			 " invalid IP address '$hostname': $reason\n";
		$self->warn($pmsg, \@tokens, "!Invalid IP address: $reason");
	    }
        } else {
            #push @tokens, split_value("IP addr part", '\.', $hostname);
            push @tokens, "IP addr: $hostname";
        }
    } else {
	$self->mesg(2, *parse{PACKAGE} .  "::parse: hostname");
        if (${$self->{"params"}}{"recognize_hostnames"}) {
            # hostname parsing from RFC 952, 1034, 1123
            # <label> ::= <letter> [ [ <ldh-str> ] <let-dig> ]
	    $hostpat = qr/([A-Za-z0-9][-A-Za-z0-9]*[A-Za-z0-9]*)/;
            if (($hostname =~ /^($hostpat)(\.$hostpat)*\.?$/)
	        && $1 !~ /^\d+$/
		&& length($hostname) <= 255) {
		$valid = 1;
	    } elsif ($hostname eq "unknown") {
		### Non-standard, but some proxies use this.
	        push @tokens, "Non-standard hostname 'unknown'";
		$valid = 1;
	    } elsif ($hostname =~ /^([\w.]+)(, [\w.]+)+$/) {
	        ### hostname list, nonstandard but common
		### Note that \w above means we accept _ in a hostname---illegal
		my @hosts = split /, /, $hostname;
		for my $host (@hosts) {
		    my $sub = new IDS::DataSource::HTTP::Host($self->{"params"}, $host);
		    push @tokens, $sub->tokens;
		}
		$valid = 1; # not necessarily true, since children may have had invalid hosts; we
		            # count on them to do their own reporting of problems.
	    } else {
	        $valid = 0;
		$reason = "Hostname does not match pattern";
	    }

            if ($valid && ${$self->{"params"}}{"lookup_hosts"}) {
                my @results = gethostbyname($hostname);
                if ($#results <= 3) {
		    $valid = 0;
		    $reason = "Hostname fails DNS lookup";
		}
            }
            if ($valid) { 
	        push @tokens, "Valid hostname";
	    } else {
		my $pmsg = *parse{PACKAGE} .  "::parse: In " .
			 ${$self->{"params"}}{"source"} .
			 " invalid hostname '$hostname': $reason\n";
		$self->warn($pmsg, \@tokens, "!Invalid hostname: $reason");
	    }
        } else {
            #push @tokens, split_value("Host part", '\.', $hostname);
            push @tokens, "Hostname: $hostname";
        }
    }

    $self->mesg(2, *parse{PACKAGE} .  "::parse: tokens\n    ",
                "\n    ", \@tokens);
    $self->{"tokens"} = \@tokens;
}

sub valid_ip_octet {
    my $octet = shift;
    defined($octet) or confess "missing octet in valid_ip_octet";
    return $octet >= 0 && $octet <= 255;
}

# accessor functions not provided by the superclass

=head1 AUTHOR INFORMATION

Copyright 2005-2007, Kenneth Ingham.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Address bug reports and comments to: ids_test at i-pi.com.  When sending
bug reports, please provide the versions of IDS::Test.pm, IDS::Algorithm.pm,
IDS::DataSource.pm, the version of Perl, and the name and version of the
operating system you are using.  Since Kenneth is a PhD student, the
speed of the reponse depends on how the research is proceeding.

=head1 BUGS

Please report them.

=head1 SEE ALSO

L<IDS::Algorithm>, L<IDS::DataSource>

=cut

1;
