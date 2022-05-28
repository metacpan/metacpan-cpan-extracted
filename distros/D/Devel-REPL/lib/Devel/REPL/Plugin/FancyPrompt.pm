use strict;
use warnings;
package Devel::REPL::Plugin::FancyPrompt;
# ABSTRACT: Facilitate user-defined prompts

our $VERSION = '1.003029';

use Devel::REPL::Plugin;
use namespace::autoclean;

has 'fancy_prompt' => (
  is => 'rw', lazy => 1,

  # yes, this needs to be a double sub
  default => sub {
    sub {
      my $self = shift;
      sprintf 're.pl(%s):%03d%s> ',
              $self->can('current_package') ? $self->current_package : 'main',
              $self->lines_read,
              $self->can('line_depth') ? ':' . $self->line_depth : '';
    }
  },
);

has 'fancy_continuation_prompt' => (
  is => 'rw', lazy => 1,

  # yes, this needs to be a double sub
  default => sub {
    sub {
      my $self = shift;
      sprintf 're.pl(%s):%03d:%d* ',
              $self->can('current_package') ? $self->current_package : 'main',
              $self->lines_read,
              $self->line_depth,
    }
  },
);

has 'lines_read' => (
  is => 'rw', lazy => 1, default => 0,
);

around 'prompt' => sub {
  shift;
  my $self = shift;
  if ($self->can('line_depth') && $self->line_depth) {
    return $self->fancy_continuation_prompt->($self);
  }
  else {
    return $self->fancy_prompt->($self);
  }
};

before 'read' => sub {
  my $self = shift;
  $self->lines_read($self->lines_read + 1);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::REPL::Plugin::FancyPrompt - Facilitate user-defined prompts

=head1 VERSION

version 1.003029

=head1 SYNOPSIS

    use Devel::REPL;

    my $repl = Devel::REPL->new;
    $repl->load_plugin('MultiLine::PPI'); # for indent depth
    $repl->load_plugin('Packages');       # for current package
    $repl->load_plugin('FancyPrompt');
    $repl->run;

=head1 DESCRIPTION

FancyPrompt helps you write your own prompts. The default fancy prompt resembles
C<irb>'s default prompt. The default C<fancy_prompt> looks like this:

    re.pl(main):001:0> 2 + 2
    4

C<re.pl> is a constant. C<main> is the current package. The first number is how
many lines have been read so far. The second number (only if you have a
C<MultiLine> plugin) is how deep you are; intuitively, your indent level. This
default can be implemented with:

    $_REPL->fancy_prompt(sub {
      my $self = shift;
      sprintf 're.pl(%s):%03d%s> ',
              $self->can('current_package') ? $self->current_package : 'main',
              $self->lines_read,
              $self->can('line_depth') ? ':' . $self->line_depth : '';
    });

C<current_package> is provided by L<Devel::REPL::Plugin::Packages> (which
tracks the current package). C<line_depth> is provided by a C<MultiLine> plugin
(probably C<MultiLine::PPI>).

You may also set a C<fancy_continuation_prompt>. The default is very similar to
C<fancy_prompt>'s default (except C<*> instead of C<< > >>).

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
