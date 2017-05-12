package Markdent::Simple::Document;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.26';

use Markdent::Handler::HTMLStream::Document;
use Markdent::Types qw( ArrayRef Str );
use MooseX::Params::Validate qw( validated_list );

use Moose;
use MooseX::StrictConstructor;

with 'Markdent::Role::Simple';

sub markdown_to_html {
    my $self = shift;
    my ( $dialects, $title, $charset, $language, $markdown )
        = validated_list(
        \@_,
        dialects => {
            isa => Str | ( ArrayRef [Str] ), default => [],
        },
        title    => { isa => Str },
        charset  => { isa => Str, optional => 1 },
        language => { isa => Str, optional => 1 },
        markdown => { isa => Str },
        );

    my $handler_class = 'Markdent::Handler::HTMLStream::Document';
    my %handler_p     = (
        title => $title,
        ( $charset  ? ( charset  => $charset )  : () ),
        ( $language ? ( language => $language ) : () ),
    );

    return $self->_parse_markdown(
        $markdown,
        $dialects,
        $handler_class,
        \%handler_p
    );
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Convert Markdown to an HTML Document

__END__

=pod

=head1 NAME

Markdent::Simple::Document - Convert Markdown to an HTML Document

=head1 VERSION

version 0.26

=head1 SYNOPSIS

    use Markdent::Simple::Document;

    my $mds  = Markdent::Simple::Document->new();
    my $html = $mds->markdown_to_html(
        title    => 'My Document',
        markdown => $markdown,
    );

=head1 DESCRIPTION

This class provides a very simple interface for converting Markdown to a
complete HTML document.

=head1 METHODS

This class provides the following methods:

=head2 Markdent::Simple::Document->new()

Creates a new Markdent::Simple::Document object.

=head2 $mds->markdown_to_html( title => $title, markdown => $markdown )

This method turns Markdown into HTML. It accepts the following parameters:

=over 4

=item * title => $title

The title of the document. This is required.

=item * charset => $charset

If provided, a C<< <meta charset="..."> >> tag will be added to the document's
C<< <head> >>.

=item * language => $language

If provided, a "lang" attribute will be added to the document's C<< <html> >>
tag.

=item * dialects => [...]

This can either be a single string or an array ref of strings containing the
class names of dialects. This parameter is optional.

=back

=head1 ROLES

This class does the L<Markdent::Role::Simple> role.

=head1 BUGS

See L<Markdent> for bug reporting details.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
