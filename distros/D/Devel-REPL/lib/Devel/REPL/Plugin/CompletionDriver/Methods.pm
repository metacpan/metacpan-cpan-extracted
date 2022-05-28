use strict;
use warnings;
package Devel::REPL::Plugin::CompletionDriver::Methods;
# ABSTRACT: Complete class or object method names

our $VERSION = '1.003029';

use Devel::REPL::Plugin;
use Devel::REPL::Plugin::Completion;    # die early if cannot load
use namespace::autoclean;

sub BEFORE_PLUGIN {
    my $self = shift;
    for (qw/Completion FindVariable/) {
        $self->load_plugin($_);
    }
}

around complete => sub {
  my $orig = shift;
  my ($self, $text, $document) = @_;

  my $last = $self->last_ppi_element($document);
  my $incomplete = '';

  # handle an incomplete method name, and back up to the ->
  if ($last->isa('PPI::Token::Word')) {
      my $previous = $last->sprevious_sibling
        or return $orig->(@_);
      $previous->isa('PPI::Token::Operator') && $previous->content eq '->'
        or return $orig->(@_);
      $incomplete = $last->content;
      $last = $previous;
  }

  # require a -> here
  return $orig->(@_)
    unless $last->isa('PPI::Token::Operator')
        && $last->content eq '->';

  # ..which is preceded by a word (class name)
  my $previous = $last->sprevious_sibling
    or return $orig->(@_);
  $previous->isa('PPI::Token::Word') || $previous->isa('PPI::Token::Symbol')
    or return $orig->(@_);
  my $class;

  # we have a variable, need to look up its class
  if ($previous->isa('PPI::Token::Symbol')) {
    my $object_ref = $self->find_variable($previous->content)
      or return $orig->(@_);
    $class = blessed($$object_ref)
      or return $orig->(@_);
  }
  else  {
    $class = $previous->content;
  }

  # now we have $class->$incomplete

  my $metaclass = Class::MOP::Class->initialize($class);

  my $re = qr/^\Q$incomplete/;

  return $orig->(@_),
         grep { $_ =~ $re }
         map  { $_->name }
         $metaclass->get_all_methods;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::REPL::Plugin::CompletionDriver::Methods - Complete class or object method names

=head1 VERSION

version 1.003029

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-REPL>
(or L<bug-Devel-REPL@rt.cpan.org|mailto:bug-Devel-REPL@rt.cpan.org>).

There is also an irc channel available for users of this distribution, at
L<C<#devel> on C<irc.perl.org>|irc://irc.perl.org/#devel-repl>.

=head1 AUTHOR

Shawn M Moore, C<< <sartak at gmail dot com> >>

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2007 by Matt S Trout - mst (at) shadowcatsystems.co.uk (L<http://www.shadowcatsystems.co.uk/>).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
