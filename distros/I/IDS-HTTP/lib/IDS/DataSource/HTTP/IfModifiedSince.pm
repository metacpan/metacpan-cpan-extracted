# HTTP If-Modified-Since line; Section 14.28 of RFC 2616
#
# subclass of HTTP:Part; see that for interface requirements
#
package IDS::DataSource::HTTP::IfModifiedSince;
use base qw(IDS::DataSource::HTTP::Part);

use strict;
use warnings;
use Carp qw(carp confess);
use IDS::DataSource::HTTP::Date;
use IDS::DataSource::HTTP::Int;

$IDS::DataSource::HTTP::IfModifiedSince::VERSION = "1.0";

sub empty {
    my $self  = shift;
    undef $self->{"data"}, $self->{"tokens"};
}

sub parse {
    my $self  = shift;
    my $data = $self->{"data"}; # convenience
    my @tokens;

    $self->mesg(1, *parse{PACKAGE} .  "::parse: data '$data'");

    if ($data =~ /^(.*); (length=(\d+))$/) {
	push @tokens, "Non-standard If-Modified-Since";
        my $date = new IDS::DataSource::HTTP::Date($self->{"params"}, $1);
	push @tokens, $date->tokens();
	my $int = new IDS::DataSource::HTTP::Int($self->{"params"}, $3);
	push @tokens, $int->tokens();
    } else {
        my $date = new IDS::DataSource::HTTP::Date($self->{"params"}, $data);
	push @tokens, $date->tokens();
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
