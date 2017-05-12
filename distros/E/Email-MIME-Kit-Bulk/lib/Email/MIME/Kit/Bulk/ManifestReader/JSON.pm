package Email::MIME::Kit::Bulk::ManifestReader::JSON;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Extension of E::M::K::ManifestReader::JSON for Email::MIME::Kit::Bulk
$Email::MIME::Kit::Bulk::ManifestReader::JSON::VERSION = '0.0.3';

use Moose;

extends 'Email::MIME::Kit::ManifestReader::JSON';

sub read_manifest {
    my ($self) = @_;

    my $manifest = 'manifest.json';
    if ($self->kit->has_language) {
        $manifest = 'manifest.' . $self->kit->language . '.json';
    }

    my $json_ref = $self->kit->kit_reader->get_kit_entry($manifest);

    my $content = JSON->new->decode($$json_ref);
}

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Email::MIME::Kit::Bulk::ManifestReader::JSON - Extension of E::M::K::ManifestReader::JSON for Email::MIME::Kit::Bulk

=head1 VERSION

version 0.0.3

=head1 DESCRIPTION

Extends L<Email::MIME::Kit::ManifestReader::JSON>. The manifest of the 
kit will be 'C<manifest.I<language>.json>', where I<language> is provided
via 'C<targets.json>'. If no language is given, the manifest file defaults
to 'C<manifest.json>'.

=head1 AUTHORS

=over 4

=item *

Jesse Luehrs    <doy@cpan.org>

=item *

Yanick Champoux <yanick.champoux@iinteractive.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Infinity Interactive <contact@iinteractive.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
