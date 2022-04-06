#!/usr/bin/perl

#
# dbcolsregression.pm
# Copyright (C) 1997-2022 by John Heidemann <johnh@isi.edu>
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbcolsregression;

=head1 NAME

dbcolsregression - compute linear regression between two columns

=head1 SYNOPSIS

    dbcolsregression  [-a] column1 column2

=head1 DESCRIPTION

Compute linear regression over C<column1> and C<column2>.
Outputs slope, intercept, and correlation coefficient.

=head1 OPTIONS

=over 4

=item B<-a> or B<--include-non-numeric>

Compute stats over all records (treat non-numeric records
as zero rather than just ignoring them).

=item B<-f FORMAT> or B<--format FORMAT>

Specify a L<printf(3)>-style format for output statistics.
Defaults to C<%.5g>.

=back

=for comment
begin_standard_fsdb_options

This module also supports the standard fsdb options:

=over 4

=item B<-d>

Enable debugging output.

=item B<-i> or B<--input> InputSource

Read from InputSource, typically a file name, or C<-> for standard input,
or (if in Perl) a IO::Handle, Fsdb::IO or Fsdb::BoundedQueue objects.

=item B<-o> or B<--output> OutputDestination

Write to OutputDestination, typically a file name, or C<-> for standard output,
or (if in Perl) a IO::Handle, Fsdb::IO or Fsdb::BoundedQueue objects.

=item B<--autorun> or B<--noautorun>

By default, programs process automatically,
but Fsdb::Filter objects in Perl do not run until you invoke
the run() method.
The C<--(no)autorun> option controls that behavior within Perl.

=item B<--help>

Show help.

=item B<--man>

Show full manual.

=back

=for comment
end_standard_fsdb_options


=head1 SAMPLE USAGE

=head2 Input:

    #fsdb x	y
    160	126
    180	103
    200	82
    220	75
    240	82
    260	40
    280	20

=head2 Command:

    cat DATA/xy.fsdb | dbcolsregression x y | dblistize

=head2 Output:

    #fsdb -R C slope:d intercept:d confcoeff:d n:q
    slope:     -0.79286
    intercept: 249.86
    confcoeff: -0.95426
    n:         7

    #  | dbcolsregression x y
    #                confidence intervals assume normal distribution and small n.
    #  | dblistize

Sample data from 
L<http://people.hofstra.edu/faculty/Stefan_Waner/RealWorld/calctopic1/regression.html>
by Stefan Waner and Steven R. Costenoble.

=head1 SEE ALSO

L<dbcolstats>,
L<dbcolscorrelate>,
L<Fsdb>.


=head1 CLASS FUNCTIONS

=cut

@ISA = qw(Fsdb::Filter);
$VERSION = 2.0;

use strict;
use Pod::Usage;
use Carp;

use Fsdb::Filter;
use Fsdb::IO::Reader;
use Fsdb::IO::Writer;
use Fsdb::Support qw($is_numeric_regexp);


=head2 new

    $filter = new Fsdb::Filter::dbcolsregression(@arguments);

Create a new dbcolsregression object, taking command-line arguments.

=cut

sub new ($@) {
    my $class = shift @_;
    my $self = $class->SUPER::new(@_);
    bless $self, $class;
    $self->set_defaults;
    $self->parse_options(@_);
    $self->SUPER::post_new();
    return $self;
}


=head2 set_defaults

    $filter->set_defaults();

Internal: set up defaults.

=cut

sub set_defaults ($) {
    my($self) = @_;
    $self->SUPER::set_defaults();
    $self->{_include_non_numeric} = undef;
    $self->{_format} = "%.5g";
    $self->{_columns} = [];
    $self->{_fscode} = undef;
}

=head2 parse_options

    $filter->parse_options(@ARGV);

Internal: parse command-line arguments.

=cut

sub parse_options ($@) {
    my $self = shift @_;

    my(@argv) = @_;
    $self->get_options(
	\@argv,
 	'help|?' => sub { pod2usage(1); },
	'man' => sub { pod2usage(-verbose => 2); },
	'a|include-non-numeric!' => \$self->{_include_non_numeric},
	'autorun!' => \$self->{_autorun},
	'd|debug+' => \$self->{_debug},
	'f|format=s' => \$self->{_format},
	'F|fs|cs|fieldseparator|columnseparator=s' => \$self->{_fscode},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'log!' => \$self->{_logprog},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	) or pod2usage(2);
    push (@{$self->{_columns}}, @argv);
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup ($) {
    my($self) = @_;

    $self->finish_io_option('input', -comment_handler => $self->create_pass_comments_sub);

    croak($self->{_prog} . ": exactly two columns must be specified to compute a correlation.\n")
	if ($#{$self->{_columns}} != 1);
    foreach (0..$#{$self->{_columns}}) {
	my $column = $self->{_columns}[$_];
	$self->{_colis}[$_] = $self->{_in}->col_to_i($column);
	croak $self->{_prog} . ": column $column does not exist in the input stream.\n"
	    if (!defined($self->{_colis}[$_]));
    };

    my @output_options = (-cols => [qw(slope:d intercept:d confcoeff:d n:q)]);
    unshift (@output_options, -fscode => $self->{_fscode})
	if (defined($self->{_fscode}));
    $self->finish_io_option('output', @output_options);
}

=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run ($) {
    my($self) = @_;

    my($n) = 0;
    my($sxy) = 0.0;
    my($sx) = 0.0;
    my($sy) = 0.0;
    my($sxx) = 0.0;
    my($syy) = 0.0;

    my $read_fastpath_sub = $self->{_in}->fastpath_sub();
    my $fref;
    my $xf = $self->{_colis}[0];
    my $yf = $self->{_colis}[1];
    my $x;
    my $y;
    while ($fref = &$read_fastpath_sub()) {
	$x = $fref->[$xf];
	$y = $fref->[$yf];
        if ($x !~ /$is_numeric_regexp/) {
	    next if (!$self->{_include_non_numeric});
	    $x = 0;
	};
        if ($y !~ /$is_numeric_regexp/) {
	    next if (!$self->{_include_non_numeric});
	    $y = 0;
	};
        $n++;
        $sx += $x;
        $sxx += $x * $x;
        $sy += $y;
        $syy += $y * $y;
        $sxy += $x * $y;
    };

    croak($self->{_prog} . ": no input\n")
	if ($n == 0);

    #
    # Compute linear regression.
    #
    my $denom_x = ($n * $sxx - $sx * $sx);
    my $denom_y = ($n * $syy - $sy * $sy);
    my($slope, $intercept, $coeff);
    if ($denom_x == 0 || $denom_y == 0) {
	$slope = "inf";
	$intercept = "nan";
	$coeff = "nan";
    } else {
	$slope = (1.0 * $n * $sxy - $sx * $sy) / $denom_x;
	$intercept = (1.0 * $sy - $slope * $sx) / $n;
        $coeff = (1.0 * $n * $sxy - $sx * $sy) / (sqrt($denom_x) * sqrt($denom_y));

	$slope = $self->numeric_formatting($slope);
	$intercept = $self->numeric_formatting($intercept);
	$coeff = $self->numeric_formatting($coeff);
    };
    my @of = ($slope, $intercept, $coeff, $n);
    $self->{_out}->write_row_from_aref(\@of);
}

=head1 AUTHOR and COPYRIGHT

Copyright (C) 1997-2022 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
