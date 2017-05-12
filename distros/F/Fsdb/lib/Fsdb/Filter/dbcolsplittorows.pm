#!/usr/bin/perl

#
# dbcolsplittorows.pm
# Copyright (C) 1991-2008 by John Heidemann <johnh@isi.edu>
# $Id: 56d2923e0064a9026e77232e84b7f8a1c48e1947 $
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbcolsplittorows;

=head1 NAME

dbcolsplittorows - split an existing column into multiple new rows

=head1 SYNOPSIS

dbcolsplittorows [-C ElementSeperator] [-e null] [-E] [-N enumerated-name] column [column...]

=head1 DESCRIPTION

Split column into pieces, outputting one row for each piece.

By default, any empty fields are ignored.
If an empty field value is given with -e, then they produce output.

When a null value is given, empty fields at the beginning and end of
lines are suppressed (like perl split).  Unlike perl, if ALL fields
are empty, we generate one (and not zero) empty fields.

The inverse of this commend is L<dbfilepivot>.


=head1 OPTIONS

=over 4

=item B<-C S> or B<--element-separator S>

Specify the separator used to split columns.
(Defaults to a single underscore.)

=item B<-E> or B<--enumerate>

Enumerate output columns: rather than assuming the column name uses
the element separator, we keep it whole and fill in with indexes
starting from 0.

=item B<-N> or B<--new-name> N

Name the new column N for enumeration.
Defaults to C<index>.

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

=item B<--help>

Show help.

=item B<--man>

Show full manual.

=back

=for comment
end_standard_fsdb_options


=head1 SAMPLE USAGE

=head2 Input:

    #fsdb name uid
    John_Heidemann  2274
    Greg_Johnson    2275
    Root    0
    # this is a simple database
    #  | dbcol fullname uid
    #  | dbcolrename fullname name

=head2 Command:

    cat data.fsdb | dbcolsplittorows name

=head2 Output:

    #fsdb name uid
    John    2274
    Heidemann       2274
    Greg    2275
    Johnson 2275
    Root    0
    # this is a simple database
    #  | dbcol fullname uid
    #  | dbcolrename fullname name
    #  | dbcolsplittorows name

=head1 SEE ALSO

L<Fsdb(1)>.
L<dbcolmerge(1)>.
L<dbcolsplittocols(1)>.
L<dbcolrename(1)>.
L<dbfilepvot(1)>.


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
    $self->{_destination_column} = 'count';
    $self->{_target_column} = undef;
    $self->{_empty} = undef;
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
	'E|enumerate!' => \$self->{_enumerate},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'log!' => \$self->{_logprog},
	'N|new-name=s' => \$self->{_destination_column},
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
	if ($self->{_element_separator} =~ /\'/);
    croak $self->{_prog} . ": bad empty value.\n"
	if ($self->{_empty} =~ /\'/);

    $self->finish_io_option('output', -clone => $self->{_in}, -outputheader => 'delay');
    if ($self->{_enumerate}) {
	$self->{_out}->col_create($self->{_destination_column})
	    or croak $self->{_prog} . ": cannot create column '" . $self->{_destination_column} . "' (maybe it already existed?)\n";
    };
}

=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run ($) {
    my($self) = @_;

    my $read_fastpath_sub = $self->{_in}->fastpath_sub();
    my $write_fastpath_sub = $self->{_out}->fastpath_sub();

    my $empty = $self->{_empty};
    my $enum_coli = undef;
    if ($self->{_enumerate}) {
	$enum_coli = $self->{_out}->col_to_i($self->{_destination_column});
	croak $self->{_prog} . ": enumeration column " . $self->{_destion_column} . " doesn't exist, even though we created it.\n"
	    if (!defined($enum_coli));
    };


    my($loop) = q'{
        my $fref;
	while ($fref = &$read_fastpath_sub()) {
	    my @p = split(/' . quotemeta($self->{_elem_separator}) . '/, $fref->[' . $self->{_target_coli} . ']);
	    push(@p, undef) if ($#p == -1);
	    my($i) = 0;
	    foreach (@p) {
		if (!defined($_) || $_ eq "") {
		    ' . (!defined($empty) ? "next;\n" : '$_ = ' . "'" . $empty . "';" ) . '
		};
		$fref->[' . $self->{_target_coli} . '] = $_;' . 
		(defined($enum_coli) ? '  $fref->[' . $enum_coli . '] = $i++;' : '') . '
		&$write_fastpath_sub($fref);
	    };
        };
    }';
    eval $loop;
    $@ && croak $self->{_prog} . ": interal eval error: $@.\ncode:\n$loop";
}


=head1 AUTHOR and COPYRIGHT

Copyright (C) 1991-2008 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;

