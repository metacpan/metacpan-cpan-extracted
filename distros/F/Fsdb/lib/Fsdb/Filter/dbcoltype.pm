#!/usr/bin/perl -w

#
# dbcoltype.pm
# Copyright (C) 2022 by John Heidemann <johnh@isi.edu>
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbcoltype;

=head1 NAME

dbcoltype - define (or redefine) types for columns of an Fsdb file

=head1 SYNOPSIS

dbcol [-v] [column type...]

=head1 DESCRIPTION

Define the type of each column, where COLUMN and TYPE are pairs.
Or, with the C<-v> option, redefine all types as string.

The data does not change (just the header).

=head1 OPTIONS

=over 4

=item B<-v> or B<--clear-types>

Remove definitions from columns that are listed,
or from all columns if none are listed.
The effect is to restore types to their default type of "a" (string).

=back

=for comment
begin_standard_fsdb_options

and the standard fsdb options:

=over 4

=item B<-d>

Enable debugging output.

=item B<-i> or B<--input> InputSource

Read from InputSource, typically a file, or - for standard input,
or (if in Perl) a IO::Handle, Fsdb::IO or Fsdb::BoundedQueue objects.

=item B<-o> or B<--output> OutputDestination

Write to OutputDestination, typically a file, or - for standard output,
or (if in Perl) a IO::Handle, Fsdb::IO or Fsdb::BoundedQueue objects.

=item B<--autorun> or B<--noautorun>

By default, programs process automatically,
but Fsdb::Filter objects in Perl do not run until you invoke
the run() method.
The C<--(no)autorun> option controls that behavior within Perl.

=item B<--header> H

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

    #fsdb account passwd uid gid fullname homedir shell
    johnh * 2274 134 John_Heidemann /home/johnh /bin/bash
    greg * 2275 134 Greg_Johnson /home/greg /bin/bash
    root * 0 0 Root /root /bin/bash
    # this is a simple database

=head2 Command:

    cat DATA/passwd.fsdb account | dbcoltype uid l gid l

=head2 Output:

    #fsdb account passwd uid:l gid:l fullname homedir shell
    johnh * 2274 134 John_Heidemann /home/johnh /bin/bash
    greg * 2275 134 Greg_Johnson /home/greg /bin/bash
    root * 0 0 Root /root /bin/bash
    # this is a simple database


=head1 SEE ALSO

L<dbcoldefine(1)>,
L<dbcolcreate(1)>,
L<Fsdb(3)>.


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


=head2 new

    $filter = new Fsdb::Filter::dbcoltype(@arguments);

Create a new dbcoltype object, taking command-line arguments.

=cut

sub new {
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
    $self->{_clear_types} = undef;
    $self->{_header} = undef;
}

=head2 parse_options

    $filter->parse_options(@ARGV);

Internal: parse options

=cut

sub parse_options ($@) {
    my $self = shift @_;

    my(@arg_cols) = @_;
    $self->get_options(
	\@arg_cols,
 	'help|?' => sub { pod2usage(1); },
	'man' => sub { pod2usage(-verbose => 2); },
	'autorun!' => \$self->{_autorun},
	'close!' => \$self->{_close},
	'd|debug+' => \$self->{_debug},
	'header=s' => \$self->{_header},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'log!' => \$self->{_logprog},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
        'v|clear-types!' => \$self->{_clear_types}
	) or pod2usage(2);
    push (@{$self->{_arg_cols}}, @arg_cols);
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup ($) {
    my($self) = @_;

    croak($self->{_prog} . ": must either clear all types with -v (invert) or list columsn and types.\n")
        if (!defined($self->{_clear_types}) && $#{$self->{_arg_cols}} == -1);

    my(@in_options) = (-comment_handler => $self->create_pass_comments_sub);
    push(@in_options, -header => $self->{_header}) if (defined($self->{_header}));
    $self->finish_io_option('input', @in_options);

    # parse arguments
    my %new_types = ();
    my($n, $i);
    my(@arg_cols) = @{$self->{_arg_cols}};
    while ($#arg_cols > -1) {
        $n = shift @arg_cols;
        my($nt) = '';
        if (!defined($self->{_clear_types})) {
            croak($self->{_prog} . ": column $n with missing type.\n")
                if ($#arg_cols == -1);
            $nt = shift @arg_cols;
        };
	$i = $self->{_in}->col_to_i($n);
	croak($self->{_prog} . ":  unknown column ``$_''.\n")
            if (!defined($i));
        $new_types{$i} = $nt;  # note we index by $i not $n! (so the user can specify columns by name or index
    };

    # setup new types
    my @colspecs = ();
    my $cols_ref = $self->{_in}->cols();
    if (defined($self->{_clear_types}) && $#{$self->{_arg_cols}} == -1) {
        # clear all types
        @colspecs = @$cols_ref;
    } else {
        # set or clear some types
        foreach $n (@$cols_ref) {
            $i = $self->{_in}->col_to_i($n);
            my($cs) = $self->{_in}->col_to_colspec($n);
            if (defined($new_types{$i})) {
                my($nt) = $new_types{$i};
                $cs = $self->{_in}->col_to_name($i) . ($nt ne '' ? ":" . $nt : '');
            };
            push(@colspecs, $cs);
        };
    };

    #
    # setup output
    #
    $self->finish_io_option('output', -clone => $self->{_in}, -cols => \@colspecs);
}

=head2 run

    $filter->run();

Internal: run over all data rows.

=cut
sub run ($) {
    my($self) = @_;
    # can't get any easier than this
    my $read_fastpath_sub = $self->{_in}->fastpath_sub();
    my $write_fastpath_sub = $self->{_out}->fastpath_sub();
    my $fref;
    while ($fref = &$read_fastpath_sub()) {
	&$write_fastpath_sub($fref);
    };
}

=head2 finish

    $filter->finish();

Internal: write trailer.

=cut
sub finish ($) {
    my($self) = @_;

    $self->SUPER::finish();
}

=head1 AUTHOR and COPYRIGHT

Copyright (C) 2022 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;

