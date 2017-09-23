# ========================================================================== #
# lib/JPList/Request.pm  - JPList Request parser module
# Copyright (C) 2017 Exceleron Software, LLC
# ========================================================================== #

package JPList::Request;

use Moose;
use URI::Escape;
use JSON;

with 'JPList::Controls::Filter';
with 'JPList::Controls::Sort';

# ========================================================================== #

=head1 NAME

JPList::Request - JPList Request parser module

=head1 VERSION

Version 0.05

=cut

our $VERSION = '0.05';

=head1 SYNOPSIS

  use JPList::Request;
  my $jplist_req = JPList::Request->new(request_params => $self->request_params);

=head1 DESCRIPTION

The JPList::Request module allows you to decode the request params with all the controls

=head2 ATTRIBUTES

=over 4

=cut

# ========================================================================== #

has 'request_params' => (
    is  => 'rw',
    isa => 'Str'
);

has 'request_data' => (
    is      => 'rw',
    builder => '_decode_request_params',
    lazy    => 1,
    clearer => 'clear_request_data'
);

has 'filter_attrs' => (
    is  => 'rw',
    isa => 'HashRef'
);

has 'filter_data' => (
    is  => 'rw',
    isa => 'ArrayRef'
);

has 'sort_data' => (
    is  => 'rw',
    isa => 'ArrayRef'
);

has 'pagination_data' => (
    is  => 'rw',
    isa => 'HashRef'
);

has 'is_download' => (
    is      => 'rw',
    default => 0
);

# ========================================================================== #

=back

=head2 METHODS

=over 4

=cut

# ========================================================================== #

=item C<decode_data>

Params : $statuses_request

Returns: NONE

Desc   : decode the request params

=cut

sub decode_data
{
    my ($self) = @_;

    if (ref($self->request_data) eq 'ARRAY') {

        $self->_store_status_list($self->request_data);

    }
    else {

        return undef;
    }
}

# ========================================================================== #

=item C<_decode_request_params>

Params : $self->request_params

Returns: Data structure of formatted request data structure

Desc   : decode params

=cut

sub _decode_request_params
{

    my $self = shift;

    return decode_json(uri_unescape($self->request_params));
}

# ========================================================================== #

=item C<_store_status_list>

Params : Request Data

Returns: NONE

Desc   : parses the list of unique actions and computes filter, sort and pagination data

=cut

sub _store_status_list
{
    my ($self, $statuses_request) = @_;

    foreach my $status_req (@$statuses_request) {
        my $action = $status_req->{'action'};
        push(@{$self->{'status_list'}->{$action}}, $status_req);
    }

    $self->_get_filter_data();

    $self->_get_sort_data();

    $self->_get_pagination_data();

    ## Clear unwanted attributes
    $self->clear_request_data();
    delete($self->{'status_list'});
}

# ========================================================================== #

=item C<_get_filter_data>

Params : NONE

Returns: NONE

Desc   : private function to parse filter data

=cut

sub _get_filter_data
{
    my ($self) = @_;

    my @filter_data;

    # This is used to store the values of filter by column name
    # Eg: $jplist->jplist_request->filter_attrs->{'ServiceType'}
    my %filter_attrs;

    foreach my $filter_vals (@{$self->{'status_list'}->{'filter'}}) {
        if ($filter_vals->{'type'} eq 'textbox') {
            my $filter_result = $self->textbox($filter_vals);
            if (defined $filter_result) {
                push(@filter_data, $filter_result);
                $filter_attrs{$filter_result->{'column'}} = $filter_result->{'value'};
            }
        }
        elsif ($filter_vals->{'type'} eq 'filter-drop-down') {
            my $filter_result = $self->filterdropdown($filter_vals);
            if (defined $filter_result) {
                push(@filter_data, $filter_result);
                $filter_attrs{$filter_result->{'column'}} = $filter_result->{'value'};
            }
        }
        elsif ($filter_vals->{'type'} eq 'filter-select') {
            my $filter_result = $self->filterselect($filter_vals);
            if (defined $filter_result) {
                push(@filter_data, $filter_result);
                $filter_attrs{$filter_result->{'column'}} = $filter_result->{'value'};
            }
        }
        elsif ($filter_vals->{'type'} eq 'date-picker-range-filter') {
            my $filter_result = $self->filterdaterange($filter_vals);
            if (defined $filter_result) {
                push(@filter_data, $filter_result);
                $filter_attrs{$filter_result->{'column'}} = $filter_result;
            }
        }
        elsif ($filter_vals->{'type'} eq 'date-picker-filter') {
            my $filter_result = $self->filterdatepicker($filter_vals);
            if (defined $filter_result) {
                push(@filter_data, $filter_result);
                $filter_attrs{$filter_result->{'column'}} = $filter_result->{'value'};
            }
        }
        elsif ($filter_vals->{'type'} eq 'checkbox-group-filter') {
            my $filter_result = $self->checkboxgroup($filter_vals);
            if (defined $filter_result) {
                push(@filter_data, $filter_result);
                $filter_attrs{$filter_result->{'column'}} = $filter_result->{'values'};
            }
        }
        elsif ($filter_vals->{'type'} eq 'button-filter' and $filter_vals->{'name'} eq 'download') {
            print STDERR "[jplist info] download request filter called\n";
            my $data = $filter_vals->{'data'};
            if (    exists($data->{'filterType'})
                and ($data->{'filterType'} eq 'path')
                and exists($data->{'path'})
                and ($data->{'path'} eq '.download'))
            {
                $self->is_download(1);
            }
        }
    }

    $self->filter_data(\@filter_data);
    $self->filter_attrs(\%filter_attrs);
}

# ========================================================================== #

=item C<_get_sort_data>

Params : NONE

Returns: NONE

Desc   : private functiont to parse sort data

=cut

sub _get_sort_data
{
    my ($self) = @_;

    my @sort_data;

    foreach my $sort_vals (@{$self->{'status_list'}->{'sort'}}) {
        if ($sort_vals->{'type'} eq 'sort-drop-down') {
            my $sort_result = $self->sortdropdown($sort_vals);
            push(@sort_data, $sort_result);
        }
        elsif ($sort_vals->{'type'} eq 'sort-select') {
            my $sort_result = $self->sortselect($sort_vals);
            push(@sort_data, $sort_result);
        }
    }

    $self->sort_data(\@sort_data);
}

# ========================================================================== #

=item C<_get_pagination_data>

Params : NONE

Returns: NONE

Desc   : private functiont to parse pagination data

=cut

sub _get_pagination_data
{
    my ($self) = @_;

    my $pagination_data;

    foreach my $paging_vals (@{$self->{'status_list'}->{'paging'}}) {
        my $data = $paging_vals->{'data'};

        if ($data) {
            if ($data->{'currentPage'}) {
                $pagination_data->{'currentPage'} = $data->{'currentPage'};
            }

            if ($data->{'number'}) {
                $pagination_data->{'number'} = $data->{'number'};
            }
        }
    }

    $self->pagination_data($pagination_data);
}

1;

__END__

=back
   
=head1 AUTHORS

Sheeju Alex, <sheeju@exceleron.com>

=head1 BUGS

https://github.com/sheeju/JPList/issues

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc JPList


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=JPList>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/JPList>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/JPList>

=item * Search CPAN

L<http://search.cpan.org/dist/JPList/>

=back

=head1 ACKNOWLEDGEMENTS

Development time supported by Exceleron L<www.exceleron.com|http://www.exceleron.com>.

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2017 Exceleron Software, LLC

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

# vim: ts=4
# vim600: fdm=marker fdl=0 fdc=3
