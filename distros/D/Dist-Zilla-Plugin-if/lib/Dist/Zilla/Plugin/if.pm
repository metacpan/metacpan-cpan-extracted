use 5.010;    #  _Pulp__5010_qr_m_propagate_properly
use strict;
use warnings;
use utf8;

package Dist::Zilla::Plugin::if;

our $VERSION = '0.002002';

# ABSTRACT: Load a plugin only if a condition is true

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( has around with );
use Dist::Zilla::Util qw();
use Eval::Closure qw( eval_closure );

with 'Dist::Zilla::Role::PluginLoader::Configurable';

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

has conditions => ( is => 'ro', lazy_build => 1 );
sub _build_conditions { return [] }

sub check_conditions {
  my ($self) = @_;

  my $env = {};
  ## no critic (ValuesAndExpressions::RequireInterpolationOfMetachars)
  $env->{q[$root]}  = \$self->zilla->root;
  $env->{q[$zilla]} = \$self->zilla;
  my $code = join q[ and ], @{ $self->conditions }, q[1];
  my $closure = eval_closure(
    source      => qq[sub { \n] . $code . qq[}\n],
    environment => $env,
  );
  ## use critic;
  return $closure->();
}

around 'load_plugins' => sub {
  my ( $orig, $self, $loader ) = @_;
  return unless $self->check_conditions;
  return $self->$orig($loader);
};

__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::if - Load a plugin only if a condition is true

=head1 VERSION

version 0.002002

=head1 SYNOPSIS

  [if / FooLoader]
  dz_plugin            = Git::Contributors
  dz_plugin_name       = KNL/Git::Contributors
  dz_plugin_minversion = 0.010
  ?= -e $root . '.git'
  ?= -e $root . '.git/config'
  >= include_authors = 1
  >= include_releaser = 0
  >= order_by = name

=head1 DESCRIPTION

C<if> is intended to be a similar utility to L<< perl C<if>|if >>.

It will execute all of C<condition> in turn, and only when all return true, will the plugin
be added to C<Dist::Zilla>

=head1 METHODS

=head2 C<mvp_aliases>

=over 4

=item * C<dz_plugin_arguments=> can be written as C<< >= >> or C<< dz_plugin_argument= >>

=item * C<conditions=> can be written as C<< ?= >> or C<< condition= >>

=back

=head2 C<mvp_multivalue_args>

All of the following support multiple declaration:

=over 4

=item * C<dz_plugin_arguments>

=item * C<prereq_to>

=item * C<conditions>

=back

=head2 C<register_prereqs>

By default, registers L</dz_plugin_package> version L</dz_plugin_minimumversion>
as C<develop.requires> ( as per L</prereq_to> ).

=head2 check_conditions

Compiles C<conditions> into a single sub and executes it.

  conditions = y and foo
  conditions = x blah

Compiles as

  sub { y and foo and x blah and 1 }

But with C<$root> and C<$zilla> in scope.

=head1 ATTRIBUTES

=head2 C<dz_plugin>

B<REQUIRED>

The C<plugin> identifier.

For instance, C<[GatherDir / Foo]> and C<[GatherDir]> approximation would both set this field to

  dz_plugin => 'GatherDir'

=head2 C<dz_plugin_name>

The "Name" for the C<plugin>.

For instance, C<[GatherDir / Foo]> would set this value as

  dz_plugin_name => "Foo"

and C<[GatherDir]> approximation would both set this field to

  dz_plugin_name => "Foo"

In C<Dist::Zilla>, C<[GatherDir]> is equivalent to C<[GatherDir / GatherDir]>.

Likewise, if you do not specify C<dz_plugin_name>, the value of C<dz_plugin> will be used.

=head2 C<dz_plugin_minversion>

The minimum version of C<dz_plugin> to use.

At present, this B<ONLY> affects C<prereq> generation.

=head2 C<conditions>

A C<mvp_multivalue_arg> attribute that creates an array of conditions
that must all evaluate to true for the C<dz_plugin> to be injected.

These values are internally simply joined with C<and> and executed in an C<Eval::Closure>

Two variables are defined in scope for your convenience:

=over 4

=item * C<$zilla> - The Dist::Zilla builder object itself

=item * C<$root> - The same as C<< $zilla->root >> only more convenient.

=back

For added convenience, this attribute has an alias of '?' ( mnemonic "Test" ), so the following are equivalent:

  [if]
  dz_plugin_name = Foo
  ?= exists $ENV{loadfoo}
  ?= !!$ENV{loadfoo}

  [if]
  dz_plugin_name = Foo
  condition = exists $ENV{loadfoo}
  condition = !!$ENV{loadfoo}

  [if]
  dz_plugin_name = Foo
  conditions = exists $ENV{loadfoo}
  conditions = !!$ENV{loadfoo}

=head2 C<dz_plugin_arguments>

A C<mvp_multivalue_arg> attribute that creates an array of arguments
to pass on to the created plugin.

For convenience, this attribute has an alias of '>' ( mnemonic "Forward" ), so that the following example:

  [GatherDir]
  include_dotfiles = 1
  exclude_file = bad
  exclude_file = bad2

Would be written

  [if]
  dz_plugin = GatherDir
  ?= $ENV{dogatherdir}
  >= include_dotfiles = 1
  >= exclude_file = bad
  >= exclude_file = bad2

Or in crazy long form

  [if]
  dz_plugin = GatherDir
  condtion = $ENV{dogatherdir}
  dz_plugin_argument = include_dotfiles = 1
  dz_plugin_argument = exclude_file = bad
  dz_plugin_argument = exclude_file = bad2

=head2 C<prereq_to>

This determines where dependencies get injected.

Default is:

  develop.requires

And a special value

  none

Prevents dependency injection.

This attribute may be specified multiple times.

=head2 C<dz_plugin_package>

This is an implementation detail which returns the expanded name of C<dz_plugin>

You could probably find some evil use for this, but I doubt it.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
