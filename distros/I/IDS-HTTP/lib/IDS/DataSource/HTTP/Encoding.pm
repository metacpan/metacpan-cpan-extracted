# HTTP Accept-Encoding line; section 14.3 of RFC 2616 applies here
# qvalues are from section 3.9
#
# subclass of HTTP:Part; see that for interface requirements
#

package IDS::DataSource::HTTP::Encoding;

use strict;
use warnings;
use Carp qw(carp confess);
use base qw(IDS::DataSource::HTTP::Part);

$IDS::DataSource::HTTP::Encoding::VERSION     = "1.0";

sub empty {
    my $self  = shift;
    undef $self->{"data"}, $self->{"tokens"};
}

sub parse {
    my $self  = shift;
    my $accept = $self->{"data"}; # convenience
    my ($type, $param, @tokens);

    $self->mesg(1, *parse{PACKAGE} .  "::parse: data '$accept'");

    # Example line:
    # Accept-Encoding: gzip;q=1.0, identity; q=0.5, *;q=0
    my $pat = qr/[-a-zA-Z0-9!#\$%^&*_+|.~]+/; # missing '"` (3 chars)
    # First, split at commas
    for my $pref (split /,\s*/, $accept) {
        $pref =~ /^([^;]+)(;.*)?/;
	$type = $1;
	$param = $2;
	if ($type =~ /^$pat$/) {
	    push @tokens, "Encoding: $type";
	} else {
	    my $pmsg = *parse{PACKAGE} .  "::parse: In " .
		     ${$self->{"params"}}{"source"} .
		     " Invalid encoding: '$type'";
	    $self->warn($pmsg, \@tokens, "!Invalid encoding");
	}

        # See if a parameter is present (e.g., qvalue)
	if (defined($param)) {
	    my $pobj = new IDS::DataSource::HTTP::AcceptParams($self->{"params"}, $param);
	    push @tokens, $pobj->tokens();
	}
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
