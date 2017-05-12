package HTTP::Headers::ActionPack::LinkHeader;
BEGIN {
  $HTTP::Headers::ActionPack::LinkHeader::AUTHORITY = 'cpan:STEVAN';
}
{
  $HTTP::Headers::ActionPack::LinkHeader::VERSION = '0.09';
}
# ABSTRACT: A Link

use strict;
use warnings;

use URI::Escape                     qw[ uri_escape uri_unescape ];
use HTTP::Headers::ActionPack::Util qw[ join_header_words ];

use parent 'HTTP::Headers::ActionPack::Core::BaseHeaderType';

sub BUILDARGS {
    my $class = shift;
    my ($href, @params) = @_;

    $href =~ s/^<//;
    $href =~ s/>$//;

    $class->SUPER::BUILDARGS( $href, @params );
}

sub BUILD {
    my $self = shift;
    foreach my $param ( grep { /\*$/ } @{ $self->_param_order } ) {
        my ($encoding, $language, $content) = ( $self->params->{ $param } =~ /^(.*)\'(.*)\'(.*)$/);
        $self->params->{ $param } = {
            encoding => $encoding,
            language => $language,
            content  => uri_unescape( $content )
        };
    }
}

sub href { (shift)->subject         }
sub rel  { (shift)->params->{'rel'} }

sub relation_matches {
    my ($self, $relation) = @_;

    if ( my $rel = $self->params->{'rel'} ) {
        # if it is an extension rel type
        # then it is a URI and it should
        # not be compared in a case-insensitive
        # manner ...
        if ( $rel =~ m!^\w+\://! ) {
            $self->params->{'rel'} eq $relation ? 1 : 0;
        }
        # if it is not a URI, then compare
        # it case-insensitively
        else {
            (lc $self->params->{'rel'} ) eq (lc $relation) ? 1 : 0;
        }
    }
}

sub as_string {
    my $self = shift;

    my @params;
    foreach my $param ( @{ $self->_param_order } ) {
        if ( $param =~ /\*$/ ) {
            my $complex = $self->params->{ $param };
            push @params => ( $param,
                join "'" => (
                    $complex->{'encoding'},
                    $complex->{'language'},
                    uri_escape( $complex->{'content'} ),
                )
            );
        }
        else {
            push @params => ( $param, $self->params->{ $param } );
        }
        my ($encoding, $language, $content) = ( $self->params->{ $param } =~ /^(.*)\'(.*)\'(.*)$/);
    }

    join_header_words( '<' . $self->href . '>', @params );
}

1;

__END__

=pod

=head1 NAME

HTTP::Headers::ActionPack::LinkHeader - A Link

=head1 VERSION

version 0.09

=head1 SYNOPSIS

  use HTTP::Headers::ActionPack::LinkHeader;

  # build from string
  my $link = HTTP::Headers::ActionPack::LinkHeader->new_from_string(
      '<http://example.com/TheBook/chapter2>;rel="previous";title="previous chapter"'
  );

  # normal constructor
  my $link = HTTP::Headers::ActionPack::LinkHeader->new(
      '<http://example.com/TheBook/chapter2>' => (
          rel   => "previous",
          title => "previous chapter"
      )
  );

  # normal constructor, and <> around link are optional
  my $link = HTTP::Headers::ActionPack::LinkHeader->new(
      'http://example.com/TheBook/chapter2' => (
          rel   => "previous",
          title => "previous chapter"
      )
  );

=head1 DESCRIPTION

This is an object which represents an HTTP Link header. It
is most often used as a member of a L<HTTP::Headers::ActionPack::LinkList>
object.

=head1 METHODS

=over 4

=item C<href>

=item C<new_from_string ( $link_header_string )>

This will take an HTTP header Link string
and parse it into and object.

=item C<as_string>

This stringifies the link respecting the
parameter order.

NOTE: This will canonicalize the header such
that it will add a space between each semicolon
and quotes and unquotes all headers appropriately.

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
