package Markdent::Handler::HTMLStream::Document;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.37';

use Markdent::Types;

use Moose;
use MooseX::SemiAffordanceAccessor;

with 'Markdent::Role::HTMLStream';

has title => (
    is       => 'ro',
    isa      => t('Str'),
    required => 1,
);

has charset => (
    is        => 'ro',
    isa       => t('Str'),
    predicate => '_has_charset',
);

has language => (
    is        => 'ro',
    isa       => t('Str'),
    predicate => '_has_language',
);

my $Doctype = <<'EOF';
<!DOCTYPE html>
EOF

sub start_document {
    my $self = shift;

    $self->_stream_raw($Doctype);
    $self->_stream_start_tag(
        'html', {
            $self->_has_language() ? ( lang => $self->language() ) : (),
        },
    );
    $self->_stream_start_tag('head');
    $self->_stream_start_tag( 'meta', { charset => $self->charset() } )
        if $self->_has_charset();
    $self->_stream_start_tag('title');
    $self->_stream_text( $self->title() );
    $self->_stream_end_tag('title');
    $self->_stream_end_tag('head');
    $self->_stream_start_tag('body');
}

sub end_document {
    my $self = shift;

    $self->_stream_end_tag('body');
    $self->_stream_end_tag('html');
}

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Turns Markdent events into a complete HTML document

__END__

=pod

=encoding UTF-8

=head1 NAME

Markdent::Handler::HTMLStream::Document - Turns Markdent events into a complete HTML document

=head1 VERSION

version 0.37

=head1 DESCRIPTION

This class takes an event stream and turns it into a complete HTML document.

=head1 METHODS

This role provides the following methods:

=head2 Markdent::Handler::HTMLStream::Document->new(...)

This method creates a new handler. It accepts the following parameters:

=over 4

=item * title => $title

The title of the document. This is required.

=item * charset => $charset

If provided, a C<< <meta charset="..."> >> tag will be added to the document's
C<< <head> >>.

=item * language => $language

If provided, a "lang" attribute will be added to the document's C<< <html> >>
tag.

=item * output => $fh

The file handle or object to which HTML output will be streamed. If you want
to capture the output in a string, you can open a filehandle to a string:

  my $buffer = q{};
  open my $fh, '>', \$buffer;

If you pass a file handle (or L<IO::Handle> object), then all calls to
C<print()> will be checked, and an error will be thrown.

You can pass an object of any other class, it must implement its own
C<print()> method, and error handling is left up to this method.

=back

=head1 ROLES

This class does the L<Markdent::Role::HTMLStream>,
L<Markdent::Role::EventsAsMethods>, and L<Markdent::Role::Handler> roles.

=head1 BUGS

See L<Markdent> for bug reporting details.

Bugs may be submitted at L<https://github.com/houseabsolute/Markdent/issues>.

I am also usually active on IRC as 'autarch' on C<irc://irc.perl.org>.

=head1 SOURCE

The source code repository for Markdent can be found at L<https://github.com/houseabsolute/Markdent>.

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
