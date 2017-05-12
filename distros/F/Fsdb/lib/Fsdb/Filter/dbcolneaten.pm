#!/usr/bin/perl -w

#
# dbcolneaten.pm
# Copyright (C) 1991-2015 by John Heidemann <johnh@isi.edu>
# $Id: 08aa35fa94fdc4d03a4df698dd6cad51ed924281 $
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbcolneaten;

=head1 NAME

dbcolneaten - pretty-print columns of Fsdb data (assuming a monospaced font)

=head1 SYNOPSIS

dbcolneaten [-E] [field_settings]

=head1 DESCRIPTION

L<dbcolneaten> arranges that the Fsdb data appears in 
neat columns if you view it with a monospaced font.
To do this, it pads out each field with spaces to line up 
the next field.

Field settings are of the form

    field op value

OP is >=, =, or <= specifying that the width of 
that FIELD must be more, equal, or less than that VALUE


L<dbcolneaten> runs in O(1) memory but disk space proportional to the
size of data.

=head1 OPTIONS

=over 4

=item B<-E> or B<--noeoln>

Omit padding for the last column (at the end-of-the-line).
(Default behavior.)

=item B<-e> or B<--eoln>

Do padding and include an extra field separator after the last column.
(Useful if you're interactively adding a column.)

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

	#fsdb fullname homedir uid gid
	Mr._John_Heidemann_Junior	/home/johnh	2274	134
	Greg_Johnson	/home/greg	2275	134
	Root	/root	0	0
	# this is a simple database
	#   | dbcol fullname homedir uid gid

=head2 Command:

    dbcolneaten

=head2 Output:

	#fsdb -F s fullname       homedir     uid  gid
	Mr._John_Heidemann_Junior /home/johnh 2274 134
	Greg_Johnson              /home/greg  2275 134
	Root                      /root       0    0  
	# this is a simple database
	#   | dbcol fullname homedir uid gid
	#   | dbcolneaten


=head1 BUGS

Does not handle tab separators correctly.


=head1 SEE ALSO

L<Fsdb>.


=head1 CLASS FUNCTIONS

=cut

@ISA = qw(Fsdb::Filter);
($VERSION) = 2.0;

use strict;
use Pod::Usage;
use Carp;

use Fsdb::Filter;
use Fsdb::IO::Reader;
use Fsdb::IO::Writer;
use Fsdb::IO::Replayable;


=head2 new

    $filter = new Fsdb::Filter::dbcolneaten(@arguments);

Create a new dbcolneaten object, taking command-line arguments.

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
    $self->{_do_eoln} = 0;
    $self->{_field_specs} = [];
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
	'eoln!' => \$self->{_do_eoln},
	'e' => sub { $self->{_do_eoln} = 1; },
	'E' => sub { $self->{_do_eoln} = 0; },
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'log!' => \$self->{_logprog},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	) or pod2usage(2);
    push (@{$self->{_field_specs}}, @argv);
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup ($) {
    my($self) = @_;

    $self->finish_io_option('input', -comment_handler => $self->create_pass_comments_sub('_replayable_writer'));

    my @change_fscode;
    push (@change_fscode, -fscode => 's') if ($self->{_in}->fscode eq 'D');
    $self->finish_io_option('output', -clone => $self->{_in}, @change_fscode,
	-outputheader => sub { $self->format_header(@_) } );

    $self->{_replayable} = new Fsdb::IO::Replayable(-writer_args => [ -clone => $self->{_in} ], -reader_args => [ -comment_handler => $self->create_pass_comments_sub ]);
    $self->{_replayable_writer} = $self->{_replayable}->writer;
}

=head2 format_header

    $filter->format_header($out)

Format the header for the current object to output stream C<$out>.

=cut
sub format_header ($) {
    my($self, $out) = @_;

    croak if ($self->{_out} != $out);  # assert

    # Write out a comment that shows the header fields.
    # get Fsdb::IO to generate the prequel
    $out->update_headerrow;
    my @cols = @{$out->cols};
    $cols[0] = $out->{_header_prequel} . $cols[0];
    my $pad = $self->{_pad_fn};
    # Since we're writing the header, we need to be picky about the fs we use.
    # see test case dbcolneaten_strange_sep.cmd
    my $header_fs = $out->{_fs};
    $header_fs = ' ' if ($header_fs !~ /^\s+$/);   # Fall back on benign space if the data uses something fancy.
    &$pad(\@cols, $self->{_colwidths}, $header_fs);
    my $padded_header = join('', @cols);

# Sigh, debugging no longer works because we return the result so fastpath is not done yet.  Fortunately, no bugs remain.
#    if ($self->{_debug}) {
#	my(@debug_colwidths) = @{$self->{_colwidths}};
#	$debug_colwidths[0] = "# ". $debug_colwidths[0];
#	&$pad(\@debug_colwidths, $self->{_colwidths}, $self->{_out}->{_fs});
#	my $padded_debug = join('', @debug_colwidths, "\n");
#	&$write_fastpath_sub($padded_debug);
#    };

    return $padded_header;
}

=head2 run

    $filter->run();

Scan the data once,
then rewrite it neatly.

=cut
sub run ($) {
    my($self) = @_;

    #
    # first, scan the data to find widths
    #
    my $read_fastpath_sub = $self->{_in}->fastpath_sub();
    my $replayable_writer_fastpath_sub = $self->{_replayable_writer}->fastpath_sub();
    my $fref;
    my @colwidths = (0) x $self->{_in}->ncols;
    while ($fref = &$read_fastpath_sub()) {
	foreach (0..$#colwidths) {
	    my $l = defined($fref->[$_]) ? length($fref->[$_]) : 0;
	    $colwidths[$_] = $l if ($l > $colwidths[$_]);
	};
	&$replayable_writer_fastpath_sub($fref);
    };
    $self->{_replayable}->close;

    #
    # handle arguments
    # (Sigh, we'd prefer to handle these in setup,
    # but we also don't want to duplicate the code.)
    #
    foreach (@{$self->{_field_specs}}) {
        my($field_name, $op, $value) = m/([^<>=]*)\s*([<>=]+)\s*(\d+)/;
        croak $self->{_prog} . ": unknown field specification.\n"
	    if (!defined($field_name) || !defined($value));
        my($field_col) = $self->{_in}->col_to_i($field_name);
        die ($self->{_prog} . ": unknown column ``$field_name''.\n")
	    if (!defined($field_col));
        if ($op eq '=') {
    	    $colwidths[$field_col] = $value;
        } elsif ($op eq '>=') {
            $colwidths[$field_col] = $value if ($colwidths[$field_col] < $value);
        } elsif ($op eq '<=') {
            $colwidths[$field_col] = $value if ($colwidths[$field_col] > $value);
        } else {
            die $self->{_prog} . ": bad operation $op in field spec $_.\n";
        };
    }

    my $fs_width = length($self->{_in}->{_fs});
    my $empty_width = length($self->{_empty});
    my $do_eoln = $self->{_do_eoln};
    # pad: pad out @$fields_ref to match @$colwidthref spacing per field
    my $pad = sub {
	my($fields_ref, $colwidthref, $extra_char) = @_;
	my $running_place = 0;
	my $running_target = 0;
	foreach (0..$#{$colwidthref}) {
	    my $this_col_width = defined($fields_ref->[$_]) ? length($fields_ref->[$_]) : $empty_width;
	    $running_place += $this_col_width;
	    $running_target += $colwidthref->[$_];
	    my $more = $running_target - $running_place;
	    if ($more > 0 && ($_ < $#{$colwidthref} || $do_eoln)) {
		$fields_ref->[$_] .= (" " x $more);
		$running_place += $more;
	    };
	    # add on field sep for comments
	    # (only used for the first #fsdb line)
	    $fields_ref->[$_] .= $extra_char if (defined($extra_char) && $_ != $#{$colwidthref});
	};
    };
    # save aside what we'll need in $self->format_header
    $self->{_colwidths} = \@colwidths;
    $self->{_pad_fn} = $pad;

    #
    # output:
    #
    my $replayable_reader = $self->{_replayable}->reader;
    my $replayable_reader_fastpath_sub = $replayable_reader->fastpath_sub();
    # the next line will callback format_header as a side effect
    my $write_fastpath_sub = $self->{_out}->fastpath_sub();

    # now, rewrite the data
    while ($fref = &$replayable_reader_fastpath_sub()) {
	&$pad($fref, \@colwidths, undef);
	&$write_fastpath_sub($fref);
    };
    $replayable_reader->close;
}


=head1 AUTHOR and COPYRIGHT

Copyright (C) 1991-2015 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
