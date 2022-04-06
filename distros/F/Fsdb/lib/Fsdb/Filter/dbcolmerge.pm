#!/usr/bin/perl

#
# dbcolmerge.pm
# Copyright (C) 1991-2022 by John Heidemann <johnh@isi.edu>
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbcolmerge;

=head1 NAME

dbcolmerge - merge multiple columns into one

=head1 SYNOPSIS

dbcolmerge [-C ElementSeparator] [columns...]

=head1 DESCRIPTION

For each row, merge multiple columns down to a single column (always a string),
joining elements with ElementSeparator (defaults to a single underscore).

=head1 OPTIONS

=over 4

=item B<-C S> or B<--element-separator S>

Specify the separator used to join columns.
(Defaults to a single underscore.)

=item B<-e E> or B<--empty E>

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

=item B<--header H>

Use H as the full Fsdb header, rather than reading a header from
then input.

=item B<--help>

Show help.

=item B<--man>

Show full manual.

=back

=for comment
end_standard_fsdb_options


=head1 SAMPLE USAGE

=head2 Input:

    #fsdb      first   last
    John    Heidemann
    Greg    Johnson
    Root    -
    # this is a simple database
    #  | /home/johnh/BIN/DB/dbcol fullname
    #  | dbcolrename fullname first_last
    #  | /home/johnh/BIN/DB/dbcolsplit -C _ first_last
    #  | /home/johnh/BIN/DB/dbcol first last

=head2 Command:

    cat data.fsdb | dbcolmerge -C _ first last

=head2 Output:

    #fsdb      first   last    first_last
    John    Heidemann       John_Heidemann
    Greg    Johnson Greg_Johnson
    Root    -        Root_
    # this is a simple database
    #  | /home/johnh/BIN/DB/dbcol fullname
    #  | dbcolrename fullname first_last
    #  | /home/johnh/BIN/DB/dbcolsplit first_last
    #  | /home/johnh/BIN/DB/dbcol first last
    #  | /home/johnh/BIN/DB/dbcolmerge -C _ first last


=head1 SEE ALSO

L<Fsdb>.
L<dbcolsplittocols>.
L<dbcolsplittorows>.
L<dbcolrename>.


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

    $filter = new Fsdb::Filter::dbcolmerge(@arguments);

Create a new dbcolmerge object, taking command-line arguments.

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
    $self->{_elem_separator} = '_';
    $self->{_merge_columns} = [];
    $self->{_header} = undef;
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
	'C|element-separator=s' => \$self->{_elem_separator},
	'd|debug+' => \$self->{_debug},
	'e|empty=s' => \$self->{_empty},
	'header=s' => \$self->{_header},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'log!' => \$self->{_logprog},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	) or pod2usage(2);
    push (@{$self->{_merge_columns}}, @argv);
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup ($) {
    my($self) = @_;

    # Sanity check user's input to avoid injection attacks.
    croak($self->{_prog} . ": bad element separator.\n")
	if ($self->{_elem_separator} =~ /\'/);

    croak($self->{_prog} . ": no columns to merge selected.\n")
	if ($#{$self->{_merge_columns}} == -1);

    my(@finish_args) = (-comment_handler => $self->create_pass_comments_sub);
    push (@finish_args, -header => $self->{_header}) if (defined($self->{_header}));
    $self->finish_io_option('input', @finish_args);

    $self->finish_io_option('output', -clone => $self->{_in}, -outputheader => 'delay');
    $self->{_merged_colname} = join($self->{_elem_separator}, @{$self->{_merge_columns}});
    $self->{_out}->col_create($self->{_merged_colname})
	or croak($self->{_prog} . ": cannot create column " . $self->{_merged_colname} . " (maybe it already existed?)\n");
    $self->{_merged_coli} = $self->{_out}->col_to_i($self->{_merged_colname});

    #
    # Write the code to do the merge, and check stuff on the way.
    #
    my $code = '';
    my $joiner = '';
    my $empty = $self->{_empty};
    croak("bad empty value: $empty\n") if ($empty eq "'");
    $code = '$fref->[' . $self->{_merged_coli} . '] = ';
    foreach (@{$self->{_merge_columns}}) {
	my $i = $self->{_in}->col_to_i($_);
	croak ($self->{_prog} . ": unknown column ``$_''.\n")
	    if (!defined($i));
	my $f = '$fref->[' . $i . ']';
	$code .= "$joiner ($f eq '$empty' ? '' : $f) ";
	$joiner = " . '" . $self->{_elem_separator} . "' . ";
    };
    $code .= ';';
    $self->{_join_code} = $code;
}

=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run ($) {
    my($self) = @_;

    my $read_fastpath_sub = $self->{_in}->fastpath_sub();
    my $write_fastpath_sub = $self->{_out}->fastpath_sub();

    my($loop) = q'{
        my $fref;
	while ($fref = &$read_fastpath_sub()) {
	    ' . $self->{_join_code} . q'
	    &$write_fastpath_sub($fref);
        };
    }';
    print $loop if ($self->{_debug});
    eval $loop;
    $@ && croak($self->{_prog} . ": interal eval error: $@.\n");
}

=head1 AUTHOR and COPYRIGHT

Copyright (C) 1991-2022 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
