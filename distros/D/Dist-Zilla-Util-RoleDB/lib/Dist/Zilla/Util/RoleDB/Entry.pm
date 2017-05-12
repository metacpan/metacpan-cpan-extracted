use 5.006;
use strict;
use warnings;

package Dist::Zilla::Util::RoleDB::Entry;

our $VERSION = '0.004001';

# ABSTRACT: Extracted meta-data about a role

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moo qw( has );
use Carp qw( croak );

## no critic (NamingConventions)
my $is_Str = sub { 'SCALAR' eq ref \$_[0] or 'SCALAR' eq ref \( my $val = $_[0] ) };
my $is_ArrayRef = sub {
  return 'ARRAY' eq ref $_[0] unless $_[1];
  return unless 'ARRAY' eq ref $_[0];
  for ( @{ $_[0] } ) {
    return unless $_[1]->($_);
  }
  1;
};
my $is_Bool = sub { not defined $_[0] or q() eq $_[0] or '0' eq $_[0] or '1' eq $_[0] };















has name => (
  isa => sub { $is_Str->( $_[0] ) or croak 'name must be a Str' },
  is            => ro =>,
  required      => 1,
  documentation => q[The unprefixed version of the role name, ie: -Foo => DZR::Foo],
);









has full_name => (
  isa => sub { $is_Str->( $_[0] ) or croak 'full_name must be a Str' },
  is            => ro =>,
  lazy          => 1,
  builder       => '_build_full_name',
  documentation => q[The fully qualified version of the role name],
);

sub _build_full_name {
  my ($self) = @_;
  my $role_name = $self->name;
  return $role_name unless $role_name =~ /\A-/msx;
  $role_name =~ s{\A-}{Dist::Zilla::Role::}msx;
  return $role_name;
}



































has required_modules => (
  isa => sub { $is_ArrayRef->( $_[0], $is_Str ) or croak 'required_modules must be an ArrayRef of Str' },
  is      => ro =>,
  lazy    => 1,
  builder => '_build_required_modules',
  ## no critic (ProhibitImplicitNewlines)
  documentation => <<'EOF', );
A list of things that must be manually require()d for the module to exist.
Note: This should not be needed for anything, as its really only intended
as a way to make hidden packages require()able.
Usually, this will be exactly one item, and it will be the same as the modules name.
EOF

sub _build_required_modules {
  my ($self) = @_;
  return [ $self->full_name ];
}







sub is_phase { return }









has description => (
  isa => sub { $is_Str->( $_[0] ) or croak 'description must be a Str' },
  is            => ro =>,
  required      => 1,
  documentation => q[A text description of the role. A copy of ABSTRACT would be fine],
);







has deprecated => (
  isa => sub { $is_Bool->( $_[0] ) or croak 'deprecated must be Boolean' },
  is            => ro =>,
  lazy          => 1,
  builder       => '_build_deprecated',
  documentation => q[Set this to 1 if this role is deprecated],
);

sub _build_deprecated { return }

no Moo;










sub require_module {
  my ($self) = @_;
  require Module::Runtime;
  for my $module ( @{ $self->required_modules } ) {
    Module::Runtime::require_module($module);
  }
  return $self->full_name;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Util::RoleDB::Entry - Extracted meta-data about a role

=head1 VERSION

version 0.004001

=head1 SYNOPSIS

    use Dist::Zilla::Util::RoleDB::Entry;
    my $entry = Dist::Zilla::Util::RoleDB::Entry->new(
        name => "-FileGatherer",
        description => "A thing that adds files to your dist"
    );

=head1 METHODS

=head2 is_phase

Returns false

=head2 C<require_module>

Load the module itself.

Usually, this just amounts to requiring C<full_name>, but it might not be
in the case somebody has manually modified C<required_modules>

=head1 ATTRIBUTES

=head2 C<name>

Contains the short name for the role, in a form acceptable by C<Dist::Zilla>'s C<plugins_with> method.

e.g:

    -FileGatherer

Because

    zilla->plugins_with(-FileGatherer)

=head2 C<full_name>

Contains the fully qualified version of the role.

For instance, when C<name> is C<-FileGatherer>, C<full_name> will be C<Dist::Zilla::Role::FileGatherer>

=head2 C<required_modules>

This contains an C<ArrayRef> of Modules that are required if one ever intends to use the module in C<full_name>.

Note, that this is not intended to be really used. It only exists as a helper in the event one wishes to document
a roles existence in a file other than one matching its name.

For example:

    Foo.pm:

        package Foo;

        use Moose::Role;

        package Bar;

        use Moose::Role;

In such a scenario, one cannot get Bar without C<require Foo>

So here,

    ->new( name => 'Foo' ); # required_modules is automatically [Foo]
    ->new( name => 'Bar', required_modules => ['Foo'] );

Also, if a role has peculiar load order requirements ( like seen in Class::MOP ) that means
certain other libraries must be C<require>'d before C<require>ing the module itself, this would be a convenient place to put such information.

This mechanism is mostly to support C<< $entry->require_module >>

=head2 C<description>

Contains a textual description of the Role.

Usually, a copy of the Roles "ABSTRACT" will do the trick.

=head2 C<deprecated>

If a role is deprecated, setting this may be useful.

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
