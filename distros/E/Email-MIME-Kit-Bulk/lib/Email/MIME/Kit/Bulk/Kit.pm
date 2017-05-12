package Email::MIME::Kit::Bulk::Kit;
our $AUTHORITY = 'cpan:YANICK';
# ABSTRACT: Email::MIME kit customized for Email::MIME::Kit::Bulk
$Email::MIME::Kit::Bulk::Kit::VERSION = '0.0.3';

use strict;
use warnings;

use Email::MIME::Kit::Bulk::ManifestReader::JSON;

use Moose;

extends 'Email::MIME::Kit';

has '+_manifest_reader_seed' => (
    default => '=Email::MIME::Kit::Bulk::ManifestReader::JSON',
);

has language => (
    is        => 'ro',
    isa       => 'Str',
    predicate => 'has_language',
);

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Email::MIME::Kit::Bulk::Kit - Email::MIME kit customized for Email::MIME::Kit::Bulk

=head1 VERSION

version 0.0.3

=head1 DESCRIPTION

I<Email::MIME::Kit::Bulk::Kit> extends L<Email::MIME::Kit>. It defaults the C<manifest_reader>
attribute to L<Email::MIME::Kit::Bulk::ManifestReader::JSON>, and add a new 
C<language> attribute.

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
