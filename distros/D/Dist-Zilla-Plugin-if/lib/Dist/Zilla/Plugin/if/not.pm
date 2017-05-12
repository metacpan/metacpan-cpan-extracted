use 5.008;    # utf8
use strict;
use warnings;
use utf8;

package Dist::Zilla::Plugin::if::not;

our $VERSION = '0.002002';

# ABSTRACT: Only load a plugin if a condition is false

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( has around with );
use Dist::Zilla::Util qw();
use Eval::Closure qw( eval_closure );

with 'Dist::Zilla::Role::PluginLoader::Configurable';

has conditions => ( is => 'ro', lazy_build => 1 );
sub _build_conditions { return [] }

around dump_config => sub {
  my ( $orig, $self, @args ) = @_;
  my $config = $self->$orig(@args);
  my $localconf = $config->{ +__PACKAGE__ } = {};

  $localconf->{conditions} = $self->conditions;

  $localconf->{ q[$] . __PACKAGE__ . '::VERSION' } = $VERSION
    unless __PACKAGE__ eq ref $self;

  return $config;
};

around mvp_aliases => sub {
  my ( $orig, $self, @rest ) = @_;
  my $hash = $self->$orig(@rest);
  $hash = {
    %{$hash},
    q{?}         => 'conditions',
    q[condition] => 'conditions',
  };
  return $hash;
};
around mvp_multivalue_args => sub {
  my ( $orig, $self, @args ) = @_;
  return ( qw( conditions ), $self->$orig(@args) );
};








sub check_conditions {
  my ($self) = @_;

  my $env = {};
  ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
  $env->{q[$root]}  = \$self->zilla->root;
  $env->{q[$zilla]} = \$self->zilla;
  my $code = join q[ and ], @{ $self->conditions }, q[1];
  my $closure = eval_closure(
    source      => qq[sub {  \n] . $code . qq[ }\n],
    environment => $env,
  );
  ## use critic;
  return !$closure->();
}

around 'load_plugins' => sub {
  my ( $orig, $self, $loader ) = @_;
  return unless $self->check_conditions;
  return $self->$orig($loader);
};

no Moose;

__PACKAGE__->meta->make_immutable;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::if::not - Only load a plugin if a condition is false

=head1 VERSION

version 0.002002

=head1 METHODS

=head2 C<check_conditions>

This is identical to L<< C<if>|Dist::Zilla::Plugin::if >> except this condition
returns inverted.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
