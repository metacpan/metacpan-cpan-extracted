package JavaScript::Code::Element;

use strict;
use vars qw[ $VERSION @RESERVEDWORDS ];
use base qw[ JavaScript::Code::Accessor Clone ];

$VERSION = '0.08';

@RESERVEDWORDS = qw [
  abstract boolean break byte
  case catch char class const continue
  default delete do double
  else export extends
  false final finally float for function
  goto
  if implements in instanceof int
  long
  native new null
  package private protected public
  return
  short static super switch synchronized
  this thow throws transient true try typeof
  var void
  while with
];

use overload
  'eq' => sub { 0 },
  '==' => sub { 0 };

__PACKAGE__->mk_accessors(qw[ parent ]);

=head1 NAME

JavaScript::Code::Element - A JavaScript Element

=head1 DESCRIPTION

Base class for javascript elements like blocks, variables, functions and so on.

=head1 METHODS

=head2 new

=head2 $self->clone( )

Clones the element.

=cut

=head2 $self->parent( )

The parent element.

=cut

=head1 SEE ALSO

L<JavaScript::Code>

=head1 AUTHOR

Sascha Kiefer, C<esskar@cpan.org>

=head1 LICENSE

This library is free software, you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

=head2 $self->get_indenting( )

=cut

sub get_indenting {
    my ( $self, $intend ) = @_;

    return '' unless $intend > 1;
    return '    ' x ( $intend - 1 );
}

=head2 $self->exists_in_parent( )

=cut

sub exists_in_parent {
    my ( $self, $obj, $parent ) = @_;

    unless ( defined $parent ) {
        $parent = $self->parent;
        return 0 unless defined $parent;

        return $self->exists_in_parent( $obj, $parent );
    }

    if ( $parent->can('elements') ) {
        foreach my $element ( @{ $parent->elements } ) {
            last
              if Scalar::Util::refaddr($element) ==
              Scalar::Util::refaddr($self);
            next unless $element->isa('JavaScript::Code::Variable');
            return 1 if $obj eq $element;

        }
    }

    return $parent->exists_in_parent($obj);
}

{    # I do not like this, but well ... :-)

    my %ReservedWords = map { ( $_, 1 ) } @RESERVEDWORDS;

=head2 $self->is_valid_name( )

=cut

    sub is_valid_name {
        my ( $self, $name, $built_in ) = @_;

        return 0 if !$built_in and exists $ReservedWords{$name};
        return $name =~ m{^[a-zA-Z][a-zA-Z0-9_]*$};
    }
}

1;

