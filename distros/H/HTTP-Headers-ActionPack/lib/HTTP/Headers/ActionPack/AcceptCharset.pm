package HTTP::Headers::ActionPack::AcceptCharset;
# ABSTRACT: A Priority List customized for Media Types

use strict;
use warnings;

our $VERSION = '0.10';

use Encode qw[ find_encoding ];

use parent 'HTTP::Headers::ActionPack::PriorityList';

sub new_from_string {
    my $self = shift->SUPER::new_from_string(@_);
    # From RFC-2616 sec14.2
    # If no "*" is present in an Accept-Charset
    # field, then all character sets not explicitly
    # mentioned get a quality value of 0, except for
    # ISO-8859-1, which gets a quality value of 1
    # if not explicitly mentioned.
    unless ( defined $self->priority_of('*')
        || defined $self->priority_of('ISO-8859-1') ) {

        $self->add( 1 => 'ISO-8859-1' );
    }

    return $self;
}

sub canonicalize_choice {
    return unless defined $_[1];
    return '*' if $_[1] eq '*';
    my $charset = find_encoding($_[1])
        or return;
    return $charset->mime_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

HTTP::Headers::ActionPack::AcceptCharset - A Priority List customized for Media Types

=head1 VERSION

version 0.10

=head1 SYNOPSIS

  use HTTP::Headers::ActionPack::AcceptCharset;

  # normal constructor
  my $list = HTTP::Headers::ActionPack::AcceptCharset->new(
      [ 1.0 => 'UTF-8' ],
      [ 0.7 => 'ISO-8859-1' ],
  );

  # or from a string
  my $list = HTTP::Headers::ActionPack::AcceptCharsetList->new_from_string(
      'UTF-8; q=1.0, ISO-8859-1; q=0.7'
  );

=head1 DESCRIPTION

This is a subclass of the L<HTTP::Headers::ActionPack::PriorityList>
class with some charset specific features.

=head1 METHODS

=over 4

=item C<new_from_string>

This method overrides the default constructor to add some additional logic
required by RFC-2616. If an Accept-Charset header does not explicitly define
the priority for "*" or "ISO-8859-1", then the default priority for
"ISO-8859-1" must be set to 1.0.

Note that we do not override the C<new> method. If you are passing an
explicitly list of values to the constructor we assume you know what you are
doing.

=item C<canonicalize_choice>

This takes a string containing a character set name and returns the canonical
MIME name for the character set. For example, it transforms "utf8" to "UTF-8".

=back

=head1 SUPPORT

Bugs may be submitted at L<https://github.com/sartak/http-headers-actionpack/issues>.

=head1 SOURCE

The source code repository for HTTP-Headers-ActionPack can be found at L<https://github.com/sartak/http-headers-actionpack>.

=head1 AUTHORS

=over 4

=item *

Stevan Little <stevan@cpan.org>

=item *

Dave Rolsky <autarch@urth.org>

=item *

Robert Rothenberg <perl@rhizomnic.com>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 - 2026 by Infinity Interactive, Inc.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

The full text of the license can be found in the
F<LICENSE> file included with this distribution.

=cut
