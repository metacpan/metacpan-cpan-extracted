package IDS::Algorithm::EnumOrRandom;
use base qw(IDS::Algorithm);
$IDS::Algorithm::EnumOrRandom::VERSION = "1.0";

=head1 NAME

IDS::Algorithm::EnumOrRandom - is a value enumurated or random;
based on section 4.4 in the Kruegel and Vigna paper (L</SEE ALSO>).

=head1 SYNOPSIS

A usage synopsis would go here.  Since it is not here, read on.

=head1 DESCRIPTION

BUG: This algorithm cannot go straight from training to testing without
saving; the save function also performs the necessary calculations.

See IDS::Algorithm.pm docs for any functions not described here.

notation from kruegel2003anomaly

=cut

use strict;
use warnings;
use IO::File;
use Statistics::Basic::CoVariance;
use Statistics::Basic::Variance;
use Carp qw(cluck carp confess);
use IDS::Utils qw(to_fh);

sub param_options {
    my $self = shift;

    return (
	    "eor_verbose=i" => \${$self->{"params"}}{"verbose"},
	    "ids_state=s"   => \${$self->{"params"}}{"state_file"},
	    "separator=s"   => \${$self->{"params"}}{"separator"},
	   );
}

sub default_parameters {
    my $self = shift;

    %{$self->{"params"}} = (
        "verbose"    => 0,
        "state_file" => 0,
	"separator"  => '=',
    );
}


sub initialize {
    my $self = shift;

    $self->{"f"} = {}; # count of occurrences of each "a" (attribute)
    $self->{"g"} = {}; # count of new versus seen values for each "a"
    $self->{"value"} = {}; # values seen for each "a"; probably needs to be tied
}

sub save {
    my $self = shift;
    my $fname = $self->find_fname(shift);
    defined($fname) && $fname or
	confess *save{PACKAGE} .  "::save missing filename";
    my $fh = to_fh($fname, ">");
    my $verbose = ${$self->{"params"}}{"verbose"};

    my ($a, @f, $covar, $fvar, $gvar, $rho, %value);

    %value = %{$self->{"value"}};
    for $a (keys %{$self->{"g"}}) {
        print "Looking at $a\n" if $verbose;
        @f = (1 .. ${$self->{"f"}}{$a});
        $covar = new Statistics::Basic::CoVariance(\@f, \@{${$self->{"g"}}{$a}})->query;
	$fvar = new Statistics::Basic::Variance(\@f)->query;
	$gvar = new Statistics::Basic::Variance(\@{${$self->{"g"}}{$a}})->query;
	print "fvar $fvar gvar $gvar\n" if $verbose;
        $rho = $fvar != 0 && $gvar != 0 ? $covar / sqrt($fvar * $gvar)
	                                : 1;
	print "rho $rho\n" if $verbose;
        if ($rho < 0) {
            my $n = scalar(keys (%{$value{$a}}));
            print $fh "--------------- $n '$a' ---------------\n";
            print $fh map {"$_\n"} keys (%{$value{$a}});
        } else {
            print $fh "--------------- random '$a' ---------------\n";
        }
    }
    undef $fh;
}

sub load {
    my $self = shift;
    my $fname = $self->find_fname(shift);
    $fname or
	confess *load{PACKAGE} . "::load missing filename";
    my $fh = to_fh($fname, "<");

    my ($k, $v, $i, $j, $line, %value, $count, $end);

    $self->{"value"} = {};
    $self->{"f"} = {};
    $self->{"g"} = {};
    %value = ();

    $i=0;
    while (<$fh>) {
        chomp;
	if (/^--------------- (\d+) '([^']*)' ---------------$/) {
	    $count = $1;
	    $a = $2;
	    for ($j=0; $j < $count; $j++) {
		$line = <$fh>;
		chomp($line);
		$value{$a}{$line} = 1;
	    }
	    $i = $end;
	} elsif (/^--------------- random '([^']*)' ---------------$/) {
	    $a = $1;
	    $value{$a} = "random";
	} else {
	    die "Unexpected line ($i) '$_'\n";
	}
	$i++;
    }
    $self->{"value"} = \%value;
}

sub add {
    my $self = shift;
    my $tokensref = shift or
        confess "bug: missing tokensref to ", *add{PACKAGE} . "::add";
    my $string = shift; # not used
    my $instance = shift or
        confess "bug: missing instance to ", *add{PACKAGE} . "::add";
    my $verbose = ${$self->{"params"}}{"verbose"};
    my $sep = ${$self->{"params"}}{"separator"};

    my ($a, $v, $pair, $new, $gend);

    for $pair (@{$tokensref}) {
	print "pair '$pair'\n" if $verbose;

	# only try this if we can get a key+value
        ($a, $v) = split(/$sep/, $pair, 2);
        if (defined($a) && defined($v)) {
	    print "a '$a' v '$v'\n" if $verbose;

	    exists(${$self->{"value"}}{$a}) or ${$self->{"value"}}{$a} = {};

	    # f(x) = x; # since this function is strictly incrementing, we
	    # keep track of the top, and generate the array of numbers when
	    # needed later.
	    ${$self->{"f"}}{$a}++;

	    # g(x)
	    # Is the value new?
	    $new = undef;
	    # If statement checks include checks for continuing to learn
	    ### continued learning may not be valid for this algorithm
	    if (exists(${$self->{"value"}}{$a}) && ${$self->{"value"}}{$a} ne "random") {
		# we have seen this $a; how about the $v?
		if (exists(${$self->{"value"}}{$a}{$v})) {
		    # yes
		    $new = 0;
		    ${$self->{"value"}}{$a}{$v}++;
		} else {
		    # no
		    $new = 1;
		    ${$self->{"value"}}{$a}{$v} = 1;
		}
	    } else {
		# we have never seen this $a before
		${$self->{"value"}}{$a} = {};
		$new = 1;
	    }
	    if (exists(${$self->{"g"}}{$a})) {
		$gend = $#{${$self->{"g"}}{$a}};
		# gend must be >= 0 since when we create it, we put a value in.
		push @{${$self->{"g"}}{$a}}, $new
			 ? (${${$self->{"g"}}{$a}}[$gend] - 1)
			 : (${${$self->{"g"}}{$a}}[$gend] + 1);
	    } else {
		${$self->{"g"}}{$a} = [ 0 ];
	    }
	} else {
	    # This is not serious, at least with the HTTP parser;
	    # it has some tokens that are validated and deleted.
	    # There is no need for us to try to memorize IP addrs,
	    # qvalues, etc.
	    print "Could not split '$pair' at '$sep'\n" if $verbose;
	}
    }
}


sub test {
    my $self = shift;
    my $tokensref = shift or
        confess "bug: missing tokensref to ", *test{PACKAGE} . "::test";
    my $string = shift; # not used
    my $instance = shift or
        confess "bug: missing instance to ", *test{PACKAGE} . "::test";

    my ($a, $v, $n, $pair, $result);

    $n = scalar(@{$tokensref});
    $result = 0;
    for $pair (@{$tokensref}) {
        ($a, $v) = split(/${$self->{"params"}}{"separator"}/, $pair, 2);

	defined($a) or confess "a undefined; pair '$pair'";

	if (exists(${$self->{"value"}}{$a})) {
	    if (${$self->{"value"}}{$a} eq "random") {
		# random means any value is OK
	        $result++;
	    } elsif (exists(${$self->{"value"}}{$a}{$v}) &&
	             defined(${$self->{"value"}}{$a}{$v}) &&
	             ${$self->{"value"}}{$a}{$v}) {
		# enumerated is only OK if we have seen it.
	        $result++;
	    }
	}
    }

    ### Should this be very strict or weighted?
    ### Currently choose strict
    return $result == $n ? 1 : 0; # strict
    # return $result / $n; # proportional
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
