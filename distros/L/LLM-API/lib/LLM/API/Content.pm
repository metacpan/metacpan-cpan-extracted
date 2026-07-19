package LLM::API::Content;

use strict;
use warnings;

use English qw(-no_match_vars);
use JSON::PP;

our @ACCESSORS = qw(blocks);

__PACKAGE__->follow_best_practice;
__PACKAGE__->mk_accessors(@ACCESSORS);

our $VERSION = '1.0.1';

use parent qw(Class::Accessor::Fast);

########################################################################
sub new {
########################################################################
  my ( $class, $content ) = @_;

  $content = ref $content ? $content : decode_json($content);

  my $self = $class->SUPER::new();

  $self->set_blocks( $content // [] );

  return $self;
}

########################################################################
sub text {
########################################################################
  my ($self) = @_;

  return join q{}, map { $_->{text} // q{} } grep { $_->{type} eq 'text' } @{ $self->get_blocks };
}

########################################################################
sub thinking {
########################################################################
  my ($self) = @_;

  return join qq{\n}, map { $_->{thinking} // q{} } grep { $_->{type} eq 'thinking' } @{ $self->get_blocks };
}

########################################################################
sub tool_uses {
########################################################################
  my ($self) = @_;

  return [ grep { $_->{type} eq 'tool_use' } @{ $self->get_blocks } ];
}

1;

__END__

=pod

=head1 NAME

LLM::API::Content

=head1 DESCRIPTION

Wraps the C<content> array from an Anthropic Messages API response. A
response can contain multiple content blocks of different types (for
example a C<thinking> block followed by a C<text> block, when
adaptive thinking is enabled) - this class does not assume the first
block is the one you want.

=head1 METHODS

=head2 text

Returns the concatenated text of all C<text>-type blocks. Empty
string if there are none.

=head2 thinking

Returns the concatenated thinking content of all C<thinking>-type
blocks, joined by newlines. Empty string if there are none.

=head2 tool_uses

Returns an arrayref of all C<tool_use>-type blocks, unmodified.

=head2 blocks

Returns the raw, unfiltered arrayref of content blocks as received
from the API.

=head1 AUTHOR

Rob Lauer - <rlauer@treasurersbriefcase.com>

=cut
