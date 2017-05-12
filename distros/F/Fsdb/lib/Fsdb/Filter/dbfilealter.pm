#!/usr/bin/perl -w

#
# dbfilealter.pm
# Copyright (C) 2008-2015 by John Heidemann <johnh@isi.edu>
# $Id: 452833c6982aef27189f6f944be088d26f6413e2 $
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbfilealter;

=head1 NAME

dbfilealter - alter the format of an Fsdb file, changing the row/column separator

=head1 SYNOPSIS

dbfilealter [-c] [-F fs] [-R rs] [-Z compression] [column...]

=head1 DESCRIPTION

This program reformats a Fsdb file,
altering the row (C<-R rs>) or column (C<-F fs>) separator.
It verifies that this action does not violate the
file constraints (for example, if spaces appear in data and 
the new format has space as a separator),
and optionally corrects things.

With C<-Z compression> it controls compression on the file

=head1 OPTIONS

=over 4

=item B<-F> or B<--fs> or B<--fieldseparator> S

Specify the field (column) separator as C<S>.
See below for valid field separators.

=item B<-R> or B<--rs> or B<--rowseparator> S

Specify the row separator as C<S>.
See below for valid row separators.

=item B<-Z> or B<--compression> S

Specify file compression as given by file extension C<S>.
Supported compressions are F<gz> for gzip,
F<bz2> for bzip2,
F<xz> for xz,
or "none" or undef to disable compression.
Default is none.

=item B<-c> or B<--correct>

Correct any inconsistency caused by the new separators,
if possible.

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

=head2 Valid Field Separators


=over 4

=item B<D>
default: any amount of whitespace on input, tabs on output.

=item B<s>
single space (exactly one space for input and output).

=item B<S>
double space on output; two or more spaces on input.

=item B<t>
single tab character (exactly one tab for input and output).

=item B<XN>
take I<N> as one or more hex digits that specify a unicode character.
Accept one or more of those characters on input,
output exactly one of those characters.

=item B<CA>
take I<A> as a one (unicode) literal character.
Accept one or more of those characters on input, 
output exactly one of those characters.

=back

Potentially in the future C<xN> and C<cA> will support
single-character-on-input equivalents of C<XN> and <CA>.

=head2 Valid Row Seperators

Three row separators are allowed:

=over 4

=item B<D>
the default, one line per row

=item B<C>
complete rowized. 
Each line is a field-labeled and its value,
and a blank line separates "rows".
All fields present in the output.

=item B<I>
incompletely rowized.
Like C<C>, but 
null fields are omitted from the output.

=back


=head1 SAMPLE USAGE

=head2 Input:

    #fsdb name id test1
    a 1 80
    b 2 70
    c 3 65

=head2 Command:

    cat data.fsdb | dbfilealter -F S

=head2 Output:

    #fsdb -F S name id test1
    a  1  80
    b  2  70
    c  3  65
    #  | dbfilealter -F S

=head2 Command 2:

    cat data.fsdb | dbfilealter -R C

=head2 Output:

    #fsdb -R C name id test1
    name: a
    id: 1
    test1: 80
    
    name: b
    id: 2
    test1: 70
    
    name: c
    id: 3
    test1: 65
    
    #   | dbfilealter -R C

=head2 Correction mode input:

    #fsdb -F S name id test1
    a student  1  80
    b nice  2  70
    c all  3  65

=head2 Correction mode command:

    cat correction.fsdb | dbfilealter -c -F D

=head2 Correction mode output:

    #fsdb name id test1
    a_student	1	80
    b_nice	2	70
    c_all	3	65
    #   | dbfilealter -c -F D

=head1 SEE ALSO

L<Fsdb>,
L<dbcoldefine>.


=head1 CLASS FUNCTIONS

=cut

@ISA = qw(Fsdb::Filter);
($VERSION) = 2.0;

use strict;
use Pod::Usage;
use Carp;

use Fsdb::Filter;
use Fsdb::IO::Writer;


=head2 new

    $filter = new Fsdb::Filter::dbfilealter(@arguments);

Create a new dbfilealter object, taking command-line arguments.

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
    $self->{_fscode} = undef;
    $self->{_rscode} = undef;
    $self->{_compression} = undef;
    $self->{_correct} = undef;
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
	'c|correct!' => \$self->{_correct},
	'd|debug+' => \$self->{_debug},
	'F|fs|cs|fieldseparator|columnseparator=s' => \$self->{_fscode},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'log!' => \$self->{_logprog},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	'R|rs|rowseparator=s' => \$self->{_rscode},
	'Z|compression=s' => \$self->{_compression},
	) or pod2usage(2);
    push (@{$self->{_cols}}, @argv);
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup ($) {
    my($self) = @_;

    $self->finish_io_option('input', -comment_handler => $self->create_pass_comments_sub);

    # all the hard work is on the next line where we force the right codes
    my @out_args = ();
    push (@out_args, -fscode => $self->{_fscode})
	if (defined($self->{_fscode}));
    push (@out_args, -rscode => $self->{_rscode})
	if (defined($self->{_rscode}));
    push (@out_args, -compression => $self->{_compression})
	if (defined($self->{_compression}));
    $self->finish_io_option('output', -clone => $self->{_in}, @out_args);
}

=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run ($) {
    my($self) = @_;
    # can't get any easier than this
    my $read_fastpath_sub = $self->{_in}->fastpath_sub();
    my $out = $self->{_out};
    my $write_fastpath_sub = $self->{_out}->fastpath_sub();
    my $loop_sub;
    my $loop_sub_code =  q'
	    $loop_sub = sub {
		my $fref;
		while ($fref = &$read_fastpath_sub()) {
		    ' .
		    ($self->{_correct} ? '$out->correct_fref_containing_fs($fref);' : '') .
		    '
		    &$write_fastpath_sub($fref);
		};
	    }';
    eval $loop_sub_code;
    $@ && die $self->{_prog} . ":  internal eval error: $@.\n";

    &$loop_sub();
}

=head1 AUTHOR and COPYRIGHT

Copyright (C) 2008-2015 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
