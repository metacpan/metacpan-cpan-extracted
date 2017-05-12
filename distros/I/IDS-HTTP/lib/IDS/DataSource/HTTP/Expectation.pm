# HTTP Expectation; Section 14.20 of RFC 2616
#
# subclass of HTTP:Part; see that for interface requirements
#

package IDS::DataSource::HTTP::Expectation;

use strict;
use warnings;
use Carp qw(carp confess);
use base qw(IDS::DataSource::HTTP::Part);

$IDS::DataSource::HTTP::Expectation::VERSION     = "1.0";

sub empty {
    my $self  = shift;
    undef $self->{"data"}, $self->{"tokens"};
}

sub parse {
    my $self  = shift;
    my $data = $self->{"data"}; # convenience
    my @tokens;

    $self->mesg(1, *parse{PACKAGE} .  "::parse: data '$data'");

    my $tokenpat = qr/[-a-zA-Z0-9!#\$%^&*_+|.~]+/; # missing '"` (3 chars)

    if ($data eq "100-continue") {
        push @tokens, "Expectation: 100-continue";
    } elsif ($data =~ /^($tokenpat)(=("$tokenpat"|$tokenpat))?(.*)$/) {
        push @tokens, "Expectation token: $1";
        push @tokens, "Expectation $1 value: $3" if defined($3);
	if ($4) {
	    my $params = $4;
	    $params = s/^;\s*//;
	    # params are ; separated.
	    for my $param (split /;\s*/, $params) {
	        if ($param =~ /^($tokenpat)(=("$tokenpat"|$tokenpat))?$/) {
		    push @tokens, "Expectation parameter: $1";
		    push @tokens, "Expectation $1 parameter value: $3"
		        if defined($3);
		} else {
		    my $pmsg = *parse{PACKAGE} .  "::parse: In " .
			     ${$self->{"params"}}{"source"} .
			     " invalid expect param '$param'\n";
		    $self->warn($pmsg, \@tokens, "!Invalid expect param");
		}
	    }
	}
    } else {
	my $pmsg = *parse{PACKAGE} .  "::parse: In " .
		 ${$self->{"params"}}{"source"} .
		 " invalid expectation '$data'\n";
	$self->warn($pmsg, \@tokens, "!Invalid expectation");
    }

    $self->mesg(2, *parse{PACKAGE} .  "::parse: tokens\n    ",
                "\n    ", \@tokens);
    $self->{"tokens"} = \@tokens;
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
