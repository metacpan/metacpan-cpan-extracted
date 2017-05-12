#!/usr/bin/perl

#
# cgi_to_db.pm
# Copyright (C) 1998-2007 by John Heidemann
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License,
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

package Fsdb::Filter::cgi_to_db;

=head1 NAME

cgi_to_db - convert stored CGI files (from CGI.pm) to fsdb

=head1 SYNOPSIS

    cgi_to_db [-duU] [-e EmptyValue] [cgi-files...]

=head1 DESCRIPTION

Converts all stored CGI files (from CGI.pm) to fsdb,
optionally unescaping the contents.
When contents are unescaped, CR NL is recoded as ``\n''.

Output is always in fsdb list format with double space (type ``S'')
field separator.

Unlike most Fsdb programs, the input to this program is 
I<not> usually from standard input.  However, the program will take 
C<-i> options.

This program requires temporary storage equal to the size of the data
(so that it can handle the case of different entries having different
headers).

=head1 OPTIONS

=over 4

=item B<-u> or B<--unescape>

do unescape data, converting CGI escape codes like %xx
to regular characters (default)

=item B<-U> or B<--nounescape>

do I<not> unescape data, but leave it CGI-encoded

=item B<-e E> or B<--empty E>

give value E as the value for empty (null) records

=item B<-T TmpDir>

where to put tmp files.
Also uses environment variable TMPDIR, if -T is 
not specified.
Default is /tmp.

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

file A (TEST/cgi_to_db_ex.in):

    name=test
    id=111-11-1111
    email=test%40usc.edu
    submit_time=Tue%20Jan%2014%2011%3A32%3A39%202003
    =

file B (TEST/cgi_to_db_ex.in-2):

    name=test2
    id=222-22-2222
    email=test2%40usc.edu
    newfield=foo
    emptyfield=
    submit_time=Tue%20Jan%2024%2022%3A32%3A39%202003
    =


=head2 Command:

    cgi_to_db TEST/cgi_to_db_ex.in TEST/cgi_to_db_ex.in-2


=head2 Output:

    #fsdb -R C -F S name id email submit_time newfield emptyfield
    name:  test
    id:  111-11-1111
    email:  test\@usc.edu
    submit_time:  Tue Jan 14 11:32:39 2003

    name:  test2
    id:  222-22-2222
    email:  test2\@usc.edu
    newfield:  foo
    emptyfield:  -
    submit_time:  Tue Jan 24 22:32:39 2003

    #  | cgi_to_db TEST/cgi_to_db_ex.in TEST/cgi_to_db_ex.in-2


=head1 SEE ALSO

L<Fsdb>.
L<CGI(3pm)>.
L<http://stein.cshl.org/boulder/>.
L<http://stein.cshl.org/WWW/software/CGI/>

=head1 CLASS FUNCTIONS

=cut

@ISA = qw(Fsdb::Filter);
$VERSION = 2.0;

use strict;
use Pod::Usage;
use Carp;

use Fsdb::Filter;
use Fsdb::IO::Writer;
use Fsdb::Support::NamedTmpfile;


=head2 new

    $filter = new Fsdb::Filter::cgi_to_db(@arguments);

Create a new cgi_to_db object, taking command-line arguments.

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
    $self->{_unescape} = 1;
    $self->{_save_in_filename} = undef;
    $self->set_default_tmpdir;
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
	'e|empty=s' => \$self->{_empty},
	'i|input=s@' => sub { $self->parse_io_option('inputs', @_); },
	'inputs' => sub {}, # for compatibility with dbmerge, but here --inputs is implicit
	'log!' => \$self->{_logprog},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	'u|unescape!' => \$self->{_unescape},
	'T|tmpdir|tempdir=s' => \$self->{_tmpdir},
	'U' => sub { $self->{_unescape} = undef; },
	'<>' => sub { $self->parse_io_option('inputs', @_); },
	) or pod2usage(2);
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup ($) {
    my($self) = @_;

    # Sigh, can't do anything, because multiple inputs and no clue about output format.
}

=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run ($) {
    my($self) = @_;

    #
    # Scan all the input, saving it, so we know the column names.
    # Note the tmpfile is NOT in fsdb format.
    #
    $self->{_save_in_filename} = Fsdb::Support::NamedTmpfile::alloc($self->{_tmpdir});
    open (TMP, ">$self->{_save_in_filename}") or croak $self->{_prog} . ": cannot write to " . $self->{_save_in_filename} . "\n";
    my %columns_found;
    my @columns_ordered;
    foreach my $fn (@{$self->{_inputs}}) {
	open(IN, "<$fn") or croak $self->{_prog} . ": cannot open input file $fn\n";
	my $at_end_of_record = 1;
	while (<IN>) {
	    print TMP $_;
	    chomp;
	    if ($_ eq '=') {
		$at_end_of_record = 1;
		next;
	    };
	    $at_end_of_record = 0;
	    my($key, $value) = m/^([^=]*)=(.*)$/;
	    croak $self->{_prog} .  " missing key in $_ in file $fn" if (!defined($key));
	    next if (defined($columns_found{$key}));
	    # new one!
	    $columns_found{$key} = 1;
	    push(@columns_ordered, $key);
	};
	close IN;
	print TMP "=\n" if (!$at_end_of_record);
    };
    close TMP;

    #
    # Now go back and do the real output.
    #
    $self->finish_io_option('output', -fscode => 'S', -rscode => 'C',
	    -cols => \@columns_ordered);
    open (TMP, "<$self->{_save_in_filename}") or croak $self->{_prog} . ": cannot read from " . $self->{_save_in_filename} . "\n";
    my %row;
    my $at_end_of_record = 1;
    my $unescape = $self->{_unescape};
    while (<TMP>) {
	chomp;
	if ($_ eq '=') {
	    $self->{_out}->write_row_from_href(\%row);
	    %row = ();
	    $at_end_of_record = 1;
	    next;
	};
	$at_end_of_record = 0;
	my($key, $value) = m/^([^=]*)=(.*)$/;
	croak $self->{_prog} .  ": interal error, empty $key." if (!defined($key));
	croak $self->{_prog} .  ": interal error, found key $key in second pass." if (!defined($columns_found{$key}));

	#
	# deal with the value
	#
	$value = $self->{_empty} if (!defined($value) || $value eq '');
	if ($unescape) {
	    # map newlines to something
	    $value =~ s/%0D%0A/%0A/g;  # change CR NL to just NL
	    $value =~ s/%0A/ \\n /g;  # change NL to my thing
	    $value =~ s/%09/ /g;  # tabs to spaces
	    $value =~ s/%(..)/chr(hex($1))/eg;  # now general unescape
	};
	$value =~ s/  +/ /g; 	# prune double spaces (for -FS option)
	$value =~ s/\r//g;  # second check on CRs
	$row{$key} = $value;
    };
    croak $self->{_prog} .  ": internal error, tmpfile finished in middle of record.\n" if (!$at_end_of_record);
    close TMP;
}

=head1 AUTHOR and COPYRIGHT

Copyright (C) 1991-2008 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
