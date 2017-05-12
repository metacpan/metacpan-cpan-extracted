package HTTP::Headers::ActionPack::MediaType;
BEGIN {
  $HTTP::Headers::ActionPack::MediaType::AUTHORITY = 'cpan:STEVAN';
}
{
  $HTTP::Headers::ActionPack::MediaType::VERSION = '0.09';
}
# ABSTRACT: A Media Type

use strict;
use warnings;

use Scalar::Util qw[ blessed ];

use parent 'HTTP::Headers::ActionPack::Core::BaseHeaderType';

sub type  { (shift)->subject }
sub major { (split '/' => (shift)->type)[0] }
sub minor { (split '/' => (shift)->type)[1] }

sub matches_all {
    my $self = shift;
    $self->type eq '*/*' && $self->params_are_empty
        ? 1 : 0;
}

# must be exactly the same
sub equals {
    my ($self, $other) = @_;
    $other = (ref $self)->new_from_string( $other ) unless blessed $other;
    $other->type eq $self->type && _compare_params( $self->params, $other->params )
        ? 1 : 0;
}

# types must be compatible and params much match exactly
sub exact_match {
    my ($self, $other) = @_;
    $other = (ref $self)->new_from_string( $other ) unless blessed $other;
    $self->type_matches( $other ) && _compare_params( $self->params, $other->params )
        ? 1 : 0;
}

# types must be be compatible and params should align
sub match {
    my ($self, $other) = @_;
    $other = (ref $self)->new_from_string( $other ) unless blessed $other;
    $self->type_matches( $other ) && $self->params_match( $other->params )
        ? 1 : 0;
}

## ...

sub type_matches {
    my ($self, $other) = @_;
    return 1 if $other->type eq '*' || $other->type eq '*/*' || $other->type eq $self->type;
    $other->major eq $self->major && $other->minor eq '*'
        ? 1 : 0;
}

sub params_match {
    my ($self, $other) = @_;
    my $params = $self->params;
    foreach my $k ( keys %$other ) {
        next if $k eq 'q';
        return 0 if not exists $params->{ $k };
        return 0 if $params->{ $k } ne $other->{ $k };
    }
    return 1;
}

## ...

sub _compare_params {
    my ($left, $right) = @_;
    my @left_keys  = sort grep { $_ ne 'q' } keys %$left;
    my @right_keys = sort grep { $_ ne 'q' } keys %$right;

    return 0 unless (scalar @left_keys) == (scalar @right_keys);

    foreach my $i ( 0 .. $#left_keys ) {
        return 0 unless $left_keys[$i] eq $right_keys[$i];
        return 0 unless $left->{ $left_keys[$i] } eq $right->{ $right_keys[$i] };
    }

    return 1;
}

1;

__END__

=pod

=head1 NAME

HTTP::Headers::ActionPack::MediaType - A Media Type

=head1 VERSION

version 0.09

=head1 SYNOPSIS

  use HTTP::Headers::ActionPack::MediaType;

  # normal constructor
  my $mt = HTTP::Headers::ActionPack::MediaType->new(
      'application/xml' => (
          'q'       => 0.5,
          'charset' => 'UTF-8'
      )
  );

  # construct from string
  my $mt = HTTP::Headers::ActionPack::MediaType->new_from_string(
      'application/xml; q=0.5; charset=UTF-8'
  );

=head1 DESCRIPTION

This is an object which represents an HTTP media type
definition. This is most often found as a member of a
L<HTTP::Headers::ActionPack::MediaTypeList> object.

=head1 METHODS

=over 4

=item C<type>

Accessor for the type.

=item C<major>

The major portion of the media type name.

=item C<minor>

The minor portion of the media type name.

=item C<matches_all>

A media type matched all if the type is C<*/*>
and if it has no parameters.

=item C<equals ( $media_type | $media_type_string )>

This will attempt to determine if the C<$media_type> is
exactly the same as itself. If given a C<$media_type_string>
it will parse it into an object.

In order for two type to be equal, the types must match
exactly and the parameters much match exactly.

=item C<exact_match ( $media_type | $media_type_string )>

This will attempt to determine if the C<$media_type> is
a match with itself using the C<type_matches> method below.
If given a C<$media_type_string> it will parse it into an
object.

In order for an exact match to occur it the types must
be compatible and the parameters much match exactly.

=item C<match ( $media_type | $media_type_string )>

This will attempt to determine if the C<$media_type> is
a match with itself using the C<type_matches> method and
C<params_match> method below. If given a C<$media_type_string>
it will parse it into an object.

In order for an exact match to occur it the types must
be compatible and the parameters must be a subset.

=item C<type_matches ( $media_type | $media_type_string )>

This will determine type compatibility, properly handling
the C<*> types and major and minor elements of the type.

=item C<params_match ( $parameters )>

This determines if the C<$parameters> are a subset of the
invocants parameters.

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
