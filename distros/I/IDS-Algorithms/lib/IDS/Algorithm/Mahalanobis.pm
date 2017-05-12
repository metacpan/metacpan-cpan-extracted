package IDS::Algorithm::Mahalanobis;
use base qw(IDS::Algorithm);
$IDS::Algorithm::Mahalanobis::VERSION = "1.0";

=head1 NAME

Mahalanobis - An IDS algorithm implementing an approximation of the IDS
by Wang and Stolfo (See the L</SEE ALSO> section for the reference).

=head1 SYNOPSIS

A usage synopsis would go here.  Since it is not here, read on.

=head1 DESCRIPTION

DIFFERENCE: Wang and Stolfo correlated packet length with character
frequencies.  Since my data does not have original packets, I am
applying their method to the whole request (which often comes in a
single packet).

See IDS::Algorithm.pm docs for any functions not described here

ASSUMPTION: characters are 0..255; unicode (etc) not yet supported.

=cut

use strict;
use warnings;
use Carp qw(cluck carp confess);
use IDS::Utils qw(to_fh);
use bytes;

=head2 Parameters

Parameters are:

=over

=item WS_verbose

Turn on extra messages as the algorithm runs.

=item alpha

The value of the constant alpha in the simplified Mahalanobis distance.
See page 7 in the Wang and Stolfo paper.

=item ids_state

The file to load the saved state from.

=back

=head2 Methods

Most of these methods are required by L<IDS::Algorithm>; see
documentation there for additional information.

=over

=item default_parameters()

Sets all of the default values for the parameters.  Normally called by
new() or one of its descendents.

=item param_options()

Provides the parameters to use with Getopt::Long.

=back

=cut

sub default_parameters {
    my $self = shift;

    %{$self->{"params"}} = (
        "verbose" => 0,
        "alpha" => 0.001, # guessed value; the whole alpha concept in
                          # the paper seems to me to be a kludge
	"state_file" => 0,
    );
}

sub param_options {
    my $self = shift;

    return (
	    "WS_verbose=i" => \${$self->{"params"}}{"verbose"},
	    "alpha=f"      => \${$self->{"params"}}{"alpha"},
	    "ids_state=s"  => \${$self->{"params"}}{"state_file"},
	   );
}

=over

=item initialize()

Called by Super::new().  We set up the data structures here for storing
the mean, mean**2, and number of observations for each character.

=back

=cut

sub initialize {
    my $self = shift;

    map { ${$self->{"observations"}}[$_] = 0 } 0..255;
    map { ${$self->{"mean"}}[$_] = 0 } 0..255;
    map { ${$self->{"mean2"}}[$_] = 0 } 0..255;
}

=over

=item save(fn)

Save the current state to the file or filehandle provided.  find_fname
(in IDS::Algorithm) handles figuring out the destination.

=back

=cut

sub save {
    my $self = shift;
    my $fname = $self->find_fname(shift);
    defined($fname) && $fname or
	confess *save{PACKAGE} .  "::save missing filename";
    my $fh = to_fh($fname, ">");

    my ($i);

    for ($i=0; $i<256; $i++) {
	print $fh "$i; ", ${$self->{"observations"}}[$i], "; ",
	      ${$self->{"mean"}}[$i], "; ",
	      ${$self->{"mean2"}}[$i], "\n";
    }
}

=over

=item load(fn)

Load the current state from the file or filehandle provided.  find_fname
(in IDS::Algorithm) handles figuring out the source.

=back

=cut

sub load {
    my $self = shift;
    my $fname = $self->find_fname(shift);
    $fname or
	confess *load{PACKAGE} . "::load missing filename";
    my $fh = to_fh($fname, "<");

    my $verbose = ${$self->{"params"}}{"verbose"};

    my ($n, $i, $mean, $mean2, $obs);

    $n = 0;
    while (<$fh>) {
	chomp;
	($i, $obs, $mean, $mean2) = split(/; /);
	${$self->{"observations"}}[$i] = $obs;
	${$self->{"mean"}}[$i] = $mean;
	${$self->{"mean2"}}[$i] = $mean2;
	$n++;
    }
    warn "Duplicate data loaded from $fname"
        if $n != scalar(@{$self->{"mean"}});
}

=over

=item add(tokenref, string, n)

Update the character frequency statistics.  For calculating the
Mahalanobis distance, these stats are the mean and the mean**2, as well
as a count of the number of observations.  The array is indexed by
ord(chr) to improve performance.

=begin latex

The mean and $\mbox{mean}^2$ are for character frequencies.  This means that

\[
1 = \sum_c f(c)
\]
for the freqency $f$ over all characters $c$.

We keep the mean current without having to remember all prior values (which
cause us to run out of memory for large training sets) by using the observation
by Knuth that when we have a new $x_{N+1}$ to add in, 
\[
\overline{x}' = \overline{x} + \frac{x_{N+1} - \overline{x}}{N+1}
\]

By storing the mean, $\mbox{mean}^2$, and number of observations, we can support
the incremental learning as described in Section 3.3 of the Wang and
Stolfo paper.

=end latex

This function only uses the string version of the data.  The tokens and 
instance are ignored.

=back

=cut

sub add {
    my $self = shift;
    my $tref = shift; # not used
    my $data = shift or
        confess "bug: missing data to ", *add{PACKAGE} . "::add";
    my $verbose = ${$self->{"params"}}{"verbose"};

    my ($i, @freqs);

    print "Data: '$data'\n" if $verbose > 1;

    @freqs = ();
    $self->freq_calc($data, \@freqs);

    if ($verbose) {
        print "Freqs:\n";
	map { print "$_: $freqs[$_]\n"; } 0 .. 255;
    }

    for ($i = 0; $i<256; $i++) {
	${$self->{"observations"}}[$i]++;
	${$self->{"mean"}}[$i] += ($freqs[$i] - ${$self->{"mean"}}[$i]) /
	    ${$self->{"observations"}}[$i];
	${$self->{"mean2"}}[$i] += ($freqs[$i]**2 - ${$self->{"mean2"}}[$i]) /
	    ${$self->{"observations"}}[$i];
     }

     # wasteful during training, but required for adaptive testing
     $self->calc_stddev;
}

=over

=item freq_calc(data, freqref)

Calculate character frequencies in the data string provided.  The result
is returned in the array referenced by freqref.

=back

=cut

sub freq_calc {
    my $self = shift;
    my $data = shift or
        confess "bug: missing data to ", *freq_calc{PACKAGE} . "::add";
    my $freqref = shift or
        confess "bug: missing freqref to ", *freq_calc{PACKAGE} . "::add";

    my ($i, $byte, $chr, $length);

    $length = length($data);

    # init
    map { ${$freqref}[$_] = 0 } 0..255;

    # count
    map { ${$freqref}[ord($_)]++; } split(//, $data);
 
    # scale
    map { ${$freqref}[$_] /= $length } 0..255;
}

=over

=item test(tokenref, string, n)

Test the string to see how similar its character distribution is to the
distribution we have learned.  This function only uses the string version
of the data.  The tokens and instance are ignored.

=begin latex

\providecommand{\abs}[1]{\mid #1 \mid}

From training, we have $n_c$ is the number of observations for a character
$c$, $y_{c,i}$ is the frequency with which character $c$ in the $i$th
observation occurred in the training data,
$ \overline{y_c} = \sum_{i = 0}^{n_c} \frac{y_{c,i}}{n_c}$, and
$ \overline{y_c^2} = \sum_{i = 0}^{n_c} \frac{y_{c,i}^2}{n_c}$.
We have a $\overline{y}$ and $\overline{y^2}$ for each character.

Given a set of character frequencies $X$ for a test item and
$\sigma_c = \sqrt{\overline{y_c^2} - \overline{y_c}^2}$, then
the simplified Mahalanobis distance per Wang and Stolfo is:
\[
d = \sum_{c} \frac{\abs{x_c - \overline{y_c}}}{\sigma_c + \alpha}
\]
where $c$ is an index across all characters, and $x_c \in X$.
Note that $\alpha$ is the constant from the Wang and Stolfo paper,
and in this code, it is the parameter \texttt{alpha}.  

We differ from Wang and Stolfo in mapping the distance $d \in
[0,\infty)$ into $[0,1]$ by producing a result $r \in [0,1] $.
\[
r = \left\{ \begin{array}{ll}
            1 & \mbox{if $d \le 1$}\\[0.5em]
	    \frac{1}{\log{(d - 1 + e)}} & \mbox{if $d > 1$}\\
	    \end{array}
	    \right.
\]
$e$ is the base of the natural logarithms.  This (or a similar) mapping
is required because IDS::Algorithm requires that the result of testing
be in $[0,1]$.  The mapping for values $\le 1$ is justified because the
larger the distance, the more abnormal the data item.  Experience shows
that most normal requests have a distance $> 1$.

=end latex 

=back

=cut

sub test {
    my $self = shift;
    my $tref = shift; # not used
    my $data = shift;

    my (@freq, $dist, $i, $chr, $stddev, $result, $d, $e);
    my $alpha = ${$self->{"params"}}{"alpha"};
    my $verbose = ${$self->{"params"}}{"verbose"};

    exists($self->{"stddev"}) or $self->calc_stddev;

    print "data '$data'\n" if $verbose;

    # calculate the frequency distribution for this datum
    @freq = ();
    $self->freq_calc($data, \@freq);

    print "Freq: ", join(", ", @freq), "\n" if $verbose > 1;

    # compare with simplified Mahalanobis distance
    $dist = 0;
    for ($i=0; $i<256; $i++) {
	$d = abs($freq[$i] - ${$self->{"mean"}}[$i] ) / (${$self->{"stddev"}}[$i] + $alpha);
	$dist += $d;
	print "stddev[$i] = ", ${$self->{"stddev"}}[$i], ", dist $d\n" if $verbose > 1;
    }
    # distance is potentially (nearly) unbounded.  Since we need it to
    # be in [0,1] with 1 meaning close, we use the following function:
    $e = exp(1);
    $result = $dist <= 1 ? 1 : (1.0 / log($dist + $e - 1));
    print "dist $dist result $result\n", if $verbose;
    return $result;
}

sub calc_stddev {
    my $self = shift;
    my ($i);

    $self->{"stddev"}= [];
    for ($i=0; $i<256; $i++) {
	${$self->{"stddev"}}[$i] = sqrt(abs(${$self->{"mean2"}}[$i] - ${$self->{"mean"}}[$i]**2));
    }
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

"Anomalous Payload-based Network Intrusion Detection" by Ke Wang and
Salvatore J. Stolfo, pages 203--222 in Recent Advances in Intrusion
Detection: 7th International Symposium, RAID 2004, Sophia Antipolis,
France, September 15-17, 2004. Proceedings.  Published as Lecture Notes
in Computer Science 3224, ISBN 3-540-23123-4.

=cut

1;
