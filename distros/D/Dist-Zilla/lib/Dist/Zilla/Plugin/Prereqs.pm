package Dist::Zilla::Plugin::Prereqs 6.032;
# ABSTRACT: list simple prerequisites

use Moose;
with 'Dist::Zilla::Role::PrereqSource';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

#pod =head1 SYNOPSIS
#pod
#pod In your F<dist.ini>:
#pod
#pod   [Prereqs]
#pod   Foo::Bar = 1.002
#pod   MRO::Compat = 10
#pod   Sub::Exporter = 0
#pod
#pod You can specify requirements for different phases and relationships with:
#pod
#pod   [Prereqs]
#pod   -phase = test
#pod   -relationship = recommends
#pod
#pod   Fitz::Fotz    = 1.23
#pod   Text::SoundEx = 3
#pod
#pod Remember that if you load two Prereqs plugins, each will needs its own name,
#pod added like this:
#pod
#pod   [Prereqs / PluginName]
#pod   -phase = test
#pod   -relationship = recommends
#pod
#pod   Fitz::Fotz    = 1.23
#pod   Text::SoundEx = 3
#pod
#pod If the name is the CamelCase concatenation of a phase and relationship
#pod (or just a relationship), it will set those parameters implicitly.  If
#pod you use a custom name, but it does not specify the relationship, and
#pod you didn't specify either C<-phase> or C<-relationship>, it throws the
#pod error C<No -phase or -relationship specified>.  This is to prevent a
#pod typo that makes the name meaningless from slipping by unnoticed.
#pod
#pod The example below is equivalent to the example above, except for the name of
#pod the resulting plugin:
#pod
#pod   [Prereqs / TestRecommends]
#pod   Fitz::Fotz    = 1.23
#pod   Text::SoundEx = 3
#pod
#pod =head1 DESCRIPTION
#pod
#pod This module adds "fixed" prerequisites to your distribution.  These are prereqs
#pod with a known, fixed minimum version that doesn't change based on platform or
#pod other conditions.
#pod
#pod You can specify prerequisites for different phases and kinds of relationships.
#pod In C<RuntimeRequires>, the phase is Runtime and the relationship is Requires.
#pod These are described in more detail in the L<CPAN::Meta
#pod specification|CPAN::Meta::Spec/PREREQUISITES>.
#pod
#pod The phases are:
#pod
#pod =for :list
#pod * configure
#pod * build
#pod * test
#pod * runtime
#pod * develop
#pod
#pod The relationship types are:
#pod
#pod =for :list
#pod * requires
#pod * recommends
#pod * suggests
#pod * conflicts
#pod
#pod If the phase is omitted, it will default to I<runtime>; thus, specifying
#pod "Prereqs / Recommends" in your dist.ini is equivalent to I<RuntimeRecommends>.
#pod
#pod Not all of these phases are useful for all tools, especially tools that only
#pod understand version 1.x CPAN::Meta files.
#pod
#pod =cut

has prereq_phase => (
  is   => 'ro',
  isa  => 'Str',
  lazy => 1,
  init_arg => 'phase',
  default  => 'runtime',
);

has prereq_type => (
  is   => 'ro',
  isa  => 'Str',
  lazy => 1,
  init_arg => 'type',
  default  => 'requires',
);

around dump_config => sub {
  my ($orig, $self) = @_;
  my $config = $self->$orig;

  my $this_config = {
    type  => $self->prereq_type,
    phase => $self->prereq_phase,
  };

  $config->{'' . __PACKAGE__} = $this_config;

  return $config;
};

has _prereq => (
  is   => 'ro',
  isa  => 'HashRef',
  default => sub { {} },
);

sub mvp_aliases { return { -relationship => '-type' } }

around BUILDARGS => sub {
  my $orig = shift;
  my ($class, @arg) = @_;

  my $args = $class->$orig(@arg);
  my %copy = %{ $args };

  my $zilla = delete $copy{zilla};
  my $name  = delete $copy{plugin_name};

  my @dashed = grep { /^-/ } keys %copy;

  my %other;
  for my $dkey (@dashed) {
    my $key = $dkey =~ s/^-//r;

    $other{ $key } = delete $copy{ $dkey };
  }

  confess "don't try to pass -_prereq as a build arg!" if $other{_prereq};

  # Handle magic plugin names:
  unless (($other{phase} and $other{type})
            # plugin comes from a bundle
          or $name =~ m! (?: \A | / ) Prereqs? \z !x) {

    my ($phase, $type) = $name =~ /\A
      (Build|Test|Runtime|Configure|Develop)?
      (Requires|Recommends|Suggests|Conflicts)
    \z/x;

    if ($type) {
      $other{phase} ||= lc $phase if defined $phase;
      $other{type}  ||= lc $type;
    } else {
      $zilla->chrome->logger->log_fatal({ prefix => "[$name] " },
                                      "No -phase or -relationship specified")
        unless $other{phase} or $other{type};
    }
  }

  return {
    zilla => $zilla,
    plugin_name => $name,
    _prereq     => \%copy,
    %other,
  }
};

sub register_prereqs {
  my ($self) = @_;

  $self->zilla->register_prereqs(
    {
      type  => $self->prereq_type,
      phase => $self->prereq_phase,
    },
    %{ $self->_prereq },
  );
}

__PACKAGE__->meta->make_immutable;
1;

#pod =head1 SEE ALSO
#pod
#pod =over 4
#pod
#pod =item *
#pod
#pod Core Dist::Zilla plugins:
#pod L<@Basic|Dist::Zilla::PluginBundle::Basic>,
#pod L<AutoPrereqs|Dist::Zilla::Plugin::AutoPrereqs>.
#pod
#pod =item *
#pod
#pod The CPAN Meta specification: L<CPAN::Meta/PREREQUISITES>.
#pod
#pod =back
#pod
#pod =cut

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Prereqs - list simple prerequisites

=head1 VERSION

version 6.032

=head1 SYNOPSIS

In your F<dist.ini>:

  [Prereqs]
  Foo::Bar = 1.002
  MRO::Compat = 10
  Sub::Exporter = 0

You can specify requirements for different phases and relationships with:

  [Prereqs]
  -phase = test
  -relationship = recommends

  Fitz::Fotz    = 1.23
  Text::SoundEx = 3

Remember that if you load two Prereqs plugins, each will needs its own name,
added like this:

  [Prereqs / PluginName]
  -phase = test
  -relationship = recommends

  Fitz::Fotz    = 1.23
  Text::SoundEx = 3

If the name is the CamelCase concatenation of a phase and relationship
(or just a relationship), it will set those parameters implicitly.  If
you use a custom name, but it does not specify the relationship, and
you didn't specify either C<-phase> or C<-relationship>, it throws the
error C<No -phase or -relationship specified>.  This is to prevent a
typo that makes the name meaningless from slipping by unnoticed.

The example below is equivalent to the example above, except for the name of
the resulting plugin:

  [Prereqs / TestRecommends]
  Fitz::Fotz    = 1.23
  Text::SoundEx = 3

=head1 DESCRIPTION

This module adds "fixed" prerequisites to your distribution.  These are prereqs
with a known, fixed minimum version that doesn't change based on platform or
other conditions.

You can specify prerequisites for different phases and kinds of relationships.
In C<RuntimeRequires>, the phase is Runtime and the relationship is Requires.
These are described in more detail in the L<CPAN::Meta
specification|CPAN::Meta::Spec/PREREQUISITES>.

The phases are:

=over 4

=item *

configure

=item *

build

=item *

test

=item *

runtime

=item *

develop

=back

The relationship types are:

=over 4

=item *

requires

=item *

recommends

=item *

suggests

=item *

conflicts

=back

If the phase is omitted, it will default to I<runtime>; thus, specifying
"Prereqs / Recommends" in your dist.ini is equivalent to I<RuntimeRecommends>.

Not all of these phases are useful for all tools, especially tools that only
understand version 1.x CPAN::Meta files.

=head1 PERL VERSION

This module should work on any version of perl still receiving updates from
the Perl 5 Porters.  This means it should work on any version of perl
released in the last two to three years.  (That is, if the most recently
released version is v5.40, then this module should work on both v5.40 and
v5.38.)

Although it may work on older versions of perl, no guarantee is made that the
minimum required version will not be increased.  The version may be increased
for any reason, and there is no promise that patches will be accepted to
lower the minimum required perl.

=head1 SEE ALSO

=over 4

=item *

Core Dist::Zilla plugins:
L<@Basic|Dist::Zilla::PluginBundle::Basic>,
L<AutoPrereqs|Dist::Zilla::Plugin::AutoPrereqs>.

=item *

The CPAN Meta specification: L<CPAN::Meta/PREREQUISITES>.

=back

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
