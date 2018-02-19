#!/usr/bin/perl -w

#
# dbmerge2.pm
# Copyright (C) 1991-2018 by John Heidemann <johnh@isi.edu>
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbmerge2;

=head1 NAME

dbmerge2 - merge exactly two inputs in sorted order based on the the specified columns

=head1 SYNOPSIS

    dbmerge2 --input A.fsdb --input B.fsdb [-T TemporaryDirectory] [-nNrR] column [column...]

or
    cat A.fsdb | dbmerge2 --input B.fsdb [-T TemporaryDirectory] [-nNrR] column [column...]

=head1 DESCRIPTION

Merge exactly two sorted input files, producing one sorted result.
Inputs can both be specified with C<--input>, or one can come
from standard input and the other from C<--input>.

Inputs must have identical schemas (columns, column order,
and field separators).

Dbmerge2 consumes a fixed amount of memory regardless of input size.

Although described above as a command line too, the command line
version of dbmerge2 is not installed by default.
Dbmerge2 is used primarily internal to perl;
L<dbmerge(1)> is the command-line tool for user use.

Warning: we do not verify that each input is actually sorted.
In correct merge results will occur if they are not.

=head1 OPTIONS

General option:

=over 4

=item B<--saveoutput $OUT_REF>

Save output writer (for integration with other fsdb filters).

=item <-T TmpDir>

where to put tmp files.
Also uses environment variable TMPDIR, if -T is 
not specified.
Default is /tmp.

=back

Sort specification options (can be interspersed with column names):

=over 4

=item B<-r> or B<--descending>

sort in reverse order (high to low)

=item B<-R> or B<--ascending>

sort in normal order (low to high)

=item B<-n> or B<--numeric>

sort numerically

=item B<-N> or B<--lexical>

sort lexicographically

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

File F<a.fsdb>:

    #fsdb cid cname
    11 numanal
    10 pascal

File F<b.fsdb>:

    #fsdb cid cname
    12 os
    13 statistics

=head2 Command:

    dbmerge2 --input a.fsdb --input b.fsdb cname

or

    cat a.fsdb | dbmerge2 --input b.fsdb cname

=head2 Output:

    #fsdb      cid     cname
    11 numanal
    12 os
    10 pascal
    13 statistics
    #  | dbmerge2 --input a.fsdb --input b.fsdb cname

=head1 SEE ALSO

L<dbmerge(1)>,
L<dbsort(1)>,
L<Fsdb(3)>

=head1 CLASS FUNCTIONS

=cut


@ISA = qw(Fsdb::Filter);
($VERSION) = 2.0;

use strict;
use Pod::Usage;
use Carp qw(croak);

use Fsdb::Filter;
use Fsdb::IO::Reader;
use Fsdb::IO::Writer;

=head2 new

    $filter = new Fsdb::Filter::dbmerge2(@arguments);

Create a new object, taking command-line arguments.

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
    my $self = shift @_;
    $self->SUPER::set_defaults();
    $self->{_info}{input_count} = 2;
    $self->{_sort_argv} = [];
    $self->{_tmpdir} = defined($ENV{'TMPDIR'}) ? $ENV{'TMPDIR'} : "/tmp";
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
	'autorun!' => \$self->{_autorun},
	'close!' => \$self->{_close},
	'd|debug+' => \$self->{_debug},
	'i|input=s@' => sub { $self->parse_io_option('inputs', @_); },
	'log!' => \$self->{_logprog},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	'saveoutput=s' => \$self->{_save_output},
	'T|tmpdir|tempdir=s' => \$self->{_tmpdir},
	# sort key options:
	'n|numeric' => sub { $self->parse_sort_option(@_); },
	'N|lexical' => sub { $self->parse_sort_option(@_); },
	'r|descending' => sub { $self->parse_sort_option(@_); },
	'R|ascending' => sub { $self->parse_sort_option(@_); },
	'<>' => sub { $self->parse_sort_option('<>', @_); },
	) or pod2usage(2);
}


=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup ($) {
    my($self) = @_;

    croak($self->{_prog} . ": no sorting key specified.\n")
	if ($#{$self->{_sort_argv}} == -1);

    #
    # setup final IO
    #
    $self->setup_exactly_two_inputs;
    $self->finish_io_option('inputs', -comment_handler => $self->create_pass_comments_sub);
    $self->finish_io_option('output', -clone => $self->{_ins}[0]);

    croak($self->{_prog} . ": input streams have different schemas; cannot merge\n")
	if ($self->{_ins}[0]->compare($self->{_ins}[1]) ne 'identical');

    $self->{_compare_code} = $self->create_compare_code(@{$self->{_ins}});;
    croak($self->{_prog} . ": no merge field specified.\n")
	if (!defined($self->{_compare_code}));
    print "COMPARE CODE:\n\t" . $self->{_compare_code} . "\n" if ($self->{_debug} && $self->{_debug} > 1);
}


=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run ($) {
    my($self) = @_;

    # Override the usual package globals for $a, $b (!),
    # then eval compare_sub in this lexical context.
    # We're Having Fun Now.
    my($a, $b);
    my $compare_sub;
    eval '$compare_sub = ' . $self->{_compare_code};
    $@ && croak($self->{_prog} . ":  internal eval error in compare code: $@.\n");
    my @fastpath_subs;
    foreach (0..1) {
	$fastpath_subs[$_] = $self->{_ins}[$_]->fastpath_sub();
    };
    my $out_fastpath_sub = $self->{_out}->fastpath_sub();

    # prime the pump
    $a = &{$fastpath_subs[0]}();
    $b = &{$fastpath_subs[1]}();
    for (;;) {
	last if (!defined($a) || !defined($b));  # eof on one
	my $cmp = &{$compare_sub}();   # compare $a vs $b
	if ($cmp <= 0) {
	    &{$out_fastpath_sub}($a);
	    $a = &{$fastpath_subs[0]}();
	} else {
	    &{$out_fastpath_sub}($b);
	    $b = &{$fastpath_subs[1]}();
	};
    };
    # one should be done
    croak("assert") if (defined($a) && defined($b));   # assert
    # drain the one that's still full
    while (defined($a)) {
	&{$out_fastpath_sub}($a);
	$a = &{$fastpath_subs[0]}();
    };
    while (defined($b)) {
	&{$out_fastpath_sub}($b);
	$b = &{$fastpath_subs[1]}();
    };
    # print "# dbmerge2: both inputs done\n" if ($self->{_debug});
    foreach (0..1) {
	$self->{_ins}[$_]->close;
    };
};
    

=head1 AUTHOR and COPYRIGHT

Copyright (C) 1991-2018 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
