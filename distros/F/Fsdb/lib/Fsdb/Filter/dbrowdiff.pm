#!/usr/bin/perl

#
# dbrowdiff.pm
# Copyright (C) 1991-2018 by John Heidemann <johnh@isi.edu>
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbrowdiff;

=head1 NAME

dbrowdiff - compute row-by-row differences of some column

=head1 SYNOPSIS

dbrowdiff [-B|-I] column

=head1 DESCRIPTION

For a given column, compute the differences between each row
of the table.  Differences are output to two new columns,
C<absdiff> and C<pctdiff>.

Differences are either relative to the previous column 
(I<incremental> mode), or relative to the first row
(I<baseline> mode), the default.

=head1 OPTIONS

=over 4

=item B<-B> or B<--baseline>

Select baseline mode (the default), where differences are relative to the first row.

=item B<-I> or B<--incremental>

Select incremental mode, where differences are relative to the previous row.

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

    #fsdb      event   clock
    _null_getpage+128       815812813.281756
    _null_getpage+128       815812813.328709
    _null_getpage+128       815812813.353830
    _null_getpage+128       815812813.357169
    _null_getpage+128       815812813.375844
    _null_getpage+128       815812813.378358
    #  | /home/johnh/BIN/DB/dbrow 
    #  | /home/johnh/BIN/DB/dbcol event clock

=head2 Command:

    cat DATA/kitrace.fsdb | dbrowdiff clock

=head2 Output:

    #fsdb      event   clock   absdiff pctdiff
    _null_getpage+128       815812813.281756        0       0
    _null_getpage+128       815812813.328709        0.046953        5.7554e-09
    _null_getpage+128       815812813.353830        0.072074        8.8346e-09
    _null_getpage+128       815812813.357169        0.075413        9.2439e-09
    _null_getpage+128       815812813.375844        0.094088        1.1533e-08
    _null_getpage+128       815812813.378358        0.096602        1.1841e-08
    #  | /home/johnh/BIN/DB/dbrow 
    #  | /home/johnh/BIN/DB/dbcol event clock
    #  | dbrowdiff clock


=head1 SEE ALSO

L<Fsdb>.
L<dbcolmovingstats>.
L<dbrowuniq>.
L<dbfilediff>.

L<dbrowdiff>, L<dbrowuniq>, and L<dbfilediff> are similar but different.
L<dbrowdiff> computes row-by-row differences for a column,
L<dbrowuniq> eliminates rows that have no differences,
and L<dbfilediff> compares fields of two files.


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

    $filter = new Fsdb::Filter::dbrowdiff(@arguments);

Create a new dbrowdiff object, taking command-line arguments.

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
    $self->{_mode} = 'B';
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
	'B|baseline' => sub { $self->{_mode} = 'B'; },
	'close!' => \$self->{_close},
	'd|debug+' => \$self->{_debug},
	'f|format=s' => \$self->{_format},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'I|incremental' => sub { $self->{_mode} = 'I'; },
	'log!' => \$self->{_logprog},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
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

    $self->finish_io_option('input', -comment_handler => $self->create_pass_comments_sub);

    $self->{_target_coli} = $self->{_in}->col_to_i($self->{_target_column});
    croak($self->{_prog} . ": target column " . $self->{_target_column} . " is not in input stream.\n")
	if (!defined($self->{_target_coli}));

    $self->finish_io_option('output', -clone => $self->{_in}, -outputheader => 'delay');
    foreach (qw(absdiff pctdiff)) {
	$self->{_out}->col_create($_)
	    or croak($self->{_prog} . ": cannot create column $_ (maybe it already existed?)\n");
    };
}

=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run ($) {
    my($self) = @_;

    my $read_fastpath_sub = $self->{_in}->fastpath_sub();
    my $write_fastpath_sub = $self->{_out}->fastpath_sub();

    my $target_coli = $self->{_target_coli};
    my $absdiff_coli = $self->{_out}->col_to_i('absdiff');
    my $pctdiff_coli = $self->{_out}->col_to_i('pctdiff');
    my $format = $self->{_format};
    my $incremental_mode = ($self->{_mode} eq 'I');

    my $base;
    my $absdiff;
    my $pctdiff;
    my $fref;

    while ($fref = &$read_fastpath_sub()) {
	if (!defined($base)) {
	    $absdiff = $pctdiff = 0.0;
	    $base = $fref->[$target_coli];
	} else {
	    $absdiff = $fref->[$target_coli] - $base;
	    $pctdiff = ($absdiff / $base) * 100.0 if ($base != 0);
	};
	$fref->[$absdiff_coli] = sprintf("$format", $absdiff);
	if ($base == 0) {
	    $fref->[$pctdiff_coli] = $self->{_empty};
	} else {
	    $fref->[$pctdiff_coli] = sprintf("$format", $pctdiff);
	};
	$base = $fref->[$target_coli] if ($incremental_mode);
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
