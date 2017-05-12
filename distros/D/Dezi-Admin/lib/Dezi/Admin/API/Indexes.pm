package Dezi::Admin::API::Indexes;
use strict;
use warnings;
use Carp;
use base qw( Plack::Component );
use Data::Dump qw( dump );
use Plack::Util::Accessor qw(
    debug
    engine
);
use JSON;
use Plack::Middleware::REST::Util;
use Dezi::Admin::Utils;
use Dezi::Admin::API::Response;

our $VERSION = '0.006';

our @FIELDS = ( 'path', 'config', );

sub get_list {
    my ( $self, $req ) = @_;

    # we don't actually need the sql,
    # but the param parsing is convenient.
    my %sql = Dezi::Admin::Utils::params_to_sql( $req, 'ignored' );

    #dump \%sql;

    my $list  = [];
    my $index = $self->engine->index;
    my $total = scalar @$index;
    for my $idx ( @{ $self->engine->searcher->invindex } ) {
        my $res = {
            path   => "$idx",
            config => $idx->get_header->data,
        };
        push @$list, $res;
    }

    my $resp = Dezi::Admin::API::Response->new(
        total   => $total,
        results => $list,

    );
    $resp->metaData->{fields}   = [@FIELDS];
    $resp->metaData->{sortInfo} = {
        direction => ( $sql{direction} || 'ASC' ),
        field     => ( $sql{sort}      || 'path' ),
    };

    $resp->metaData->{limit} = $sql{limit};
    $resp->metaData->{start} = $sql{offset};

    return $resp;
}

sub get_index {
    my ( $self, $req ) = @_;
    my $id = request_id( $req->env );

    # TODO

    return {};
}

#######################################################
## internal packages for Plack::Middleware::REST
##

package    # noindex
    Dezi::Admin::API::Indexes::GET;

use base qw( Dezi::Admin::API::Indexes );

sub call {
    my ( $self, $env ) = @_;
    my $req  = Plack::Request->new($env);
    my $idx  = $self->get_index($req);
    my $resp = $req->new_response;
    $resp->status(200) unless $resp->status;
    $resp->content_type(Dezi::Admin::Utils::json_mime_type)
        unless $resp->content_type;
    $resp->body($idx);
    return $resp->finalize;
}

package    # noindex
    Dezi::Admin::API::Indexes::LIST;

use base qw( Dezi::Admin::API::Indexes );

sub call {
    my ( $self, $env ) = @_;
    my $req  = Plack::Request->new($env);
    my $list = $self->get_list($req);
    my $resp = $req->new_response;
    $resp->status(200) unless $resp->status;
    $resp->content_type(Dezi::Admin::Utils::json_mime_type)
        unless $resp->content_type;
    $resp->body("$list");
    return $resp->finalize;
}

1;

__END__

=head1 NAME

Dezi::Admin::API::Indexes - Dezi administration API to index metadata

=head1 SYNOPSIS

 /api/indexes?q=foo&sort=name&dir=asc&limit=10&offset=0

=head1 DESCRIPTION

Dezi::Admin::API::Stats isa L<Plack::Component>.

=head1 METHODS

=head2 get_list

Returns L<Dezi::Admin::API::Response> object representing metadata for
one or more indexes matching GET params.

=head2 get_index

Returns L<Dezi::Admin::API::Response> object for a single index.

=head1 AUTHOR

Peter Karman, C<< <karman at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dezi-admin at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dezi-Admin>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dezi::Admin


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dezi-Admin>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dezi-Admin>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dezi-Admin>

=item * Search CPAN

L<http://search.cpan.org/dist/Dezi-Admin/>

=back

=head1 COPYRIGHT & LICENSE

Copyright 2013 Peter Karman.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut
