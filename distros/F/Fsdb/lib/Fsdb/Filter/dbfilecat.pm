#!/usr/bin/perl -w

#
# dbfilecat.pm
# Copyright (C) 2013-2018 by John Heidemann <johnh@isi.edu>
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbfilecat;

=head1 NAME

dbfilecat - concatenate two files with identical schema

=head1 SYNOPSIS

    dbfilecat --input A.fsdb [--input B.fsdb...]

or

    echo A.fsdb | dbfilecat --xargs


=head1 DESCRIPTION

Concatenate all provided input files,
producing one result.
We remove extra header lines.

Inputs can both be specified with C<--input>, or one can come
from standard input and the other from C<--input>.
With C<--xargs>, each line of standard input is a filename for input.

Inputs must have identical schemas (columns, column order,
and field separators).

Like L<dbmerge>, but no worries about sorting,
and with no arguments we read standard input
(although that's not very useful).


=head1 OPTIONS

General option:

=over 4

=item B<--xargs>

Expect that input filenames are given, one-per-line, on standard input.
(In this case, merging can start incrementally.

=item B<--removeinputs>

Delete the source files after they have been consumed.
(Defaults off, leaving the inputs in place.)

=for comment
begin_standard_fsdb_options

This module also supports the standard fsdb options:

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

    dbfilecat --input a.fsdb --input b.fsdb


=head2 Output:

    #fsdb      cid     cname
    11 numanal
    10 pascal
    12 os
    13 statistics
    #  | dbmerge --input a.fsdb --input b.fsdb

=head1 SEE ALSO

L<dbmerge(1)>,
L<Fsdb(3)>

=head1 CLASS FUNCTIONS

=cut


@ISA = qw(Fsdb::Filter);
($VERSION) = 2.0;

use 5.010;
use strict;
use Pod::Usage;
use Carp qw(croak carp);

use Fsdb::Filter;
use Fsdb::IO::Reader;
use Fsdb::IO::Writer;


=head2 new

    $filter = new Fsdb::Filter::dbmerge(@arguments);

Create a new object, taking command-line arguments.

=cut

sub new($@) {
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

sub set_defaults($) {
    my $self = shift @_;
    $self->SUPER::set_defaults();
    $self->{_remove_inputs} = undef;
    $self->{_xargs} = undef;
}

=head2 parse_options

    $filter->parse_options(@ARGV);

Internal: parse command-line arguments.

=cut

sub parse_options($@) {
    my $self = shift @_;

    my(@argv) = @_;
    my $past_sort_options = undef;
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
	'removeinputs!' => \$self->{_remove_inputs},
	'xargs!' => \$self->{_xargs},
	) or pod2usage(2);
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup($) {
    my($self) = @_;

    if ($#{$self->{_inputs}} == -1) {
	# default to stdin
	push(@{$self->{_inputs}}, '-');
    };
    if ($self->{_xargs} && $#{$self->{_inputs}} > 0) {
	croak($self->{_prog} . ": --xargs and multiple inputs (perhaps you meant NOT --xargs?).\n");
    };
    if (!$self->{_xargs} && $self->{_remove_inputs}) {
	croak($self->{_prog} . ": --remove_inputs only works with --xargs.\n");
    };

    if ($self->{_xargs}) {
	croak($self->{_prog} . ": --xargs and internal error, no input.\n")
	    if ($#{$self->{_inputs}} != 0);
	# have to delay comments in next line because otherwise _out is not yet open
        $self->finish_io_option('inputs', -header => '#fsdb filename', -comment_handler => $self->create_delay_comments_sub);
	croak($self->{_prog} . ": xargs setup input stream failed " . $self->{_ins}[0]->error() . "\n")
	    if ($self->{_ins}[0]->error());
    } else {
	$self->finish_io_option('inputs', -comment_handler => $self->create_pass_comments_sub);
	foreach (@{$self->{_ins}}) {
	    croak($self->{_prog} . ": input streams have different schemas; cannot concatenate\n")
		if ($self->{_ins}[0]->compare($_) ne 'identical');
	};
	$self->finish_io_option('output', -clone => $self->{_ins}[0]);
    };
}

=head2 _run_one

    $filter->_run_one();

Internal: stream out one input stream.

=cut
sub _run_one($) {
    my($self, $in) = @_;
    my $read_fastpath_sub = $in->fastpath_sub();
    my $write_fastpath_sub = $self->{_out}->fastpath_sub();
    my $fref;
    print STDERR "# dbfilecat: _run_one start\n" if ($self->{_debug});
    while ($fref = &$read_fastpath_sub()) {
	&$write_fastpath_sub($fref);
    };
    print STDERR "# dbfilecat: _run_one end\n" if ($self->{_debug});
}

=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run($) {
    my($self) = @_;

    if ($self->{_xargs}) {
	my $inputs = 0;
        my $read_fastpath_sub = $self->{_ins}[0]->fastpath_sub();
	while (my $fref = &$read_fastpath_sub()) {
	    $inputs++;
	    print STDERR "# dbfilecat: xargs got $fref->[0]\n" if ($self->{_debug});
	    my $this_in = new Fsdb::IO::Reader(-file => $fref->[0], -comment_handler => $self->create_tolerant_pass_comments_sub());
	    if (!$self->{_out}) {
	    	$self->finish_io_option('output', -clone => $this_in);
	    } else {
		croak($self->{_prog} . ": input streams have different schemas; cannot concatenate\n")
		    if ($self->{_out}->compare($this_in) ne 'identical');
	    };
	    $self->_run_one($this_in);
	    if ($self->{_remove_inputs}) {
		unlink($fref->[0]) or
		    carp $self->{_prog} . ": --remove-inputs, but cannot remove " . $fref->[0] . "\n";
	    };
	};
	croak($self->{_prog} . ": no input with --xargs\n")
	    if ($inputs == 0);
    } else {
	foreach my $in (@{$self->{_ins}}) {
	    $self->_run_one($in);
	};
	print STDERR "# dbfilecat: _ins end\n" if ($self->{_debug});
    };
};



=head1 AUTHOR and COPYRIGHT

Copyright (C) 2013-2018 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
