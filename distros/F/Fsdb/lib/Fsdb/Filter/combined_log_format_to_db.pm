#!/usr/bin/perl

#
# combined_log_format_to_db.pm
# Copyright (C) 2008 by John Heidemann <johnh@isi.edu>
# $Id: 4124e62011ce3c8d253dfdaef66ec91961cb0010 $
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblib for details.
#

package Fsdb::Filter::combined_log_format_to_db;

=head1 NAME

combined_log_format_to_db - convert Apache Combined Log Format to Fsdb

=head1 SYNOPSIS

    combined_log_format_to_db < access_log > access_log.fsdb

=head1 DESCRIPTION

Converts logs in Apache Combined-Log-Format into Fsdb format.


=head1 OPTIONS

No program-specific options.

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

    foo.example.com - - [01/Jan/2007:00:00:01 -0800] "GET /~moll/wedding/index.html HTTP/1.0" 200 2390 "-" "Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp)"
    127.0.0.1 - - [01/Jan/2007:00:00:02 -0800] "GET /hpdc2007/ HTTP/1.1" 304 - "http://grid.hust.edu.cn:8080/call/cfp.jsp" "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; InfoPath.1; InfoPath.2)"
    bar.example.com - - [31/Dec/2006:23:51:40 -0800] "GET /nsnam/dist/ns-allinone-2.29.2.tar.gz HTTP/1.1" 206 58394090 "file://D:\\\xce\xd2\xb5\xc4\xce\xc4\xb5\xb5\\ns2\\XP_Using_Cygwin.htm#Windows_Support_for_Ns-2.27_and_Earlier" "Mozilla/4.0 (compatible; MSIE 5.00; Windows 98)"
    127.0.0.1 - - [01/Jan/2007:00:00:02 -0800] "GET /hpdc2007/hpdc.css HTTP/1.1" 304 - "http://www.isi.edu/hpdc2007/" "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; InfoPath.1; InfoPath.2)"

=head2 Command:

    combined_log_format_to_db

=head2 Output:

    #fsdb -F S client identity userid time method resource protocol status size refer useragent
    foo.example.com  -  -  [01/Jan/2007:00:00:01 -0800]  GET  /~moll/wedding/index.html  HTTP/1.0  200  2390  "-"  "Mozilla/5.0 (compatible; Yahoo! Slurp; http://help.yahoo.com/help/us/ysearch/slurp)"
    127.0.0.1  -  -  [01/Jan/2007:00:00:02 -0800]  GET  /hpdc2007/  HTTP/1.1  304  -  "http://grid.hust.edu.cn:8080/call/cfp.jsp"  "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; InfoPath.1; InfoPath.2)"
    bar.example.com  -  -  [31/Dec/2006:23:51:40 -0800]  GET  /nsnam/dist/ns-allinone-2.29.2.tar.gz  HTTP/1.1  206  58394090  "file://D:\\\xce\xd2\xb5\xc4\xce\xc4\xb5\xb5\\ns2\\XP_Using_Cygwin.htm#Windows_Support_for_Ns-2.27_and_Earlier"  "Mozilla/4.0 (compatible; MSIE 5.00; Windows 98)"
    127.0.0.1  -  -  [01/Jan/2007:00:00:02 -0800]  GET  /hpdc2007/hpdc.css  HTTP/1.1  304  -  "http://www.isi.edu/hpdc2007/"  "Mozilla/4.0 (compatible; MSIE 7.0; Windows NT 5.1; InfoPath.1; InfoPath.2)"
    #   | combined_log_format_to_db

=head1 SEE ALSO

L<Fsdb>.
L<http://httpd.apache.org/docs/2.0/logs.html>


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

    $filter = new Fsdb::Filter::combined_log_format_to_db(@arguments);

Create a new combined_log_format_to_db object, taking command-line arguments.

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
	'close!' => \$self->{_close},
	'd|debug+' => \$self->{_debug},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
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

    $self->finish_io_option('output', -fscode => 'S',
	    -cols => [qw(client identity userid time method resource protocol status size refer useragent)]);
}

=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run ($) {
    my($self) = @_;
    my $write_fastpath_sub = $self->{_out}->fastpath_sub();
    my @f;
    my @s;
    my ($CLIENT, $IDENTITY, $USERID, $TIMESTART, $TIMEZONE, $METHOD, $RESOURCE, $PROTOCOL, $STATUS, $SIZE, $REFER, $USERAGENT0) = (0..20); 
    my $in_fh = $self->{_in};

    my $line;
    while (defined($line = $in_fh->getline)) {
	@s = split(' ', $line);
	$s[$METHOD] =~ s/^"//;
	$s[$PROTOCOL] =~ s/"$//; # protocol has trailing "
	my $ua = join(" ", @s[$USERAGENT0 .. $#s]); # UA is all that's left
	@f = ($s[$CLIENT], $s[$IDENTITY], $s[$USERID], $s[$TIMESTART] . " " . $s[$TIMEZONE], $s[$METHOD], $s[$RESOURCE], $s[$PROTOCOL], $s[$STATUS], $s[$SIZE], $s[$REFER], $ua);
	&$write_fastpath_sub(\@f);
    };
}

=head1 AUTHOR and COPYRIGHT

Copyright (C) 2008 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
