package HTTP::Headers::ActionPack::AcceptCharset;
BEGIN {
  $HTTP::Headers::ActionPack::AcceptCharset::AUTHORITY = 'cpan:STEVAN';
}
{
  $HTTP::Headers::ActionPack::AcceptCharset::VERSION = '0.09';
}
# ABSTRACT: A Priority List customized for Media Types

use strict;
use warnings;

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

=head1 NAME

HTTP::Headers::ActionPack::AcceptCharset - A Priority List customized for Media Types

=head1 VERSION

version 0.09

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

=head1 AUTHOR

Stevan Little <stevan.little@iinteractive.com>

=head1 CONTRIBUTORS

=over 4

=item *

Andrew Nelson <anelson@cpan.org>

=item *

Dave Rolsky <autarch@urth.org>

=item *

Florian Ragwitz <rafl@debian.org>

=item *

Jesse Luehrs <doy@tozt.net>

=item *

Karen Etheridge <ether@cpan.org>

=back

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2012 by Infinity Interactive, Inc..

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
