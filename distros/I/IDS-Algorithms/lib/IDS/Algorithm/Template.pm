package IDS::Algorithm::Template;
use base qw(IDS::Algorithm);
$IDS::Algorithm::Template::VERSION = "1.0";

=head1 NAME

IDS::Algorithm::Template - A template for an IDS algorithm for use with
IDS::Test.

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
	    "Template_verbose=i" => \${$self->{"params"}}{"verbose"},
	    "ids_state=s"        => \${$self->{"params"}}{"state_file"},
	   );
}

sub default_parameters {
    my $self = shift;

    %{$self->{"params"}} = (
        "verbose" => 1,
        "state_file" => 0,
    );
}

sub initialize {
    my $self = shift;

    warn *initialize{PACKAGE} . "::initialize not yet written\n";
}

sub save {
    my $self = shift;
    my $fname = $self->find_fname(shift);
    defined($fname) && $fname or
	confess *save{PACKAGE} .  "::save missing filename";
    my $fh = to_fh($fname, ">");

    confess *save{PACKAGE} . "::save not yet written\n";
}

sub load {
    my $self = shift;
    my $fname = $self->find_fname(shift);
    $fname or
	confess *load{PACKAGE} . "::load missing filename";
    my $fh = to_fh($fname, "<");

    confess *load{PACKAGE} . "::load not yet written\n";
}

sub test {
    my $self = shift;
    my $tokensref = shift or
        confess "bug: missing tokensref to ", *test{PACKAGE} . "::test";
    my $string = shift or
        confess "bug: missing string to ", *test{PACKAGE} . "::test";
    my $instance = shift or
        confess "bug: missing instance to ", *test{PACKAGE} . "::test";

    confess *test{PACKAGE} . "::test not yet written\n";
}

sub add {
    my $self = shift;
    my $tokensref = shift or
        confess "bug: missing tokensref to ", *add{PACKAGE} . "::add";
    my $string = shift or
        confess "bug: missing string to ", *add{PACKAGE} . "::add";
    my $instance = shift or
        confess "bug: missing instance to ", *add{PACKAGE} . "::add";

    confess *add{PACKAGE} . "::add not yet written\n";
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
