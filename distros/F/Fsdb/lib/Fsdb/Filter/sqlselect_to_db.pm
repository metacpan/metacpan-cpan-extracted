#!/usr/bin/perl

#
# sql_to_db.pm
# Copyright (C) 2014-2018 by John Heidemann <johnh@isi.edu>
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblib for details.
#

package Fsdb::Filter::sqlselect_to_db;

=head1 NAME

sqlselect_to_db - convert MySQL or MariaDB selected tables to fsdb

=head1 SYNOPSIS

    sqlselect_to_db <source.sqlselect_table >dest.fsdb

=head1 DESCRIPTION

Converts a MySQL or MariaDB tables to Fsdb format.

The input is I<not> fsdb.
The first non-box row is taken to be the names of the columns.

The output is two-space-separated fsdb.
(Someday more general field separators should be supported.)

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

    +----------------+---------------+--------------------+------+-------------------------+
    | username       | firstname     | lastname           | id   | email                   |
    +----------------+---------------+--------------------+------+-------------------------+
    | johnh          | John          | Heidemann          |  134 | johnh@isi.edu           |
    +----------------+---------------+--------------------+------+-------------------------+
    1 row in set (0.01 sec)

=head2 Command:

    sqlselect_to_db

=head2 Output:

    #fsdb -F S username firstname lastname id email
    johnh  John  Heidemann  134  johnh@isi.edu
    #   | sqlselect_to_db


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

    $self->{_lineno} = 0;
    my($header);
    for (;;) {
	$header = $self->{_in}->getline;
	$self->{_lineno}++;
	croak $self->{_prog} . ": cound not find header\n"
	    if (!defined($header));
	chomp($header);
	last if ($header !~ /^[-+]+$/);
    };
    my(@raw_columns) = split(/\|/, $header);
    shift(@raw_columns);  #  REQUIRE leading |
        #if ($raw_columns[0] eq '');  
    my(@columns) = Fsdb::IO::clean_potential_columns(@raw_columns);
    $self->finish_io_option('output', -fscode => 'S', -cols => \@columns);
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
	$self->{_lineno}++;
	last if (!defined($line));
        chomp $line;
	next if ($line =~ /^[-+]+$/);
	next if ($line =~ /\d+ rows? in set/);
	my(@row) = split(/\|/, $line);
	shift(@row);  # require leading |
	grep { s/^ +//g; } @row;
	grep { s/ +$//g; } @row;
	grep { s/  +/ /g; } @row;   # clean up for fsdb double-space separator
	grep { s/^ *$/-/g; } @row;  # add null values for fields
	&{$write_fastpath_sub}(\@row);
    };
}


=head1 AUTHOR and COPYRIGHT

Copyright (C) 2014-2018 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
