use 5.008;    # 8 = utf8, 6 = pragmas , our, noparam varmethod, 4 = __PACKAGE__
use strict;
use warnings;
use utf8;

package Dist::Zilla::Plugin::Prereqs::MatchInstalled;

our $VERSION = '1.001003';

# ABSTRACT: Depend on versions of modules the same as you have installed

our $AUTHORITY = 'cpan:KENTNL'; # AUTHORITY

use Moose qw( has around with );
use MooseX::Types::Moose qw( HashRef ArrayRef Str );
use Dist::Zilla::Util::ConfigDumper qw( config_dumper );
with 'Dist::Zilla::Role::PrereqSource';


























has applyto_phase => (
  is => ro =>,
  isa => ArrayRef [Str] =>,
  lazy    => 1,
  default => sub { [qw(build test runtime configure develop)] },
);














has applyto_relation => (
  is      => 'ro',
  isa     => ArrayRef [Str],
  lazy    => 1,
  default => sub { [qw(requires recommends suggests)] },
);













has applyto => (
  is => ro =>,
  isa => ArrayRef [Str] =>,
  lazy    => 1,
  builder => _build_applyto =>,
);









has _applyto_list => (
  is => ro =>,
  isa => ArrayRef [ ArrayRef [Str] ],
  lazy    => 1,
  builder => _build__applyto_list =>,
);















has modules => (
  is => ro =>,
  isa => ArrayRef [Str],
  lazy    => 1,
  default => sub { [] },
);







has _modules_hash => (
  is      => ro                   =>,
  isa     => HashRef,
  lazy    => 1,
  builder => _build__modules_hash =>,
);





sub _build_applyto {
  my $self = shift;
  my @out;
  for my $phase ( @{ $self->applyto_phase } ) {
    for my $relation ( @{ $self->applyto_relation } ) {
      push @out, $phase . q[.] . $relation;
    }
  }
  return \@out;
}





sub _build__applyto_list {
  my $self = shift;
  my @out;
  for my $type ( @{ $self->applyto } ) {
    if ( $type =~ /^ ([^.]+) [.] ([^.]+) $/msx ) {
      push @out, [ "$1", "$2" ];
      next;
    }
    return $self->log_fatal( [ q[<<%s>> does not match << <phase>.<relation> >>], $type ] );
  }
  return \@out;
}





sub _build__modules_hash {
  my $self = shift;
  return { map { ( $_, 1 ) } @{ $self->modules } };
}





sub _user_wants_upgrade_on {
  my ( $self, $module ) = @_;
  return exists $self->_modules_hash->{$module};
}



















sub mvp_multivalue_args { return qw(applyto applyto_relation applyto_phase modules) }







sub mvp_aliases { return { 'module' => 'modules' } }











sub current_version_of {
  my ( undef, $package ) = @_;
  if ( 'perl' eq $package ) {

    # Thats not going to work, Dave.
    return $];
  }
  require Module::Data;
  my $module_data = Module::Data->new($package);
  return if not $module_data;
  return if not -e $module_data->path;
  return if -d $module_data->path;
  return $module_data->_version_emulate;
}
around dump_config => config_dumper( __PACKAGE__, qw( applyto_phase applyto_relation applyto modules ) );








sub register_prereqs {
  my ($self)  = @_;
  my $zilla   = $self->zilla;
  my $prereqs = $zilla->prereqs;
  my $guts = $prereqs->cpan_meta_prereqs->{prereqs} || {};

  my $failmsg = q[];
  $failmsg .= q[You asked for the installed version of %s, ];
  $failmsg .= q[and it is a dependency but it is apparently not installed];
  for my $applyto ( @{ $self->_applyto_list } ) {
    my ( $phase, $rel ) = @{$applyto};
    next if not exists $guts->{$phase};
    next if not exists $guts->{$phase}->{$rel};
    my $reqs = $guts->{$phase}->{$rel}->as_string_hash;
    for my $module ( keys %{$reqs} ) {
      next unless $self->_user_wants_upgrade_on($module);
      my $latest = $self->current_version_of($module);
      if ( not defined $latest ) {
        $self->log( [ $failmsg, $module ] );
        next;
      }
      $zilla->register_prereqs( { phase => $phase, type => $rel }, $module, $latest );
    }
  }
  return $prereqs;
}
__PACKAGE__->meta->make_immutable;
no Moose;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::Prereqs::MatchInstalled - Depend on versions of modules the same as you have installed

=head1 VERSION

version 1.001003

=head1 SYNOPSIS

This is based on the code of
L<< C<[Author::KENTNL::Prereqs::Latest::Selective]>|Dist::Zilla::Plugin::Author::KENTNL::Prereqs::Latest::Selective >>,
but intended for a wider audience.

    [Prereqs::MatchInstalled]
    module = My::Module

If you want to automatically add B<all> modules that are C<prereqs>, perhaps instead look at
L<< C<[Prereqs::MatchInstalled::All]>|Dist::Zilla::Plugin::Prereqs::MatchInstalled::All >>

B<NOTE:> Dependencies will only be upgraded to match the I<Installed> version if they're found elsewhere in the dependency tree.

This is designed so that it integrates with other automated version provisioning.

If you're hard-coding module dependencies instead, you will want to place this module I<after> other modules that declare
dependencies.

For instance:

    [Prereqs]
    Foo = 0

    [Prereqs::MatchInstalled]
    module = Foo

^^ C<Foo> will be upgraded to the version installed.

By default, dependencies that match values of C<module> will be upgraded when they are found in:

    phase: build, test, runtime, configure, develop
    relation: depends, suggests, recommends

To change this behavior, specify one or more of the following parameters:

    applyto_phase = build
    applyto_phase = configure

    applyto_relation = requires

etc.

For more complex demands, this also works:

    applyto = build.requires
    applyto = configure.recommends

And that should hopefully be sufficient to cover any conceivable use-case.

Also note, we don't do any sort of sanity checking on the module list you provide.

For instance,

    module = strict
    module = warning

Will both upgrade the strict and warnings dependencies on your module, regardless of how daft an idea that may be.

And with a little glue

    module = perl

Does what you want, but you probably shouldn't rely on that :).

=head1 METHODS

=head2 mvp_multivalue_args

The following properties can be specified multiple times:

=over 4

=item * C<applyto>

=item * C<applyto_relation>

=item * C<applyto_phase>

=item * C<modules>

=back

=head2 C<mvp_aliases>

The C<module> is an alias for C<modules>

=head2 C<current_version_of>

    $self->current_version_of($package);

Attempts to find the current version of C<$package>.

Returns C<undef> if something went wrong.

=head2 C<register_prereqs>

This is for L<< C<Dist::Zilla::Role::PrereqSource>|Dist::Zilla::Role::PrereqSource >>, which gets new prerequisites
from this module.

=head1 ATTRIBUTES

=head2 C<applyto_phase>

Determines which phases will be checked for module dependencies to upgrade.

    [Prereqs::MatchInstalled]
    applyto_phase = build
    applyto_phase = test

Defaults to:

    build test runtime configure develop

=head2 C<applyto_relation>

Determines which relations will be checked for module dependencies to upgrade.

    [Prereqs::MatchInstalled]
    applyto_relation = requires

Defaults to:

    requires suggests recommends

=head2 C<applyto>

Determines the total list of C<phase>/C<relation> combinations which will be checked for dependencies to upgrade.

If not specified, is built from L<< C<applyto_phase>|/applyto_phase >> and L<< C<applyto_relation>|/applyto_relation >>

    [Prereqs::MatchInstalled]
    applyto = runtime.requires
    applyto = configure.requires

=head2 C<modules>

Contains the list of modules that will be searched for in the existing C<Prereqs> stash to upgrade.

    [Prereqs::MatchInstalled]
    module = Foo
    module = Bar
    modules = Baz ; this is the same as the previous 2

If you want to automatically add B<all> modules that are C<prereqs>, perhaps instead look at
L<< C<[Prereqs::MatchInstalled::All]>|Dist::Zilla::Plugin::Prereqs::MatchInstalled::All >>

=head1 PRIVATE ATTRIBUTES

=head2 C<_applyto_list>

B<Internal.>

Contains the contents of L<< C<applyto>|/applyto >> represented as an C<ArrayRef[ArrayRef[Str]]>

=head2 C<_modules_hash>

Contains a copy of L<< C<modules>|/modules >> as a hash for easy look-up.

=head1 PRIVATE METHODS

=head2 _build_applyto

=head2 _build_applyto_list

=head2 _build__modules_hash

=head2 _user_wants_upgrade_on

=begin MetaPOD::JSON v1.1.0

    {
        "namespace":"Dist::Zilla::Plugin::Prereqs::MatchInstalled",
        "interface":"class",
        "inherits":"Moose::Object",
        "does":["Dist::Zilla::Role::PrereqSource","Dist::Zilla::Role::Plugin","Dist::Zilla::Role::ConfigDumper"]
    }


=end MetaPOD::JSON

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
