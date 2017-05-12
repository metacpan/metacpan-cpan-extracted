# HTTP Accept-Charset line; section 14.2 of RFC 2616 applies here
# qvalues are from section 3.9
#
# subclass of HTTP:Part; see that for interface requirements
#

package IDS::DataSource::HTTP::Charset;

use strict;
use warnings;
use Carp qw(carp confess);
use base qw(IDS::DataSource::HTTP::Part);
use IDS::DataSource::HTTP::AcceptParams;

$IDS::DataSource::HTTP::Charset::VERSION     = "1.0";

sub empty {
    my $self  = shift;
    undef $self->{"data"}, $self->{"tokens"};
}

sub parse {
    my $self  = shift;
    my $accept = $self->{"data"}; # convenience
    my ($type, $param);
    my @tokens = ();
    my $OK = 1; # optimism

    $self->mesg(1, *parse{PACKAGE} .  "::parse: data '$accept'");

    # Example line:
    # Accept-Charset: iso-8859-5, unicode-1-1;q=0.8
    my $pat = qr/[-a-zA-Z0-9!#\$%^&*_+|.~]+/; # missing '"` (3 chars)
    # First, split at commas
    for my $pref (split /,\s*/, $accept) {
        $pref =~ /^([^;]+)(;.*)?/;
	$type = $1;
	$param = $2;
	if ($type =~ /^$pat$/) {
	    push @tokens, "Charset: $type";
        } else {
	    push @tokens, "Invalid charset: $type";
	    $OK = 0;
	}
        # See if a parameter is present (e.g., qvalue)
	if (defined($param)) {
	    my $pobj = new IDS::DataSource::HTTP::AcceptParams($self->{"params"}, $param);
	    push @tokens, $pobj->tokens();
	}
    }

    $self->mesg(2, *parse{PACKAGE} .  "::parse: tokens\n    ",
                "\n    ", \@tokens);
    if (exists(${$self->{"params"}}{"Syntax only"}{"Charset"}) &&
        ${$self->{"params"}}{"Syntax only"}{"Charset"}) {
        $self->{"tokens"} = [ $OK ? "Charset syntax OK"
                                  : "Charset syntax NOT OK" ];
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
