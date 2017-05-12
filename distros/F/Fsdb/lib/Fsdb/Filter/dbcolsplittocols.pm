#!/usr/bin/perl

#
# dbcolsplittocols.pm
# Copyright (C) 1991-2015 by John Heidemann <johnh@isi.edu>
# $Id: a77153f1d066313657e9c830914d1f135e047459 $
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbcolsplittocols;

=head1 NAME

dbcolsplittocols - split an existing column into multiple new columns

=head1 SYNOPSIS

dbcolsplittocols [-E] [-C ElementSeparator] column [column...]

=head1 DESCRIPTION

Create new columns by splitting an existing column.
The fragments of the column are each divided by ElementSeparator
(default is underscore).

This command is the opposite of dbcolmerge.
Names of the new columns are given by splitting the name
of the existing column.  dbcolrename may be useful
to set column names.


=head1 OPTIONS

=over 4

=item B<-C S> or B<--element-separator S>

Specify the separator I<S> used to join columns.
(Defaults to a single underscore.)

=item B<-E> or B<--enumerate>

Enumerate output columns: rather than assuming the column name uses
the element separator, we keep it whole and fill in with indexes
starting from 0.
(Not currently implemented, but planned.  See
L<dbcolsplittorows>.)

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

    #fsdb      first_last
    John_Heidemann
    Greg_Johnson
    Root
    # this is a simple database
    #  | dbcolrename fullname first_last
    #  | /home/johnh/BIN/DB/dbcol first_last

=head2 Command:

    cat data.fsdb | dbcolsplittocols first_last

=head2 Output:

    #fsdb      first_last      first   last
    John_Heidemann  John    Heidemann
    Greg_Johnson    Greg    Johnson
    Root    Root
    # this is a simple database
    #  | dbcolrename fullname first_last
    #  | /home/johnh/BIN/DB/dbcol first_last
    #  | /home/johnh/BIN/DB/dbcolsplittocols first_last

=head1 SEE ALSO

L<Fsdb(3)>.
L<dbcolmerge(1)>.
L<dbcolsplittorows(1)>.
L<dbcolrename(1)>.


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

    $filter = new Fsdb::Filter::dbcolsplittocols(@arguments);

Create a new dbcolsplittocols object, taking command-line arguments.

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
    $self->{_enumerate} = undef;
    $self->{_target_column} = undef;
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
	'E|enumerate!' => \$self->{_enumerate},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
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

    $self->finish_io_option('input', -comment_handler => $self->create_pass_comments_sub);

    pod2usage(2) if (!defined($self->{_target_column}));

    $self->{_target_coli} = $self->{_in}->col_to_i($self->{_target_column});
    croak $self->{_prog} . ": target column " . $self->{_target_column} . " is not in input stream.\n"
	if (!defined($self->{_target_coli}));

    # Sanity check user's input to avoid injection attacks.
    croak $self->{_prog} . ": bad element separator.\n"
	if ($self->{_elem_separator} =~ /\'/);

    $self->finish_io_option('output', -clone => $self->{_in}, -outputheader => 'delay');
    my(@new_columns);
    if ($self->{_enumerate}) {
	# xxx: need to estimate how many we need, but we can't do that.
	croak $self->{_prog} . ": enumeration is not currently supported\n";
    } else {
	@new_columns = split(/$self->{_elem_separator}/, $self->{_target_column});
    };
    my @new_colis = ();

    #
    # Write the code to do the split, and check stuff on the way.
    #
    my $code = 'my @p = split(/' . quotemeta($self->{_elem_separator}) . '/, $fref->[' . $self->{_target_coli} . ']);' . "\n" .
	'push(@p, (' . "'" . $self->{_empty} . "') x (" . $#new_columns . ' - $#p)) if ($#p < ' . $#new_columns . ");\n";
    my $new_ci = 0;
    foreach (@new_columns) {
	$self->{_out}->col_create($_)
	    or croak $self->{_prog} . ": cannot create column " . $_ . " (maybe it already existed?)\n";
	my $i = $self->{_out}->col_to_i($_);
	push(@new_colis, $i);
	$code .= '$fref->[' . $i . '] = $p[' . $new_ci . '];' . "\n";
	$new_ci++;
    };
    $self->{_split_code} = $code;
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
	    ' . $self->{_split_code} . q'
	    &$write_fastpath_sub($fref);
        };
    }';
    print $loop if ($self->{_debug});
    eval $loop;
    $@ && croak $self->{_prog} . ": interal eval error: $@.\n";
}


=head1 AUTHOR and COPYRIGHT

Copyright (C) 1991-2015 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
