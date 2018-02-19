#!/usr/bin/perl -w

#
# dbcol.pm
# Copyright (C) 1991-2018 by John Heidemann <johnh@isi.edu>
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbcol;

=head1 NAME

dbcol - select columns from an Fsdb file

=head1 SYNOPSIS

dbcol [-v] [-e -] [column...]

=head1 DESCRIPTION

Select one or more columns from the input database.
If a value is given for empty columns with the -e option,
then any named columns which don't exist will be created.
Otherwise, non-existent columns are an error.

Note:  a safer way to create columns is dbcolcreate.

=head1 OPTIONS

=over 4

=item B<-r> or B<--relaxed-errors>

Relaxed error checking: ignore columns that aren't there.

=item B<-v> or B<--invert-match>

Output all columns except those listed (like grep -v).

=item B<-e> EmptyValue or B<--empty>

Specify the value newly created columns get.

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

    cat DATA/passwd.fsdb account | dbcol account

=head2 Output:

    #fsdb      account
    johnh
    greg
    root
    # this is a simple database
    #  | dbcol account


=head1 SEE ALSO

L<dbcolcreate(1)>,
L<Fsdb(3)>

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

    $filter = new Fsdb::Filter::dbcol(@arguments);

Create a new dbcol object, taking command-line arguments.

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
    $self->{_null_value} = undef;
    $self->{_invert_match} = undef;
    $self->{_relaxed_errors} = undef;
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
 	'e|empty=s' => \$self->{_null_value},
	'header=s' => \$self->{_header},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'log!' => \$self->{_logprog},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	'r|relaxed-errors!' => \$self->{_relaxed_errors},
        'v|invert-match!' => \$self->{_invert_match}
	) or pod2usage(2);
    push (@{$self->{_arg_cols}}, @arg_cols);
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup ($) {
    my($self) = @_;

    my(@in_options) = (-comment_handler => $self->create_pass_comments_sub);
    push(@in_options, -header => $self->{_header}) if (defined($self->{_header}));
    $self->finish_io_option('input', @in_options);
    my $read_fastpath_sub = $self->{_in}->fastpath_sub();

    my @new_arg_cols = ();
    if ($self->{_invert_match}) {
	my %bad_cols;
	foreach (@{$self->{_arg_cols}}) {
	    my($badf) = $self->{_in}->col_to_i($_);
	    if (!defined($badf)) {
		croak($self->{_prog} . ":  unknown column ``$_'' for omission.\n")
		    if (!$self->{_relaxed_errors});
		# skip it if relaxed
		next;
	    };
	    my($badn) = $self->{_in}->i_to_col($badf);
	    $bad_cols{$badn} = 1;
	};
	# rebuild list from survivors
	foreach (@{$self->{_in}->cols}) {
	    push(@new_arg_cols, $_) if (!$bad_cols{$_});
	};
    } else {
        # convert any numeric colnames to names
	foreach (@{$self->{_arg_cols}}) {
	    push(@new_arg_cols, defined($self->{_in}->col_to_i($_)) ?
			$self->{_in}->i_to_col($self->{_in}->col_to_i($_)) :
			$_);
	};
    };
    @{$self->{_arg_cols}} = @new_arg_cols;

    #
    # setup conversion
    #
    my($copy_code) = "";
    my(%new_colnames);
    for my $out_coli (0..$#{$self->{_arg_cols}}) {
	my $colname = $self->{_arg_cols}[$out_coli];
	croak($self->{_prog} . ":  duplicate colname $colname\n")
	    if (defined($new_colnames{$colname}));
	$new_colnames{$colname} = $out_coli;
	my $in_coli = $self->{_in}->col_to_i($colname);
	if (defined($in_coli)) {
	    $copy_code .= '$nf['.$out_coli.'] = $fref->['.$in_coli.'];' . "\n";
	} elsif (!defined($self->{_null_value})) {
	    croak ($self->{_prog} . ":  creating new column ``$colname'' without specifying null value.\n");
	} else {
	    $copy_code .= '$nf['.$out_coli."] = '" . $self->{_null_value} . "';\n";
	};
    };

    #
    # setup output
    #
    $self->finish_io_option('output', -clone => $self->{_in}, -cols => \@{$self->{_arg_cols}});
    my $write_fastpath_sub = $self->{_out}->fastpath_sub();

    #
    # write the loop
    #
    # Since perl5 doesn't cache eval, eval the whole loop.
    #
    # This is very hairy.  Use the eval to pull in the copy code,
    # and wrap it in an anon subroutine that we store away.
    # We have to do all this HERE, rather than in run,	
    # because $read_fastpath_sub is local to here.
    #
    {
	my $loop_sub;
	my $loop_sub_code =  q'
	    $loop_sub = sub {
		my $fref;
		my @nf;
		while ($fref = &$read_fastpath_sub()) {
	    ' . $copy_code . q'
		    &$write_fastpath_sub(\@nf);
		};
	    };
        ';
	eval $loop_sub_code;
	$@ && croak($self->{_prog} . ":  internal eval error: $@.\n");
	$self->{_loop_sub} = $loop_sub;
    }
}

=head2 run

    $filter->run();

Internal: run over all data rows.

=cut
sub run ($) {
    my($self) = @_;
    &{$self->{_loop_sub}}();
}

=head2 finish

    $filter->finish();

Internal: write trailer.

=cut
sub finish ($) {
    my($self) = @_;

    $self->{_out}->write_comment($self->{_prog} . "\'s code: " . code_prettify($self->{_loop_code}))
	if ($self->{_debug});
    $self->SUPER::finish();
}

=head1 AUTHOR and COPYRIGHT

Copyright (C) 1991-2018 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;

