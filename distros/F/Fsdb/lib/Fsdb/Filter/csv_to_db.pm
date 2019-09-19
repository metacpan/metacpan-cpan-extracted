#!/usr/bin/perl

#
# csv_to_db.pm
# Copyright (C) 2005-2007 by John Heidemann <johnh@isi.edu>
# $Id: 6d26ba96e4a0b34fac3cb167418ed83bf90fe137 $
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblib for details.
#

package Fsdb::Filter::csv_to_db;

=head1 NAME

csv_to_db - convert comma-separated-value data into fsdb

=head1 SYNOPSIS

    csv_to_db <source.csv 

=head1 DESCRIPTION

Converts a comma-separated-value data stream to Fsdb format.

The input is CSV-format (I<not> fsdb).
The first row is taken to be the names of the columns.

The output is two-space-separated fsdb.
(Someday more general field separators should be supported.)
Fsdb fields are normalized version of the CSV file:
spaces are converted to single underscores.

=head1 OPTIONS

=over 4

=item B<-F> or B<--fs> or B<--fieldseparator> S

Specify the field (column) separator as C<S>.
See L<dbfilealter> for valid field separators.
Default is S (double space).

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

    paper,papertitle,reviewer,reviewername,score1,score2,score3,score4,score5

    1,"test, paper",2,Smith,4,4,,,
    2,other paper,3,Jones,3,3,,,

=head2 Command:

    csv_to_db

=head2 Output:

    #fsdb -F S paper papertitle reviewer reviewername score1 score2 score3 score4 score5
    1  test, paper  2  Smith  4  4  -  -  -
    2  other paper  3  Jones  3  3  -  -  -
    #  | csv_to_db 


=head1 SEE ALSO

L<Fsdb>.
L<db_to_csv>.


=head1 CLASS FUNCTIONS

=cut

@ISA = qw(Fsdb::Filter);
$VERSION = 2.0;

use strict;
use Pod::Usage;
use Carp;

use Text::CSV_XS;

use Fsdb::Filter;
use Fsdb::IO::Writer;


=head2 new

    $filter = new Fsdb::Filter::csv_to_db(@arguments);

Create a new csv_to_db object, taking command-line arguments.

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
    $self->{_fscode} = 'S';
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
	'F|fs|cs|fieldseparator|columnseparator=s' => \$self->{_fscode},
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

    my $csv = $self->{_csv} = new Text::CSV_XS({'binary' => 1});

    my($header);
    $header = $self->{_in}->getline;
    my $e = $csv->parse($header) or croak($self->{_prog} . ": cannot parse header $header\n");
    my(@columns) = Fsdb::IO::clean_potential_columns($csv->fields());

    $self->finish_io_option('output', -fscode => $self->{_fscode}, -cols => \@columns);
}

=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run ($) {
    my($self) = @_;

    my $write_fastpath_sub = $self->{_out}->fastpath_sub();

    my $csv = $self->{_csv};
    my $lineno = 0;
    for (;;) {
	my $line = $self->{_in}->getline;
	$lineno++;
	last if (!defined($line));
        chomp $line;
	# skip blank lines
	next if ($line eq '');
	my $e = $csv->parse($line);
	if (! $e) {
	    carp "# csv conversion error in on line $lineno: " . $csv->error_diag() . "\n";
	    next;   # skip error lines
	};
	my(@row) = $csv->fields();
	grep { s/  +/ /g; } @row;   # clean up for fsdb double-space separator
	grep { s/^ *$/-/g; } @row;  # add null values for fields
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
