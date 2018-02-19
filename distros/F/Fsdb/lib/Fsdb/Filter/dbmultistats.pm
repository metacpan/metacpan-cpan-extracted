#!/usr/bin/perl -w

#
# dbmultistats.pm
# Copyright (C) 1991-2015 by John Heidemann <johnh@isi.edu>
# $Id: 85a9faaa887a82737100dceee7013e2894b800e1 $
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbmultistats;

=head1 NAME

dbmultistats - run dbcolstats over each group of inputs identified by some key

=head1 SYNOPSIS

$0 [-dm] [-c ConfidencePercent] [-f FormatForm] [-q NumberOfQuartiles] -k KeyField ValueField

=head1 DESCRIPTION

The input table is grouped by KeyField,
then we compute a separate set of column statistics on ValueField 
for each group with a unique key.

Assumptions and requirements
are the same as L<dbmapreduce>
(this program is just a wrapper around that program):

By default, data can be provided in arbitrary order
and the program consumes O(number of unique tags) memory,
and O(size of data) disk space.

With the -S option, data must arrive group by tags (not necessarily sorted),
and the program consumes O(number of tags) memory and no disk space.
The program will check and abort if this precondition is not met.

With two -S's, program consumes O(1) memory, but doesn't verify
that the data-arrival precondition is met.

(Note that these semantics are exactly like
    dbmapreduce -k KeyField -- dbcolstats ValueField
L<dbmultistats> provides a simpler API that passes
through statistics-specific arguments
and is optimized when data is pre-sorted and there
are no quarties or medians.)

=head1 OPTIONS

Options are the same as L<dbcolstats>.

=over 4

=item B<-k> or B<--key> KeyField

specify which column is the key for grouping (default: the first column)

=item B<--output-on-no-input>

Enables null output (all fields are "-", n is 0)
if we get input with a schema but no records.
Without this option, just output the schema but no rows.
Default: no output if no input.

=item B<-a> or B<--include-non-numeric>

Compute stats over all records (treat non-numeric records
as zero rather than just ignoring them).

=item B<-c FRACTION> or B<--confidence FRACTION>

Specify FRACTION for the confidence interval.
Defaults to 0.95 for a 95% confidence factor.

=item B<-f FORMAT> or B<--format FORMAT>

Specify a L<printf(3)>-style format for output statistics.
Defaults to C<%.5g>.

=item B<-m> or B<--median>

Compute median value.  (Will sort data if necessary.)
(Median is the quantitle for N=2.)

=item B<-q N> or B<--quantile N>

Compute quantile (quartile when N is 4),
or an arbitrary quantile for other values of N,
where the scores that are 1 Nth of the way across the population.

=item B<-S> or B<--pre-sorted>

Assume data is already sorted.
With one -S, we check and confirm this precondition.
When repeated, we skip the check.

=item B<-T TmpDir>

where to put temporary data.
Only used if median or quantiles are requested.
Also uses environment variable TMPDIR, if -T is 
not specified.
Default is /tmp.

=item B<--parallelism=N> or B<-j N>

Allow up to N reducers to run in parallel.
Default is the number of CPUs in the machine.

=item B<-F> or B<--fs> or B<--fieldseparator> S

Specify the field (column) separator as C<S>.
See L<dbfilealter> for valid field separators.

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

    #fsdb experiment duration
    ufs_mab_sys 37.2
    ufs_mab_sys 37.3
    ufs_rcp_real 264.5
    ufs_rcp_real 277.9

=head2 Command:

    cat DATA/stats.fsdb | dbmultistats -k experiment duration

=head2 Output:

    #fsdb      experiment      mean    stddev  pct_rsd conf_range      conf_low       conf_high        conf_pct        sum     sum_squared     min     max     n
    ufs_mab_sys     37.25 0.070711 0.18983 0.6353 36.615 37.885 0.95 74.5 2775.1 37.2 37.3 2
    ufs_rcp_real    271.2 9.4752 3.4938 85.13 186.07 356.33 0.95 542.4 1.4719e+05 264.5 277.9 2
    #  | /home/johnh/BIN/DB/dbmultistats experiment duration


=head1 SEE ALSO

L<Fsdb>.
L<dbmapreduce>.
L<dbcolstats>.


=head1 CLASS FUNCTIONS

=cut

@ISA = qw(Fsdb::Filter);
$VERSION = 2.0;

use strict;
use Pod::Usage;
use Carp;

use Fsdb::Filter;
use Fsdb::Filter::dbmapreduce;
use Fsdb::Filter::dbcolstats;
use Fsdb::IO::Reader;


=head2 new

    $filter = new Fsdb::Filter::dbmultistats(@arguments);

Create a new dbmultistats object, taking command-line arguments.

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
    $self->{_key_column} = undef;
    $self->{_pre_sorted} = 0;
    $self->{_confidence_fraction} = undef;
    $self->{_format} = undef;
    $self->{_quantile} = undef;
    $self->{_median} = undef;   # special case: renames the output field
    $self->{_max_parallelism} = undef;
    $self->{_include_non_numeric} = undef;
    $self->{_header} = undef;
    $self->{_output_on_no_input} = undef;
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
	'close!' => \$self->{_close},
	'c|confidence=f' => \$self->{_confidence_fraction},
	'd|debug+' => \$self->{_debug},
	'f|format=s' => \$self->{_format},
	'F|fs|cs|fieldseparator|columnseparator=s' => \$self->{_fscode},
	'header=s' => \$self->{_header},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'j|parallelism=i' => \$self->{_max_parallelism},
	'k|key=s' => \$self->{_key_column},
	'log!' => \$self->{_logprog},
	'm|median!' =>  \$self->{_median},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
        'output-on-no-input!' => \$self->{_output_on_no_input},
	'q|quantile=i' => \$self->{_quantile},
	'S|pre-sorted+' => \$self->{_pre_sorted},
	'T|tmpdir|tempdir=s' => \$self->{_tmpdir},
	) or pod2usage(2);
    $self->parse_target_column(\@argv);
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

Pass the right options to dbmapreduce and dbcolstats.

=cut

sub setup ($) {
    my($self) = @_;

    pod2usage(2) if (!defined($self->{_target_column}));

    #
    # First, dbcolstats:
    #
    my @dbcolstats_argv = (qw(--no-output-on-no-input --nolog));
    push(@dbcolstats_argv, '--fieldseparator', $self->{_fscode})
	if (defined($self->{_fscode}));
    push(@dbcolstats_argv, '--include-non-numeric')
	if (defined($self->{_include_non_numeric}));
    push(@dbcolstats_argv, '--confidence', $self->{_confidence_fraction})
	if (defined($self->{_confidence_fraction}));
    push(@dbcolstats_argv, '--format', $self->{_format})
	if (defined($self->{_format}));
    push(@dbcolstats_argv, '--median')
	if (defined($self->{_median}));
    push(@dbcolstats_argv, '--quantile', $self->{_quantile})
	if (defined($self->{_quantile}));
    push(@dbcolstats_argv, '--tmpdir', $self->{_tmpdir})
	if (defined($self->{_tmpdir}));
    push(@dbcolstats_argv, '--parallelism', $self->{_max_parallelism})
	if (defined($self->{_max_parallelism}));
    # last one!
    # push (@dbcolstats_argv, $self->{_target_column});
    # Added by hand below.

    # sigh, noclose/saveoutput didn't work
    my @dbmapreduce_argv = (qw(--nolog --noclose --copy-fs)); # --noclose --saveoutput), \$self->{_out});
#    push(@dbmapreduce_argv, qw(--noclose --saveoutput), \$self->{_out});
#    $self->{_child_saves_output} = 1;
    # pass input and output
    push(@dbmapreduce_argv, '--fieldseparator', $self->{_fscode})
	if (defined($self->{_fscode}));
    push (@dbmapreduce_argv, "--header", $self->{_header})
	if (defined($self->{_header}));
    push (@dbmapreduce_argv, "--input", $self->{_input});
    push (@dbmapreduce_argv, "--output", $self->{_output});
    # the rest
    push (@dbmapreduce_argv, ("-S") x $self->{_pre_sorted})
	if ($self->{_pre_sorted});
    push (@dbcolstats_argv, '--parallelism', $self->{_max_parallelism})
	if (defined($self->{_max_parallelism}));
    push (@dbmapreduce_argv, "--key", $self->{_key_column})
	if (defined($self->{_key_column}));

    #
    # Optimize: use dbcolstats -k if we can
    $self->{_multi_aware_reducer} = 1;
    $self->{_multi_aware_reducer} = undef if (defined($self->{_median}) || defined($self->{_quantile}));
    $self->{_multi_aware_reducer} = undef if (!$self->{_pre_sorted});
    if ($self->{_multi_aware_reducer}) {
	push(@dbcolstats_argv, '--key', $self->{_key_column});
	push(@dbmapreduce_argv, '--multiple-ok');
	$self->{_child_saves_output} = 1;
	push(@dbmapreduce_argv, '--noclose', '--saveoutput', \$self->{_out});
    };


    my $dbcolstats_code = 'dbcolstats(';
    foreach (@dbcolstats_argv) {
	$dbcolstats_code .= "'$_', ";
    };
    $dbcolstats_code .= "'" . $self->{_target_column} . "')";
    push (@dbmapreduce_argv, '--code', $dbcolstats_code);

    print join(" ", @dbmapreduce_argv) if ($self->{_debug});    

    $self->{_mapreducer} = new Fsdb::Filter::dbmapreduce(@dbmapreduce_argv);
    $self->{_mapreducer}->setup;
}

=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run ($) {
    my($self) = @_;
    $self->{_mapreducer}->run;
}


=head2 finish

    $filter->finish();

Internal: write trailer.

=cut
sub finish ($) {
    my($self) = @_;
    $self->{_mapreducer}->finish;
    # we need to add our trailer
#    $self->SUPER::finish();
    # xxx: hack hack hack
    # --saveoutput didn't work, so fake it up here
    my $post = "# " . $self->compute_program_log() . "\n";
    if ($self->{_child_saves_output}) {
        $self->SUPER::finish();
    } else {
        if (ref($self->{_output}) =~ /^Fsdb::IO/) {	
    	    $self->{_output}->write_comment($post);
	    $self->{_output}->close if ($self->{_close});
        } elsif (ref($self->{_output}) =~ /^Fsdb::BoundedQueue/) {	
	    $self->{_output}->enqueue($post);
	    $self->{_output}->enqueue(undef)  if ($self->{_close});
        } elsif ($self->{_output} eq '-') {
	    # stdout
	    print $post;
        } else {
	    # assume file handle
	    $self->{_output}->print($post);
	    $self->{_output}->close if ($self->{_close});
        };
    };
}

=head1 AUTHOR and COPYRIGHT

Copyright (C) 1991-2015 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
