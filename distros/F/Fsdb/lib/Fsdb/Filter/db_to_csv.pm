#!/usr/bin/perl -w

#
# db_to_csv.pm
# Copyright (C) 2007 by John Heidemann <johnh@isi.edu>
# $Id: 2fc5da9ab90db77e3b4b2adfdf26f9fe040194df $
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::db_to_csv;

=head1 NAME

db_to_csv - convert fsdb to the comma-separated-value file-format

=head1 SYNOPSIS

    db_to_csv [-C]

=head1 DESCRIPTION

Covert an existing fsdb file to comma-separated value format.

Input is fsdb format.

Output is CSV-format plain text (I<not> fsdb).

=head1 OPTIONS

=over 4

=item B<-C> or <--omit-comments>

Also strip all comments.

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

	#fsdb -F S paper papertitle reviewer reviewername score1 score2 score3 score4 score5
	1  test, paper  2  Smith  4  4  -  -  -
	2  other paper  3  Jones  3  3  -  -  -
	2  input double space  3  Jones  3  3  -  -  -
	#  | csv_to_db 

=head2 Command:

    cat data.fsdb | db_to_csv

=head2 Output:

	paper,papertitle,reviewer,reviewername,score1,score2,score3,score4,score5
	1,"test, paper",2,Smith,4,4,-,-,-
	2,"other paper",3,Jones,3,3,-,-,-
	2,"input double space",3,Jones,3,3,-,-,-
	#  | csv_to_db 
	#  | db_to_csv 


=head1 SEE ALSO

L<Fsdb>.
L<dbfilealter>.
L<csv_to_db>


=head1 CLASS FUNCTIONS

=cut

@ISA = qw(Fsdb::Filter);
$VERSION = 2.0;

use strict;
use Pod::Usage;
use Carp;
use Text::CSV_XS;

use Fsdb::Filter;
use Fsdb::IO::Reader;


=head2 new

    $filter = new Fsdb::Filter::db_to_csv(@arguments);

Create a new db_to_csv object, taking command-line arguments.

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
    $self->{_omit_comments} = undef;
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
	'C|omit-comments!' => \$self->{_omit_comments},
	'd|debug+' => \$self->{_debug},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'log!' => \$self->{_logprog},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	) or pod2usage(2);
    pod2usage(2) if ($#argv != -1);
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup ($) {
    my($self) = @_;

    my $comment_sub;
    if ($self->{_omit_comments}) {
	$comment_sub = sub {};
    } else {
	$comment_sub = sub { $self->{_out}->print(join("\n", @_)); };
    };

    $self->finish_io_option('input', -comment_handler => $comment_sub);

    $self->finish_fh_io_option('output');
    $self->{_logprog} = undef if ($self->{_omit_comments});

    # write out the header as the first line
    # xxx: perhaps have an option to suppress this?
    my $csv = $self->{_csv} = new Text::CSV_XS;
    $csv->combine(@{$self->{_in}->cols})
	or croak $self->{_prog} . ": cannot generate column names.\n";
    $self->{_out}->print($csv->string .  "\n");
}

=head2 run

    $filter->run();

Internal: run over each row.

=cut
sub run ($) {
    my($self) = @_;

    my $read_fastpath_sub = $self->{_in}->fastpath_sub();
    my $fref;
    my $csv = $self->{_csv};
    my $out_fh = $self->{_out};
    while ($fref = &{$read_fastpath_sub}()) {
	$csv->combine(@$fref)
	    or croak $self->{_prog} . ": failed on this line: " . join("  ", @$fref) . ".\n";
	$out_fh->print($csv->string . "\n");
    };
}




=head1 AUTHOR and COPYRIGHT

Copyright (C) 1991-2008 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
