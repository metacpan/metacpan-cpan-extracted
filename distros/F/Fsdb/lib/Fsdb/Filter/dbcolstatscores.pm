#!/usr/bin/perl

#
# dbcolstatscores.pm
# Copyright (C) 1997-2018 by John Heidemann <johnh@isi.edu>
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbcolstatscores;

=head1 NAME

dbcolstatscores - compute z-scores or t-scores for each value in a population

=head1 SYNOPSIS

dbcolstatscores [-t] [--tmean=MEAN] [--tstddev=STDDEV] column

=head1 DESCRIPTION

Compute statistics (z-score and optionally t-score) over a COLUMN of
numbers.  Creates new columns called "zscore", "tscore".
T-scores are only computed if requested with the C<-t> option,
or if C<--tmean> or C<--tstddev> are explicitly specified
(defaults are mean of 50, standard deviation of 10).

You may recall from your statistics class that a z-score is simply
the value normalized by mean and standard deviation, so that 0.0
is the mean and positive or negative values are multiples of the
standard deviation.
It assumes data follows a normal (Gaussian) distribution.

T-score scales the z-score to match a mean of 50 and a standard
deviation of 10.  This program allows generalized t-scores that use
any mean and standard deviation.

Other scales are sometimes used as well.  The Wechsler Adult
Intelligence Scale (one type of IQ test) is adjusted to a mean of 100
and a standard deviation of 15.  Other tests scale to other standard
deviations.

This program requires two passes over the data, and consumes
O(1) memory and O(number of rows) disk space.

=head1 OPTIONS

=over 4

=item B<-a> or B<--include-non-numeric>

Compute stats over all records (treat non-numeric records
as zero rather than just ignoring them).

=item B<-t>

Compute t-scores in addition to z-scores.

=item B<--tmean MEAN>

Use the given MEAN for t-scores.

=item B<--tstddev STDDEV> or B<--tsd STDDEV>

Use the given STDDEV for the standard deviation of the t-scores.

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

    #fsdb name id test1
    a 1 80
    b 2 70
    c 3 65
    d 4 90
    e 5 70
    f 6 90

=head2 Command:

    cat DATA/grades.fsdb | dbcolstatscores --tmean 50 --tstddev 10 test1 | dbcolneaten

=head2 Output:

    #fsdb name id test1 zscore   tscore 
    a       1  80    0.23063  52.306 
    b       2  70    -0.69188 43.081 
    c       3  65    -1.1531  38.469 
    d       4  90    1.1531   61.531 
    e       5  70    -0.69188 43.081 
    f       6  90    1.1531   61.531 
    #  | dbcolstatscores --tmean 50 --tstddev 10 test1
    #  | dbcolneaten 


=head1 SEE ALSO

L<dbcolpercentile(1)>,
L<dbcolstats(1)>,
L<Fsdb>,
L<dbcolscorrelate>


=head1 CLASS FUNCTIONS

=cut

@ISA = qw(Fsdb::Filter);
($VERSION) = 2.0;

use strict;
use Pod::Usage;
use Carp;

use Fsdb::Filter;
use Fsdb::IO::Reader;
use Fsdb::IO::Writer;
use Fsdb::Filter::dbpipeline qw(dbpipeline_open2 dbpipeline_close2_hash dbcolstats);
use Fsdb::Support qw($is_numeric_regexp);
use Fsdb::Support::NamedTmpfile;


=head2 new

    $filter = new Fsdb::Filter::dbcolstatscores(@arguments);

Create a new dbcolstatscores object, taking command-line arguments.

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
    $self->{_do_tscores} = undef;
    $self->{_t_mean} = undef;
    $self->{_t_stddev} = undef;
    $self->{_format} = "%.5g";
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
	'close!' => \$self->{_close},
	'd|debug+' => \$self->{_debug},
	'f|format=s' => \$self->{_format},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'log!' => \$self->{_logprog},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	't!' => \$self->{_do_tscores},
	'tmean=f' => \$self->{_t_mean},
	'tstddev|tsd=f' => \$self->{_t_stddev},
	'T|tmpdir|tempdir=s' => \$self->{_tmpdir},
	) or pod2usage(2);
    $self->parse_target_column(\@argv);
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup ($) {
    my($self) = @_;

    pod2usage(2) if (!defined($self->{_target_column}));
    $self->{_do_tscores} = 1 if (defined($self->{_t_mean}));
    $self->{_do_tscores} = 1 if (defined($self->{_t_stddev}));
    $self->{_t_mean} ||= 50.0;
    $self->{_t_stddev} ||= 10.0;

    $self->finish_io_option('input', -comment_handler => $self->create_delay_comments_sub);
    $self->{_target_coli} = $self->{_in}->col_to_i($self->{_target_column});
    croak($self->{_prog} . ": target column " . $self->{_target_column} . " is not in input stream.\n")
	if (!defined($self->{_target_coli}));

    $self->finish_io_option('output', -clone => $self->{_in}, -outputheader => 'delay');
    $self->{_out}->col_create('zscore')
	or croak($self->{_prog} . ": cannot create column zscore (maybe it already existed?)\n");
    if ($self->{_do_tscores}) {
        $self->{_out}->col_create('tscore')
	    or croak($self->{_prog} . ": cannot create column tscore (maybe it already existed?)\n");
    };
}

=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run ($) {
    my($self) = @_;

    #
    # Shunt the data to a separate file.
    #
    $self->{_copy_filename} = Fsdb::Support::NamedTmpfile::alloc($self->{_tmpdir});
    my $copy_writer = new Fsdb::IO::Writer(-file => $self->{_copy_filename},
			-clone => $self->{_in});

    # and take stats
    my ($stats_source_queue, $stats_sink, $stats_thread) =
	    dbpipeline_open2([-cols => [qw(data)]], dbcolstats(qw(data)));

    my $read_fastpath_sub = $self->{_in}->fastpath_sub();
    my $target_coli = $self->{_target_coli};
    my $fref;
    while ($fref = &$read_fastpath_sub()) {
	# copy and send to stats
	$copy_writer->write_rowobj($fref);
	$stats_sink->write_row($fref->[$target_coli]);
    };
    # close up both
    $copy_writer->close;
    my $stats_href = dbpipeline_close2_hash($stats_source_queue, $stats_sink, $stats_thread);
    foreach (qw(mean stddev)) {
	croak($self->{_prog} . ": internal error, missing stats field $_.\n")
	    if (!defined($stats_href->{$_}));
    };
    my $mean = $stats_href->{'mean'};
    my $stddev = $stats_href->{'stddev'};

    #
    # now re-open the copy and generate the new data
    #
    $self->{_in} = new Fsdb::IO::Reader(-file => $self->{_copy_filename},
		    -comment_handler => $self->create_pass_comments_sub);
    my $new_target_coli = $self->{_in}->col_to_i($self->{_target_column});
    croak($self->{_prog} . ": internal error: old and new target column numbers don't match.\n")
	if ($target_coli != $new_target_coli);
    $read_fastpath_sub = $self->{_in}->fastpath_sub(); # regenerate
    my $write_fastpath_sub = $self->{_out}->fastpath_sub(); # regenerate
    my $zscore_coli = $self->{_out}->col_to_i('zscore');
    my $tscore_coli = $self->{_do_tscores} ? $self->{_out}->col_to_i('tscore') : undef;
    while ($fref = &$read_fastpath_sub()) {
	my $x = $fref->[$target_coli];
	if ($x =~ /$is_numeric_regexp/) {
	    my $zscore = ($x - $mean) / $stddev;
	    $fref->[$zscore_coli] = $self->numeric_formatting($zscore);
	    if ($self->{_do_tscores}) {
		my $tscore = $zscore * $self->{_t_stddev} + $self->{_t_mean};
		$fref->[$tscore_coli] = $self->numeric_formatting($tscore);
            };
	} else {
	    $fref->[$zscore_coli] = '-';
	    $fref->[$tscore_coli] = '-' if ($self->{_do_tscores});
	};
	&$write_fastpath_sub($fref);
    };
}

=head1 AUTHOR and COPYRIGHT

Copyright (C) 1991-2018 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
