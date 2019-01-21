package Facebook::Graph::Role::Uri;
$Facebook::Graph::Role::Uri::VERSION = '1.1205';
use Moo::Role;
use URI;

sub uri {
    return URI->new('https://graph.facebook.com')
}

has api_version => (
    is  => 'rw',
    default => 'v3.1',
);

sub generate_versioned_path {
    my ($self, $path) = @_;
    return join('/', $self->api_version, $path);
}


1;

=head1 NAME

Facebook::Graph::Role::Uri - The base URI for the Facebook Graph API.

=head1 VERSION

version 1.1205

=head1 DESCRIPTION

Provides a C<uri> method in any class which returns a L<URI> object that points to the Facebook Graph API.

=head1 LEGAL

Facebook::Graph is Copyright 2010 - 2017 Plain Black Corporation (L<http://www.plainblack.com>) and is licensed under the same terms as Perl itself.

=cut
