# HTTP Agent or User-Agent
# RFC 2616 section 14.43 (User-Agent)
# Agent is not in RFC 2616, but is common.
#
# subclass of HTTP:Part; see that for interface requirements
#

package IDS::DataSource::HTTP::Agent;

use strict;
use warnings;
use Carp qw(carp confess);
use base qw(IDS::DataSource::HTTP::Part);

$IDS::DataSource::HTTP::Agent::VERSION     = "1.0";

sub empty {
    my $self  = shift;
    undef $self->{"data"}, $self->{"tokens"};
}

sub parse {
    my $self  = shift;
    my $agent = $self->{"data"}; # convenience
    my @tokens = ();
    my $OK = 1; # optimism

    $self->mesg(1, *parse{PACKAGE} .  "::parse: data '$agent'");

    unless ($agent =~ m!(\w+)/([\d.]+)( +\(([^\)]*)\))?!) {
	push @tokens, "User agent: $agent";
	$self->{"tokens"} = \@tokens;
	return;
    }
    while (m!(\w+)/([\d.]+)( +\(([^\)]*)\))?!g) {
# below is correct; commented out because of code freeze for PhD
#    while (m!(\w+)/([\d.]+)( +\((.*)\))?!g) {
	push @tokens, "User agent: $1";
	push @tokens, "User agent version: $2";
	if (defined($3)) {
	    my $info = $4;
	    $self->mesg(2, *parse{PACKAGE} .  "::parse: addl info '$info'");
	    push @tokens, map {"UA additional info: $_"} split /; +/, $info;
	}
    }

    $self->mesg(2, *parse{PACKAGE} .  "::parse: tokens\n    ",
                "\n    ", \@tokens);
    if (exists(${$self->{"params"}}{"Syntax only"}{"User-Agent"}) &&
        ${$self->{"params"}}{"Syntax only"}{"User-Agent"}) {
        $self->{"tokens"} = [ $OK ? "Agent syntax OK"
                                  : "Agent syntax NOT OK" ];
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
