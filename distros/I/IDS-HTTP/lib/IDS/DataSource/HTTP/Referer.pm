# HTTP Referer line; Section 14.36 of RFC 2616
#
# subclass of HTTP:Part; see that for interface requirements
#
# This is simply a wrapper for IDS::DataSource::HTTP::URI.  However, we may want a
# syntax-only check here, but not for URIs in general.
#

package IDS::DataSource::HTTP::Referer;

use strict;
use warnings;
use Carp qw(carp confess);
use base qw(IDS::DataSource::HTTP::Part);

$IDS::DataSource::HTTP::Referer::VERSION     = "1.0";

sub empty {
    my $self  = shift;
    undef $self->{"data"}, $self->{"tokens"};
}

sub parse {
    my $self  = shift;
    my $referer = $self->{"data"}; # convenience
    my $OK = 1; # optimism
    my (@tokens, $params, $uri);

    $self->mesg(1, *parse{PACKAGE} .  "::parse: data '$referer'");

    $params = $self->{"params"};

    ${$params}{"Syntax only"}{"URI"} = ${$params}{"Syntax only"}{"Referer"}
        if (exists(${$params}{"Syntax only"}{"Referer"}));

    $uri = new IDS::DataSource::HTTP::URI($params, $referer);
    $self->{"URI"} = $uri;

    $self->{"tokens"} = $uri->tokens();
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
