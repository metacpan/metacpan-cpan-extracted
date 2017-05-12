#!/usr/bin/perl

#
# dbcolrename.pm
# Copyright (C) 1991-2015 by John Heidemann <johnh@isi.edu>
# $Id: ef5f2e367d568155d5b7c0131550d2e76635982c $
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbcolrename;

=head1 NAME

dbcolrename - change the names of columns in a fsdb schema

=head1 SYNOPSIS

dbcolrename OldName1 NewName1 [OldName2 NewName2] ...

=head1 DESCRIPTION

Dbcolrename changes the names of columns in a fsdb schema,
mapping OldName1 to NewName1, and so on for multiple pairs of column names.

Note that it is valid to do "overlapping" renames
like C<dbcolrename a b b a>.

=head1 OPTIONS

No non-standard options.

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

    #fsdb account passwd uid gid fullname homedir shell
    johnh * 2274 134 John_Heidemann /home/johnh /bin/bash
    greg * 2275 134 Greg_Johnson /home/greg /bin/bash
    root * 0 0 Root /root /bin/bash
    # this is a simple database

=head2 Command:

    cat DATA/passwd.fsdb | dbcolrename fullname first_last

=head2 Output:

    #fsdb      account passwd  uid     gid     first_last      homedir shell
    johnh * 2274 134 John_Heidemann /home/johnh /bin/bash
    greg * 2275 134 Greg_Johnson /home/greg /bin/bash
    root * 0 0 Root /root /bin/bash
    # this is a simple database
    #  | dbcolrename fullname first_last


=head1 SEE ALSO

L<Fsdb>.


=head1 CLASS FUNCTIONS

=cut

@ISA = qw(Fsdb::Filter);
($VERSION) = 2.0;

use strict;
use Carp;
use Pod::Usage;

use Fsdb::Filter;
use Fsdb::IO::Reader;
use Fsdb::IO::Writer;


=head2 new

    $filter = new Fsdb::Filter::dbcolrename(@arguments);

Create a new dbcolrename object, taking command-line arguments.

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
#    $self->{_rename_old} = [];
#    $self->{_rename_new} = [];
    $self->{_rename_map} = {};
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
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'log!' => \$self->{_logprog},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	) or pod2usage(2);
    croak $self->{_prog} . ": dbcolrename requires an even number of arguments to do (old,new pairs)\n"
        if ( ($#argv + 1) % 2 != 0);
    while ($#argv >= 1) {
	my($old) = shift @argv;
	my($new) = shift @argv;
#	# preserve ordering to allow concurrent a->b b->a renames
#	push(@{$self->{_rename_old}}, $old);
#	push(@{$self->{_rename_new}}, $new);
	$self->{_rename_map}{$old} = $new;
	# we do error checking in setup
    };
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup ($) {
    my($self) = @_;

    $self->finish_io_option('input', -comment_handler => $self->create_pass_comments_sub);

    my @old_cols = @{$self->{_in}->cols};
    my @new_cols = @old_cols;
    my %cur_cols;  # just for double naming
    foreach (0..$#old_cols) {
	$cur_cols{$old_cols[$_]} = $_;
    };

    foreach (keys %{$self->{_rename_map}}) {
	my ($old) = $_;
	my ($new) = $self->{_rename_map}{$old};
	my $old_i = $self->{_in}->col_to_i($old);
	croak $self->{_prog} . ": column `$old' is not in input stream.\n"
	    if (!defined($old_i));
	croak $self->{_prog} . ": column `$new' already exists in the output stream.\n"
	    if (defined($cur_cols{$new}));
	$new_cols[$old_i] = $new;
	$cur_cols{$new} = $old_i;
    };

    $self->finish_io_option('output', -clone => $self->{_in}, -cols => \@new_cols);
}

=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run ($) {
    my($self) = @_;

    my $read_fastpath_sub = $self->{_in}->fastpath_sub();
    my $write_fastpath_sub = $self->{_out}->fastpath_sub();
    my $fref;
    while ($fref = &$read_fastpath_sub()) {
	&$write_fastpath_sub($fref);
    };

}


=head1 AUTHOR and COPYRIGHT

Copyright (C) 1991-2015 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
