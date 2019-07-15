#!/usr/bin/perl

#
# dbrow.pm
# Copyright (C) 1991-2018 by John Heidemann <johnh@isi.edu>
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblibdir for details.
#

package Fsdb::Filter::dbrow;

=head1 NAME

dbrow - select rows from an Fsdb file based on arbitrary conditions

=head1 SYNOPSIS

dbrow [-vw] CONDITION [CONDITION...]

=head1 DESCRIPTION

Select rows for which all CONDITIONS are true.
Conditions are specified as Perl code,
in which column names are be embedded, preceded by underscores.

=head1 OPTIONS

=over 4

=item B<-v>

Invert the selection, picking rows where at least one condition does
I<not> match.

=back

=for comment
begin_standard_fsdb_options

This module also supports the standard fsdb options:

=over 4

=item B<-d>

Enable debugging output.

=item B<-w> or B<--warnings>

Enable warnings in user supplied code.

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

    #fsdb account passwd uid gid fullname homedir shell
    johnh * 2274 134 John_Heidemann /home/johnh /bin/bash
    greg * 2275 134 Greg_Johnson /home/greg /bin/bash
    root * 0 0 Root /root /bin/bash
    # this is a simple database

=head2 Command:

    cat DATA/passwd.fsdb | dbrow '_fullname =~ /John/'

=head2 Output:

    #fsdb      account passwd  uid     gid     fullname        homedir shell
    johnh   *       2274    134     John_Heidemann  /home/johnh     /bin/bash
    greg    *       2275    134     Greg_Johnson    /home/greg      /bin/bash
    # this is a simple database
    #  | /home/johnh/BIN/DB/dbrow 


=head1 BUGS

Doesn't detect references to unknown columns in conditions.

END
    #' for font-lock mode.
    exit 1;

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

    $filter = new Fsdb::Filter::dbrow(@arguments);

Create a new dbrow object, taking command-line arguments.

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
    $self->{_invert_match} = undef;
    $self->{_warnings} = undef;
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
	'header=s' => \$self->{_header},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'log!' => \$self->{_logprog},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
        'v|invert-match!' => \$self->{_invert_match},
        'w|warnings!' => \$self->{_warnings},
	) or pod2usage(2);
    push (@{$self->{_argv}}, @argv);
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

    $self->finish_io_option('output', -clone => $self->{_in});
    my $write_fastpath_sub = $self->{_out}->fastpath_sub();

    #
    # convert code to perl
    #
    my($partial_code, $needs_lfref) = $self->{_in}->codify(join(") && (", @{$self->{_argv}}));

    my($negate_code) = $self->{_invert_match} ? "!" : "";

    {
	my $loop_sub;
        my $loop_code = q'
	    $loop_sub = sub {
		my $fref;
		my $lfref;
		my $result;
		while ($fref = &$read_fastpath_sub()) {
		    ' .
		    ($self->{_warnings} ? "use" : "no") . q' strict "vars";
		    # BEGIN USER PROVIDED CODE
		    $result = ' . $negate_code . '(' . $partial_code . q');

		    # END USER PROVIDED CODE
		    ' . ($needs_lfref ? q'
		    $lfref = $fref;  # save for next pass
                    ' : '') . q'
		    &$write_fastpath_sub($fref) if ($result);
		};
	    };
	    ';
	if ($self->{_debug}) {
	    print STDERR "DEBUG:\n$loop_code\n";
	    exit 1;
        };
	eval $loop_code;
	$@ && croak($self->{_prog} . ":  eval error compiling user-provided code: $@.\n");
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
