#!/usr/bin/perl -w

#
# dbsubprocess.pm
# Copyright (C) 1991-2015 by John Heidemann <johnh@isi.edu>
# $Id: 630ba67be630dfda1dae8d724df2877a8f37a54e $
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbsubprocess;

=head1 NAME

dbsubprocess - invoke a subprocess as a Fsdb filter object

=head1 SYNOPSIS

    dbsubprocess [--] program [arguments...]

=head1 DESCRIPTION

Run PROGRAM as a process, with optional ARGUMENTS as program arguments,
feeding its standard input and standard output
as fsdb streams.  A "--" can separate arguments to dbsubprocess
from the program and its arguments.

As with similar tools, like open2, the caller is expected to take
care that the subprocess does not deadlock.

This program is primarily for internal use by dbmapreduce.

Like L<dbpipeline>, L<dbsubprocess> program does have a 
Unix command; instead it is used only from within Perl.

=head1 OPTIONS

=over 4

=item B<-w> or B<--warnings>

Enable warnings in user supplied code.
(Default to include warnings.)

=item B<-E> or B<--endsub> SUB

Call Perl SUB when the subprocess terminates.
The sub runs in the parent and is a Fred ending sub, see
L<Fsdb::Support::Freds>.

=back

=for comment
begin_standard_fsdb_options

and the standard fsdb options:

=over 4

=item B<-d>

Enable debugging output.

=item B<-i> or B<--input> InputSource

Read from InputSource, typically a file, or - for standard input,
or (if in Perl) a IO::Handle, Fsdb::IO objects.
(For this case, it cannot be Fsdb::BoundedQueue).

=item B<-o> or B<--output> OutputDestination

Write to OutputDestination, typically a file, or - for standard output,
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

	#fsdb name id test1
	a	1	80
	b	2	70
	c	3	65
	d	4	90
	e	5	70
	f	6	90

=head2 Command:

the following perl code:

    use Fsdb::Filter::dbsubprocess;
    my $f = new Fsdb::Filter::dbsubprocess(qw(cat));
    $f->setup_run_finish;
    exit 0;

=head2 Output:

	#fsdb name id test1
	a	1	80
	b	2	70
	c	3	65
	d	4	90
	e	5	70
	f	6	90
	#   | dbsubprocess cat

=head1 SEE ALSO

L<dbpipeline(1)>,
L<Fsdb(3)>

=head1 CLASS FUNCTIONS

=cut

@ISA = qw(Fsdb::Filter);
($VERSION) = 2.0;

use strict;
use Pod::Usage;
# use IPC::Open2;
use Carp;
use IO::Pipe;

use Fsdb::Support::Freds;
use Fsdb::Filter;
use Fsdb::Filter::dbfilecat;
use Fsdb::IO::Reader;
use Fsdb::IO::Writer;


=head2 new

    $filter = new Fsdb::Filter::dbsubprocess(@arguments);

Create a new dbsubprocess object, taking command-line arguments.

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
    $self->{_external_command_argv} = [];
    $self->{_warnings} = 1;
    $self->{_ending_sub} = undef;
}

=head2 parse_options

    $filter->parse_options(@ARGV);

Internal: parse options

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
	'E|endsub=s' => \$self->{_ending_sub},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'log!' => \$self->{_logprog},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	'saveoutput=s' => \$self->{_save_output},
        'w|warnings!' => \$self->{_warnings},
	) or pod2usage(2);
    push (@{$self->{_external_command_argv}}, @argv);
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup ($) {
    my($self) = @_;

    shift @{$self->{_external_command_argv}}
	if ($#{$self->{_external_command_argv}} >= 0 && $self->{_external_command_argv}[0] eq '--');
    croak $self->{_prog} . ": no program given.\n"
        if ($#{$self->{_external_command_argv}} < 0);

    my $input_ref = ref($self->{_input});
    if ($input_ref =~ /^Fsdb::BoundedQueue/) {
	croak $self->{_prog} . ": cannot handle BoundedQueue any more.\n"
    } elsif ($input_ref =~ /^IO::/) {
	$self->{_in_fileno} = $self->{_input}->fileno;
    } elsif ($input_ref =~ /^Fsdb::IO::Reader/) {
	# start up a converter Fred
        my $pipe = new IO::Pipe;
	croak $self->{_prog} . ": error opening pipe.\n"
	    if ($pipe->error);
	my $input = $self->{_input};
	my $input_fred = new Fsdb::Support::Freds('dbsubprocess_Fsdb::IO::Reader_converter',
	    sub {
		$pipe->writer();
		new Fsdb::Filter::dbfilecat(
		    '--autorun',
		    '--nolog',
		    '--input' => $input,
		    '--output' => $pipe);
		exit 0;
	    });
	$self->{_input_fred} = $input_fred;
	$pipe->reader();
	$self->{_in_fileno} = $pipe->fileno;
    } elsif ($input_ref eq '' && $self->{_input} eq '-') {
	$self->{_in_fileno} = 0;   # stdin
    } elsif ($input_ref eq '') {
	# a file
	my $fh = IO::File->new($self->{_input}, "r");
	$fh->binmode;
	$self->{_in_fileno} = $fh->fileno;
    } else {
	croak $self->{_prog} . ": unknown input method (ref: $input_ref).\n"
    };

    my $output_ref = ref($self->{_output});
    if ($output_ref =~ /^Fsdb::BoundedQueue/) {
	croak $self->{_prog} . ": cannot handle BoundedQueue any more.\n"
    } elsif ($output_ref =~ /^IO::/) {
	$self->{_out_fileno} = $self->{_output}->fileno;
    } elsif ($output_ref =~ /^Fsdb::IO::Writer/) {
	croak $self->{_prog} . ": cannot handle Fsdb::IO::Writer yet.\n"
    } elsif ($output_ref eq '' && $self->{_output} eq '-') {
	$self->{_out_fileno} = 1;   # stdout
    } elsif ($output_ref eq '') {
	# a file
	my $fh = IO::File->new($self->{_output}, "w");
	$fh->binmode;
	croak $self->{_prog} . ": cannot open output file: " . $self->{_output} . ".\n"
	    if ($fh->error);
	$self->{_out_fileno} = $fh->fileno;
	croak $self->{_prog} . ": strangely unset fileno for output file: " . $self->{_output} . ".\n"
	    if (!defined($self->{_out_fileno}));
    } else {
	croak $self->{_prog} . ": unknown output method.\n"
    };
}

=head2 run

    $filter->run();

Internal: run over all data rows.

=cut
sub run ($) {
    my($self) = @_;

    # catch sigpipe for failure cases in the child
    if ($self->{_warnings}) {
	$SIG{'PIPE'} = sub {
	    warn $self->{_prog} . ": external dbmapreduce reduce program exited with SIGPIPE (" . join(" ", @{$self->{_external_command_argv}}) . "), probably not consuming all input.\n";
	};
    } else {
	$SIG{'PIPE'} = sub { };
    };

    #
    # run the subproc
    # most of this is cribbed from IPC::Open2, but simplified.
    #
    my $child_rdr_fd = $self->{_in_fileno};
    croak $self->{_prog} . ": internal error, in_fileno not ready.\n" if (!defined($child_rdr_fd));
    my $child_wtr_fd = $self->{_out_fileno};
    croak $self->{_prog} . ": internal error, out_fileno not ready.\n" if (!defined($child_wtr_fd));
    my $args_ref = \@{$self->{_external_command_argv}};
    my $fred = new Fsdb::Support::Freds('dbsubprocess', 
	sub {
	    # in child
	    untie *STDIN;
	    untie *STDOUT;
	    open \*STDIN, "<&=", $child_rdr_fd or croak $self->{_prog} . ": cannot reopen stdin from $child_rdr_fd\n";
	    open \*STDOUT, ">&=", $child_wtr_fd or croak $self->{_prog} . ": cannot reopen stdout to $child_wtr_fd\n";
	    # ignore stderr
	    exec @$args_ref or croak $self->{_prog} . ": cannot exec: " . join(" ", @$args_ref) . "\n";
	    # never returns, either way.
	    die;   # just in case
	}, $self->{_ending_sub});
    $self->{_fred} = $fred;
}

=head2 finish

    $filter->finish();

Internal: run over all data rows.

=cut
sub finish($) {
    my($self) = @_;

    # and reap the subprocess
    foreach my $fred ($self->{_input_fred}, $self->{_fred}) {
	if (defined($fred)) {
	    $fred->join();
	    croak $self->{_prog} . ": fred failed: " . $fred->error()
		if ($fred->error());
	};
    };
    # fake up _out
    my $out = IO::Handle->new_from_fd($self->{_out_fileno}, "w")
	    or croak $self->{_prog} . ": cannot write log\n";
    $self->{_out} = $out;
    $self->SUPER::finish();  # will close it
#	$out->print("# " . $self->compute_program_log() . "\n");
}

=head1 AUTHOR and COPYRIGHT

Copyright (C) 1991-2015 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;

