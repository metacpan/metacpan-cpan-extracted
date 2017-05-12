#!/usr/bin/perl -w

#
# dbfilediff.pm
# Copyright (C) 2012-2015 by John Heidemann <johnh@isi.edu>
# $Id: 3221524c041f6e1037daba3af5e80a4df19feb6d $
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbfilediff;

=head1 NAME

dbfilediff - compare two fsdb tables

=head1 SYNOPSIS

    dbfilediff [-Eq] [-N diff_column_name] --input table1.fsdb --input table2.fsdb 

OR

    cat table1.fsdb  | dbfilediff [-sq] --input table2.fsdb

=head1 DESCRIPTION

Dbfilediff compares two Fsdb tables, row by row.
Unlike Unix L<diff(1)>, this program assumes the files are identical
line-by-line and we compare fields.
Thus, insertion of one extra row will result in all
subsequent lines being marked different.

By default, I<all> columns must be unique.
(At some point, support to specific specific columns may be added.)

Output is a new table with a new column C<diff>
(or something else if the C<-N> option is given),
"-"  and "+" for the first and second non-equal rows,
"=" for matching lines, 
or "~" if they are equal with epsilon numerics
(in which case only the second row is included).
Unlike Unix L<diff(1)>, we output I<all> rows (the "=" lines),
not just diffs (the C<--quiet> option suppresses this output).

Optionally, with C<-E> it will do a "epsilon numeric" comparision,
to account for things like variations in different computer's
floating point precision and differences in printf output.

Epsilon comparision is asymmetric, in that it assumes the first
input is correct an allows the second input to vary,
but not the reverse.

Because two tables are required,
input is typically in files.
Standard input is accessible by the file "-".

=head1 OPTIONS

=over 4

=item B<-E> or B<--epsilon>

Do epsilon-numeric comparison. (Described above.)

Epsilon-comparision is only done on columns that look like floating
point numbers, not on strings or integers.
Epsilon comparision allows the last digit to vary by 1,
or for there to be one extra digit of precision,
but only for floating point numbers.

Rows that are within epsilon are not considered different 
for purposes of the exit code.

=item B<--exit>

Exit with a status of 1 if some differences were found.
(By default, the exit status is 0 with or without differences
if the file is processed successfully.)

=item B<-N> on B<--new-name>

Specify the name of the C<diff> column, if any.
(Default is C<diff>.)

=item B<-q> or B<--quiet>

Be quiet, suppressing output for identical rows.
(This behavior is different from Unix L<diff(1)> 
where C<-q> suppresses I<all> output.)
If repeated, omits epsilon-equivalent rows.

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

    #fsdb event clock absdiff pctdiff
    _null_getpage+128	815812813.281756	0	0
    _null_getpage+128	815812813.328709	0.046953	5.7554e-09
    _null_getpage+128	815812813.353830	0.025121	3.0793e-09
    _null_getpage+128	815812813.357169	0.0033391	4.0929e-10

And in the file F<TEST/dbfilediff_ex.in-2>:

    #fsdb event clock absdiff pctdiff
    _null_getpage+128	815812813.281756	0	0
    _null_getpage+128	815812813.328709	0.046953	5.7554e-09
    _null_getpage+128	815812813.353830	0.025121	3.0793e-09
    _null_getpage+128	815812813.357169	0.003339	4.0929e-10


=head2 Command:

    cat TEST/dbfilediff_ex.in | dbfilediff -i - -i TEST/dbfilediff_ex.in-2

=head2 Output:

    #fsdb event clock absdiff pctdiff diff
    _null_getpage+128	815812813.281756	0	0	=
    _null_getpage+128	815812813.328709	0.046953	5.7554e-09	=
    _null_getpage+128	815812813.353830	0.025121	3.0793e-09	=
    _null_getpage+128	815812813.357169	0.0033391	4.0929e-10	-
    _null_getpage+128	815812813.357169	0.003339	4.0929e-10	+
    #   | dbfilediff --input TEST/dbfilediff_ex.in-2

By comparision, if one adds the C<-s> option, then all rows will pass as equal.

=head1 SEE ALSO

L<Fsdb>.
L<dbrowuniq>.
L<dbfilediff>.

L<dbrowdiff>, L<dbrowuniq>, and L<dbfilediff> are similar but different.
L<dbrowdiff> computes row-by-row differences for a column,
L<dbrowuniq> eliminates rows that have no differences,
and L<dbfilediff> compares fields of two files.



=head1 CLASS FUNCTIONS

=cut

@ISA = qw(Fsdb::Filter);
($VERSION) = 2.0;

use strict;
use Carp qw(croak);
use Pod::Usage;
# use Regexp::Common;

use Fsdb::Filter;
use Fsdb::IO::Reader;
use Fsdb::IO::Writer;


=head2 new

    $filter = new Fsdb::Filter::dbfilediff(@arguments);

Create a new dbfilediff object, taking command-line arguments.

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
    $self->{_info}{input_count} = 2;
    $self->{_epsilon_numerics} = undef;
    $self->{_exit_one_if_diff} = undef;
    $self->{_destination_column} = 'diff';
    $self->{_quiet} = 0;
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
	'a|all!' => sub { $self->{_join_type} = 'outer'; },
	'autorun!' => \$self->{_autorun},
	'close!' => \$self->{_close},
	'd|debug+' => \$self->{_debug},
	'E|epsilon!' => \$self->{_epsilon_numerics},
	'exit!' => \$self->{_exit_one_if_diff},
	'i|input=s@' => sub { $self->parse_io_option('inputs', @_); },
	'log!' => \$self->{_logprog},
	'N|new-name=s' => \$self->{_destination_column},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	'q|quiet+' => \$self->{_quiet},
	) or pod2usage(2);
    croak $self->{_prog} . ": internal error, extra arguments.\n"
	if ($#argv != -1);
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup ($) {
    my($self) = @_;

    $self->setup_exactly_two_inputs;
    $self->finish_io_option('inputs', -comment_handler => undef);
    $self->finish_io_option('output', -clone => $self->{_ins}[0], -outputheader => 'delay');
    $self->{_out}->col_create($self->{_destination_column})
	    or croak $self->{_prog} . ": cannot create column " . $self->{_destination_column} . " (maybe it already existed?)\n";


    croak $self->{_prog} . ": input streams have different schemas; cannot merge\n"
	if ($self->{_ins}[0]->compare($self->{_ins}[1]) ne 'identical');
}

=head2 _find_epsilon

    ($value, $epsilon, $sig_figs) = _find_epsilon($fp)

Return a numeric VALUE and an EPSILON that reflects its significant figures
with possible rounding error.

=cut
sub _find_epsilon {
    my($v) = @_;

    # use Regexp::Common;
    # # (now in-lined since it's unlikely floating point numbers will change)
    # my $real_regexp = $RE{num}{real}{-keep};
    # $v =~ /$real_regexp/;
    $v =~ /((?i)([+-]?)((?=[.]?[0123456789])([0123456789]*)(?:([.])([0123456789]{0,}))?)(?:([E])(([+-]?)([0123456789]+))|))/;
    my($match, $significand) = ($1, $3);  # these are STRINGS
    return undef if (!defined($match));  # non-numeric
    #
    # Need to convert significand to epsilon.
    #
    # first, find significant digits in the string (non-trivial)
    # then, adjust that by the exponent.
    #
    # For test cases, see TEST/find_epsilon.t.
    #
    my($figs) = $significand;
    $figs =~ s/\.//;
    $figs =~ s/^0*//g;   # longest match
    $figs = '0' if ($figs eq '');
    my($sig_figs) = length($figs);

    my($reformat) = sprintf("%e", $v);
    my($log10) = ($reformat =~ /e([-+]\d+)$/);
    $log10 += 1;   # force numeric and account for the digit before the decimal

    my($epsilon) = 10**($log10 - $sig_figs);

    return($v, $epsilon, $sig_figs, $log10);
}

=head2 run

    $filter->run();

Internal: run over each row.

=cut
sub run ($) {
    my($self) = @_;

    my @fastpath_subs;
    foreach (0..1) {
	$fastpath_subs[$_] = $self->{_ins}[$_]->fastpath_sub();
    };
    my $out_fastpath_sub = $self->{_out}->fastpath_sub();

    my $epsilon_numerics = $self->{_epsilon_numerics};

    my $difference_count = 0;
    my($f0, $f1);
    # prime the pump
    $f0 = &{$fastpath_subs[0]}();
    $f1 = &{$fastpath_subs[1]}();	
    for (;;) {
	last if (!defined($f0) && !defined($f1));
	if (!defined($f0)) {
	    # 0 is done, but 1 lives on: drain it
	    $difference_count++;
	    push(@$f1, "+");
	    &$out_fastpath_sub($f1);
	    $f1 = &{$fastpath_subs[1]}();
	    next;
	};
	if (!defined($f1)) {
	    # vice versa
	    $difference_count++;
	    push(@$f0, "-");
	    &$out_fastpath_sub($f0);
	    $f0 = &{$fastpath_subs[0]}();
	    next;
	};
	# diff them
	my $eq = 1;
	foreach (0..$#{$f0}) {
	    if ($f0->[$_] ne $f1->[$_]) {
		if ($epsilon_numerics && $f0->[$_] =~ /\./) {
		    my($g0, $epsilon) = _find_epsilon($f0->[$_]);
		    my($g1) = _find_epsilon($f1->[$_]);
		    if (!defined($g0) || !defined($g1)) {
			$eq = undef;
			last;
			# non-numeric compare
		    };
		    # 
		    # epsilon handles the print-level differences,
		    # BUT we still get floating point representation
		    # problems.  For example, 7.22 vs 7.23
		    # has a difference of 0.0100000000000007,
		    # but an epsilon of 0.01
		    # (because computers work in binary).
		    #
		    # Fix: increase epsilon by
		    # its own "epsilon" of 1e-6 :-)
		    # (because single precision IEEE floating 
		    # point has about 7 digits of precision).
		    #
		    $epsilon *= 1.000001;
		    if (abs($g0 - $g1) > $epsilon) {
			$eq = undef;
			last;
			# sloppy numeric compare fails;
			# non-numeric compare
		    };
		    $eq = 'epsilon';
		    # sloppy numeric compare succeeds; keep going
		} else {
		    $eq = undef;
		    last;
		};
	    };
	};
	if (defined($eq)) {
	    if ($eq eq 'epsilon') {
	        push(@$f1, "~");
		&$out_fastpath_sub($f1) if ($self->{_quiet} <= 1);
	    } else {
	        push(@$f1, "=");
		&$out_fastpath_sub($f1) if ($self->{_quiet} == 0);
	    };
	} else {
	    $difference_count++;
	    push(@$f0, "-");
	    &$out_fastpath_sub($f0);
	    push(@$f1, "+");
	    &$out_fastpath_sub($f1);
	};
	# continue
	$f0 = &{$fastpath_subs[0]}();
	$f1 = &{$fastpath_subs[1]}();	
    };
    if ($self->{_exit_one_if_diff} && $difference_count > 0) {
	# unusual for Fsdb.
	exit(1);
    };
}


=head1 AUTHOR and COPYRIGHT

Copyright (C) 2012-2015 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
