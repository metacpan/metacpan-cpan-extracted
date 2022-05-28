use strict;
use warnings;
package Devel::REPL::Plugin::CompletionDriver::Globals;
# ABSTRACT: Complete global variables, packages, namespaced functions

our $VERSION = '1.003029';

use Devel::REPL::Plugin;
use Devel::REPL::Plugin::Completion;    # die early if cannot load
use namespace::autoclean;

sub BEFORE_PLUGIN {
    my $self = shift;
    $self->load_plugin('Completion');
}

around complete => sub {
  my $orig = shift;
  my ($self, $text, $document) = @_;

  my $last = $self->last_ppi_element($document);

  return $orig->(@_)
    unless $last->isa('PPI::Token::Symbol')
        || $last->isa('PPI::Token::Word');

  my $sigil = $last =~ s/^[\$\@\%\&\*]// ? $1 : undef;
  my $re = qr/^\Q$last/;

  my @package_fragments = split qr/::|'/, $last;

  # split drops the last fragment if it's empty
  push @package_fragments, '' if $last =~ /(?:'|::)$/;

  # the beginning of the variable, or an incomplete package name
  my $incomplete = pop @package_fragments;

  # recurse for the complete package fragments
  my $stash = \%::;
  for (@package_fragments) {
    $stash = $stash->{"$_\::"};
  }

  # collect any variables from this stash
  my @found = grep { /$re/ }
              map  { join '::', @package_fragments, $_ }
              keys %$stash;

  # check to see if it's an incomplete package name, and add its variables
  # so Devel<TAB> is completed correctly
  for my $key (keys %$stash) {
      next unless $key =~ /::$/;            # only look at deeper packages
      next unless $key =~ /^\Q$incomplete/; # only look at matching packages
      push @found,
        map { join '::', @package_fragments, $_ }
        map { "$key$_" } # $key already has trailing ::
        keys %{ $stash->{$key} };
  }

  return $orig->(@_), @found;
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::REPL::Plugin::CompletionDriver::Globals - Complete global variables, packages, namespaced functions

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
