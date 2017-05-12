package HTML::FormHandlerX::Field::URI::HTTP;

# ABSTRACT: an HTTP URI field

use version; our $VERSION = version->declare('v0.4');

use HTML::FormHandler::Moose;
extends 'HTML::FormHandler::Field::Text';

use URI;
use Regexp::Common qw(URI);

has 'scheme' => (
    is       => 'rw',
    isa      => 'RegexpRef',
    required => 1,
    default  => sub {qr/https?/i},
);

has 'inflate' => (
    is      => 'rw',
    isa     => 'Bool',
    default => 1,
);

our $class_messages = { 'uri_http_invalid' => 'HTTP URI is invalid.' };

sub get_class_messages {
    my $self = shift;
    return { %{ $self->next::method }, %{$class_messages}, };
}

sub validate {
    my $self = shift;
    my $uri  = $self->value;

    my $is_valid = 0;
    my $regex = $RE{URI}{HTTP}{ -scheme => $self->scheme };
    if ($uri =~ m{^$regex$}) {
        $is_valid = 1;
        $self->_set_value($self->inflate ? URI->new($uri) : $uri);
    } else {
        $self->add_error($self->get_message('uri_http_invalid'));
    }

    return $is_valid;
}

__PACKAGE__->meta->make_immutable;
use namespace::autoclean;
1;

__END__

=pod

=head1 NAME

HTML::FormHandlerX::Field::URI::HTTP - an HTTP URI field

=head1 VERSION

version v0.4

=head1 SYNOPSIS

This field inherits from a Text field and is used to validate HTTP(S) URIs.
Validated values are inflated into an L<URI> object.

 has_field 'url' => (
     type    => 'URI::HTTP',
     scheme  => qr/https?/i,  ## default
     inflate => 1,            ## default
 );

=head1 METHODS

=head2 scheme

This method is used to set the type of regex used for validating the URI. By
default both HTTP and HTTPS URIs are marked as valid. You can set this to only
validate HTTP or HTTPS if you wish:

 scheme => qr/http/i,   # only validate HTTP URIs
 scheme => qr/https/i,  # only validate HTTPS URIs
 scheme => qr/https?/i, # validate both HTTP and HTTPS (default behaviour)

=head2 inflate

A boolean value that is checked whether or not the URL should be inflated into
the L<URI> object. Default is true.

=head1 SEE ALSO

=over 4

=item L<HTML::FormHandler>

=item L<HTML::FormHandler::Field::Text>

=item L<Regexp::Common::URI::http>

=item L<URI>

=back

=head1 AUTHOR

Roman F. <romanf@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Roman F..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
