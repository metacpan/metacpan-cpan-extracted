#!/usr/bin/perl -w

#
# dbrowaccumulate.pm
# Copyright (C) 1991-2018 by John Heidemann <johnh@isi.edu>
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#


package Fsdb::Filter::dbrowaccumulate;

=head1 NAME

dbrowaccumulate - compute a running sum of a column

=head1 SYNOPSIS

dbrowaccumulate [-C increment_constant] [-I initial_value] [-c increment_column] [-N new_column_name]

=head1 DESCRIPTION

Compute a running sum over a column of data,
or of a constant incremented per row,
perhaps to generate a cumulative distribution.

What to accumulate is specified by C<-c> or C<-C>.

The new column is named by the C<-N> argument, defaulting to C<accum>.

=head1 OPTIONS

=over 4

=item B<-c> or B<--column> COLUMN

Accumulate values from the given COLUMN.
No default.

=item B<-C> or B<--constant> K

Accumulate the given constant K for each row of input.
No default.

=item B<-I> or B<--initial-value> I

Start accumulation at value I.
Defaults to zero.

=item B<-N> or B<--new-name> N

Name the new column N.
Defaults to C<accum>.

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

    #fsdb      diff
    0.0
    00.000938
    00.001611
    00.001736
    00.002006
    00.002049
    #  | /home/johnh/BIN/DB/dbrow 
    #  | /home/johnh/BIN/DB/dbcol diff
    #  | dbsort diff

=head2 Command:

    cat DATA/kitrace.fsdb | dbrowaccumulate -c diff

=head2 Output:

    #fsdb      diff    accum
    0.0     0
    00.000938       .000938
    00.001611       .002549
    00.001736       .004285
    00.002006       .006291
    00.002049       .00834
    #  | /home/johnh/BIN/DB/dbrow 
    #  | /home/johnh/BIN/DB/dbcol diff
    #  | dbsort diff
    #  | /home/johnh/BIN/DB/dbrowaccumulate diff


=head1 SEE ALSO

L<Fsdb>,
L<dbrowenumerate>.


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
use Fsdb::Support qw($is_numeric_regexp);


=head2 new

    $filter = new Fsdb::Filter::dbrowaccumulate(@arguments);

Create a new dbrowaccumulate object, taking command-line arguments.

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
    $self->{_target_column} = undef;
    $self->{_increment} = undef;
    $self->{_destination_column} = 'accum';
    $self->{_initial_value} = 0;
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
	'c|column=s' => \$self->{_target_column},
	'C|increment=s' => \$self->{_increment},
	'close!' => \$self->{_close},
	'd|debug+' => \$self->{_debug},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'I|initial-value=s' => \$self->{_initial_value},
	'log!' => \$self->{_logprog},
	'N|new-name=s' => \$self->{_destination_column},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	) or pod2usage(2);
    push (@{$self->{_argv}}, @argv);
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup ($) {
    my($self) = @_;

    croak($self->{_prog} . ": neither -c nor -C specified, so nothing to accumulate.\n")
        if (!(defined($self->{_target_column}) || defined($self->{_increment})));
    croak($self->{_prog} . ": both -c nor -C specified, but can't double accumulate.\n")
        if (defined($self->{_target_column}) && defined($self->{_increment}));

    $self->finish_io_option('input', -comment_handler => $self->create_pass_comments_sub);

    if (defined($self->{_target_column})) {
	$self->{_target_coli} = $self->{_in}->col_to_i($self->{_target_column});
	croak($self->{_prog} . ": target column " . $self->{_target_column} . " is not in input stream.\n")
	    if (!defined($self->{_target_coli}));
    };

    # early error detection
    croak($self->{_prog} . ": invalid, non-numeric increment '" . $self->{_increment} . "'\n")
	if (defined($self->{_increment}) && $self->{_increment} !~ /$is_numeric_regexp/);
    croak($self->{_prog} . ": invalid, non-numeric initial value '" . $self->{_initial_value} . "'\n")
	if ($self->{_initial_value} !~ /$is_numeric_regexp/);
	
    $self->finish_io_option('output', -clone => $self->{_in}, -outputheader => 'delay');
    $self->{_out}->col_create($self->{_destination_column})
	or croak($self->{_prog} . ": cannot create column '" . $self->{_destination_column} . "' (maybe it already existed?)\n");
}

=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run ($) {
    my($self) = @_;

    my $read_fastpath_sub = $self->{_in}->fastpath_sub();
    my $write_fastpath_sub = $self->{_out}->fastpath_sub();

    my $accum_coli = $self->{_out}->col_to_i($self->{_destination_column});

    my $pre_set_x_code = '';
    my $loop_set_x_code = '';
    if (defined($self->{_target_coli})) {
	$loop_set_x_code = '$x = $fref->[' . $self->{_target_coli} . '];' .
		'$x = 0 if ($x !~ /$is_numeric_regexp/);';
    } elsif (defined($self->{_increment})) {
	# already sanity checked
	$pre_set_x_code = '$x = ' . $self->{_increment} . ';';
    } else {
	croak("internal error");
    };

    my $initial_accum = defined($self->{_initial_value}) ? $self->{_initial_value} + 0 : 0;
    my $loop_sub;
    my $loop_sub_code = '$loop_sub = sub {
	my $fref;
	my $accum = $initial_accum;
	my $x;
	' . $pre_set_x_code . '
	while ($fref = &$read_fastpath_sub()) {
	    ' . $loop_set_x_code . '
	    $accum += $x;
	    $fref->[' . $accum_coli . '] = $accum;
	    &$write_fastpath_sub($fref);
	};
    };';
    print STDERR $loop_sub_code if ($self->{_debug});
    eval $loop_sub_code;
    $@ && croak($self->{_prog} . ":  internal eval error: $@.\n");
    &$loop_sub();
}


=head1 AUTHOR and COPYRIGHT

Copyright (C) 1991-2018 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
