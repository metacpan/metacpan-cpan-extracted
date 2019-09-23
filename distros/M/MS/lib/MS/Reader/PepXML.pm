package MS::Reader::PepXML;

use strict;
use warnings;

use parent qw/MS::Reader::XML/;

use Carp;

use MS::Reader::PepXML::Result;

sub _post_load {

    my ($self) = @_;

    $self->{__curr_list} = $self->{msms_run_summary}->[0];
    $self->SUPER::_post_load();

}


sub _pre_load {

    my ($self) = @_;

    # ---------------------------------------------------------------------------#
    # These tables are the main configuration point between the parser and the
    # specific document schema. For more information, see the documentation
    # for the parent class MS::Reader::XML
    # ---------------------------------------------------------------------------#

    $self->{_toplevel} = 'msms_pipeline_analysis';

    $self->{__record_classes} = {
        spectrum_query => 'MS::Reader::PepXML::Result',
    };

    $self->{_skip_inside} = { map {$_ => 1} qw/
        spectrum_query
    / };

    $self->{_make_index} = { map {$_ => 'spectrum'} qw/
        spectrum_query
    / };

    $self->{_make_named_array} = {
        userParam => 'name',
    };

    $self->{_make_named_hash} = {
        parameter => 'name'
    };

    $self->{_make_anon_array} = { map {$_ => 1} qw/
        data_filter
        msms_run_summary
        specificity
        search_summary
        sequence_search_constraint
        aminoacid_modification
        terminal_modification
        analysis_timestamp
        inputfile
        roc_error_data
        mixture_model
        distribution_point
        mixturemodel_distribution
        posmodel_distribution
        negmodel_distribution
        mixturemodel
        point
        roc_data_point
        error_point
    / };

}

sub fetch_result {

    my ($self, $idx, %args) = @_;
    return $self->fetch_record( $self->{__curr_list}, $idx, %args);

}

sub next_result {

    my ($self) = @_;
    return $self->next_record( $self->{__curr_list} );

}

sub n_lists {

    my ($self) = @_;
    return scalar @{$self->{msms_run_summary}};

}

sub goto_list {

    my ($self, $idx) = @_;
    my $ref = $self->{msms_run_summary}->[$idx];
    $ref->{__pos} = 0;
    $self->{__curr_list} = $ref;

}

sub result_count {

    my ($self) = @_;
    return $self->record_count( $self->{__curr_list} );

}

sub raw_file {

    my ($self, $idx) = @_;
    return $self->{msms_run_summary}->[$idx]->{base_name}
        .  $self->{msms_run_summary}->[$idx]->{raw_data};

}

1;


__END__

=pod

=encoding UTF-8

=head1 NAME

MS::Reader::PepXML - A simple but complete pepXML parser

=head1 SYNOPSIS

    use MS::Reader::PepXML;

    my $search = MS::Reader::PepXML->new('search.pep.xml');

    # for single search files

    while (my $result = $search->next_result) {
        # $result is an MS::Reader::PepXML::Result object
    }

    # for multi-search files

    my $n = $search->n_lists;

    for (0..$n-1) {
        
        $self->goto_list($_);
        while (my $result = $search->next_result) {
            # $result is an MS::Reader::PepXML::Result object
        }
       
    }


=head1 DESCRIPTION

C<MS::Reader::PepXML> is a parser for the pepXML file format for spectral
search results. It aims to provide complete access to the data contents while
not being overburdened by detailed class infrastructure.  Convenience methods
are provided for accessing commonly used data. Users who want to extract data
not accessible through the available methods should examine the data structure
of the parsed object. The C<dump()> method of L<MS::Reader::XML>, from which
this class inherits, provides an easy way of doing so.

=head1 INHERITANCE

C<MS::Reader::PepXML> is a subclass of L<MS::Reader::XML>, which in turn
inherits from L<MS::Reader>, and inherits the methods of these parental
classes. Please see the documentation for those classes for details of
available methods not detailed below.

=head1 METHODS

=head2 new

    my $search = MS::Reader::PepXML->new( $fn,
        use_cache => 0,
        paranoid  => 0,
    );

Takes an input filename (required) and optional argument hash and returns an
C<MS::Reader::PepXML> object. This constructor is inherited directly from
L<MS::Reader>. Available options include:

=over

=item * use_cache — cache fetched records in memory for repeat access
(default: FALSE)

=item * paranoid — when loading index from disk, recalculates MD5 checksum
each time to make sure raw file hasn't changed. This adds (typically) a few
seconds to load times. By default, only file size and mtime are checked.

=back

=head2 next_result
    
    while (my $s = $search->next_result) {
        # do something with $s
    }

Returns an C<MS::Reader::PepXML::Result> object representing the next result
(pepXML element <<spectrum_query>>) in the current result list, or C<undef> if
the end of records has been reached. In a multi-list file (i.e. multiple
<<msms_run_summary>> elements) you must call C<goto_list()> for each one
followed by iterating over the list records.

=head2 fetch_result

    my $s = $search->fetch_result($idx);

Takes a single argument (zero-based record index) and returns an
C<MS::Reader::PepXML::Result> object representing the record at that index.
Throws an exception if the index is out of range.

=head2 result_count

    my $n = $search->result_count;

Returns the number of result records in the current result list (not the same
as the number of results in the file if it contains multiple runs/lists).

=head2 n_lists

    my $n = $search->n_lists;

Returns the number of result lists (pepXML <msms_run_summary> elements) in
the file. If this number is greater than one, individual lists can be iterated
over using C<goto_list()> and C<next_result()>.

=head2 goto_list

    $search->goto_list($idx);

Takes a single argument (zero-based list index) and sets the record pointer to
the first result from that list.

=head2 raw_file

    $search->raw_file($idx);

Takes a single argument (zero-based list index) and returns the raw file path
associated with that list. If index is not provided, index 0 is assumed.

=head1 CAVEATS AND BUGS

The API is in alpha stage and is not guaranteed to be stable.

Please reports bugs or feature requests through the issue tracker at
L<https://github.com/jvolkening/p5-MS/issues>.

=head1 SEE ALSO

=over 4

=item * L<InSilicoSpectro>

=item * L<PepXML::Parser>

=back

=head1 AUTHOR

Jeremy Volkening <jdv@base2bio.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015-2016 Jeremy Volkening

This program is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
details.

You should have received a copy of the GNU General Public License along with
this program.  If not, see <http://www.gnu.org/licenses/>.

=cut
