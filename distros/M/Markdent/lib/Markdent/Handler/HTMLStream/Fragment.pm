package Markdent::Handler::HTMLStream::Fragment;

use strict;
use warnings;
use namespace::autoclean;

our $VERSION = '0.26';

use Moose;
use MooseX::SemiAffordanceAccessor;

with 'Markdent::Role::HTMLStream';

sub start_document { }
sub end_document   { }

__PACKAGE__->meta()->make_immutable();

1;

# ABSTRACT: Turns Markdent events into an HTML fragment

__END__

=pod

=head1 NAME

Markdent::Handler::HTMLStream::Fragment - Turns Markdent events into an HTML fragment

=head1 VERSION

version 0.26

=head1 DESCRIPTION

This class takes an event stream and turns it into an HTML document, without a
doctype, C<< <html> >>, C<< <head> >> or C<< <body> >> tags.

=head1 METHODS

This role provides the following methods:

=head2 Markdent::Handler::HTMLStream::Document->new(...)

This method creates a new handler. It accepts the following parameters:

=over 4

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

=head1 AUTHOR

Dave Rolsky <autarch@urth.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Dave Rolsky.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
