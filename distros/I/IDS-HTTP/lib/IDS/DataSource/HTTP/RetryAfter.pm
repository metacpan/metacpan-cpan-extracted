# HTTP RetryAfter line; Section 14.37 of RFC 2616
#

package IDS::DataSource::HTTP::RetryAfter;

use strict;
use warnings;
use Carp qw(carp confess);
use base qw(IDS::DataSource::HTTP::Part);

$IDS::DataSource::HTTP::RetryAfter::VERSION     = "1.0";

sub empty {
    my $self  = shift;
    undef $self->{"data"}, $self->{"tokens"};
}

sub parse {
    my $self  = shift;
    my $value = $self->{"data"}; # convenience
    my @tokens;

    $self->mesg(1, *parse{PACKAGE} .  "::parse: data '$value'");

    # The value can be either a date or delta-seconds.
    if ($value =~ /^\d+$/) {
	$self->{"sub"} = new IDS::DataSource::HTTP::Int($self->{"params"}, $value);
    } else {
	$self->{"sub"} = new IDS::DataSource::HTTP::Date($self->{"params"}, $value);
    }

    $self->{"tokens"} = $self->{"sub"}->tokens();
    $self->mesg(2, *parse{PACKAGE} .  "::parse: tokens\n    ",
                "\n    ", $self->{"tokens"});
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
