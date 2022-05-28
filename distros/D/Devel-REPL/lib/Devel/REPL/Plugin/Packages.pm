use strict;
use warnings;
package Devel::REPL::Plugin::Packages;
# ABSTRACT: Keep track of which package the user is in

our $VERSION = '1.003029';

use Devel::REPL::Plugin;
use namespace::autoclean;

our $PKG_SAVE;

has 'current_package' => (
  isa      => 'Str',
  is       => 'rw',
  default  => 'Devel::REPL::Plugin::Packages::DefaultScratchpad',
  lazy     => 1
);

around 'wrap_as_sub' => sub {
  my $orig = shift;
  my ($self, @args) = @_;
  my $line = $self->$orig(@args);
  # prepend package def before sub { ... }
  return q!package !.$self->current_package.qq!;\n${line}!;
};

around 'mangle_line' => sub {
  my $orig = shift;
  my ($self, @args) = @_;
  my $line = $self->$orig(@args);
  # add a BEGIN block to set the package around at the end of the sub
  # without mangling the return value (we save it off into a global)
  $line .= '
; BEGIN { $Devel::REPL::Plugin::Packages::PKG_SAVE = __PACKAGE__; }';
  return $line;
};

after 'execute' => sub {
  my ($self) = @_;
  # if we survived execution successfully, save the new package out the global
  $self->current_package($PKG_SAVE) if defined $PKG_SAVE;
};

around 'eval' => sub {
  my $orig = shift;
  my ($self, @args) = @_;
  # localise the $PKG_SAVE global in case of nested evals
  local $PKG_SAVE;
  return $self->$orig(@args);
};

package # hide from PAUSE
    Devel::REPL::Plugin::Packages::DefaultScratchpad;

# declare empty scratchpad package for cleanliness

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::REPL::Plugin::Packages - Keep track of which package the user is in

=head1 VERSION

version 1.003029

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-REPL>
(or L<bug-Devel-REPL@rt.cpan.org|mailto:bug-Devel-REPL@rt.cpan.org>).

There is also an irc channel available for users of this distribution, at
L<C<#devel> on C<irc.perl.org>|irc://irc.perl.org/#devel-repl>.

=head1 AUTHOR

Matt S Trout - mst (at) shadowcatsystems.co.uk (L<http://www.shadowcatsystems.co.uk/>)

=head1 COPYRIGHT AND LICENCE

This software is copyright (c) 2007 by Matt S Trout - mst (at) shadowcatsystems.co.uk (L<http://www.shadowcatsystems.co.uk/>).

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
