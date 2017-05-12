package HTTP::Headers::ActionPack::ContentNegotiation;
BEGIN {
  $HTTP::Headers::ActionPack::ContentNegotiation::AUTHORITY = 'cpan:STEVAN';
}
{
  $HTTP::Headers::ActionPack::ContentNegotiation::VERSION = '0.09';
}
# ABSTRACT: A class to handle content negotiation

use strict;
use warnings;

use Carp         qw[ confess ];
use Scalar::Util qw[ blessed ];
use List::Util   qw[ first ];

sub new {
    my $class       = shift;
    my $action_pack = shift;

    (blessed $action_pack && $action_pack->isa('HTTP::Headers::ActionPack'))
        || confess "You must supply an instance of HTTP::Headers::ActionPack";

    bless { action_pack => $action_pack } => $class;
}

sub action_pack { (shift)->{'action_pack'} }

sub choose_media_type {
    my ($self, $provided, $header) = @_;
    my $requested       = blessed $header ? $header : $self->action_pack->create( 'MediaTypeList' => $header );
    my $parsed_provided = [ map { $self->action_pack->create( 'MediaType' => $_ ) } @$provided ];

    my $chosen;
    foreach my $request ( $requested->iterable ) {
        my $requested_type = $request->[1];
        $chosen = _media_match( $requested_type, $parsed_provided );
        return $chosen if $chosen;
    }

    return;
}

sub choose_language {
    my ($self, $provided, $header) = @_;

    return $self->_make_choice(
        choices => $provided,
        header  => $header,
        class   => 'AcceptLanguage',
        matcher => \&_language_match,
    );
}

sub choose_charset {
    my ($self, $provided, $header) = @_;

    # NOTE:
    # Making the default charset UTF-8, which
    # is maybe sensible, I dunno.
    # - SL
    return $self->_make_choice(
        choices => $provided,
        header  => $header,
        class   => 'AcceptCharset',
        default => 'UTF-8',
        matcher => \&_simple_match,
    );
}

sub choose_encoding {
    my ($self, $provided, $header) = @_;

    return $self->_make_choice(
        choices => $provided,
        header  => $header,
        class   => 'PriorityList',
        default => 'identity',
        matcher => \&_simple_match,
    );
}

sub _make_choice {
    my $self = shift;
    my %args = @_;

    my ($choices, $header, $class, $default, $matcher)
        = @args{qw( choices header class default matcher )};

    return if @$choices == 0;
    return if $header eq '';

    my $accepted         = blessed $header ? $header : $self->action_pack->create( $class => $header );
    my $star_priority    = $accepted->priority_of( '*' );

    my @canonical = map {
        my $c = $accepted->canonicalize_choice($_);
        $c ? [ $_, $c ] : ()
    } @$choices;

    my ($default_ok, $any_ok);

    if ($default) {
        $default = $accepted->canonicalize_choice($default);
        my $default_priority = $accepted->priority_of( $args{default} );

        if ( not defined $default_priority ) {
            if ( defined $star_priority && $star_priority == 0.0 ) {
                $default_ok = 0;
            }
            else {
                $default_ok = 1;
            }
        }
        elsif ( $default_priority == 0.0 ) {
            $default_ok = 0;
        }
        else {
            $default_ok = 1;
        }
    }

    if ( not defined $star_priority ) {
        $any_ok = 0;
    }
    elsif ( $star_priority == 0.0 ) {
        $any_ok = 0;
    }
    else {
        $any_ok = 1;
    }

    my $chosen;
    for my $item ($accepted->iterable) {
        my ($priority, $acceptable) = @$item;

        next if $priority == 0;

        if (my $match = first { $matcher->( $acceptable, $_->[1] ) } @canonical) {
            $chosen = $match->[0];
            last;
        }
    }

    return $chosen if $chosen;

    if ($any_ok) {
        my $match = first {
            my $priority = $accepted->priority_of( $_->[1] );
            return 1 unless defined $priority && $priority == 0;
            return 0;
        }
        @canonical;

        return $match->[0] if $match;
    }

    if ( $default && $default_ok ) {
        my $match = first { $matcher->( $default, $_->[1] ) } @canonical;
        if ($match) {
            my $priority = $accepted->priority_of( $match->[1] );
            return $match->[0] unless defined $priority && $priority == 0;
        }
    }

    return;
}

## ....

sub _media_match {
    my ($requested, $provided) = @_;
    return $provided->[0] if $requested->matches_all;
    return first { $_->match( $requested ) } @$provided;
}

sub _language_match {
    my ($range, $tag) = @_;
    ((lc $range) eq (lc $tag)) || $range eq "*" || $tag =~ /^$range\-/i;
}

sub _simple_match {
    return $_[0] eq $_[1];
}

1;

__END__

=pod

=head1 NAME

HTTP::Headers::ActionPack::ContentNegotiation - A class to handle content negotiation

=head1 VERSION

version 0.09

=head1 SYNOPSIS

  use HTTP::Headers::ActionPack;

  my $n = HTTP::Headers::ActionPack->new->get_content_negotiator;

  # matches text/html; charset="iso8859-1"
  $n->choose_media_type(
      ["text/html", "text/html;charset=iso8859-1" ],
      "text/html;charset=iso8859-1, application/xml"
  );

  # matches en-US
  $n->choose_language(
      ['en-US', 'es'],
      "da, en-gb;q=0.8, en;q=0.7"
  );

  # matches US-ASCII
  $n->choose_charset(
      [ "UTF-8", "US-ASCII" ],
      "US-ASCII, UTF-8"
  );

  # matches gzip
  $n->choose_encoding(
      [ "gzip", "identity" },
      "gzip, identity;q=0.7"
  );

=head1 DESCRIPTION

This class provides a set of methods used for content negotiation. It makes
full use of all the header objects, such as L<HTTP::Headers::ActionPack::MediaType>,
L<HTTP::Headers::ActionPack::MediaTypeList> and L<HTTP::Headers::ActionPack::PriorityList>.

Content negotiation is a tricky business, it needs to account for such
things as the quality rating, order of elements (both in the header and
in the list of provided items) and in the case of media types it gets
even messier. This module does it's best to figure things out and do what
is expected on it. We have included a number of examples from the RFC
documents in our test suite as well.

=head1 METHODS

=over 4

=item C<choose_media_type ( $provided, $header )>

Given an ARRAY ref of media type strings and an HTTP header, this will
return the appropriately matching L<HTTP::Headers::ActionPack::MediaType>
instance.

=item C<choose_language ( $provided, $header )>

Given a list of language codes and an HTTP header value, this will attempt
to negotiate the best language match. It will return the language string
that best matched.

=item C<choose_charset ( $provided, $header )>

Given a list of charset names and an HTTP header value, this will attempt
to negotiate the best charset match. It will return the name of the charset
that best matched.

=item C<choose_encoding ( $provided, $header )>

Given a list of encoding names and an HTTP header value, this will attempt
to negotiate the best encoding match. It will return the name of the encoding
which best matched.

=back

=head1 SEE ALSO

L<HTTP::Negotiate>

There is nothing wrong with this module, however it attempts to answer all
the negotiation questions at once, whereas this module allows you to do it
one thing at a time.

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
