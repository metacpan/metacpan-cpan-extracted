#!/usr/bin/perl

#
# tabdelim_to_db.pm
# Copyright (C) 2005-2007 by John Heidemann <johnh@isi.edu>
# $Id: 1a976a31ff4f2b1a666224af678a0ad4ca3e47c4 $
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblib for details.
#

package Fsdb::Filter::tabdelim_to_db;

=head1 NAME

tabdelim_to_db - convert tab-delimited data into fsdb

=head1 SYNOPSIS

    tabdelim_to_db <source.tabdelim >target.fsdb

=head1 DESCRIPTION

Converts a tab-delimited data stream to Fsdb format.

The input is tab-delimited (I<not> fsdb):
the first row is taken to be the names of the columns;
tabs separate columns.

The output is a fsdb file with a proper header
and a tab field-separator.

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

	name    email   test1
	Tommy Trojan    tt@usc.edu      80
	Joe Bruin       joeb@ucla.edu   85
	J. Random       jr@caltech.edu  90

=head2 Command:

    tabdelim_to_db

=head2 Output:

	#fsdb -Ft name email test1
	Tommy Trojan    tt@usc.edu      80
	Joe Bruin       joeb@ucla.edu   85
	J. Random       jr@caltech.edu  90
	#  | dbcoldefine name email test1


=head1 SEE ALSO

L<Fsdb>.


=head1 CLASS FUNCTIONS

=cut

@ISA = qw(Fsdb::Filter);
$VERSION = 2.0;

use strict;
use Pod::Usage;
use Carp;

use Fsdb::Filter;
use Fsdb::IO::Writer;


=head2 new

    $filter = new Fsdb::Filter::tabdelim_to_db(@arguments);

Create a new tabdelim_to_db object, taking command-line arguments.

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
	'd|debug+' => \$self->{_debug},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'log!' => \$self->{_logprog},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	) or pod2usage(2);
    pod2usage(2) if ($#argv >= 0);
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup ($) {
    my($self) = @_;

    $self->finish_fh_io_option('input');

    my($header);
    $header = $self->{_in}->getline;
    my(@columns) = Fsdb::IO::clean_potential_columns(split(/\t/, $header));
    croak $self->{_prog} . ": don't find any column headings in the first row.\n"
	if ($#columns == -1);

    $self->finish_io_option('output', -fscode => 't', -cols => \@columns);
}

=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run ($) {
    my($self) = @_;

    my $write_fastpath_sub = $self->{_out}->fastpath_sub();

    for (;;) {
	my $line = $self->{_in}->getline;
	last if (!defined($line));
        chomp $line;
	my @row = split(/\t/, $line);
	&{$write_fastpath_sub}(\@row);
    };
}


=head1 AUTHOR and COPYRIGHT

Copyright (C) 1991-2008 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
