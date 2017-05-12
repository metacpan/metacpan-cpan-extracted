# HTTP Accept line; Section 14.1 of RFC 2616
#
# subclass of HTTP:Part; see that for interface requirements
#

package IDS::DataSource::HTTP::Accept;

use strict;
use warnings;
use Carp qw(carp confess);
use base qw(IDS::DataSource::HTTP::Part);
use IDS::DataSource::HTTP::AcceptParams;

$IDS::DataSource::HTTP::Accept::VERSION     = "1.0";

sub empty {
    my $self  = shift;
    undef $self->{"data"}, $self->{"tokens"};
}

sub parse {
    my $self  = shift;
    my $accept = $self->{"data"}; # convenience
    my $OK = 1; # optimism
    my @tokens = ();

    $self->mesg(1, *parse{PACKAGE} .  "::parse: data '$accept'");

    # the pattern below contains .+ which I do not think are in the
    # standard, but they show up.
    # my $accept_pattern = qr!^(\*|(\w+))/([-+.*\w]+)(;.*)?$!; # original
    my $accept_pattern = qr!^(\*|(\w+))(/([-+.*\w]+))?(;\s*.*)?$!;
    for my $token (split /,\s*/, $accept) { # standard says \s+, but \s*
    					    # covers non-standard agents also.
	$self->mesg(3, "    token '$token'");
	if ($token =~ m!$accept_pattern!) {
	    my $type = $1;
	    my $subtype = defined($4) ? $4 : "Nonstandard: nosubtype";
	    my $params = $5;
	    $self->mesg(3, "    type '$type' subtype '$subtype'");
	    push @tokens, "Accept type: $type", "Accept subtype: $subtype";
	    if (defined($params)) {
		$self->mesg(3, "    params '$params'");
		my $pobj = IDS::DataSource::HTTP::AcceptParams->new($self->{"params"}, $params);
		push @tokens, $pobj->tokens();
	    }
	} else {
	    my $pmsg = *parse{PACKAGE} .  "::parse: In " .
		     ${$self->{"params"}}{"source"} .
		     " invalid accept in '$token'\n";
	    $self->warn($pmsg, \@tokens, "!Invalid accept value");
	    $OK = 0;
	}
    }

    $self->mesg(2, *parse{PACKAGE} .  "::parse: tokens\n    ",
                "\n    ", \@tokens);
    if (exists(${$self->{"params"}}{"Syntax only"}{"Accept"}) &&
        ${$self->{"params"}}{"Syntax only"}{"Accept"}) {
	$self->{"tokens"} = [ $OK ? "Accept syntax OK"
	                          : "Accept syntax NOT OK" ];
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
