# HTTP x-forwarded-for line; Section 14.1 of RFC 2616
#
# subclass of HTTP:Part; see that for interface requirements
#

package IDS::DataSource::HTTP::XForwarded;

use strict;
use warnings;
use Carp qw(carp confess);
use base qw(IDS::DataSource::HTTP::Part);
use IDS::DataSource::HTTP::URIAuthority;

$IDS::DataSource::HTTP::XForwarded::VERSION     = "1.0";

sub empty {
    my $self  = shift;
    undef $self->{"data"}, $self->{"tokens"};
}

sub parse {
    my $self  = shift;
    my $data = $self->{"data"}; # convenience
    my ($part, @parts, @tokens);

    $self->mesg(1, *parse{PACKAGE} .  "::parse: data '$data'");

    # If the data contains spaces or commas, consider it a list.
    if ($data =~ /[,\s]/) {
        @parts = split /,?\s+/, $data;
    } else {
        @parts = ( $data );
    }

    for $part (@parts) {
	my $pobj = new IDS::DataSource::HTTP::URIAuthority($self->{"params"}, $part);
        push @tokens, $pobj->tokens;
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
