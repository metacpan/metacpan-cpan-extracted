#!/usr/bin/perl -w

#
# dbcolcreate.pm
# Copyright (C) 1991-2022 by John Heidemann <johnh@isi.edu>
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbcolcreate;

=head1 NAME

dbcolcreate - create new columns

=head1 SYNOPSIS

    dbcolcreate NewColumn1 [NewColumn2]

or

    dbcolcreate -e DefaultValue NewColumnWithDefault

=head1 DESCRIPTION

Create columns C<NewColumn1>, etc.
with an optional C<DefaultValue>.


=head1 OPTIONS

=over 4

=item B<-e> EmptyValue or B<--empty>

Specify the value newly created columns get.

=item B<-f> or B<--first>

Put all new columns as the first columns of each row.
By default, they go at the end of each row.

=item B<--no-recreate-fatal>

By default, creating an existing column is an error.
With B<--no-recreate-fatal>, we ignore re-creation.

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

    #fsdb test
    a
    b

=head2 Command:

    cat data.fsdb | dbcolcreate foo 

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

    $filter = new Fsdb::Filter::dbcolcreate(@arguments);

Create a new dbcolcreate object, taking command-line arguments.

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
    $self->{_creations} = [];
    $self->{_first} = undef;
    $self->{_create_values} = {};
    $self->{_recreate_fatal} = 1;
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
	'e|empty=s' => \$self->{_empty},
	'f|first!' => \$self->{_first},
	'header=s' => \$self->{_header},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'recreate-fatal!' => \$self->{_recreate_fatal},
	'log!' => \$self->{_logprog},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	'<>' => sub { 
	    my($target) = @_;
	    if ($target eq '-') {
		warn "dbcolcreate: appear to be using fsdb-1 dual argument syntax.  Replace \"NewCol DefaultValue\" with \"-e DefaultValue NewCol\".\n";
		return;
	    };
	    push(@{$self->{_creations}}, $target);
	    $self->{_create_values}{$target} = $self->{_empty};
	},
	) or pod2usage(2);
    pod2usage(2) if ($#argv != -1);
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup ($) {
    my($self) = @_;

    croak($self->{_prog} . ": no new columns to create.\n")
	if ($#{$self->{_creations}} == -1);

    my(@in_options) = (-comment_handler => $self->create_pass_comments_sub);
    push(@in_options, -header => $self->{_header}) if (defined($self->{_header}));
    $self->finish_io_option('input', @in_options);

    my @new_cols = ( $self->{_in}->colspecs() );
    my %existing_cols;
    foreach (@new_cols) {
	$existing_cols{$_} = 1;
    };
    my $coli = ($self->{_first} ? 0 : $#new_cols);
    my $insert_args = '';
    foreach (@{$self->{_creations}}) {
	if (defined($existing_cols{$_})) {
	    next if (!$self->{_recreate_fatal});
	    croak($self->{_prog} . ": attempt to create pre-existing column $_.\n");
	};
	$coli++;
	if ($self->{_first}) {
	    unshift @new_cols, $_;
	} else {
	    push @new_cols, $_;
	};
	$existing_cols{$_} = 2;
	my $val = $self->{_create_values}{$_};
	my $quote = "'";
	if ($val =~ /\'/) {
	    $quote = '|';
	    croak($self->{_prog} . ": internal error: cannot find reasonable way to do quoting.\n")
		if ($val =~ /\|/);
	};
	$insert_args .= "\t\t, q" . $quote . $val . $quote . "\n";
    };
    my $insert_code = "\t" . ($self->{_first} ? "unshift" : "push") . '(@$fref' . $insert_args . ");\n";
    #
    # A fun case, exercised by TEST/dbmapreduce_dbrowenumerate.cmd:
    #
    # IF we are invoked with --no-recreate-fatal
    # AND the column we're creating already exists,
    # THEN we end up with  nothing to create.
    # The result is this obscure warning:
    # Useless use of unshift with no values at (eval 37) line 5, <GEN9> line 1.
    #
    # To fix that case, we turn ourselves into a pass-through loop.
    #
    $insert_code = '' if ($insert_args eq '');

    $self->finish_io_option('output', -clone => $self->{_in}, -cols => \@new_cols);
    
    #
    # write the loop
    #
    {
	my $loop_sub;
	my $read_fastpath_sub = $self->{_in}->fastpath_sub();
	my $write_fastpath_sub = $self->{_out}->fastpath_sub();
	my $loop_sub_code = q'
	    $loop_sub = sub {
		my $fref;
		while ($fref = &$read_fastpath_sub()) {
		' . $insert_code . q'
		    &$write_fastpath_sub($fref);
		};
	    };
	';
	eval $loop_sub_code;
	$@ && croak( $self->{_prog} . ":  internal eval error: $@.\n");
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

Copyright (C) 1991-2022 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
