#!/usr/bin/perl

#
# xml_to_db.pm
# Copyright (C) 2011-2018 by John Heidemann <johnh@isi.edu>
#
# This program is distributed under terms of the GNU general
# public license, version 2.  See the file COPYING
# in $dblib for details.
#

package Fsdb::Filter::xml_to_db;

=head1 NAME

xml_to_db - convert a subset of XML into fsdb

=head1 SYNOPSIS

    xml_to_db -k EntityField <source.xml

=head1 DESCRIPTION

Converts a I<very limited> subset of XML into Fsdb format.

The input is XML-format (I<not> fsdb).
The input is parsed as XML, and each entity
of type ENTITYFIELD is extracted as a row.
ENTITYFIELD can have mutliple components separated by slashes
to walk down the XML tree, if necessary.

The input XML file is assumed to be I<very simple>.
All rows are assumed to be sequential in one entity.
Any other than the specified ENTITYFIELD are ignored.
The schema is assumed to be defined by the first instances of that field.

The output is two-space-separated fsdb.
(Someday more general field separators should be supported.)
Fsdb fields are normalized version of the CSV file:
spaces are converted to single underscores.

=head1 OPTIONS

=over 4

=item B<-e> EmptyValue or B<--empty>

Specify the value newly created columns get.

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

	<?xml version='1.0' standalone='yes'?>
	<gnuPod>
	 <files>
	  <file addtime="3389919728" album="Born to Pick" artist="7th Day Buskers" title="Loch Lamor" />
	  <file addtime="3389919728" album="Born to Pick" artist="7th Day Buskers" title="The Floods" />
	  <file addtime="3389919735" album="Copland Conducts Copland" artist="Aaron Copland" title="Our Town" />
	 </files>
	 <playlist name="new shows" plid="97241" >
	   <regex artist="^(Le Show|This American Life)$" />
	 </playlist>
	</gnuPod>

=head2 Command:

        xml_to_db -k files/file <gnupod.xml

=head2 Output:

	#fsdb -F S addtime album artist title
	3389919728  Born to Pick  7th Day Buskers  Loch Lamor
	3389919728  Born to Pick  7th Day Buskers  The Floods
	3389919735  Copland Conducts Copland  Aaron Copland  Our Town
	#   | xml_to_db -k files/file

=head1 SEE ALSO

L<Fsdb>.


=head1 CLASS FUNCTIONS

=cut

@ISA = qw(Fsdb::Filter);
$VERSION = 2.0;

use strict;
use Pod::Usage;
use Carp;

use XML::Simple;

use Fsdb::Filter;
use Fsdb::IO::Writer;


=head2 new

    $filter = new Fsdb::Filter::xml_to_db(@arguments);

Create a new xml_to_db object, taking command-line arguments.

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
    $self->{_entity} = undef;
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
	'k|key|entity=s' => \$self->{_entity},
	'i|input=s' => sub { $self->parse_io_option('input', @_); },
	'log!' => \$self->{_logprog},
	'o|output=s' => sub { $self->parse_io_option('output', @_); },
	) or pod2usage(2);
    pod2usage(2) if ($#argv >= 0);
}

=head2 _find_entities

    $filter->_find_entities

Internal: walk the ENTITYFIELD specification through the XML::Simple data structure.
Returns an aref.

=cut
sub _find_entities {
    my($self) = @_;
    croak($self->{_prog} . ": no XML input.\n") if (!defined($self->{_xml_in}));
    my @entity_path = split(m@/@, $self->{_entity});
    my $href = $self->{_xml_in};
    my $last_entity = pop(@entity_path);
    foreach (@entity_path) {
	croak($self->{_prog} . ": missing element $_ of entity path.\n")
	    if (!defined($href->{$_}));
	croak($self->{_prog} . ": element $_ of entity path is not href.\n")
	    if (ref($href->{$_}) ne 'HASH');
	$href = $href->{$_};
    };
    croak($self->{_prog} . ": last $last_entity of entity path is not present.\n")
        if (!defined($href->{$last_entity}));
    if (ref($href->{$last_entity}) eq 'ARRAY') {
	return $href->{$last_entity};
    } elsif (ref($href->{$last_entity}) eq 'HASH') {
	my @a;
	$href = $href->{$last_entity};
	foreach (keys %$href) {
	    push(@a, $href->{$_});
	};
	return \@a;
    } else {
	croak($self->{_prog} . ": last $last_entity of entity path is not an aref or href.\n");
    };
}

=head2 setup

    $filter->setup();

Internal: setup, parse headers.

=cut

sub setup ($) {
    my($self) = @_;

    pod2usage(2) if (!defined($self->{_entity}));

    $self->finish_fh_io_option('input');

    my $xs = $self->{_xs} = new XML::Simple;

    # xxx: have to read and parse the whole input, a no-no for setup() :-(
    $self->{_xml_in} = $self->{_xs}->XMLin($self->{_in});
    my $entities_aref = $self->_find_entities();

    my(@columns) = sort keys %{$entities_aref->[0]};

    $self->finish_io_option('output', -fscode => 'S', -cols => \@columns);
}

=head2 run

    $filter->run();

Internal: run over each rows.

=cut
sub run ($) {
    my($self) = @_;

    my $write_fastpath_sub = $self->{_out}->fastpath_sub();

    my $out = $self->{_out};
    my $cols_aref = $out->cols();
    my %cols_hash;
    my $ncols = 0;
    foreach (@$cols_aref) {
	$cols_hash{$_} = $ncols++;
    };

    my @empty_row = ($self->{_empty}) x $ncols;
    my $record_no = 0;
    foreach my $ent (@{$self->_find_entities()}) {
	my(@row) = @empty_row;
	$record_no++;
	foreach (keys %$ent) {
	    my $i = $cols_hash{$_};  # $out->col_to_i($_);
	    if (!defined($i)) {
		warn $self->{_prog} . ": unknown field $_ in record $record_no.\n";
	    } else {
		$row[$i] = $ent->{$_}; 
	    };
	};
	grep { s/  +/ /g; } @row;   # clean up for fsdb double-space separator
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
