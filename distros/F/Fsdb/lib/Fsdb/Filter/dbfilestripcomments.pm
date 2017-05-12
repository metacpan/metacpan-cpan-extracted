#!/usr/bin/perl

#
# dbfilestripcomments.pm
# Copyright (C) 1991-2008 by John Heidemann <johnh@isi.edu>
# $Id: 56971acf3abd4c1f7583a5113206c08a3a920f81 $
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#


package Fsdb::Filter::dbfilestripcomments;

=head1 NAME

dbfilestripcomments - remove comments from a fsdb file

=head1 SYNOPSIS

dbfilestripcomments [-h]

=head1 DESCRIPTION

Remove any comments in a file, including the header.  This makes the
file unreadable by other Fsdb utilities, but perhaps more readable by
humans.

With the -h option, leave the header.

=head1 OPTIONS

=over 4

=item B<-h> or B<--header>

Retain the header.

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

    #fsdb -R C      experiment      mean    stddev  pct_rsd conf_range      conf_low       conf_high        conf_pct        sum     sum_squared     min     max     n
    experiment:  ufs_mab_sys
    mean:        37.25
    stddev:      0.070711
    pct_rsd:     0.18983
    conf_range:  0.6353
    conf_low:    36.615
    conf_high:   37.885
    conf_pct:    0.95
    sum:         74.5
    sum_squared: 2775.1
    min:         37.2
    max:         37.3
    n:           2
    
    #  | /home/johnh/BIN/DB/dbmultistats experiment duration
    #  | /home/johnh/BIN/DB/dblistize 

=head2 Command:

    cat data.fsdb | dbfilestripcomments

=head2 Output:

    experiment:  ufs_mab_sys
    mean:        37.25
    stddev:      0.070711
    pct_rsd:     0.18983
    conf_range:  0.6353
    conf_low:    36.615
    conf_high:   37.885
    conf_pct:    0.95
    sum:         74.5
    sum_squared: 2775.1
    min:         37.2
    max:         37.3
    n:           2

=head1 SEE ALSO

L<Fsdb>.
L<dbcoldefine>.


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


=head2 new

    $filter = new Fsdb::Filter::dbfilestripcomments(@arguments);

Create a new dbfilestripcomments object, taking command-line arguments.

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
    $self->{_keep_header} = undef;
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
	'h|header!' => \$self->{_keep_header},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'log!' => \$self->{_logprog},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
 ) or pod2usage(2);
    push (@{$self->{_argv}}, @argv);
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup ($) {
    my($self) = @_;

    $self->finish_io_option('input');

    $self->finish_io_option('output', -clone => $self->{_in}, -outputheader => ($self->{_keep_header} ? 'now' : 'never'));
}

=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run ($) {
    my($self) = @_;

    my $read_fastpath_sub = $self->{_in}->fastpath_sub();
    my $write_fastpath_sub = $self->{_out}->fastpath_sub();
    my $fref;

    while ($fref = &$read_fastpath_sub()) {
	&$write_fastpath_sub($fref);
    };
}



=head2 finish

    $filter->finish();

Internal: write trailer.
Or in our case, don't.

=cut
sub finish ($) {
    my($self) = @_;
    # do nothing instead of calling parent
    # $self->SUPER::finish();
}

=head1 AUTHOR and COPYRIGHT

Copyright (C) 1991-2008 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
