#!/usr/bin/perl

#
# yaml_to_db.pm
# Copyright (C) 2011-2018 by John Heidemann <johnh@isi.edu>
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblib for details.
#

package Fsdb::Filter::yaml_to_db;

=head1 NAME

yaml_to_db - convert a subset of YAML into fsdb

=head1 SYNOPSIS

    yaml_to_db <source.yaml

=head1 DESCRIPTION

Converts a I<very limited> subset of YAML into Fsdb format.

The input is YAML-format (I<not> fsdb).
The input is parsed as YAML, 
assuming the file is an array of dictionary entries.
We extract the dictionary names and output this as an fsdb table.

The output is tab-separated fsdb.
(Someday more general field separators should be supported.)

=head1 OPTIONS


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

	- name: ACM
	  role: sponsor
	  alttext: ACM, the Association for Computing Machinery
	  image: logos/acm-small.jpg
	  link:  https://www.acm.org/
	  date: 2016-01-01
	
	- name: SIGCOMM
	  role: sponsor
	  alttext: SIGCOMM, ACM'S Special Interest Group on Communication
	  image: logos/sigcommlogo.png
	  link:  http://sigcomm.org
	  date: 2016-01-02
	
	- name: SIGMETRICS
	  role: sponsor
	  alttext: SIGMETRICS, ACM'S Special Interest Group on Performance Evaluation
	  image: logos/sigmetrics-small.png
	  link:  http://www.sigmetrics.org
	  date: 2016-01-03


=head2 Command:

        yaml_to_db <gnupod.yaml

=head2 Output:

	#fsdb -F t alttext date image link name role
	ACM, the Association for Computing Machinery	2016-01-01	logos/acm-small.jpg	https://www.acm.org/	ACM	sponsor
	SIGCOMM, ACM'S Special Interest Group on Communication	2016-01-02	logos/sigcommlogo.png	http://sigcomm.org	SIGCOMM	sponsor
	SIGMETRICS, ACM'S Special Interest Group on Performance Evaluation	2016-01-03	logos/sigmetrics-small.png	http://www.sigmetrics.org	SIGMETRICS	sponsor
	#   | yaml_to_db

=head1 SEE ALSO

L<Fsdb>.


=head1 CLASS FUNCTIONS

=cut

@ISA = qw(Fsdb::Filter);
$VERSION = 2.0;

use strict;
use Pod::Usage;
use Carp;

use YAML::XS;

use Fsdb::Filter;
use Fsdb::IO::Writer;


=head2 new

    $filter = new Fsdb::Filter::yaml_to_db(@arguments);

Create a new yaml_to_db object, taking command-line arguments.

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
	'e|empty=s' => \$self->{_empty},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'log!' => \$self->{_logprog},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	) or pod2usage(2);
    pod2usage(2) if ($#argv >= 0);
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup($) {
    my($self) = @_;

    # xxx: have to read and parse the whole input, a no-no for setup() :-(
    $self->finish_fh_io_option('input');
    my $yaml_str = join('', $self->{_in}->getlines);
    my $yaml = $self->{_yaml} = Load($yaml_str);

    croak($self->{_prog} . ": yaml is not in expected format (toplevel list)\n")
        if (ref $yaml ne 'ARRAY');

    #
    # allocate columns
    #
    $self->finish_fh_io_option('input');
    my $ncols = -1;
    my @cols;
    my %cols_hash;
    my $record_no = 0;
    foreach my $href (@$yaml) {
        croak($self->{_prog} . ": yaml is not in expected format, record $record_no is not a dictionary\n")
	    if (ref $href ne 'HASH');
	foreach (sort keys %$href) {
	    next if (defined($cols_hash{$_}));
	    $ncols++;
	    $cols[$ncols] = $_;
	    $cols_hash{$_} = $ncols;
	};
	$record_no++;
    };
    $self->{_ncols} = $ncols;
    $self->{_cols} = \@cols;
    $self->{_cols_hash} = \%cols_hash;

    $self->finish_io_option('output', -fscode => 't', -cols => \@cols);
    
}


=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run($) {
    my($self) = @_;

    my $write_fastpath_sub = $self->{_out}->fastpath_sub();

    my $ncols = $self->{_ncols};
    my $cols_href = $self->{_cols_hash};
	
    my @empty_row = ($self->{_empty}) x $ncols;
    my $record_no = 0;
    foreach my $href (@{$self->{_yaml}}) {
	my(@row) = @empty_row;
	$record_no++;
	foreach (keys %$href) {
	    my $i = $cols_href->{$_};  # $out->col_to_i($_);
	    if (!defined($i)) {
		warn $self->{_prog} . ": unknown field $_ in record $record_no.\n";
	    } else {
		$row[$i] = $href->{$_}; 
	    };
	};
	grep { s/\t/ /g; } @row;   # clean up for fsdb double-space separator
	grep { s/^ *$/$self->{_empty}/g; } @row;  # add null values for fields
	&{$write_fastpath_sub}(\@row);
    };
}



=head1 AUTHOR and COPYRIGHT

Copyright (C) 2011-2018 by John Heidemann <johnh@isi.edu>

This program is distributed under terms of the GNU general
public license, version 2.  See the file COPYING
with the distribution for details.

=cut

1;
