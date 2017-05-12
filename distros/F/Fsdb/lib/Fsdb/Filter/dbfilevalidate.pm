#!/usr/bin/perl -w

#
# dbfilevalidate.pm
# Copyright (C) 2007 by John Heidemann <johnh@isi.edu>
# $Id: 3136ba0e1e91c68aac840a76440e41e75b0e4666 $
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#


package Fsdb::Filter::dbfilevalidate;

=head1 NAME

dbfilevalidate - insure the source input is a well-formed Fsdb file

=head1 SYNOPSIS

    dbfilevalidate [-vc]

=head1 DESCRIPTION

Validates the input file to make sure it is a well-formed
fsdb file.  If the file is well-formed, it outputs the whole file
and exits with a good exit code.  For invalid files,
it exits with an error exit code and embedded error messages
in the stream as comments with "***" in them.

Currently this program checks for rows with missing or extra columns.

=head1 OPTIONS

=over 4

=item B<-v> or B<--errors-only>

Output only broken lines, not the whole thing.

=item B<-c> or B<--correct>

Correct errors, if possible.  Pad out rows with the empty value;
truncate rows with extra values.
If errors can be corrected the program exits with a good return code.

=item C<-e E> or C<--empty E>

give value E as the value for empty (null) records

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

    #fsdb sid cid
    1 10
    2
    1 12
    2 12

=head2 Command:

    cat TEST/dbfilevalidate_ex.in | dbvalidate

=head2 Output:

    #fsdb sid cid
    1 10
    2
    # *** line above is missing field cid.
    1 12
    2 12
    #  | dbfilevalidate 


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
use Fsdb::IO::Reader;
use Fsdb::IO::Writer;


=head2 new

    $filter = new Fsdb::Filter::dbfilevalidate(@arguments);

Create a new dbfilevalidate object, taking command-line arguments.

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
    $self->{_correct} = undef;
    $self->{_errors_only} = undef;
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
	'c|correct!' => \$self->{_correct},
	'd|debug+' => \$self->{_debug},
	'e|empty=s' => \$self->{_empty},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'log!' => \$self->{_logprog},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	'v|errors-only!' => \$self->{_errors_only},
	) or pod2usage(2);
    pod2usage(2) if ($#argv != -1);
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup ($) {
    my($self) = @_;

    $self->{_lineno} = 0;
    $self->finish_io_option('input', -comment_handler => sub {
	    $self->{_lineno}++;
	    $self->{_out}->write_raw(@_);
	});
    $self->finish_io_option('output', -clone => $self->{_in});
}

=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run ($) {
    my($self) = @_;

    $self->{_ok} = 1;
    my $read_fastpath_sub = $self->{_in}->fastpath_sub();
    my $write_fastpath_sub = $self->{_out}->fastpath_sub();
    my $fref;
    my @columns = @{$self->{_in}->cols};
    my $invert_output = $self->{_errors_only};
    my $corrected = ($self->{_correct} ? " (corrected)" : "");
    while ($fref = &{$read_fastpath_sub}()) {
	my $bad_fields = '';
	my $bad_field_count = 0;
	my $extra_field_count = 0;
	my $i;
	foreach (0..$#columns) {
	    if (!defined($fref->[$_])) {
		$bad_fields .= ($bad_fields eq '' ? "" : ", ") . $columns[$_];
		$bad_field_count++;
		$fref->[$_] = $self->{_empty} if ($self->{_correct});
	    };
        };
	if ($#$fref > $#columns) {
	    $self->{_ok} = 0;
	    $extra_field_count = ($#$fref - $#columns);
	    if ($self->{_correct}) {
		while ($#$fref > $#columns) {
		    pop @$fref;
		};
	    };
	} ;
	&{$write_fastpath_sub}($fref)
	    if ($bad_field_count || !$invert_output);
	if ($bad_field_count > 0) {
	    $self->{_ok} = 0;
	    $self->{_out}->write_comment("*** line above is missing field"
			. (($bad_field_count > 1) ? "s " : " ")
			. $bad_fields . $corrected . ".");
        };
	if ($extra_field_count) {
	    $self->{_out}->write_comment("*** line above has $extra_field_count extra column" . ($extra_field_count == 1 ? "" : "s") . $corrected . ".");
	};
    };
    $self->{_out}->write_comment("*** dbfilevalidate: some lines had errors$corrected.") if (!$self->{_ok});
}



=head2 finish

    $filter->finish();

Internal: write trailer.

=cut
sub finish ($) {
    my($self) = @_;

    $self->SUPER::finish();
    exit 1 if (!$self->{_ok} && !$self->{_correct});
}

=head1 AUTHOR and COPYRIGHT

Copyright (C) 1991-2008 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
