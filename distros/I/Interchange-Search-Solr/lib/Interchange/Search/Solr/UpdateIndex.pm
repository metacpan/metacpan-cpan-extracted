package Interchange::Search::Solr::UpdateIndex;

use strict;
use warnings;

use Moo;
use Sub::Quote;
use LWP::UserAgent;

=head1 NAME

Interchange::Search::Solr::UpdateIndex

=head1 DESCRIPTION

Updates your Solr index.

=head2 ACCESSORS

=head3 url

Solr URL for your collection, e.g.

    http://localhost:9059/solr/collection1

=cut

has url => (
    is => 'rw',
);


=head3 agent

HTTP user agent object, defaults to a LWP::UserAgent instance.

=cut

has agent => (
    is => 'rw',
    lazy => 1,
    default => sub {LWP::UserAgent->new;},
);

=head3 status_line

HTTP status line.

=cut

has status_line => (
    is => 'rwp',
    lazy => 1,
    default => quote_sub q{return '';},
);

=head2 METHODS

=head3 update

Updates index. Returns 1 on success.

Requires C<$mode> parameter which is either I<full>
or I<delta>.

=cut

sub update {
    my ($self, $mode) = @_;
    my ($update_url, $command, $request, $response);

    # reset status line
    $self->_set_status_line('');

    # construct url and request
    $update_url = $self->_construct_url($mode);
    $response = $self->agent->get($update_url);

    # save status line
    $self->_set_status_line($response->status_line);

    unless ($response->is_success) {
        return;
    }

    return $response;
}

=head3 query

Queries index.

=cut

sub query {
	my ($self, $query) = @_;
	my $url = $self->url . '/select?wt=json&'.$query;
	my $response = $self->agent->get($url);
	print $url."\n\r---------------\n\r";
	return $response;
}

sub _construct_url {
    my ($self, $mode) = @_;

    my $update_url;


    if ($mode eq 'clear') {
        return $self->url . '/update?stream.body=<delete><query>*:*</query></delete>&commit=true';
    }

    $update_url = $self->url . '/dataimport?command=';

    if ($mode eq 'full') {
        $update_url .= 'full-import';
    }
    elsif ($mode eq 'delta') {
        $update_url .= 'delta-import';
    }
    #$update_url .= '&commit=true';
}

=head1 AUTHOR

Stefan Hornburg (Racke), <racke@linuxia.de>

=head1 LICENSE AND COPYRIGHT

Copyright 2013-2021 Stefan Hornburg (Racke) <racke@linuxia.de>.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

1;
