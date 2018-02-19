#!/usr/bin/perl -w

#
# dbcolcopylast.pm
# Copyright (C) 1991-2018 by John Heidemann <johnh@isi.edu>
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbcolcopylast;

=head1 NAME

dbcolcopylast - create new columns that are copies of prior columns

=head1 SYNOPSIS

    dbcolcopylast [-e EMPTY] [column...]


=head1 DESCRIPTION

For each COLUMN, create a new column copylast_COLUMN
that is the last value for that column---that is,
the value of that column from the row before.


=head1 OPTIONS

=over 4

=item B<-e> EmptyValue or B<--empty>

Specify the value newly created columns get.

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

    #fsdb test
    a
    b

=head2 Command:

    cat data.fsdb | dbcolcopylast foo 

=head2 Output:

    #fsdb      test    foo
    a       -
    b       -


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


=head2 new

    $filter = new Fsdb::Filter::dbcolcopylast(@arguments);

Create a new dbcolcopylast object, taking command-line arguments.

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
    $self->{_copy_cols} = [];
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
	'e|empty=s' => \$self->{_empty},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'log!' => \$self->{_logprog},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	) or pod2usage(2);
    push (@{$self->{_copy_cols}}, @argv);
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup ($) {
    my($self) = @_;

    $self->finish_io_option('input', -comment_handler => $self->create_pass_comments_sub);
    $self->finish_io_option('output', -clone => $self->{_in}, -outputheader => 'delay');

    my $init_code = '';
    my $copy_code = '';
    foreach (@{$self->{_copy_cols}}) {
	my($source_coli) = $self->{_in}->col_to_i($_);
	croak($self->{_prog} . ": attempt to copy non-existing column $_.\n")
	    if (!defined($source_coli));

	my($dest_col) = "copylast_" . $_;
	$self->{_out}->col_create($dest_col)
	    or croak($self->{_prog} . ": cannot create column '$dest_col' (maybe it already existed?)\n");
	my($dest_coli) = $self->{_out}->col_to_i($dest_col);

	$init_code .= '$lfref->[' . $source_coli . '] = $empty;' . "\n";
	$copy_code .= '$fref->[' . $dest_coli . '] = $lfref->[' . $source_coli . '];' . "\n";
    };
    
    #
    # write the loop
    #
    {
	my $loop_sub;
	my $read_fastpath_sub = $self->{_in}->fastpath_sub();
	my $write_fastpath_sub = $self->{_out}->fastpath_sub();
	my $empty = $self->{_empty};
	my $loop_sub_code = q'
	    $loop_sub = sub {
		my $fref;
		my $lfref;
		' . $init_code . q'
		while ($fref = &$read_fastpath_sub()) {
		' . $copy_code . q'
		    &$write_fastpath_sub($fref);
		    $lfref = $fref;  # save for next pass
		};
	    };
	';
	print $loop_sub_code if ($self->{_debug});
	eval $loop_sub_code;
	$@ && croak($self->{_prog} . ":  internal eval error: $@.\n");
	$self->{_loop_sub} = $loop_sub;
    }
}


=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run ($) {
    my($self) = @_;
    &{$self->{_loop_sub}}();
}


=head1 AUTHOR and COPYRIGHT

Copyright (C) 1991-2018 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
