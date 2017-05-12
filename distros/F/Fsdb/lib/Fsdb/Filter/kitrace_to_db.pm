#!/usr/bin/perl

#
# kitrace_to_db.pm
# Copyright (C) 1995-2011 by John Heidemann <johnh@isi.edu>
# $Id: bd1785eb7cda24f3cbb75aeeabcc7b4d20c0cd71 $
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblib for details.
#

package Fsdb::Filter::kitrace_to_db;

=head1 NAME

kitrace_to_db - convert kitrace output to Fsdb format

=head1 SYNOPSIS

    kitrace_to_db [-Y year] [registers] <kitrace.out >kitrace.fsdb

=head1 DESCRIPTION

Converts a kitrace data stream to Fsdb format.

Optional arguments list registers
which will be picked out of the output stream
and formatted as their own columns.

=head1 OPTIONS

=over 4

=item B<-Y Y> or B<--year Y>

Specify the 4-digit year for the dataset (defaults to current year).

=item B<-u> or  B<--utc>

Specify UTC timezone (defaults to local time zeon).

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

    _null_getpage+4  Nov  7 22:40:13.281070 (            ) pid 4893
    _null_getpage+128 Nov  7 22:40:13.281756 (   00.000686) pid 4893
    _null_getpage+4  Nov  7 22:40:13.282694 (   00.000938) pid 4893
    _null_getpage+128 Nov  7 22:40:13.328709 (   00.046015) pid 4893
    _null_getpage+4  Nov  7 22:40:13.330758 (   00.002049) pid 4893
    _null_getpage+128 Nov  7 22:40:13.353830 (   00.023072) pid 4893
    _null_getpage+4  Nov  7 22:40:13.355566 (   00.001736) pid 4893
    _null_getpage+128 Nov  7 22:40:13.357169 (   00.001603) pid 4893
    _null_getpage+4  Nov  7 22:40:13.358780 (   00.001611) pid 4893
    _null_getpage+128 Nov  7 22:40:13.375844 (   00.017064) pid 4893
    _null_getpage+4  Nov  7 22:40:13.377850 (   00.002006) pid 4893
    _null_getpage+128 Nov  7 22:40:13.378358 (   00.000508) pid 4893

=head2 Command:

    kitrace_to_db -Y 1995

=head2 Output:

    #fsdb event clock diff
    _null_getpage+4  815812813.281070      0.0
    _null_getpage+128  815812813.281756  00.000686
    _null_getpage+4  815812813.282694  00.000938
    _null_getpage+128  815812813.328709  00.046015
    _null_getpage+4  815812813.330758  00.002049
    _null_getpage+128  815812813.353830  00.023072
    _null_getpage+4  815812813.355566  00.001736
    _null_getpage+128  815812813.357169  00.001603
    _null_getpage+4  815812813.358780  00.001611
    _null_getpage+128  815812813.375844  00.017064
    _null_getpage+4  815812813.377850  00.002006
    _null_getpage+128  815812813.378358  00.000508
    # | kitrace_to_db


=head1 SEE ALSO

L<Fsdb>.


=head1 CLASS FUNCTIONS

=cut

@ISA = qw(Fsdb::Filter);
$VERSION = 2.0;

use strict;
use Pod::Usage;
use Carp;
use Time::Local;

use Fsdb::Filter;
use Fsdb::IO::Reader;
use Fsdb::IO::Writer;


=head2 new

    $filter = new Fsdb::Filter::kitrace_to_db(@arguments);

Create a new kitrace_to_db object, taking command-line arguments.

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
    $self->{_registers} = [];
    $self->{_year} = undef;
    $self->{_utc} = undef;
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
	'd|debug+' => \$self->{_debug},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'log!' => \$self->{_logprog},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	'u|utc!' => \$self->{_utc},
	'Y|year=i' => \$self->{_year},
	) or pod2usage(2);
    push (@{$self->{_registers}}, @argv);
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup ($) {
    my($self) = @_;

    if (!defined($self->{_year})) {
	my(@tm) = ($self->{_utc} ? gmtime : localtime);
	$self->{_year} = $tm[5];
    };

    $self->finish_fh_io_option('input');

    my @cols = qw(event clock diff);

    # Extract the registers, if any.
    my $reg_input_code = '';
    foreach my $reg (@{$self->{_registers}}) {
	$reg =~ s/^%//;  # strip % from %o0
	push (@cols, $reg);
	$reg_input_code .= '($r) = /' . $reg . '=([\da-fA-F]+)/; push(@outf, hex($r));';
    };
    $self->{_reg_input_code} = $reg_input_code;

    $self->finish_io_option('output', -cols => \@cols);

}

=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run ($) {
    my($self) = @_;

    my %MoY = qw(Jan 0
		Feb 1
		Mar 2
		Apr 3
		May 4
		Jun 5
		Jul 6
		Aug 7
		Sep 8
		Oct 9
		Nov 10
		Dec 11);
    my $in_fh = $self->{_in};
    my $write_fastpath_sub = $self->{_out}->fastpath_sub();

    my $year = $self->{_year};
    my @outf;
    my $reg_input_sub;
    my $eval = "\$reg_input_sub = sub {\n" . $self->{_reg_input_code} . "\n};\n";
    eval $eval;
    $@ && die $self->{_prog} . ":  internal eval error: $@.\n";


    for (;;) {
	my $line = $self->{_in}->getline;
	last if (!defined($line));

	if ($line =~ /^Warning:\s+(\d+) traces were lost/) {
	    carp "lost_traces\t$1\t0\n";
	    next;
	};
	my($event, $month, $day, $hour, $min, $sec, $frac, $diff) =
	    ($line =~ /(\S+)\s+(\w{3})\s+(\d+)\s+(\d{2}):(\d{2}):(\d{2})(\.\d{6})\s+\(\s*([^)]+)\)/);
	$diff = '0.0' if ($diff !~ /\d/);
	my $t = ($self->{_utc} ? 
	    timegm($sec, $min, $hour, $day, $MoY{$month}, $year) :
	    timelocal($sec, $min, $hour, $day, $MoY{$month}, $year));
	@outf = ($event, "$t$frac", $diff);
	&{$reg_input_sub}();
	&{$write_fastpath_sub}(\@outf);
    };
}



=head1 AUTHOR and COPYRIGHT

Copyright (C) 1991-2011 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
