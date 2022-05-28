use strict;
use warnings;
package Devel::REPL::Plugin::Commands;
# ABSTRACT: Generic command creation plugin using injected functions

our $VERSION = '1.003029';

use Devel::REPL::Plugin;
use Scalar::Util qw(weaken);
use namespace::autoclean;

our $COMMAND_INSTALLER;

has 'command_set' => (
  is => 'ro',
  lazy => 1, default => sub { {} }
);

sub BEFORE_PLUGIN {
  my ($self) = @_;
  $self->load_plugin('Packages');
  unless ($self->can('setup_commands')) {
    $self->meta->add_method('setup_commands' => sub {});
  }
}

sub AFTER_PLUGIN {
  my ($self) = @_;
  $self->setup_commands;
}

after 'setup_commands' => sub {
  my ($self) = @_;
  weaken($self);
  $self->command_set->{load_plugin} = sub {
    my $self = shift;
    sub { $self->load_plugin(@_); };
  };
};

sub command_installer {
  my ($self) = @_;
  my $command_set = $self->command_set;
  my %command_subs = map {
    ($_ => $command_set->{$_}->($self));
  } keys %$command_set;
  return sub {
    my $package = shift;
    foreach my $command (keys %command_subs) {
      no strict 'refs';
      no warnings 'redefine';
      *{"${package}::${command}"} = $command_subs{$command};
    }
  };
}

around 'mangle_line' => sub {
  my ($orig, $self) = (shift, shift);
  my ($line) = @_;
  my $name = '$'.__PACKAGE__.'::COMMAND_INSTALLER';
  return qq{BEGIN { ${name}->(__PACKAGE__) }\n}.$self->$orig(@_);
};

around 'compile' => sub {
  my ($orig, $self) = (shift, shift);
  local $COMMAND_INSTALLER = $self->command_installer;
  $self->$orig(@_);
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Devel::REPL::Plugin::Commands - Generic command creation plugin using injected functions

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
