package HAL::Resource;
use Moo;
use JSON 'decode_json';
use Filter::signatures;
no warnings 'experimental::signatures';
use feature 'signatures';
use Future;

use Carp qw(croak);

our $VERSION = '0.55';

=head1 NAME

HAL::Resource - wrap a HAL resource

=head1 SYNOPSIS

    my $ua = WWW::Mechanize->new();
    my $res = $ua->get('https://api.example.com/');
    my $r = HAL::Resource->new(
        ua => $ua,
        %{ decode_json( $res->decoded_content ) },
    );

=head1 ABOUT

This module is just a very thin wrapper for HAL resources. If you find this
module useful, I'm very happy to spin it off into its own distribution.

=head1 SEE ALSO

L<Data::HAL> - similar to this module, but lacks a HTTP transfer facility and
currently fails its test suite

L<HAL::Tiny> - a module to generate HAL JSON

L<WebAPI::DBIC::Resource::HAL> - an adapter to export DBIx::Class structures
as HAL

Hypertext Application Language - L<https://en.wikipedia.org/wiki/Hypertext_Application_Language>

=cut

has ua => (
    weaken => 1,
    is => 'ro',
);

has _links => (
    is => 'ro',
);

has _external => (
    is => 'ro',
);

has _embedded => (
    is => 'ro',
);

sub resource_url( $self, $name ) {
    my $l = $self->_links;
    if( exists $l->{$name} ) {
        $l->{$name}->{href}
    }
}

sub resources( $self ) {
    sort keys %{ $self->_links }
}

sub fetch_resource_future( $self, $name, %options ) {
    my $class = $options{ class } || ref $self;
    my $ua = $self->ua;
    my $url = $self->resource_url( $name )
        or croak "Couldn't find resource '$name' in " . join ",", sort keys %{$self->_links};
    Future->done( $ua->get( $url ))->then( sub( $res ) {
        Future->done( bless { ua => $ua, %{ decode_json( $res->content )} } => $class );
    });
}

sub fetch_resource( $self, $name, %options ) {
    $self->fetch_resource_future( $name, %options )->get
}

sub navigate_future( $self, %options ) {
    $options{ class } ||= ref $self;
    my $path = delete $options{ path } || [];
    my $resource = Future->done( $self );
    for my $item (@$path) {
        my $i = $item;
        $resource = $resource->then( sub( $r ) {
            $r->fetch_resource_future( $i, %options );
        });
    };
    $resource
}

sub navigate( $self, %options ) {
    $self->navigate_future( %options )->get
}

sub inflate_list( $self, $class, $list ) {
    my $ua = $self->ua;
    map {
        $class->new( ua => $ua, %$_ )
    } @{ $list };
}

1;

=head1 AUTHOR

Max Maischein, E<lt>corion@cpan.orgE<gt>

=head1 SEE ALSO

L<perl>, L<WWW::Mechanize>.

=head1 REPOSITORY

The public repository of this module is
L<https://github.com/Corion/Finance-Bank-Postbank_de>.

=head1 SUPPORT

The public support forum of this module is
L<https://perlmonks.org/>.

=head1 BUG TRACKER

Please report bugs in this module via the RT CPAN bug queue at
L<https://rt.cpan.org/Public/Dist/Display.html?Name=Finance-Bank-Postbank_de>
or via mail to L<finance-bank-postbank_de-Bugs@rt.cpan.org>.

=head1 COPYRIGHT (c)

Copyright 2003-2018 by Max Maischein C<corion@cpan.org>.

=head1 LICENSE

This module is released under the same terms as Perl itself.

=cut
