package IDS::Algorithm::Chi2ICD;
use base qw(IDS::Algorithm);
$IDS::Algorithm::Chi2ICD::VERSION = "1.0";

=head1 NAME

IDS::Algorithm::Chi2ICD - learn or test the character distribution of
a string, using the Chi2 of ICD developed by Kruegel and Vigna (See the
L</SEE ALSO> section for the reference).

=head1 SYNOPSIS

A usage synopsis would go here.  Since it is not here, read on.

The learning and testing are based on section 4.2 in kruegel2003anomaly.

=head1 DESCRIPTION

Someday more will be here.

ASSUMPTION: characters are 0..255; need to change to allow unicode, etc

=cut

use strict;
use warnings;
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
        "chardist_verbose=i" => \${$self->{"params"}}{"verbose"},
        "ids_state=s"   => \${$self->{"params"}}{"state_file"},
    );
}

sub initialize {
    my $self = shift;

    $self->{"count"} = []; # character counts
    map { ${$self->{"count"}}[$_] = 0; } 0..255;

    $self->{"cfreq"} = []; # character frequency
    map { ${$self->{"cfreq"}}[$_] = 0; } 0..255;

    $self->{"bins"}  = []; # binned frequencies
    map { ${$self->{"bins"}}[$_] = 0; } 0..5;

    $self->{"summarized"} = 0;
}

sub summarize {
    my $self = shift;

    my ($n, $i);

    $n = 0;
    map { $n += $_ } @{$self->{"count"}};

    if ($n > 0) {
	for ($i=0; $i <= $#{$self->{"count"}}; $i++) {
	    ${$self->{"cfreq"}}[$i] = ${$self->{"count"}}[$i] / $n;
	}
    } else {
        warn "Chi2ICD::summarize n is 0!\n";
    }

    $self->{"summarized"} = 1;
}

# note we write ord(c) rather than c to avoid problems with characters
# such as \r \n etc
sub save {
    my $self = shift;
    my $fname = $self->find_fname(shift);
    defined($fname) && $fname or
        confess *save{PACKAGE} . "::save missing filename";
    my $fh = to_fh($fname, ">");

    my ($sum, $i);

    $self->{"summarized"} or $self->summarize;

    $sum = 0;
    for ($i=0; $i <= $#{$self->{"cfreq"}}; $i++) {
	print $fh "$i: ", ${$self->{"cfreq"}}[$i], "\n";
	$sum += ${$self->{"cfreq"}}[$i];
    }
    print "Saved.  sum is $sum (should be 1)\n";
}

sub load {
    my $self = shift;
    my $fname = $self->find_fname(shift);
    defined($fname) && $fname or
        confess *load{PACKAGE} . "::load missing filename";
    my $fh = to_fh($fname, "<");
    my $verbose = ${$self->{"params"}}{"verbose"};

    my ($k, $v, $sum);

    $sum = 0;
    map {chomp;
         ($k, $v) = split(/:\s+/, $_, 2);
	 ${$self->{"cfreq"}}[$k] = $v;
	 $sum += $v;
        } <$fh>;

    $self->{"bins"} = [ $self->bin(sort { $b <=> $a } @{$self->{"cfreq"}}) ];
    print "Loaded.  Sum is $sum (should be 1)\n" if $verbose;

    $self->{"summarized"} = 1;
}

sub add {
    my $self = shift;
    my $tref = shift; # not used
    my $data = shift; # zero-length OK
    defined($data) or confess "Missing data to add\n";
    my $verbose = ${$self->{"params"}}{"verbose"};

    print "Chi2ICD::add data '$data'\n" if $verbose;

    map { ${$self->{"count"}}[ord($_)]++ } split(//, $data);
}

sub test {
    my $self = shift;
    my $tref = shift; # not used
    my $data = shift;
    defined($data) or confess "bug: missing data to test";

    my (@chars, $len, @observed, @expected, $chi2, $i, $sum, $weight);

    my $verbose = ${$self->{"params"}}{"verbose"};
    my $msg_fh = ${$self->{"params"}}{"msg_fh"};

    $self->{"summarized"} or $self->summarize;

    $len = length($data);
    $len > 0 or return 0; # 0-length means no dist
    $weight = 1.0 / $len;
    map { $chars[$_] = 0; } 0..255;
    map { $chars[ord($_)] += $weight; } split(//, $data);
    @chars = sort { $b <=> $a } @chars;

    # look at what we expected
    @observed = $self->bin(@chars);
    @expected = @{$self->{"bins"}};

    if ($verbose) {
	$sum = 0;
	map { $sum += $_ } @expected;
	print $msg_fh "Expected sum $sum\n";
	die "Bad sum\n" if $sum > 1.05; # should be 1, but allow fudge
    }

    # calculate chi2
    $chi2 = 0;
    for ($i=0; $i<6; $i++) {
	if ($expected[$i] == 0) {
	    # a really unusual distribution
	    warn "expected[$i] == 0";
	    $expected[$i] = 0.000000001;
	}
	$chi2 += ($observed[$i] - $expected[$i]) ** 2 / $expected[$i];
    }

    print $msg_fh "chi2 $chi2\n" if $verbose;

    # Table lookup for 6 degrees of freedom
    # table from http://www.statsoft.com/textbook/sttable.html#chi
    # p = 0.05 => chi2 < 11.07
    # p = 0.01 => chi2 < 15.09
    # p = 0.001 => chi2 < 20.52
    return 1.0   if $chi2 < 0.41174;
    return 0.995 if $chi2 >= 0.41174  && $chi2 < 0.55430;
    return 0.990 if $chi2 >= 0.55430  && $chi2 < 0.83121;
    return 0.975 if $chi2 >= 0.83121  && $chi2 < 1.14548;
    return 0.950 if $chi2 >= 1.14548  && $chi2 < 1.61031;
    return 0.900 if $chi2 >= 1.61031  && $chi2 < 2.67460;
    return 0.750 if $chi2 >= 2.67460  && $chi2 < 4.35146;
    return 0.500 if $chi2 >= 4.35146  && $chi2 < 6.62568;
    return 0.250 if $chi2 >= 6.62568  && $chi2 < 9.23636;
    return 0.100 if $chi2 >= 9.23636  && $chi2 < 11.07050;
    return 0.050 if $chi2 >= 11.07050 && $chi2 < 12.83250;
    return 0.025 if $chi2 >= 12.83250 && $chi2 < 15.08627;
    return 0.010 if $chi2 >= 15.08627 && $chi2 < 16.74960;
    return 0.005 if $chi2 >= 16.74960 && $chi2 < 20.52;
    return 0.001 if $chi2 >= 20.52;
    # justification for direction of "p": chi2 is larger as the data
    # gets further from expected.  Therefore, larger chi2 means less
    # normal data.
}

### for now, assume 6 bins per kruegel2003anomaly.  Need to generalize
### this code
sub bin {
    my $self = shift;
    my @freq = @_;
    my (@bins);

    # bins from kruegel2003anomaly
    @bins = (0, 0, 0, 0, 0, 0);
    $bins[0] = $freq[0];
    map { $bins[1] += $_ } @freq[1..3];
    map { $bins[2] += $_ } @freq[4..6];
    map { $bins[3] += $_ } @freq[7..11];
    map { $bins[4] += $_ } @freq[12..15];
    map { $bins[5] += $_ } @freq[16..255];

    return @bins;
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

"Anomaly detection of web-based attacks" by Christopher Kruegel and
Giovanni Vigna, published in Proceedings of the 10th ACM conference
on Computer and communications security 2003, pages 251--261,
http://doi.acm.org/10.1145/948109.948144.

=cut

1;
