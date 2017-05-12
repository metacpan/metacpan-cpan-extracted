package IDS::Algorithm::Null;
use base qw(IDS::Algorithm);
$IDS::Algorithm::Null::VERSION = "1.0";

=head1 NAME

IDS::Algorithm::Null - An IDS algorithm that does nothing.  Useful for
performance testing the I/O system with IDS::Test.

=head1 SYNOPSIS

A usage synopsis would go here.  Since it is not here, read on.

=head1 DESCRIPTION

See IDS::Algorithm.pm docs for any functions not described here.

=cut

use strict;
use warnings;
use Carp qw(cluck carp confess);

sub param_options {
    my $self = shift;

    return (
	    "Null_verbose=i" => \${$self->{"params"}}{"verbose"},
	   );
}

sub default_parameters {
    my $self = shift;

    %{$self->{"params"}} = (
        "verbose" => 0,
    );
}

sub initialize {
    my $self = shift;

    return; # nothing to do in a null algorithm
}

sub save {
    my $self = shift;
    my $fname = $self->find_fname(shift);
    defined($fname) && $fname or
	confess *save{PACKAGE} .  "::save missing filename";
    my $fh = to_fh($fname, ">");

    return; # nothing to do in a null algorithm
}

sub load {
    my $self = shift;
    my $fname = $self->find_fname(shift);
    $fname or
	confess *load{PACKAGE} . "::load missing filename";
    my $fh = to_fh($fname, "<");

    return; # nothing to do in a null algorithm
}

sub test {
    my $self = shift;
    my $tokensref = shift or
        confess "bug: missing tokensref to ", *test{PACKAGE} . "::test";
    my $string = shift or
        confess "bug: missing string to ", *test{PACKAGE} . "::test";
    my $instance = shift or
        confess "bug: missing instance to ", *test{PACKAGE} . "::test";

    return 0; # nothing to do in a null algorithm
}

sub add {
    my $self = shift;
    my $tokensref = shift or
        confess "bug: missing tokensref to ", *add{PACKAGE} . "::add";
    my $string = shift or
        confess "bug: missing string to ", *add{PACKAGE} . "::add";
    my $instance = shift or
        confess "bug: missing instance to ", *add{PACKAGE} . "::add";

    return 0; # nothing to do in a null algorithm
}

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

L<IDS::Test>, L<IDS::DataSource>, L<IDS::Algorithm>

=cut

1;
