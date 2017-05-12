#!/usr/bin/perl -w

#
# tcpdump_to_db.pm
# Copyright (C) 1999-2007 by John Heidemann <johnh@isi.edu>
# $Id: 43409abf10f685dcc1abf480ced38d92f914c5c6 $
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblib for details.
#


package Fsdb::Filter::tcpdump_to_db;

=head1 NAME

tcpdump_to_db - convert tcpdump textual output to fsdb

=head1 SYNOPSIS

    tcpdump_to_db [-T] < source.tcpdump > target.fsdb

=head1 DESCRIPTION

Converts a tcpdump data stream to Fsdb format.

B<Currently it handles only TCP and silently fails on other traffic!>
Awaiting enhancement... you're welcome to help.


=head1 OPTIONS

=over 4

=item B<-t> or B<--daytime>

Adjust times relative to the first timestamp.
(Defaults on.)

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

    14:11:12.556781 dash.isi.edu.1023 > excalibur.usc.edu.ssh: S 2306448962:2306448962(0) win 32120 <mss 1460,sackOK,timestamp 82802652[|tcp]> (DF)
    14:11:12.561734 excalibur.usc.edu.ssh > dash.isi.edu.1023: S 1968320001:1968320001(0) ack 2306448963 win 4096
    14:11:12.561875 dash.isi.edu.1023 > excalibur.usc.edu.ssh: . ack 1 win 32120 (DF)
    14:11:18.746567 excalibur.usc.edu.ssh > dash.isi.edu.1023: P 316:328(12) ack 348 win 4096
    14:11:18.755176 dash.isi.edu.1023 > excalibur.usc.edu.ssh: P 348:488(140) ack 328 win 32696 (DF) [tos 0x10]
    14:11:18.847937 excalibur.usc.edu.ssh > dash.isi.edu.1023: P 328:468(140) ack 488 win 4096
    14:11:18.860047 dash.isi.edu.1023 > excalibur.usc.edu.ssh: . ack 468 win 32696 (DF) [tos 0x10]
    14:11:18.936255 dash.isi.edu.1023 > excalibur.usc.edu.ssh: P 488:516(28) ack 468 win 32696 (DF) [tos 0x10]

=head2 Command:

    tcpdump_to_db

=head2 Output:

    #fsdb time proto src dest flags start end len ack win
    51072.556781 tcp dash.isi.edu.1023 excalibur.usc.edu.ssh S 2306448962 2306448962 0 - 32120
    51072.561734 tcp excalibur.usc.edu.ssh dash.isi.edu.1023 S 1968320001 1968320001 0 2306448963 4096
    51072.561875 tcp dash.isi.edu.1023 excalibur.usc.edu.ssh . - - - 1 32120
    51078.746567 tcp excalibur.usc.edu.ssh dash.isi.edu.1023 P 316 328 12 348 4096
    51078.755176 tcp dash.isi.edu.1023 excalibur.usc.edu.ssh P 348 488 140 328 32696
    51078.847937 tcp excalibur.usc.edu.ssh dash.isi.edu.1023 P 328 468 140 488 4096
    51078.860047 tcp dash.isi.edu.1023 excalibur.usc.edu.ssh . - - - 468 32696
    51078.936255 tcp dash.isi.edu.1023 excalibur.usc.edu.ssh P 488 516 28 468 32696
    #  | tcpdump_to_db 


=head1 SEE ALSO

L<Fsdb>.


=head1 CLASS FUNCTIONS

=cut

@ISA = qw(Fsdb::Filter);
$VERSION = 2.0;

use strict;
use Pod::Usage;
use Carp;

use Fsdb::Filter;
use Fsdb::IO::Writer;


=head2 new

    $filter = new Fsdb::Filter::tcpdump_to_db(@arguments);

Create a new tcpdump_to_db object, taking command-line arguments.

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
	't|daytime!' => \$self->{_daytime},
	'T' => sub { $self->{_daytime} = undef; },
	'log!' => \$self->{_logprog},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	) or pod2usage(2);
    push (@{$self->{_argv}}, @argv);
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup ($) {
    my($self) = @_;

    $self->finish_fh_io_option('input');

    $self->finish_io_option('output', -cols => [qw(time proto src dest flags start end len ack win)]);
}

=head2 _conv_time

    $daytime = $self->_conv_time($raw);

Convert tcpdump h:mm:ss.SS format to absolute seconds.

=cut

sub _conv_time {
    my($self, $raw) = @_;
    my($h, $m, $s, $f) = ($raw =~ /^\s*(\d+):(\d+):(\d+)\.(\d+)\s*$/);
    die "$0: input doesn't look like an ascii formatted tcpdump.  Giving up.\n"
	if (!defined($h));
    my $S = (($h * 60) + $m) * 60 + $s;
    if ($self->{_daytime}) {
	if (!defined($self->{_time_origin_S})) {
	    $self->{_time_origin_S} = $S;
	    $self->{_time_origin_f} = $f;
	};
	$S -= $self->{_time_origin_S};
	$f -= $self->{_time_origin_f};
	while ($f < 0) {
	    $S -= 1;
	    $f += 1000000;
	};
	$f = sprintf("%06d", $f);
    }; 
    return "$S.$f";
}


=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run ($) {
    my($self) = @_;

    my $read_fh = $self->{_in};
    my $write_fastpath_sub = $self->{_out}->fastpath_sub();
    my $empty = $self->{_out}->{_empty};

    for (;;) {
	my $line = $read_fh->getline;
	last if (!defined($line));

        next if ($line !~ /^\d/);
        my(@F) = split(' ', $line);
        my($proto, $raw_time, $src, $dummy, $dest, $flags, $ack, $win, $start, $end, $len) = ($empty) x 20;
        $raw_time = shift @F;
        # xxx: should support other protos!
        # Currently silently fails on them.
        $proto = 'tcp';
        $src = shift @F;
        # The src field may have "truncated-ip" instead of the src.
        # If the entry is truncated then silently ignore it.
        next if ($src =~ /truncated/);
    
        $dummy = shift @F;
        $dest = shift @F;
        $dest =~ s/:$//;
        $flags = shift @F;
        if ($F[0] =~ /^\d/) {
	    ($start, $end, $len) = ($F[0] =~ /^\s*(\d+):(\d+)\((\d+)\)\s*$/);
	    shift @F;
        };
        if ($F[0] eq 'ack') {
	    shift @F;
	    $ack = shift @F;
        };
        if ($F[0] eq 'win') {
	    shift @F;
	    $win = shift @F;
        };

	my @outf = ($self->_conv_time($raw_time), $proto, $src, $dest, $flags, $start, $end, $len, $ack, $win);
	&{$write_fastpath_sub}(\@outf);
    };
}


=head1 AUTHOR and COPYRIGHT

Copyright (C) 1991-2008 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
