use strict;
use warnings;
package Devel::REPL::Plugin::Turtles;
# ABSTRACT: Generic command creation using a read hook

our $VERSION = '1.003029';

use Devel::REPL::Plugin;
use Scalar::Util qw(reftype);
use namespace::autoclean;

has default_command_prefix => (
  isa => "RegexpRef",
  is  => "rw",
  default => sub { qr/\#/ },
);

has turtles_matchers => (
  traits => ['Array'],
  isa => "ArrayRef[RegexpRef|CodeRef]",
  is  => "rw",
  lazy => 1,
  default => sub { my $prefix = shift->default_command_prefix; [qr/^ $prefix (\w+) \s* (.*) /x] },
  handles => {
    add_turtles_matcher => 'unshift',
  },
);

around 'formatted_eval' => sub {
  my $next = shift;
  my ($self, $line, @args) = @_;

  if ( my ( $command, @rest ) = $self->match_turtles($line) ) {
    my $method = "command_$command";
    my $expr_method = "expr_$method";

    if ( my $expr_code = $self->can($expr_method) ) {
      if ( my $read_more = $self->can("continue_reading_if_necessary") ) {
        push @rest, $self->$read_more(pop @rest);
      }
      $self->$expr_code($next, @rest);
    } elsif ( my $cmd_code = $self->can($method) ) {
      return $self->$cmd_code($next, @rest);
    } else {
      unless ( $line =~ /^\s*#/ ) { # special case for comments
        return $self->format($self->error_return("REPL Error", "Command '$command' does not exist"));
      }
    }
  } else {
    return $self->$next($line, @args);
  }
};

sub match_turtles {
  my ( $self, $line ) = @_;

  foreach my $thingy ( @{ $self->turtles_matchers } ) {
    if ( reftype $thingy eq 'CODE' ) {
      if ( my @res = $self->$thingy($line) ) {
        return @res;
      }
    } else {
      if ( my @res = ( $line =~ $thingy ) ) {
        return @res;
      }
    }
  }

  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::REPL::Plugin::Turtles - Generic command creation using a read hook

=head1 VERSION

version 1.003029

=head1 DESCRIPTION

By default, this plugin allows calling commands using a read hook
to detect a default_command_prefix followed by the command name,
say MYCMD as an example.  The actual routine to call for the
command is constructed by looking for subs named 'command_MYCMD'
or 'expr_MYCMD' and executing them.

=head2 NOTE

The C<default_command_prefix> is C<qr/\#/> so care must be taken
if other uses for that character are needed (e.g., '#' for the
shell escape character in the PDL shell.

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
