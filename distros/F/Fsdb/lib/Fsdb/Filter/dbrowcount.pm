#!/usr/bin/perl -w

#
# dbrowcount.pm
# Copyright (C) 2007-2015 by John Heidemann <johnh@isi.edu>
# $Id: 83fba9f283f462ac2039ab283fe5e131f7390a09 $
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbrowcount;

=head1 NAME

dbrowcount - count the number of rows in an Fsdb stream

=head1 SYNOPSIS

dbrowcount

=head1 DESCRIPTION

Count the number of rows and write out a new fsdb file
with one column (n) and one value: the number of rows.
This program is a strict subset of L<dbcolstats>.

Although there are other ways to get a count of rows
(C<dbcolstats>, or C<dbrowaccumulate -C 1> and some processing),
counting is so common it warrants its own command.
(For example, consider how often C<wc -l> is used in regular shell
scripting.)
There are some gross and subtle differences, though, in that
C<dbrowcount> doesn't require one to specify a column to search,
and it also doesn't look for and skip null data items.

=head1 OPTIONS

No program-specific options.

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

    #fsdb      absdiff
    0
    0.046953
    0.072074
    0.075413
    0.094088
    0.096602
    #  | /home/johnh/BIN/DB/dbrow 
    #  | /home/johnh/BIN/DB/dbcol event clock
    #  | dbrowdiff clock
    #  | /home/johnh/BIN/DB/dbcol absdiff

=head2 Command:

    cat data.fsdb | dbrowcount

=head2 Output:

    #fsdb n
    6
    #  | /home/johnh/BIN/DB/dbrow 
    #  | /home/johnh/BIN/DB/dbcol event clock
    #  | dbrowdiff clock
    #  | /home/johnh/BIN/DB/dbcol absdiff

=head2 Input 2:

As another example, this input produces the same output as above in
C<dbrowcount>, but different output in C<dbstats>:

    #fsdb      absdiff
    -
    -
    -
    -
    -
    -
    #  | /home/johnh/BIN/DB/dbrow 
    #  | /home/johnh/BIN/DB/dbcol event clock
    #  | dbrowdiff clock
    #  | /home/johnh/BIN/DB/dbcol absdiff


=head1 SEE ALSO

L<dbcolaccumulate(1)>,
L<dbcolstats(1)>,
L<Fsdb(3)>

=head1 CLASS FUNCTIONS

=cut

@ISA = qw(Fsdb::Filter);
($VERSION) = 2.0;

use strict;
use Pod::Usage;

use Fsdb::Filter;
use Fsdb::IO::Reader;
use Fsdb::IO::Writer;


=head2 new

    $filter = new Fsdb::Filter::dbrowcount(@arguments);

=cut

sub new {
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
}

=head2 parse_options

    $filter->parse_options(@ARGV);

Internal: parse options

=cut

sub parse_options ($@) {
    my $self = shift @_;

    $self->get_options(
	\@_,
 	'help|?' => sub { pod2usage(1); },
	'man' => sub { pod2usage(-verbose => 2); },
	'autorun!' => \$self->{_autorun},
	'close!' => \$self->{_close},
	'F|fs|cs|fieldseparator|columnseparator=s' => \$self->{_fscode},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'log!' => \$self->{_logprog},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	) or pod2usage(2);
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup ($) {
    my($self) = @_;

    $self->finish_io_option('input', -comment_handler => $self->create_delay_comments_sub);
    my @output_options = (-cols => [qw(n)]);
    unshift (@output_options, -fscode => $self->{_fscode})
	if (defined($self->{_fscode}));
    $self->finish_io_option('output', @output_options);
}

=head2 run

    $filter->run();

Internal: run over all IO

=cut
sub run ($) {
    my($self) = @_;

    my $read_fastpath_sub = $self->{_in}->fastpath_sub();

    my $n = 0;
    my $fref;
    while ($fref = &$read_fastpath_sub()) {
	$n++;
    };
    $self->{_out}->write_row_from_aref( [ $n ] );
}

=head2 finish

    $filter->finish();

Internal: write trailer.

=cut
#sub finish ($) {
#    my($self) = @_;
#
#    $self->SUPER::finish();
#}

=head1 AUTHOR and COPYRIGHT

Copyright (C) 2007-2015 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;

