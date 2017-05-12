package IDS::Algorithm::Length;
use base qw(IDS::Algorithm);
$IDS::Algorithm::Length::VERSION = "1.0";

=head1 NAME

IDS::Algorithm::Length - learn or test the length of a string;
based on section 4.1 in the Kruegel and Vigna paper (L</SEE ALSO>).

=head1 SYNOPSIS

A usage synopsis would go here.  Since it is not here, read on.

The learning and testing are based on section 4.1 in kruegel2003anomaly.

=head1 DESCRIPTION

Someday more will be here.

=cut

use strict;
use warnings;
use Statistics::Lite qw(:all);
use Carp qw(cluck carp confess);
use IDS::Utils qw(to_fh);

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
        "length_verbose=i"   => \${$self->{"params"}}{"verbose"},
	"ids_state=s"        => \${$self->{"params"}}{"state_file"},
    );
}

sub initialize {
    my $self = shift;


    $self->{"lengths"} = []; # a list of attribute lengths
    $self->{"stats"}   = {}; # length statistics from Statistics::Lite
    $self->{"summarized"} = 0;
}

sub summarize {
    my $self = shift;
    my $verbose = ${$self->{"params"}}{"verbose"};

    $self->{"stats"} = { statshash(@{$self->{"lengths"}}) };

    print join(" ", %{$self->{"stats"}}), "\n" if $verbose;
}

sub save {
    my $self = shift;
    my $fname = $self->find_fname(shift);
    defined($fname) && $fname or
	confess *save{PACKAGE} .  "::save missing filename";
    my $fh = to_fh($fname, ">");

    my ($chars, $c);

    defined($self->{"summarized"}) && $self->{"summarized"} or
            $self->summarize;

    print $fh join(" ", %{$self->{"stats"}}), "\n";
}

sub load {
    my $self = shift;
    my $fname = $self->find_fname(shift);
    $fname or 
        confess *load{PACKAGE} . "::load missing filename";
    my $fh = to_fh($fname);

    my ($line);

    $line = <$fh>;
    chomp $line;
    %{$self->{"stats"}} = split(/ /, $line);
}

# eqn 3 in kruegel2003anomaly
sub test {
    my $self = shift;
    my $tref = shift; # not used
    my $q = shift;
    defined($q) or
        confess "bug: missing q to ", *test{PACKAGE} . "::test";
    my $instance = shift; # not used

    my $var = ${$self->{"stats"}}{"variance"};
    my $mean = ${$self->{"stats"}}{"mean"};
    my $p = $var/(length($q) - $mean) **2;
    $p = $p > 1 ? 1 : $p;
    return $p;
}

sub add {
    my $self = shift;
    my $tref = shift; # not used
    my $str = shift; # 0-length is OK
    defined($str) or confess "bug: missing q to ", *add{PACKAGE} .  "::add";
    my $instance = shift; # not used

    push @{$self->{"lengths"}}, length($str);
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
