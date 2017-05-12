package IDS::Algorithm::Order;
$IDS::Algorithm::Order::VERSION = "1.0";
use base qw(IDS::Algorithm);

=head1 NAME

IDS::Algorithm::Order - learn and/or test the order of attributes;
based on section 4.6 in the Kruegel and Vigna paper (L</SEE ALSO>).

=head1 SYNOPSIS

A usage synopsis would go here.  Since it is not here, read on.

=head1 DESCRIPTION

See IDS::Algorithm.pm docs for any functions not described here.

Note when using this with a full HTTP request, using tokens without
values might be appropriate.  This class was written to test as a part
of a complete re-implementation of the kruegel2003anomaly approach.

=cut

use strict;
use warnings;
use IO::File;
use Statistics::Lite qw(:all);
use Carp qw(cluck carp confess);
use IDS::Utils qw(to_fh);

sub param_options {
    my $self = shift;

    return (
	    "order_verbose=i" => \${$self->{"params"}}{"verbose"},
	    "ids_state=s"     => \${$self->{"params"}}{"state_file"},
	   );
}

sub default_parameters {
    my $self = shift;

    %{$self->{"params"}} = (
        "verbose" => 0,
        "state_file" => 0,
    );
}

sub initialize {
    my $self = shift;

    # %before{$a}{$b} means $a occurs before $b in training data
    $self->{"before"} = {};
}

sub save {
    my $self = shift;
    my $fname = $self->find_fname(shift);
    defined($fname) && $fname or
	confess *save{PACKAGE} .  "::save missing filename";
    my $fh = to_fh($fname, ">");

    my ($t, $v);

    for $t (keys %{$self->{"before"}}) {
        print $fh "$t\n";
	for $v (keys %{${$self->{"before"}}{$t}}) {
	    print $fh "    $v\n";
	}
    }
}

sub load {
    my $self = shift;
    my $fname = $self->find_fname(shift);
    $fname or
	confess *load{PACKAGE} . "::load missing filename";
    my $fh = to_fh($fname, "<");

    my ($t, $v);

    while (<$fh>) {
        chomp;
	if (/^    /) { # an "after"
	    ${$self->{"before"}}{$t}{$_} = 1;
	} else {
	    $t = $_;
	}
    }
}

sub add {
    my $self = shift;
    my $tokensref = shift or
        confess "bug: missing tokensref to ", *add{PACKAGE} . "::add";
    my $string = shift; # not used
    my $instance = shift or
        confess "bug: missing instance to ", *add{PACKAGE} . "::add";

    my ($i, $j, $before);

    # %before{$a}{$b} means $a occurs before $b in training data
    $before = $self->{"before"};
    for ($i=0; $i < $#{$tokensref}; $i++) {
	for ($j=$i+1; $j < $#{$tokensref}; $j++) {
	    $a = ${$tokensref}[$i];
	    $b = ${$tokensref}[$j];
	    ${$before}{$a}{$b} = 1 unless exists(${$before}{$a}{$b});
	}
    }
}

sub test {
    my $self = shift;
    my $tokensref = shift or
        confess "bug: missing tokensref to ", *test{PACKAGE} . "::test";
    my $string = shift; # not used;
    my $instance = shift or
        confess "bug: missing instance to ", *test{PACKAGE} . "::test";

    my ($i, $j, $before);

    # %before{$a}{$b} means $a occurs before $b in training data
    $before = $self->{"before"};
    for ($i=0; $i < $#{$tokensref}; $i++) {
	for ($j=$i+1; $j < $#{$tokensref}; $j++) {
	    $a = ${$tokensref}[$i];
	    $b = ${$tokensref}[$j];
	    return 0 if exists(${$before}{$b}{$a}) && ${$before}{$b}{$a} && !exists(${$before}{$a}{$b});
	}
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
