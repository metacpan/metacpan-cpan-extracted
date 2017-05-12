#!/usr/bin/perl

#
# html_table_to_db.pm
# Copyright (C) 2005-2015 by John Heidemann <johnh@isi.edu>
# $Id: 025cc75c8e0df7ccdb092d89696480e5dee7dd08 $
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblib for details.
#

package Fsdb::Filter::html_table_to_db;

=head1 NAME

html_table_to_db - convert HTML tables into fsdb

=head1 SYNOPSIS

    html_table_to_db <source.html >dest.fsdb

=head1 DESCRIPTION

Converts a HTML table to Fsdb format.

The input is an HTML table (I<not> fsdb).
Column names are taken from C<TH> elements,
or defined as C<column0> through C<columnN> if 
no such elements appear.

The output is two-space-separated fsdb.
(Someday more general field separators should be supported.)
Fsdb fields are normalized version of the html file:
multiple spaces are compressed to one.

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

	<table>
	<tr><th>account</th> <th>passwd</th> <th>uid</th> <th>gid</th> <th>fullname</th> <th>homedir</th> <th>shell</th> </tr>
	<tr bgcolor="#f0f0f0"><td>johnh</td> <td>*</td> <td>2274</td> <td>134</td> <td>John &amp; Ampersand</td> <td>/home/johnh</td> <td>/bin/bash</td> </tr>
	<tr bgcolor="#f0f0f0"><td>greg</td> <td>*</td> <td>2275</td> <td>134</td> <td>Greg &lt; Lessthan</td> <td>/home/greg</td> <td>/bin/bash</td> </tr>
	<tr bgcolor="#f0f0f0"><td>root</td> <td>*</td> <td>0</td> <td>0</td> <td>Root ; Semi</td> <td>/root</td> <td>/bin/bash</td> </tr>
	<tr bgcolor="#d0d0d0"><td>four</td> <td>*</td> <td>1</td> <td>1</td> <td>Fourth Row</td> <td>/home/four</td> <td>/bin/bash</td> </tr>
	</table>

=head2 Command:

    html_table_to_db

=head2 Output:

	#fsdb -F S account passwd uid gid fullname homedir shell
	johnh  *  2274  134  John & Ampersand  /home/johnh  /bin/bash
	greg  *  2275  134  Greg < Lessthan  /home/greg  /bin/bash
	root  *  0  0  Root ; Semi  /root  /bin/bash
	four  *  1  1  Fourth Row  /home/four  /bin/bash


=head1 SEE ALSO

L<Fsdb>.
L<db_to_html_table>.


=head1 CLASS FUNCTIONS

=cut

@ISA = qw(Fsdb::Filter);
$VERSION = 2.0;

use strict;
use Pod::Usage;
use Carp;

use HTML::Parser;

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

    # Can't open up the source,
    # so can't write the header.
}

=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run ($) {
    my($self) = @_;

    my %inside;
    my $text = '';
    my $colspan = undef;
    my $header_count = 0;
    my @row;
    my @cols;
    my $start_sub = sub {
	my($tag, $attrh) = @_;
	croak $self->{_prog} . ": tr not in table.\n"
	    if ($tag eq 'tr' && !$inside{table});
	if ($tag eq 'th' || $tag eq 'td') {
	    croak $self->{_prog} . ": badly nested $tag.\n"
		if ($inside{th} || $inside{td});
	    croak $self->{_prog} . ": th or td outside table or tr.\n"
		if (!$inside{table} || !$inside{tr});
	    $text = '';
	    $colspan = $attrh->{colspan};
	};
	$inside{$tag}++;
    };
    my $end_sub = sub {
	my($tag, $attrh) = @_;
	$inside{$tag}--;
	if ($tag eq 'th' || $tag eq 'td') {
	    $header_count++ if ($tag eq 'th');
	    $text =~ s/\n/ /g;
	    $text =~ s/^\s+//; 
	    $text =~ s/\s+$//; 
	    $text =~ s/  +/ /g;  # clean up for fsdb double-space separator
	    $text = $self->{_empty} if ($text =~ /^\s+$/);
	    push(@row, $text);
	    push(@row, ($self->{_empty}) x ($colspan - 1)) if (defined($colspan) && $colspan > 1);
	    $text = '';
	} elsif ($tag eq 'tr') {
	    # take a row action
	    if (!defined($self->{_out})) {
		my $got_header = undef;
		if ($header_count == $#row+1) {
		    # first row and all headers
		    @cols = Fsdb::IO::clean_potential_columns(@row);
		    @row = ();
		    $got_header = 1;
		} else {
		    # no headers, make it up
		    foreach (0..$#row) {
			push(@cols, "column$_");
		    };
		};
		$self->finish_io_option('output', -fscode => 'S', -cols => \@cols);
		return if ($got_header);
	    };
	    # fill in empty rows, if any
	    if ($#row + 1 != $self->{_out}->ncols) {
		push(@row, ($self->{_empty} . "x") x ($self->{_out}->ncols - ($#row + 1)));
	    };
	    # and rename blank rows to the empty symbol
	    # and cleanup newlines
	    foreach (0..$#row) {
		$row[$_] =~ s/\n/ /gm;
		# next line is a bit of a hack, assuming -F S
		$row[$_] =~ s/\s\s+/  /gm;
		$row[$_] = $self->{_empty} if ($row[$_] =~ /^\s*$/);
	    };
	    $self->{_out}->write_row_from_aref(\@row);
	    @row = ();
	};
    };
    my $text_sub = sub {
	return if ($inside{script} || $inside{style});
	return if (!$inside{table} || !$inside{tr});
	$text .= $_[0] if ($inside{td} || $inside{th});
    };

    my $parser = HTML::Parser->new(api_version => 3,
		    start_h => [ $start_sub, "tagname, attr" ],
		    end_h => [ $end_sub, "tagname, attr" ],
		    text_h => [ $text_sub, "dtext" ],
		    marked_sections => 1);
    $parser->parse_file($self->{_in});

    croak $self->{_prog} . ": could not find table in html input.\n"
	if ($#cols == -1);
}


=head1 AUTHOR and COPYRIGHT

Copyright (C) 1991-2015 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
