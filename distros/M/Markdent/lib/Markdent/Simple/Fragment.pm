package Markdent::Simple::Fragment;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.26';

use Markdent::Handler::HTMLStream::Fragment;
use Markdent::Parser;
use Markdent::Types qw( ArrayRef Str );
use MooseX::Params::Validate qw( validated_list );

use Moose;
use MooseX::StrictConstructor;

with 'Markdent::Role::Simple';

sub markdown_to_html {
    my $self = shift;
    my ( $dialects, $markdown ) = validated_list(
        \@_,
        dialects => {
            isa => Str | ( ArrayRef [Str] ), default => [],
        },
        markdown => { isa => Str },
    );

    my $handler_class = 'Markdent::Handler::HTMLStream::Fragment';

    return $self->_parse_markdown(
        $markdown,
        $dialects,
        $handler_class,
    );
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Convert Markdown to an HTML Fragment

__END__

=pod

=head1 NAME

Markdent::Simple::Fragment - Convert Markdown to an HTML Fragment

=head1 VERSION

version 0.26

=head1 SYNOPSIS

    use Markdent::Simple::Fragment;

    my $mds  = Markdent::Simple::Fragment->new();
    my $html = $mds->markdown_to_html(
        markdown => $markdown,
    );

=head1 DESCRIPTION

This class provides a very simple interface for converting Markdown to an HTML fragment.

=head1 METHODS

This class provides the following methods:

=head2 Markdent::Simple::Fragment->new()

Creates a new Markdent::Simple::Fragment object.

=head2 $mdf->markdown_to_html( markdown => $markdown )

This method turns Markdown into HTML.

You can also provide an optional "dialects" parameter.

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
