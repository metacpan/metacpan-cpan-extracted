#!/usr/bin/perl -w

#
# Filter.pm
# $Id: 7843a6bb9a62b736e670fcf61fdb3e66994cf79f $
#
# Copyright (C) 2007-2008 by John Heidemann <johnh@isi.edu>
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# version 2, as published by the Free Software Foundation.
# 
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License along
# with this program; if not, write to the Free Software Foundation, Inc.,
# 51 Franklin Street, Fifth Floor, Boston, MA 02110-1301, USA.
#


package Fsdb::Filter;

=head1 NAME

Fsdb::Filter - base class for Fsdb filters

=head1 DESCRIPTION

Fsdb::Filter is the virtual base class for Fsdb filters.

Users will typically invoke individual programs via the command line
(for example, see L<dbcol(1)>)
or string together several in a Perl program
as described in L<dbpipeline(3)>.

For new Filter developers, internal processing is:

    new
	set_defaults
	parse_options
	autorun if desired
    parse_options   # optionally called additional times
    setup           # does IO on header
    run             # does IO on data
    finish          # any shutdown

In addition, the C<info> method returns metadata about a given filter.

=head1 FUNCTIONS

=cut

@ISA = ();
($VERSION) = 1.0;

use strict;
use 5.010;
use Carp qw(carp croak);
use IO::Handle;
use IO::File;
use Getopt::Long qw(GetOptionsFromArray :config no_ignore_case bundling permute);

use Fsdb::IO::Reader;
use Fsdb::IO::Writer;
use Fsdb::Support;
use Fsdb::Support::DelayPassComments;

=head2 new

    $fsdb = new Fsdb::Filter;

Create a new filter object, calling set_defaults
and parse_options.  A user program will call a specific
filter (say Fsdb::Filter::dbcol) to do processing.
See also L<dbpipeline> for aliases that remove the wordiness.

=cut

sub new {
    my ($class) = @_;
    my $self = bless {}, $class;
    $self->set_defaults;
    return $self;
}

=head2 post_new

    $filter->post_new();

Called when the subclass is done with new,
giving Fsdb::Filter a chance to autorun.

=cut

sub post_new {
    my $self = shift @_;
    $self->setup_run_finish()
        if ($self->{_autorun});
}


=head2 set_defaults

    $filter->set_defaults();

Set up object defaults.
Called once during new.

Fsdb::Filter::set_defaults does some general setup,
tracking module invocation and preparing for one input and output stream.


=cut

sub set_defaults ($) {
    my $self = shift @_;

    # see the info() method for documentation
    $self->{_info} = {
	input_type => 'fsdb*',
	input_count => 1,
	output_type => 'fsdb*',
	output_count => 1,
    };

    my($package, $filename, $line) = caller(1);
    $filename =~ s@^.*/@@g;   # strip junk
    $filename =~ s@\.pm$@@;   # strip junk
    $self->{_prog} = $filename;
    $self->{_orig_argv} = undef;
    $self->{_logprog} = 1;
    $self->{_close} = 1;
    $self->{_save_output} = undef;
    $self->{_empty} = '-';

    $self->{_debug} = 0;
    $self->{_error} = undef;

    # Fsdb::IO objects
    $self->{_in} = undef;
    $self->{_out} = undef;
    # filehandles or Fsdb::BoundedQueue:
    #
    # These next two lines cause obnoxious warnings in some versions
    #    $self->{_input} = \*STDIN;
    #    $self->{_output} = \*STDOUT;
    # of perl.  in 5.10.1:
    #
    # Unbalanced string table refcount: (2) for "blib/script/dbjoin" during global destruction.
    # Unbalanced string table refcount: (1) for "STDOUT" during global destruction.
    # Unbalanced string table refcount: (1) for "STDIN" during global destruction.
    # Scalars leaked: 2
    # Unbalanced string table refcount: (2) for "blib/script/dbjoin" during global destruction.
    # Unbalanced string table refcount: (1) for "STDOUT" during global destruction.
    # Unbalanced string table refcount: (1) for "STDIN" during global destruction.
    # Scalars leaked: 2
    #
    # fix: switch to magic variables '-' and catch them later in finish_fh_io_option.
    #
    $self->{_input} = '-';
    $self->{_output} = '-';

    $self->{_autorun} = undef;
};

=head2 set_default_tmpdir

    $filter->set_default_tmpdir

Figure out a tmpdir, from environment variables if necessary.

=cut

sub set_default_tmpdir($;$) {
    my $self = shift @_;

    foreach ($_[0], $ENV{'TMPDIR'}, "/tmp") {
	if (defined($_)) {
	    $self->{_tmpdir} = $_;
	    return;
        };
    };
    die "internal error in set_default_tmpdir";
}

=head2 parse_options

    $filter->parse_options(@ARGV);

Parse_options is called one I<or more> times to parse ARGV-style options.
It should not do any IO or any irreverssable actions; defer those to startup.

Fsdb::Filter::parse_options does no work; the subclass is expected
to call Fsdb::Filter::get_options() for all arguments.

Most modules implement certain common fsdb options, listed below.

=for comment
(Note that this text in Fsdb::Filter.pm is the master copy,
replicated in to all the module.pm files via C<make standardoptions>.)

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

=item B<--noclose>

By default, programs close their output when done.
For some cases where objects are used internally, C<--noclose>
may be used to leave output open for further I/O.
(This option is only supported by some filters.)

=item B<--saveoutput $OUT_REF>

By default, programs close their output when done.
With this option, programs in Perl can have a subprogram create
an output refrence and return it to the caller in C<$OUT_REF>.
The caller can then use it for further I/O.
(This option is only supported by some filters.)

=item B<--help>

Show help.

=item B<--man>

Show full manual.

=back

=for comment
end_standard_fsdb_options


=cut

sub parse_options ($@) {
    my $self = shift @_;
    die "Fsdb:Filter: we expect the subprogram to handle parse_options.\n";
}

=head2 parse_target_column

    $self->parse_target_column(\@argv);

A helper function: allow one column to be specified as the C<_target_column>.

=cut

sub parse_target_column($$) {
    my($self, $argv_ref) = @_;

    if ($#{$argv_ref} > 0 || $#{$argv_ref} == 0 && defined($self->{_target_column})) {
	# xxx: next line is "die" because with perl v5.8.8,
	# I get this error message with croak:
	# Bizarre copy of HASH in sassign at /usr/lib/perl5/5.8.8/Carp/Heavy.pm line 45.
	die $self->{_prog} . ": cannot specify multiple columns\n";
    } elsif ($#{$argv_ref} == 0) {
	$self->{_target_column} = $argv_ref->[0];
    };
}

=head2 get_options

    $success = $filter->get_options(\@argv, "v+" => \$verbose, ...)

get_options is just like Getopt::Long's GetOptions,
but takes the argument list as the first argument.
This list is modified and any non-options are returned.
It also saves _orig_argv in itself.

=cut

sub get_options($$@) {
    my $self = shift @_;
    my $argv_ref = shift @_;
    my @opt_specs = @_;
    # hacky interface to GetOptions, we have to copy to and from ARGV
    foreach my $p (@$argv_ref) {
	my $p_copy = $p;
	if (ref($p_copy) =~ /\:\:/) {
	    # remove the internal memory cruft for internal perl objects
	    $p_copy = ref($p_copy);
	    $p_copy =~ s/\=.*$//;
	    $p_copy = "::FsdbIPC" if ($p_copy =~ /^(Fsdb::BoundedQueue|IO::Pipe)/);
	    $p_copy = "[$p_copy]";
        };
	push (@{$self->{_orig_argv}}, $p_copy);
    };
    my $result = GetOptionsFromArray($argv_ref, @opt_specs);
    return $result;
}

=head2 parse_sort_option

    $fsdb_io = $filter->parse_sort_option($option_name, $target);

This helper function handles sorting options and column names
as described in L<dbsort(1)>.  We normalize long sort options
to unbundled short options
and accumulate them in $self->{_sort_argv}.

=cut

sub parse_sort_option ($$$) {
    my $self = shift @_;
    my ($option_name, $target) = @_;

    my $sort_aref = $self->{_sort_argv};
    if ($option_name eq '<>') {
	push (@$sort_aref, $target);
    } elsif ($option_name eq 'n' || $option_name eq 'numeric') {
	push (@$sort_aref, '-n');
    } elsif ($option_name eq 'N' || $option_name eq 'lexical') {
	push (@$sort_aref, '-N');
    } elsif ($option_name eq 't' || $option_name eq 'type-inferred-sorting') {
	push (@$sort_aref, '-t');
    } elsif ($option_name eq 'r' || $option_name eq 'descending') {
	push (@$sort_aref, '-r');
    } elsif ($option_name eq 'R' || $option_name eq 'descending') {
	push (@$sort_aref, '-R');
    } else {
	croak "parse_sort_option: unknown option $option_name for target $target\n";
    };
}



=head2 parse_io_option

    $fsdb_io = $filter->parse_io_option($io_direction, $option_name, $target);

This helper function handles C<--input> or C<--output> options,
without doing any setup.

It fills in $self->{_$IO_DIRECTION} with the resulting object,
which is either a file handle or Fsdb::Filter::Piepline object,
and expects C<finish_io_option> to convert
this token into a full Fsdb::IO object.

$IO_DIRECTION is usually input or output, but it can also be inputs
(with an "s") when multiple input sources are allowed.

=cut

sub parse_io_option ($$$$) {
    my $self = shift @_;
    my $direction = shift @_;
    my $option_name = shift @_;
    # Next line wackiness: perl-5.10's Getopt::Long passes an object, not a
    # string, so force it to be a string.
    $option_name = "$option_name" if (ref($option_name));
    my $target = shift @_;
    $target = $option_name if (!defined($target));  # xxx: sometimes we seem to loose an argument (bug in Getopt::Long?)

    my($mode) = $direction eq 'output' ? "w" : "r";

    my $token = $target;

    if ($direction eq 'input' || $direction eq 'output') {
        $self->{"_$direction"} = $token;
    } elsif ($direction eq 'inputs' || $direction eq 'outputs') {
        push (@{$self->{"_$direction"}}, $token);
    } else {
	croak "internal error: bad direction";
    };
}


=head2 finish_one_io_option

    $fsdb_io = $filter->finish_io_option($io_direction, $token, @fsdb_args);

This helper function 
finishes setting up a Fsdb::IO object in $IO_DIRECTION,
using $TOKEN as information.
using @FSDB_ARGS as parameters.
It creates the actual Fsdb::IO objects, opens the files (or whatever),
and reads the headers.
It returns the $FSDB_IO option.

$IO_DIRECTION must be "input" or "output".

Since it does IO, finish_io_option should only be called from setup,
not parse_options.

Can be called once per IO stream.

=cut

sub finish_one_io_option ($$$@) {
    my $self = shift @_;
    my $direction = shift @_;
    my $token = shift @_;

    my $fsdb;
    # fast return a raw fh, if that's an option (-raw_fh=>1 in @fsdb_args)
    if ($#_ >= 1 && $_[0] eq '-raw_fh' && $_[1]) {
	return $token;
    };
    if (ref($token) =~ /^Fsdb::IO/) {
	# assume the user gave us a good one
	$fsdb = $token;
    } else {
	my $token_ref = ref($token);
	my $token_type = undef;
	if ($token_ref =~ /^Fsdb::BoundedQueue/) {
	    $token_type = '-queue';
	} elsif ($token_ref =~ /^IO::/) {
	    $token_type = '-fh';
	} elsif ($token_ref eq '' && $token eq '-') {
	    $token_type = '-file';
	} elsif ($token_ref eq '' && $token =~ /^\*main/) {
	    $token_type = '-fh';
	} elsif ($token_ref eq '') {
	    $token_type = '-file';   # assume filename
	} else {
	    croak "unknown token type in Fsdb::Filter::finish_one_io_option\n";
	};
	if ($direction eq 'input') {
	    $fsdb = new Fsdb::IO::Reader($token_type => $token, @_);
	} elsif ($direction eq 'output') {
	    $fsdb = new Fsdb::IO::Writer($token_type => $token, @_);
	} else {
	    croak "unknown direction in Fsdb::Filter::finish_one_io_option\n";	};
    };
    # Next line is die, not croak, because croak always appends line number.
    $fsdb->error and die $self->{_prog} . ": cannot open $direction: " . $fsdb->error . "\n";
    return $fsdb;
}

=head2 finish_io_option

    $filter->finish_io_option($io_direction, @fsdb_args);

This helper function 
finishes setting up a Fsdb::IO object in $IO_DIRECTION,
using @FSDB_ARGS as parameters.
It creates the actual Fsdb::IO objects, opens the files (or whatever),
and reads the headers.
the resulting Fsdb::IO objects are 
built from C<$self->{_$IO_DIRECTION}>
and are left in C<$self->{_in}> or (C<_out> or C<@_ins>).

$IO_DIRECTION must be "input", "inputs" or "output".

Since it does IO, finish_io_option should only be called from setup,
not parse_options.

Can be called once per IO stream.

No return value.

=cut

sub finish_io_option ($$@) {
    my $self = shift @_;
    my $direction = shift @_;

    # special case multiple inputs
    if ($direction eq 'inputs') {
	my $token;
	foreach $token (@{$self->{_inputs}}) {
	    my $in = $self->finish_one_io_option('input', $token, @_);
	    push @{$self->{_ins}}, $in;
        };
	return;
    };

    # single
    my $fsdb = $self->finish_one_io_option($direction, $self->{"_$direction"}, @_);
    $self->{($direction eq 'input' ? '_in' : '_out')} = $fsdb;
}

=head2 direction_to_stdio

    $fh = direction_to_stdio($direction)

Private internal routing.  Give a filehandle for STDIN or
STDOUT based on $DIRECTION == 'input or 'output'

=cut

sub direction_to_stdio($;$){ # private
    my($direction, $encoding) = @_;
    my $fh = new IO::Handle;
    if ($direction eq 'input') {
	$fh = $fh->fdopen(fileno(STDIN), "r");
    } elsif ($direction eq 'output') {
	$fh = $fh->fdopen(fileno(STDOUT), "w");
    } else {
	croak "bad direction";
    };
    $encoding = ":utf8" if (!defined($encoding));
    binmode $fh, $encoding;
    return $fh;
}


=head2 finish_fh_io_option

    $filter->finish_fh_io_option($io_direction);

This helper function 
creates a filehandle in $IO_DIRECTION.
Compare to finish_io_option which creates a Fsdb::IO object.
It creates the actual IO::File objects, opens the files (or whatever).
The filehandle is 
built from C<$self->{_$IO_DIRECTION}>
and are left in C<$self->{_in}> or (C<_out>).

$IO_DIRECTION must be "input" or "output".

This function does no IO.

No return value.

=cut

sub finish_fh_io_option ($$;$) {
    my($self, $direction, $encoding) = @_;
    croak "finish_fh_io_option: bad direction $direction\n"
	if (!($direction eq 'input' || $direction eq 'output'));
    my $token = $self->{"_$direction"};

    my $fh;
    if (ref($token) =~ /^Fsdb::IO/) {
	croak "finish_fh_io_option: expected IO::Handle but got Fsdb::IO object.\n";
    } elsif (ref($token) =~ /^Fsdb::BoundedQueue/) {
	croak "finish_fh_io_option: doesn't currently handle Fsdb::BoundedQueue objects.\n";
    } elsif (ref($token) =~ /^IO::/) {
	# assume we got a good one passed in
	$fh = $token;
    } elsif (ref($token) eq '') {
	# (ref($token) == '' if $token == *main::STDIN or $token eq '-'
	if ($token eq '-') {
	    $fh = direction_to_stdio($direction, $encoding);
	} else {
	    # assume it's a glob to a filehandle
	    $fh = $token;
	};
    } else {
	$fh = new IO::File($token, ($direction eq 'input' ? 'r' : 'w'));
	$encoding = ":utf8" if (!defined($encoding));
	binmode $fh, $encoding;
    };

    $self->{($direction eq 'input' ? '_in' : '_out')} = $fh;
}

=head2 setup

    $filter->setup();

Do any setup that requires minimal IO
(for example, reading and parsing headers).

Called exactly once.

=cut

sub setup ($) {
    my $self = shift @_;
    die "Fsdb:Filter: we expect the subprogram to handle setup.\n";
}

=head2 run

    $filter->run();

Execute the body, typically iterating over the input rows.

Called exactly once.

=cut

sub run ($) {
    my $self = shift @_;
    die "Fsdb:Filter: we expect the subprogram to handle run.\n";
}

=head2 compute_program_log

    $log = $filter->figure_program_log();

Compute and return the log entry for a program.

=cut

sub compute_program_log($) {
    my $self = shift @_;

    my $args = '';
    # most refs were cleaned in Fsdb::Filter::get_options
    if (defined($self->{_orig_argv}) && $#{$self->{_orig_argv}} != -1) {
       foreach (@{$self->{_orig_argv}}) {
	    if (ref($_) eq 'CODE') {
		$args .= " [ANONYMOUS-CODE]";
	    } else {
		$args .= " " . Fsdb::Support::shell_quote($_);
	    };
       };
    };
    my $log = "";
    $log = "  | " . $self->{_prog} . $args;
    return $log;
}

=head2 finish

    $filter->finish();

Write out any trailing comments and close output.

=cut

sub finish($) {
    my $self = shift @_;

    if (!defined($self->{_out})) {
	my $problems = '';
	$problems .= "delay_comments " if (defined($self->{_delay_comments}));
	$problems .= "logprog " if ($self->{_logprog});
	$problems .= "save_output " if (defined($self->{_save_output}));
	carp "finish with no _out object and $problems\n"
	    if ($problems ne '');
    };

    if (defined($self->{_delay_comments})) {
	foreach (@{$self->{_delay_comments}}) {
	    $_->flush($self->{_out});
	};
    };

    if ($self->{_logprog}) {
	# ick, OO programming with broken objects...
	if (ref($self->{_out}) eq '' || ref($self->{_out}) =~ /^IO::/) {  
	    $self->{_out}->print("# " . $self->compute_program_log() . "\n");
	} else {
	    $self->{_out}->write_comment($self->compute_program_log());
	};
    };
    ${$self->{_save_output}} = $self->{_out}
	if (defined($self->{_save_output}));
    $self->{_out}->close
	if ($self->{_close} && defined($self->{_out}) && !defined($self->{_save_output}));
}

=head2 setup_run_finish

    $filter->setup_run_finish();

Shorthand for doing everything needed to run a command straightaway.

=cut

sub setup_run_finish ($) {
    my $self = shift @_;
    $self->setup();
    $self->run();
    $self->finish();
}

=head2 info

    $filter->info($INFOTYPE)

Return information about what the filter does.
Infotypes:

=over 4

=item input_type
Types of input accepted.
Raw types are: "fsdbtext", "fsdbobj", "fsdb*", "text", or "none".

=item output_type
Type of output produced.
Same format as input_type.

=item input_count
Number of input streams (usually 1).

=item output_count
Number of input streams (usually 1).

=back

=cut

sub info ($) {
    my $self = shift @_;
    my $key = shift @_;
    return $self->{_info}{$key};
}


=head1 CLASS-SPECIFIC UTILITY ROUTINES

Filter has some class-specific utility routines in it.
(I.e., they know about $self.)

=head2 create_pass_comments_sub

    $filter->create_pass_comments_sub
or
    $filter->create_pass_comments_sub('_VALUE');

Creates a code block suitable for passing to C<Fsdb::IO::Readers>
C<-comment_handler>
that passes comments through to C<$self->{_out}>.
Or with the optional argument, through C<$self->{_VALUE}>.

=cut

sub create_pass_comments_sub ($;$)
{
    my $self = shift @_;
    my($value) = $_[0] // '_out';
    # one extra level of indirection to allow for delayed opening of _out
    return sub { $self->{$value}->write_raw(@_); };
}

=head2 create_tolerant_pass_comments_sub

    $filter->create_tolerant_pass_comments_sub
or
    $filter->create_tolerant_pass_comments_sub('_VALUE');

Like C<$self->create_pass_comments_sub>,
but this version tolerates the output not being opened.
In those cases, comments are discarded.
I<Warning:> use carefully to guarantee consistent results.

A symptom requiring tolerance is to get an error like
"Can't call method "write_raw" on an undefined value at /usr/lib/perl5/vendor_perl/5.10.0/Fsdb/Filter.pm line 678."
(which will be the sub create_pass_comments_sub ($;$) line in create_pass_comments.)


=cut

sub create_tolerant_pass_comments_sub ($;$)
{
    my $self = shift @_;
    my($value) = $_[0] // '_out';
    # print STDERR "## create_tolerant_pass_comments_sub on $value, " . ref($self->{$value}) . "\n";
    # one extra level of indirection to allow for delayed opening of _out
    return sub {
	$self->{$value}->write_raw(@_)
	    if (defined($self->{$value}));
    };
}

=head2 create_delay_comments_sub

    $filter->create_delay_comments_sub($optional_value);

Creates a code block suitable for passing to Fsdb::IO::Readers -comment_handler
that will buffer comments for automatic (from $self->final) after all other IO.
No output occurs until finish() is called,
at which time C<$self-E<gt>{_out}> must be a live Fsdb object.

=cut

sub create_delay_comments_sub ($;$) {
    my $self = shift @_;
    my($value) = $_[0] // '_out';
    my $dpc = new Fsdb::Support::DelayPassComments(\$self->{$value});
    push (@{$self->{_delay_comments}}, $dpc);
    return sub { $dpc->enqueue(@_); };
}


=head2 create_compare_code

    $filter->create_compare_code($a_fsdb, $b_fsdb, $a_fref_name, $b_fref_name).

Write compare code based on sort-style options
stored in C<$self->{_sort_argv}>.
C<$A_FSDB> and C<$B_FSDB> are the L<Fsdb::IO> object that defines the schemas
for the two objects.
We assume the variables C<$a> and C<$b> point to arefs;
these names can be overridden by specifying
C<$A_FREF_NAME> and C<$B_FREF_NAME>.

Returns undef if there are no fields in C<$self->{_sort_argv}>.
=cut

sub create_compare_code ($$;$$) {
    my($self, $a_fsdb, $b_fsdb, $a_name, $b_name) = @_;
    $a_name = 'a' if (!defined($a_name));
    $b_name = 'b' if (!defined($b_name));

    #
    # A word about the 'no warnings "numeric"' bit:
    # we want to compare numeric data with <=>, 
    # but that emits warnings for our empty value "-".
    # We COULD filter that in Perl, but all the checking would make
    # it much, much slower, and the Perl core has to check anyway.
    # It turns out, <=> does The Right Thing,
    # in that (any non-numeric) == (any non-numeric)
    # and (any non-numeric) < (any numeric).
    # So we just turn off warnings.
    # But. Just. Here.
    #
    my $compare_code = "sub {\n" .
	    "\tno warnings \"numeric\";\n" .
        "\t\treturn\n";
    my($MODE_AUTO, $MODE_NUMERIC, $MODE_LEXICAL) = (0..10);
    my ($reverse, $sort_mode) = (0, $MODE_AUTO);
    my $arg;
    my $fields_found = 0;
    foreach $arg (@{$self->{_sort_argv}}) {
	if ($arg eq '-r') {
	    $reverse = 1;
	} elsif ($arg eq '-R') {
	    $reverse = 0;
	} elsif ($arg eq '-n') {
	    $sort_mode = $MODE_NUMERIC;
	} elsif ($arg eq '-N') {
	    $sort_mode = $MODE_LEXICAL;
	} elsif ($arg eq '-t') {
	    $sort_mode = $MODE_AUTO;
        } elsif ($arg =~ /^-/) {
	    croak $self->{_prog} . ": internal error: unknown option $arg in sort key\n";
	} else {
	    my ($left) = ($reverse ? $b_name : $a_name);
	    my ($right) = ($reverse ? $a_name : $b_name);
	    my $left_coli = $a_fsdb->col_to_i($arg);
	    my $right_coli = $b_fsdb->col_to_i($arg);
	    if ($reverse) {
		my $tmp_coli = $left_coli;
		$left_coli = $right_coli;
		$right_coli = $tmp_coli;
	    };
	    croak $self->{_prog} . ": unknown column name $arg in sort key\n"
		if (!defined($left_coli) || !defined($right_coli));
            my($this_sort_mode) = ($sort_mode == $MODE_AUTO ? ($a_fsdb->col_spec_is_numeric($left_coli) ? $MODE_NUMERIC : $MODE_LEXICAL) : $sort_mode);
	    my($comparison_op) = ($this_sort_mode == $MODE_NUMERIC ? "<=>" : ($this_sort_mode == $MODE_LEXICAL ? "cmp": undef));
	    $compare_code .= "\t" . '($' . $left . '->[' . $left_coli . '] ' .
    	    	    $comparison_op .
		    ' $' . $right . '->[' . $right_coli . ']) || ' .
		    ' # ' . $arg  .
		    ($reverse ? ", descending" : ", ascending") .
		    ($comparison_op eq '<=>' ? " numeric" : " lexical") .
		    "\n";
	    # note that we don't currently handle NaN comparisons returning undef
	    $fields_found++;
	};
    };
    $compare_code .= "\t0; # match\n};\n";
    return undef if ($fields_found == 0);
    return $compare_code;
}

=head2 numeric_formatting

    $out = $self->numeric_formatting($x)

Display a floating point number $x using $self->{_format},
handling possible non-numeric "-" as a special case.

=cut

sub numeric_formatting {
    my ($self, $x) = @_;
    return $x if ($x eq '-');
    return sprintf($self->{_format}, $x);
}

=head2 setup_exactly_two_inputs

    $self->setup_exactly_two_inputs

Ensure that there are exactly two input streams.
Common to L<dbmerge> and L<dbjoin>.

=cut

sub setup_exactly_two_inputs {
    my($self) = @_;
    if ($#{$self->{_inputs}} == -1) {
	croak $self->{_prog} . ": too few input sources specified, use --input.\n";
    };
    if ($#{$self->{_inputs}} > 1) {
	croak $self->{_prog} . ": too input sources specified, dbmerge only hanldes two at once.\n";
    };
    if ($#{$self->{_inputs}} == 0) {
	# need to use stdin?
#	my $token = new IO::Handle;
#	$token->fdopen(fileno(STDIN), "r");
#	unshift @{$self->{_inputs}}, $token;
	unshift @{$self->{_inputs}}, '-';
    };
    croak if ($#{$self->{_inputs}} != 1);   # assert
}


=head1 NON-CLASS UTILITY ROUTINES

Filter also has some utility routines that are not part of the class structure.
They are not exported.

(none currently)

=cut

1;
