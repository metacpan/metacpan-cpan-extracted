package IDS::Algorithm::Presence;
use base qw(IDS::Algorithm);
$IDS::Algorithm::Presence::VERSION = "1.0";

=head1 NAME

IDS::Algorithm::Presence - earn and.or test for the presence or absence
of attributes;
based on section 4.5 in the Kruegel and Vigna paper (L</SEE ALSO>).

=head1 SYNOPSIS

A usage synopsis would go here.  Since it is not here, read on.

=head1 DESCRIPTION

See IDS::Algorithm.pm docs for any functions not described here.

Note that this function does not properly implement the IDS::Algorithm
interface.

=cut

use strict;
use warnings;
use IO::File;
use Statistics::Lite qw(:all);
use Carp qw(cluck carp confess);

sub default_parameters {
    my $self = shift;

    %{$self->{"params"}} = (
        "verbose" => 0,
	"state_file" => 0,
    );
}

sub param_options {
    my $self = shift;

    return (
        "presence_verbose=i" => \${$self->{"params"}}{"verbose"},
	"ids_state=s"        => \${$self->{"params"}}{"state_file"},
    );
}

sub initialize {
    my $self = shift;

    # nothing here
}

sub save {
    my $self = shift;
    my $fname = shift or confess "bug: missing fname to save";
    my ($fh, $path);

    $fh = new IO::File("> $fname") or confess "Cannot open $fname: $!\n";
    for $path (keys %{$self->{"attpresence"}}) {
	print $fh "$path\n";
	map {print $fh "    $_\n"} keys %{${$self->{"attpresence"}}{$path}};
    }
    undef $fh;
}

sub load {
    my $self = shift;
    my $fname = shift or confess "bug: missing fname to load";
    my $fh = new IO::File("$fname") or confess "Unable to open $fname: $!\n";
    my ($path);

    while (<$fh>) {
        chomp;
	if (/^[^\s]/) { # a path
	    $path = $_;
	} else { # an attribute for the path
	    s/^    //;
	    ${$self->{"attpresence"}}{$path}{$_} = 1;
	}
    }
    undef $fh;
}

sub add {
    my $self = shift;
    my $path = shift;
    my $aref = shift;
    my $instance = shift;
    my $verbose = ${$self->{"params"}}{"verbose"};

    my ($v);

    for $v (@{$aref}) {
	print "path '$path' v '$v'\n" if $verbose;
	if (exists(${$self->{"attpresence"}}{$path}{$v})) {
	    ${$self->{"attpresence"}}{$path}{$v}++;
	} else {
	    ${$self->{"attpresence"}}{$path}{$v} = 1;
	}
    }
}

# Simple, binary result.  1 only if all have been seen previously.
sub test {
    my $self = shift;
    my $path = shift;
    my $aref = shift;
    my $instance = shift;
    my $verbose = ${$self->{"params"}}{"verbose"};

    my ($v);

    for $v (@{$aref}) {
	print "path '$path' v '$v'\n" if $verbose;
	exists(${$self->{"attpresence"}}{$path}) &&
	exists(${$self->{"attpresence"}}{$path}{$v}) &&
	defined(${$self->{"attpresence"}}{$path}{$v}) &&
	${$self->{"attpresence"}}{$path}{$v} > 0 or return 0;
    }
    return 1;
}

=head1 AUTHOR INFORMATION

Copyright 2005-2007, Kenneth Ingham.  All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

Address bug reports and comments to: ids_test at i-pi.com.  When
sending bug reports, please provide the versions of IDS::Test.pm,
IDS::Algorithm.pm, IDS::DataSource.pm, the version of Perl, and the
name and version of the operating system you are using.  Since Kenneth
is a PhD student, the speed of the response depends on how the research
is proceeding.

=head1 BUGS

Please report them.

=head1 SEE ALSO

L<IDS::Test>, L<IDS::DataSource>, L<IDS::Algorithm>

"Anomaly detection of web-based attacks" by Christopher Kruegel and
Giovanni Vigna, pages 251--261 in Proceedings of the 10th ACM conference
on computer and communications security, ACM Press, 2003, ISBN 1-58113-738-9.
http://doi.acm.org/10.1145/948109.948144

=cut

1;
