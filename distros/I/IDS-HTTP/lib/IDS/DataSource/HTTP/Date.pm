# HTTP Date; Section 3.3 of RFC 2616
#
# subclass of HTTP:Part; see that for interface requirements
#
# For reference, here are examples of the three accepted date formats:
#     Sun, 06 Nov 1994 08:49:37 GMT  ; RFC 822, updated by RFC 1123
#     Sunday, 06-Nov-94 08:49:37 GMT ; RFC 850, obsoleted by RFC 1036
#     Sun Nov  6 08:49:37 1994       ; ANSI C's asctime() format
# Example from Section 3.3.1 of RFC 2616
#
# Unfortunately, we are also admonished in the same section:
#     Recipients of date values are encouraged to be robust in accepting
#     date values that may have been sent by non-HTTP applications,
#     as is sometimes the case when retrieving or posting messages via
#     proxies/gateways to SMTP or NNTP.
# As a result, this section is a bit messy to be able to handle the
# various formats I have seen in use.
#

package IDS::DataSource::HTTP::Date;

use strict;
use warnings;
use Carp qw(carp confess);
use base qw(IDS::DataSource::HTTP::Part);

$IDS::DataSource::HTTP::Date::VERSION     = "1.0";

sub empty {
    my $self  = shift;
    undef $self->{"data"}, $self->{"tokens"};
}

sub parse {
    my $self  = shift;
    my $date = $self->{"data"}; # convenience
    my @tokens;
    my ($weekday, $day, $month, $year, $hour, $minute, $second);
    my ($TZ, $x); # x is don't care, a placeholder
    my $OK = 0;
    my $type = "None yet";

    $self->mesg(1, *parse{PACKAGE} .  "::parse: data '$date'");

    # various patterns to make the matches below cleaner
    my $day1pat = qr'(Mon|Tue|Wed|Thu|Fri|Sat|Sun)';
    my $day2pat = qr'(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)';
    my $monpat = qr'(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)';
    my $monpat2 = qr'(January|February|March|April|May|June|July|August|September|October|November|December)'; # not allowed in legal dates
    my $timepat = qr'(\d{2}):(\d{2}):(\d{2})';
    my $TZpat = qr'(\w{3})';
    my $date822 = qr"(\d{1,2}) $monpat (\d{4})"o; ### non-standard: accept 1 or 2 day digits
    my $date850 = qr"(\d{2})-$monpat-(\d{2})"o;
    my $dateansi = qr"$monpat (\d{2}|( \d))"o;
    my $rfc1123 = qr"^$day1pat, $date822 $timepat $TZpat$"o;
    my $rfc850 = qr"^$day2pat, $date850 $timepat $TZpat$"o;
    my $asctime = qr"^$day1pat $dateansi $timepat ($TZpat )?(\d{4})$"o;
    my $invalid1 = qr"^$day2pat, ( ?\d{1,2})-($monpat2)-(\d{4}) $timepat $TZpat$"o;

    if (($weekday, $day, $month, $year, $hour, $minute, $second, $TZ) = ($date =~ m/$rfc1123/)) {
        # RFC 822 updated by RFC 1123
	$type = "RFC1123";
	$OK = $self->validate_date($type, $weekday, $day, $month,
	                           $year, $hour, $minute, $second, $TZ);
    } elsif (($weekday, $day, $month, $year, $hour, $minute, $second, $TZ) = ($date =~ m/$rfc850/)) {
        # RFC 850; obsoleted by RFC 1036
	$type = "RFC850";
	$OK = $self->validate_date($type, $weekday, $day, $month,
	                           $year, $hour, $minute, $second, $TZ);
    } elsif (($weekday, $month, $day, $x, $hour, $minute, $second, $x, $TZ, $year) = ($date =~ m/$asctime/)) {
        ### Note: We accept a non-standard version as well (with a TZ)
        # ANSI C asctime
	$day =~ s/^\s*//; # remove any leading spaces; the standard allows them
	$TZ = defined($TZ) ? $TZ : "No TZ";
	$type = "ASCTIME";
	$OK = $self->validate_date($type, $weekday, $day, $month,
	                           $year, $hour, $minute, $second, $TZ);
    } elsif (($weekday, $day, $month, $x, $year, $hour, $minute, $second, $TZ) = ($date =~ m/$invalid1/)) {
	$type = "Invalid1";
#	print STDERR "$invalid1\n";
#	print STDERR "$weekday, $day, $month, $year, $hour, $minute, $second, $TZ\n";
	$OK = $self->validate_date($type, $weekday, $day, $month,
	                           $year, $hour, $minute, $second, $TZ);
    } else {
	my $pmsg = *parse{PACKAGE} .  "::parse: In " .
		 ${$self->{"params"}}{"source"} .
		 " date '$date' does not match date patterns\n";
	$self->warn($pmsg, \@tokens, "!Nomatch date");
	$OK = 0; # not OK
    }

### need to switch to the same scheme used elsewhere for syntax checks
### only
    if ($OK) {
        if (${$self->{"params"}}{"recognize_dates"}) {
	    push @tokens, "Valid $type date";
	} else {
	    # This always puts things in the same order, even though the
	    # original date format may have a different order.  Valid?
# commented out to find out which is sometimes undefined
#	    push @tokens, "Weekday: $weekday", "Day: $day",
#	                  "Month: $month", "Year: $year",
#			  "Hour: $hour", "Minute: $minute",
#			  "Second: $second", "Date type: $type";
	    push @tokens, "Weekday: $weekday";
	    push @tokens, "Day: $day";
	    push @tokens, "Month: $month";
	    push @tokens, "Year: $year";
	    push @tokens, "Hour: $hour";
	    push @tokens, "Minute: $minute";
	    push @tokens, "Second: $second";
	    push @tokens, "Date type: $type";
	}
    } else {
	my $pmsg = *parse{PACKAGE} .  "::parse: In " .
                 ${$self->{"params"}}{"source"} .
                 " invalid value in '$date'\n";
        $self->warn($pmsg, \@tokens, "!Invalid date value");
    }

    $self->mesg(2, *parse{PACKAGE} .  "::parse: tokens\n    ",
                "\n    ", \@tokens);
    $self->{"tokens"} = \@tokens;
}

# Check basic assumptions about the date.  This function could be made
# more accurate by checking the days actually in the month as the max
sub validate_date {
    my $self  = shift;
    my ($type, $weekday, $day, $month,
	$year, $hour, $minute, $second, $TZ) = @_;
    my $level = 0;
    my $name = *parse{PACKAGE} . "::validate_date";
    # Timezones from http://www.timeanddate.com/library/abbreviations/timezones/
    my @timezones = qw(ACDT ACST ADT AEDT AEST AKDT AKST AST AWST BST
                       CDT CDT CEST CET CST CST CXT EDT EDT EEST EET EST
                       EST GMT HAA HAC HADT HAE HAP HAR HAST HAT HAY HNA
                       HNC HNE HNP HNR HNT HNY IST MDT MESZ MEZ MST NDT
                       NFT NST PDT PST UTC WEST WET WST
    );

    my $OK = 1; # assume valid

    map {$OK &= defined($_)} ($type, $weekday, $day, $month, $year, $hour, $minute, $second);
    # verify still OK
    unless ($OK) {
	$self->mesg($level, "$name: undefined value received");
	return 0; # nothing further needed
    }

# This check is covered by the pattern match now
#    if ($type eq "RFC850") { # RFC 850 uses full day names
#        $OK &= $weekday =~ /^(Monday|Tuesday|Wednesday|Thursday|Friday|Saturday|Sunday)$/;
#    } else { # other formats use 3-char day names
#        $OK &= $weekday =~ /^(Mon|Tue|Wed|Thu|Fri|Sat|Sun)$/;
#    }
#    $OK or $self->mesg($level, "$name: bad weekday '$weekday'");

    $OK &= $day =~ /^\d+$/;
    $OK &= $day >= 1 && $day <= 31;
    $self->mesg($level, "$name: bad day '$day'") unless $OK;

    # This check is covered by thte pattern match now
    #$OK &= $month =~ /^(Jan|Feb|Mar|Apr|May|Jun|Jul|Aug|Sep|Oct|Nov|Dec)$/;
    #$self->mesg($level, "$name: bad month '$month'") unless $OK;

    # year sanity checks?

    $OK &= $hour =~ /^\d+$/ && $hour >= 0 && $hour <= 23;
    $self->mesg($level, "$name: bad hour '$hour'") unless $OK;
    $OK &= $minute =~ /^\d+$/ && $minute >= 0 && $minute <= 59;
    $self->mesg($level, "$name: bad minute '$minute'") unless $OK;
    $OK &= $second =~ /^\d+$/ && $second >= 0 && $second <= 59;
    $self->mesg($level, "$name: bad second '$second'") unless $OK;

    # This check is replaced by the one below
#    if ($type eq "ASCTIME") { # the only one not to use a TZ
#        $OK &= !defined($TZ) || $TZ eq "";
#    } else {
#        $OK &= $TZ eq "GMT";
#    }
    # Be generous in what we accept; if the TZ is defined and non-null
    # (and not "No TZ"), see if it is any of the known world timezones
    if (defined($TZ) && $TZ && $TZ ne "No TZ") {
        my $tzok = 0;
	map { $TZ eq $_ and $tzok = 1 } @timezones;
	$OK &= $tzok
    }
    $self->mesg($level, "$name: bad timezone '$TZ'") unless $OK;

    return $OK;
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
