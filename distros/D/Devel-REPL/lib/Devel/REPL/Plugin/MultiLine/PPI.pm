use strict;
use warnings;
package Devel::REPL::Plugin::MultiLine::PPI;
# ABSTRACT: Read lines until all blocks are closed

our $VERSION = '1.003029';

use Devel::REPL::Plugin;
use PPI;
use namespace::autoclean;

has 'continuation_prompt' => (
  is => 'rw',
  lazy => 1,
  default => sub { '> ' }
);

has 'line_depth' => (
  is => 'rw',
  lazy => 1,
  default => sub { 0 }
);

around 'read' => sub {
  my $orig = shift;
  my ($self, @args) = @_;
  my $line = $self->$orig(@args);

  if (defined $line) {
    return $self->continue_reading_if_necessary($line, @args);
  } else {
    return $line;
  }
};

sub continue_reading_if_necessary {
  my ( $self, $line, @args ) = @_;

  while ($self->line_needs_continuation($line)) {
    my $orig_prompt = $self->prompt;
    $self->prompt($self->continuation_prompt);

    $self->line_depth($self->line_depth + 1);
    my $append = $self->read(@args);
    $self->line_depth($self->line_depth - 1);

    $line .= "\n$append" if defined($append);

    $self->prompt($orig_prompt);

    # ^D means "shut up and eval already"
    return $line if !defined($append);
  }

  return $line;
}

sub line_needs_continuation
{
  my $repl = shift;
  my $line = shift;

  # add this so we can test whether the document ends in PPI::Statement::Null
  $line .= "\n;;";

  my $document = PPI::Document->new(\$line);
  return 0 if !defined($document);

  # adding ";" to a complete document adds a PPI::Statement::Null. we added a ;;
  # so if it doesn't end in null then there's probably something that's
  # incomplete
  return 0 if $document->child(-1)->isa('PPI::Statement::Null');

  # this could use more logic, such as returning 1 on s/foo/ba<Enter>
  my $unfinished_structure = sub
  {
    my ($document, $element) = @_;
    return 0 unless $element->isa('PPI::Structure');
    return 1 unless $element->finish;
    return 0;
  };

  return $document->find_any($unfinished_structure);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::REPL::Plugin::MultiLine::PPI - Read lines until all blocks are closed

=head1 VERSION

version 1.003029

=head1 SYNOPSIS

    use Devel::REPL;

    my $repl = Devel::REPL->new;
    $repl->load_plugin('LexEnv');
    $repl->load_plugin('History');
    $repl->load_plugin('MultiLine::PPI');
    $repl->run;

=head1 DESCRIPTION

Plugin that will collect lines until you have no unfinished structures. This
lets you write subroutines, C<if> statements, loops, etc. more naturally.

For example, without a MultiLine plugin,

    $ my $x = 3;
    3
    $ if ($x == 3) {

will throw a compile error, because that C<if> statement is incomplete. With a
MultiLine plugin,

    $ my $x = 3;
    3
    $ if ($x == 3) {

    > print "OH NOES!"

    > }
    OH NOES
    1

you may write the code across multiple lines, such as in C<irb> and C<python>.

This module uses L<PPI>. This plugin is named C<MultiLine::PPI> because someone
else may conceivably implement similar behavior some other less
dependency-heavy way.

=head1 SEE ALSO

C<Devel::REPL>

=head1 SUPPORT

Bugs may be submitted through L<the RT bug tracker|https://rt.cpan.org/Public/Dist/Display.html?Name=Devel-REPL>
(or L<bug-Devel-REPL@rt.cpan.org|mailto:bug-Devel-REPL@rt.cpan.org>).

There is also an irc channel available for users of this distribution, at
L<C<#devel> on C<irc.perl.org>|irc://irc.perl.org/#devel-repl>.

=head1 AUTHOR

Shawn M Moore, C<< <sartak at gmail dot com> >>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2007 by Shawn M Moore

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
