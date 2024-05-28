package Dist::Zilla::Role::FileFinderUser 6.032;
# ABSTRACT: something that uses FileFinder plugins

use MooseX::Role::Parameterized 1.01;

use Dist::Zilla::Pragmas;

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod This role enables you to search for files in the dist. This makes it easy to find specific
#pod files and have the code factored out to common methods.
#pod
#pod Here's an example of a finder: ( taken from AutoPrereqs )
#pod
#pod   with 'Dist::Zilla::Role::FileFinderUser' => {
#pod       default_finders  => [ ':InstallModules', ':ExecFiles' ],
#pod   };
#pod
#pod Then you use it in your code like this:
#pod
#pod   foreach my $file ( @{ $self->found_files }) {
#pod     # $file is an object! Look at L<Dist::Zilla::Role::File>
#pod   }
#pod
#pod =cut

#pod =attr finder_arg_names
#pod
#pod Define the name of the attribute which will hold this finder. Be sure to specify different names
#pod if you have multiple finders!
#pod
#pod This is an ArrayRef.
#pod
#pod Default: [ qw( finder ) ]
#pod
#pod =cut

parameter finder_arg_names => (
  isa => 'ArrayRef',
  default => sub { [ 'finder' ] },
);

#pod =attr default_finders
#pod
#pod This attribute is an arrayref of plugin names for the default plugins the
#pod consuming plugin will use as finders.
#pod
#pod Example: C<< [ qw( :InstallModules :ExecFiles ) ] >>
#pod
#pod The default finders are:
#pod
#pod =begin :list
#pod
#pod = :InstallModules
#pod
#pod Searches your lib/ directory for pm/pod files
#pod
#pod = :IncModules
#pod
#pod Searches your inc/ directory for pm files
#pod
#pod = :MainModule
#pod
#pod Finds the C<main_module> of your dist
#pod
#pod = :TestFiles
#pod
#pod Searches your t/ directory and lists the files in it.
#pod
#pod = :ExtraTestFiles
#pod
#pod Searches your xt/ directory and lists the files in it.
#pod
#pod = :ExecFiles
#pod
#pod Searches your distribution for executable files.  Hint: Use the
#pod L<Dist::Zilla::Plugin::ExecDir> plugin to mark those files as executables.
#pod
#pod = :PerlExecFiles
#pod
#pod A subset of C<:ExecFiles> limited just to perl scripts (those ending with
#pod F<.pl>, or with a recognizable perl shebang).
#pod
#pod = :ShareFiles
#pod
#pod Searches your ShareDir directory and lists the files in it.
#pod Hint: Use the L<Dist::Zilla::Plugin::ShareDir> plugin to set up the sharedir.
#pod
#pod = :AllFiles
#pod
#pod Returns all files in the distribution.
#pod
#pod = :NoFiles
#pod
#pod Returns nothing.
#pod
#pod =end :list
#pod
#pod =cut

parameter default_finders => (
  isa => 'ArrayRef',
  required => 1,
);

#pod =attr method
#pod
#pod This will be the name of the subroutine installed in your package for this
#pod finder.  Be sure to specify different names if you have multiple finders!
#pod
#pod Default: found_files
#pod
#pod =cut

parameter method => (
  isa     => 'Str',
  default => 'found_files',
);

role {
  my ($p) = @_;

  my ($finder_arg, @finder_arg_aliases) = @{ $p->finder_arg_names };
  confess "no finder arg names given!" unless $finder_arg;

  around mvp_multivalue_args => sub {
    my ($orig, $self) = @_;

    my @start = $self->$orig;
    return (@start, $finder_arg);
  };

  if (@finder_arg_aliases) {
    around mvp_aliases => sub {
      my ($orig, $self) = @_;

      my $start = $self->$orig;

      for my $alias (@finder_arg_aliases) {
        confess "$alias is already an alias to $start->{$alias}"
          if exists $start->{$alias} and $orig->{$alias} ne $finder_arg;
        $start->{ $alias } = $finder_arg;
      }

      return $start;
    };
  }

  has $finder_arg => (
    is  => 'ro',
    isa => 'ArrayRef[Str]',
    default => sub { [ @{ $p->default_finders } ] },
  );

  method $p->method => sub {
    my ($self) = @_;

    my @filesets = map {; $self->zilla->find_files($_) }
                   @{ $self->$finder_arg };

    my %by_name = map {; $_->name, $_ } map { @$_ } @filesets;

    return [ map {; $by_name{$_} } sort keys %by_name ];
  };
};

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Role::FileFinderUser - something that uses FileFinder plugins

=head1 VERSION

version 6.032

=head1 DESCRIPTION

This role enables you to search for files in the dist. This makes it easy to find specific
files and have the code factored out to common methods.

Here's an example of a finder: ( taken from AutoPrereqs )

  with 'Dist::Zilla::Role::FileFinderUser' => {
      default_finders  => [ ':InstallModules', ':ExecFiles' ],
  };

Then you use it in your code like this:

  foreach my $file ( @{ $self->found_files }) {
    # $file is an object! Look at L<Dist::Zilla::Role::File>
  }

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

=head1 ATTRIBUTES

=head2 finder_arg_names

Define the name of the attribute which will hold this finder. Be sure to specify different names
if you have multiple finders!

This is an ArrayRef.

Default: [ qw( finder ) ]

=head2 default_finders

This attribute is an arrayref of plugin names for the default plugins the
consuming plugin will use as finders.

Example: C<< [ qw( :InstallModules :ExecFiles ) ] >>

The default finders are:

=over 4

=item :InstallModules

Searches your lib/ directory for pm/pod files

=item :IncModules

Searches your inc/ directory for pm files

=item :MainModule

Finds the C<main_module> of your dist

=item :TestFiles

Searches your t/ directory and lists the files in it.

=item :ExtraTestFiles

Searches your xt/ directory and lists the files in it.

=item :ExecFiles

Searches your distribution for executable files.  Hint: Use the
L<Dist::Zilla::Plugin::ExecDir> plugin to mark those files as executables.

=item :PerlExecFiles

A subset of C<:ExecFiles> limited just to perl scripts (those ending with
F<.pl>, or with a recognizable perl shebang).

=item :ShareFiles

Searches your ShareDir directory and lists the files in it.
Hint: Use the L<Dist::Zilla::Plugin::ShareDir> plugin to set up the sharedir.

=item :AllFiles

Returns all files in the distribution.

=item :NoFiles

Returns nothing.

=back

=head2 method

This will be the name of the subroutine installed in your package for this
finder.  Be sure to specify different names if you have multiple finders!

Default: found_files

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
