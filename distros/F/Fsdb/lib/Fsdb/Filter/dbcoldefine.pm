#!/usr/bin/perl -w

#
# dbcoldefine.pm
# Copyright (C) 1991-2016 by John Heidemann <johnh@isi.edu>
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbcoldefine;

=head1 NAME

dbcoldefine - define the columns of a plain text file to make it an Fsdb file

=head1 SYNOPSIS

dbcoldefine [-F x] [column...]

=head1 DESCRIPTION

This program writes a new header before the data with the specified column
names.  It does I<not> do any validation of the data contents;
it is up to the user to verify that, other than the header,
the input datastream is a correctly formatted Fsdb file.

=head1 OPTIONS

=over 4

=item B<-F> or B<--fs> or B<--fieldseparator> s

Specify the field separator.

=item B<--header> H

Give the columns and field separator as a full Fsdb header
(including C<#fsdb>).
Can only be used alone, not with other specifications.

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

    102400	4937974.964736
    102400	4585247.875904
    102400	5098141.207123

=head2 Command:

    cat DATA/http_bandwidth | dbcoldefine size bw

=head2 Output:

    #fsdb size bw
    102400	4937974.964736
    102400	4585247.875904
    102400	5098141.207123
    # | dbcoldefine size bw

=head1 SEE ALSO

L<Fsdb>.
L<dbfilestripcomments>

=head1 CLASS FUNCTIONS

=cut

@ISA = qw(Fsdb::Filter);
($VERSION) = 2.0;

use strict;
use Pod::Usage;
use Carp;

use Fsdb::Filter;
use Fsdb::IO::Writer;


=head2 new

    $filter = new Fsdb::Filter::dbcoldefine(@arguments);

Create a new dbcoldefine object, taking command-line arguments.

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
    $self->{_fscode} = 'D';
    $self->{_cols} = [];
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
	'd|debug+' => \$self->{_debug},
	'F|fs|fieldseparator|columnseparator=s' => \$self->{_fscode},
	'header=s' => \$self->{_header},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'log!' => \$self->{_logprog},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	) or pod2usage(2);
    push (@{$self->{_cols}}, @argv);
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup ($) {
    my($self) = @_;

    my(@finish_args) = (-comment_handler => $self->create_pass_comments_sub);
    if (!defined($self->{_header}) && $#{$self->{_cols}} == -1) {
        croak $self->{_prog} . ": must specify either --header or columns.\n";
    } elsif (defined($self->{_header}) && $#{$self->{_cols}} == -1) {
	push(@finish_args, -header => $self->{_header});
    } elsif (!defined($self->{_header}) && $#{$self->{_cols}} > -1) {
	push(@finish_args, -fscode => $self->{_fscode}, -cols => $self->{_cols});
    } else {
        croak $self->{_prog} . ": cannot specific both --header and columns.\n";
    };
    

    # all the hard work is on the next line where we force the right codes
    $self->finish_io_option('input', @finish_args);

    $self->finish_io_option('output', -clone => $self->{_in});
}

=head2 run

    $filter->run();

Internal: run over each rows.

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

=head1 AUTHOR and COPYRIGHT

Copyright (C) 1991-2016 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
