# HTTP AcceptParams; Section 14.1 (etc) of RFC 2616.  These parameters are
# used for the various accept headers.  Hopefully they are close enough
# to share one object.
#
# subclass of HTTP:Part; see that for interface requirements
#

package IDS::DataSource::HTTP::AcceptParams;

use strict;
use warnings;
use Carp qw(carp confess);
use base qw(IDS::DataSource::HTTP::Part);

$IDS::DataSource::HTTP::AcceptParams::VERSION     = "1.0";

sub empty {
    my $self  = shift;
    undef $self->{"data"}, $self->{"tokens"};
}

sub parse {
    my $self  = shift;
    my $data = $self->{"data"}; # convenience
    my @tokens = ();
    my $OK = 1; # optimism

    $self->mesg(1, *parse{PACKAGE} . "::parse: data '$data'");

    # data should start with a ; and contain one or more ;-separated
    # parameters for the accept.  Remove the initial ; here.
    $data =~ s/^;\s*//;
    my $ap_pat = qr!^(\w+)(=([-\w.]+))?$!;
    # my $qvalpat = qr!(0(\.\d{0,3})?)|(1(\.0{0,3})?)!; # not requiring a leading zero for values <1 is
                                                        # non-standard (but common in web clients),
							# hence the line below instead.
    my $qvalpat = qr!(0?(\.\d{0,3})?)|(1(\.0{0,3})?)!;
    for my $param (split(/;\s*/, $data)) {
	$self->mesg(2, *parse{PACKAGE} . "::parse: param '$param'");
        if ($param =~ m!$ap_pat!g) {
	    my $type = $1;
	    my $value = $3;
	    unless(defined($value)) {
	        $self->warn(*parse{PACKAGE} . "::parse: " .
		    ${$self->{"params"}}{"source"} . ": Undefined value in $param", [], "!undefined value in $param");
		    next;
	    }
	    if ($type eq "q") {
		my $end = ${$self->{"params"}}{"recognize_qvalues"}
		     ? ""
		     : ": $value";
		if ($value =~ /^$qvalpat$/) {
		    push @tokens, "Accept qvalue$end";
		} else {
		    my $pmsg = *parse{PACKAGE} .  "::parse: In " .
			     ${$self->{"params"}}{"source"} .
			     " Invalid accept qvalue '$value'\n";
		    $self->warn($pmsg, \@tokens, "!invalid accept qvalue");
		    $OK = 0;
		}
	    } else {
		push @tokens, "AcceptParameter: $type";
		push @tokens, "AcceptParameter value: $value"
		    if defined($value);
	    }
	} else {
	    my $pmsg = *parse{PACKAGE} .  "::parse: In " .
		     ${$self->{"params"}}{"source"} .
		     " Bad parameter '$param'\n";
	    $self->warn($pmsg, \@tokens, "!invalid parameter");
	    $OK = 0;
	}
    }

    $self->mesg(2, *parse{PACKAGE} . "::parse: tokens\n    ",
                "\n    ", \@tokens);
    if (exists(${$self->{"params"}}{"Syntax only"}{"Accept"}) &&
        ${$self->{"params"}}{"Syntax only"}{"Accept"}) {
        $self->{"tokens"} = [ $OK ? "Accept params syntax OK"
                                  : "Accept params syntax NOT OK" ];
    } else {
        $self->{"tokens"} = \@tokens;
    }
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
