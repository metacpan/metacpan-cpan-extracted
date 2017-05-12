#!/usr/bin/perl

#
# dbcolscorrelate.pm
# Copyright (C) 1998-2015 by John Heidemann <johnh@isi.edu>
# $Id: bdcf1da03251b46bded7f59984e64e7f5060ae46 $
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbcolscorrelate;

=head1 NAME

dbcolscorrelate - find the coefficient of correlation over columns

=head1 SYNOPSIS

    dbcolscorrelate column1 column2 [column3...]

=head1 DESCRIPTION

Compute the coefficient of correlation over two (or more) columns.

The output is one line of correlations.

With exactly two columns, a new column I<correlation> is created.

With more than two columns, correlations are computed for each
pairwise combination of rows, and each output column
is given a name which is the concatenation of the two source rows,
joined with an underscore.

By default, we compute the I<population correlation coefficient>
(usually designed rho, E<0x03c1>)
and assume we see all members of the population.
With the B<--sample> option we instead compute the
I<sample correlation coefficient>, usually designated I<r>.
(Be careful in that the default here to full-population
is the I<opposite> of the default in L<dbcolstats>.)

This program requires a complete copy of the input data on disk.

=head1 OPTIONS

=over 4

=item B<--sample>

Select a the Pearson product-moment correlation coefficient
(the "sample correlation coefficient", usually designated I<r>).

=item B<--nosample>

Select a the Pearson product-moment correlation coefficient
(the "sample correlation coefficient", usually designated I<r>).



=item B<-f FORMAT> or B<--format FORMAT>

Specify a L<printf(3)>-style format for output statistics.
Defaults to C<%.5g>.

=item B<-T TmpDir>

where to put tmp files.
Also uses environment variable TMPDIR, if -T is 
not specified.
Default is /tmp.

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

    #fsdb name id test1 test2
    a 1 80 81
    b 2 70 71
    c 3 65 66
    d 4 90 91
    e 5 70 71
    f 6 90 91

=head2 Command:

    cat DATA/more_grades.fsdb | dbcolscorrelate test1 test2

=head2 Output:

    #fsdb correlation
    0.83329
    #  | dbcolscorrelate test1 test2


=head1 SEE ALSO

L<Fsdb>,
L<dbcolstatscores>,
L<dbcolsregression>.


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
use Fsdb::Support::NamedTmpfile;
use Fsdb::Filter::dbpipeline qw(dbpipeline_open2 dbpipeline_close2_hash dbcolstats);


=head2 new

    $filter = new Fsdb::Filter::dbcolscorrelate(@arguments);

Create a new dbcolscorrelate object, taking command-line arguments.

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
    $self->{_format} = "%.5g";
    $self->{_columns} = [];
    $self->{_include_non_numeric} = undef;
    $self->{_sample} = undef;
    $self->{_fscode} = undef;
    $self->set_default_tmpdir;
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
	's|sample!' =>  \$self->{_sample},
	'T|tmpdir|tempdir=s' => \$self->{_tmpdir},
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

    croak $self->{_prog} . ": at least two columns must be specified to compute a correlation.\n"
	if ($#{$self->{_columns}} < 1);
    my @output_columns;
    my %columns_processed;
    foreach my $i (0..$#{$self->{_columns}}) {
	my $column = $self->{_columns}[$i];
	croak $self->{_prog} . ": column $column is double-listed as an input column (not allowed).\n"
	    if (defined($columns_processed{$column}));
	$columns_processed{$column} = 1;
	$self->{_colis}[$i] = $self->{_in}->col_to_i($column);
	croak $self->{_prog} . ": column $column does not exist in the input stream.\n"
	    if (!defined($self->{_colis}[$i]));
	foreach my $j (0..$#{$self->{_columns}}) {
	    next if ($i >= $j);
	    push(@output_columns,  $self->{_columns}[$i] . "_" . $self->{_columns}[$j]);
	};
    };
    # if only one column, it has a special name
    $output_columns[0] =  'correlation'
	if ($#output_columns == 0);
    my @output_options = (-cols => \@output_columns);
    unshift (@output_options, -fscode => $self->{_fscode})
	if (defined($self->{_fscode}));
    $self->finish_io_option('output', @output_options);
};


=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run ($) {
    my($self) = @_;

    #
    # First, read data and save it to a file,	
    # and send each relevant column off to get stats.
    # 
    $self->{_copy_filename} = Fsdb::Support::NamedTmpfile::alloc($self->{_tmpdir});
    my $copy_writer = new Fsdb::IO::Writer(-file => $self->{_copy_filename},
			-clone => $self->{_in});

    my $read_fastpath_sub = $self->{_in}->fastpath_sub();
    my $copy_fastpath_sub = $copy_writer->fastpath_sub();

    # and take stats
    my(@stats_source_queues);
    my(@stats_sinks);
    my(@stats_threads);
    my $columns_aref = $self->{_columns};
    my $colis_aref = $self->{_colis};
    foreach (0..$#$columns_aref) {
	($stats_source_queues[$_], $stats_sinks[$_], $stats_threads[$_]) =
	    dbpipeline_open2([-cols => [qw(data)]], dbcolstats(($self->{_sample} ? '--sample' : '--nosample'), 'data'));
    }
    my $fref;
    while ($fref = &$read_fastpath_sub()) {
	# copy and send to stats
	$copy_writer->write_rowobj($fref);
	# with forking we have to close output explicitly
	# otherwise we block on the pipe(2) to the subprocesses.
	foreach (0..$#$columns_aref) {
	    $stats_sinks[$_]->write_row($fref->[$colis_aref->[$_]]);
	};
    };
    # close up both
    $copy_writer->close;
    foreach (0..$#$columns_aref) {
	$stats_sinks[$_]->close;
	$stats_sinks[$_] = undef;
    };
    my @means;
    my @stddevs;
    foreach (0..$#$columns_aref) {
	my $stats_href = dbpipeline_close2_hash($stats_source_queues[$_], $stats_sinks[$_], $stats_threads[$_]);
	$means[$_] = $stats_href->{'mean'};
	croak $self->{_prog} . ": column " . $columns_aref->[$_] . " does not have valid mean.\n"
	    if (!defined($means[$_]));
	$stddevs[$_] = $stats_href->{'stddev'};
	croak $self->{_prog} . ": column " . $columns_aref->[$_] . " does not have valid standard deviation.\n"
	    if (!defined($stddevs[$_]));
    };

    #
    # Now read back the data,
    # compute the z-scores on the fly,
    # and use that to compute the correlation.
    #
    $self->{_in}->close;
    $self->{_in} = new Fsdb::IO::Reader(-file => $self->{_copy_filename},
		    -comment_handler => $self->create_pass_comments_sub);
    my $sum_zs;
    my $ns;
    foreach my $i (0..$#$columns_aref) {
	foreach my $j (0..$#$columns_aref) {
	    next if ($i >= $j);
	    $sum_zs->[$i][$j] = 0;
	    $ns->[$i][$j] = 0;
	};
    };
	    
    $read_fastpath_sub = $self->{_in}->fastpath_sub(); # regenerate with copy stream
    while ($fref = &$read_fastpath_sub()) {
	my @zs;

	# compute z-score
	foreach (0..$#$columns_aref) {
	    my $x = $fref->[$colis_aref->[$_]];
	    if ($x !~ /$is_numeric_regexp/) {
		$zs[$_] = undef;
	    } else {
		$zs[$_] = ($x - $means[$_]) / $stddevs[$_];
	    };
        };

	# and compute running stats for correlations
	foreach my $i (0..$#$columns_aref) {
	    foreach my $j (0..$#$columns_aref) {
		next if ($i >= $j ||!defined($zs[$i]) || !defined($zs[$j]));
		$sum_zs->[$i][$j] += $zs[$i] * $zs[$j];
		($ns->[$i][$j])++;
	    };
	};
    };

    #
    # Finally output the results.
    #
    my(@correlations);
    foreach my $i (0..$#$columns_aref) {
	foreach my $j (0..$#$columns_aref) {
	    next if ($i >= $j);
	    if ($ns->[$i][$j] == 0) {
		push(@correlations, $self->{_empty});
	    } else {
		my $c = $sum_zs->[$i][$j] / $ns->[$i][$j];
		push(@correlations, $self->numeric_formatting($c));
            };
        };
    };
    $self->{_out}->write_row_from_aref(\@correlations);
};

=head1 AUTHOR and COPYRIGHT

Copyright (C) 1991-2015 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
