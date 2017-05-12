#!/usr/bin/perl -w

#
# db_to_html_table.pm
# Copyright (C) 2007-2015 by John Heidemann <johnh@isi.edu>
# $Id: 82951024a92cc183126ddfc2a823e9e9f098bd27 $
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::db_to_html_table;

=head1 NAME

db_to_html_table - convert db to an HTML table

=head1 SYNOPSIS

    db_to_html_table [-g N] <source.fsdb >dest.html

=head1 DESCRIPTION

Covert an existing dbtable to an HTML table.
The output is a fragment of an HTML page;
we assume the user fills in the rest (head and body, etc.).

Input is fsdb format.

Output is HTML code (I<not> fsdb),
with HTML-specific characters
(less than, greater than, ampersand) are escaped.
(The fsdb-1.x version assumed input was ISO-8859-1; we now assume
both input and output are unicode. 
This change is considered a feature of the 21st century.)

=head1 OPTIONS

=over 4

=item B<-g N> or <--group-count N>

Color groups of I<N> consecutive rows with one background color.

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

	#fsdb -F S account passwd uid gid fullname homedir shell
	johnh  *  2274  134  John & Ampersand  /home/johnh  /bin/bash
	greg  *  2275  134  Greg < Lessthan  /home/greg  /bin/bash
	root  *  0  0  Root ; Semi  /root  /bin/bash
	four  *  1  1  Fourth Row  /home/four  /bin/bash

=head2 Command:

    cat data.fsdb | db_to_csv -g 3

=head2 Output:

	<table>
	<tr><th>account</th> <th>passwd</th> <th>uid</th> <th>gid</th> <th>fullname</th> <th>homedir</th> <th>shell</th> </tr>
	<tr bgcolor="#f0f0f0"><td>johnh</td> <td>*</td> <td>2274</td> <td>134</td> <td>John &amp; Ampersand</td> <td>/home/johnh</td> <td>/bin/bash</td> </tr>
	<tr bgcolor="#f0f0f0"><td>greg</td> <td>*</td> <td>2275</td> <td>134</td> <td>Greg &lt; Lessthan</td> <td>/home/greg</td> <td>/bin/bash</td> </tr>
	<tr bgcolor="#f0f0f0"><td>root</td> <td>*</td> <td>0</td> <td>0</td> <td>Root ; Semi</td> <td>/root</td> <td>/bin/bash</td> </tr>
	<tr bgcolor="#d0d0d0"><td>four</td> <td>*</td> <td>1</td> <td>1</td> <td>Fourth Row</td> <td>/home/four</td> <td>/bin/bash</td> </tr>
	</table>


=head1 SEE ALSO

L<Fsdb>.
L<dbcolneaten>.
L<dbfileadjust>.
L<html_table_to_db>.


=head1 CLASS FUNCTIONS

=cut

@ISA = qw(Fsdb::Filter);
$VERSION = 2.0;

use strict;
use Pod::Usage;
use Carp;

use Fsdb::Filter;
use Fsdb::IO::Reader;


=head2 new

    $filter = new Fsdb::Filter::db_to_html_table(@arguments);

Create a new db_to_html_table object, taking command-line arguments.

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
    $self->{_group_count} = undef;
    $self->{_logprog} = undef;  # change default
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
	'g|group-count=i' => \$self->{_group_count},
	'log!' => \$self->{_logprog},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	) or pod2usage(2);
    pod2usage(2) if ($#argv != -1);
}

=head2 _format_row

    $self->_format_row($row_aref, $tag, $color);

Return as a string the HTML table row corresponding to
C<@$row_aref>, with each element delimited by C<$tag>,
with color C<$color>.

=cut

sub _format_row {
    my($self, $row_aref, $tag, $color) = @_;

    $tag = "td" if (!defined($tag));
    my $options = "";
    $options = " bgcolor=\"$color\"" if (defined($color));
    my $o = "<tr$options>";
    foreach (@$row_aref) {
	my($content) = $_;
	$content =~ s/\&/&amp;/g;
	$content =~ s/</&lt;/g;
	$content =~ s/>/&gt;/g;
	$o .= "<$tag>$content</$tag> ";
    };
    $o .= "</tr>\n";
    return $o;
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup ($) {
    my($self) = @_;

    $self->finish_io_option('input', -comment_handler => sub {});

    $self->finish_fh_io_option('output');

    # write out the header as the first line
    my $cols_aref = $self->{_in}->cols;
    $self->{_out}->print("<table>\n" .
	$self->_format_row($cols_aref, 'th'));
}

=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run ($) {
    my($self) = @_;
    my $out_fh = $self->{_out};

    my $read_fastpath_sub = $self->{_in}->fastpath_sub();
    my $fref;
    my($color, $other_color) = (undef, undef);
    my $group_n = 0;
    my $group_count = $self->{_group_count};
    if (defined($group_count)) {
	# xxx: hard coded for now
	($color, $other_color) = ("#f0f0f0", "#d0d0d0");
    };
    while ($fref = &{$read_fastpath_sub}()) {
	if (defined($group_count)) {
	    if ($group_n++ >= $group_count) {
		($color, $other_color) = ($other_color, $color);
		$group_n = 1;
	    };
	};
	$out_fh->print($self->_format_row($fref, 'td', $color));
    };

    $out_fh->print("</table>\n");
}


=head1 AUTHOR and COPYRIGHT

Copyright (C) 2007-2015 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
