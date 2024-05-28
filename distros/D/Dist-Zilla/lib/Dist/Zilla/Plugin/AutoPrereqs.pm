package Dist::Zilla::Plugin::AutoPrereqs 6.032;
# ABSTRACT: automatically extract prereqs from your modules

use Moose;
with(
  'Dist::Zilla::Role::PrereqScanner',
  'Dist::Zilla::Role::PrereqSource',
  'Dist::Zilla::Role::PPI',
);

use Dist::Zilla::Pragmas;

use Moose::Util::TypeConstraints 'enum';
use namespace::autoclean;

#pod =head1 SYNOPSIS
#pod
#pod In your F<dist.ini>:
#pod
#pod   [AutoPrereqs]
#pod   skip = ^Foo|Bar$
#pod   skip = ^Other::Dist
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin will extract loosely your distribution prerequisites from
#pod your files using L<Perl::PrereqScanner>.
#pod
#pod If some prereqs are not found, you can still add them manually with the
#pod L<Prereqs|Dist::Zilla::Plugin::Prereqs> plugin.
#pod
#pod This plugin will skip the modules shipped within your dist.
#pod
#pod B<Note>, if you have any non-Perl files in your C<t/> directory or other
#pod directories being scanned, be sure to mark those files' encoding as C<bytes>
#pod with the L<Encoding|Dist::Zilla::Plugin::Encoding> plugin so they won't be
#pod scanned:
#pod
#pod     [Encoding]
#pod     encoding = bytes
#pod     match    = ^t/data/
#pod
#pod =attr finder
#pod
#pod This is the name of a L<FileFinder|Dist::Zilla::Role::FileFinder>
#pod whose files will be scanned to determine runtime prerequisites.  It
#pod may be specified multiple times.  The default value is
#pod C<:InstallModules> and C<:ExecFiles>.
#pod
#pod =attr test_finder
#pod
#pod Just like C<finder>, but for test-phase prerequisites.  The default
#pod value is C<:TestFiles>.
#pod
#pod =attr configure_finder
#pod
#pod Just like C<finder>, but for configure-phase prerequisites.  There is
#pod no default value; AutoPrereqs will not determine configure-phase
#pod prerequisites unless you set configure_finder.
#pod
#pod =attr develop_finder
#pod
#pod Just like C<finder>, but for develop-phase prerequisites.  The default value
#pod is C<:ExtraTestFiles>.
#pod
#pod =attr skips
#pod
#pod This is an arrayref of regular expressions, derived from all the 'skip' lines
#pod in the configuration.  Any module names matching any of these regexes will not
#pod be registered as prerequisites.
#pod
#pod =attr relationship
#pod
#pod The relationship used for the registered prerequisites. The default value is
#pod 'requires'; other options are 'recommends' and 'suggests'.
#pod
#pod =attr extra_scanners
#pod
#pod This is an arrayref of scanner names (as expected by L<Perl::PrereqScanner>).
#pod It will be passed as the C<extra_scanners> parameter to L<Perl::PrereqScanner>.
#pod
#pod =attr scanners
#pod
#pod This is an arrayref of scanner names (as expected by L<Perl::PrereqScanner>).
#pod If present, it will be passed as the C<scanners> parameter to
#pod L<Perl::PrereqScanner>, which means that it will replace the default list
#pod of scanners.
#pod
#pod =head1 SEE ALSO
#pod
#pod L<Prereqs|Dist::Zilla::Plugin::Prereqs>, L<Perl::PrereqScanner>.
#pod
#pod =head1 CREDITS
#pod
#pod This plugin was originally contributed by Jerome Quelin.
#pod
#pod =cut

sub mvp_multivalue_args { qw(extra_scanners scanners) }
sub mvp_aliases { return { extra_scanner => 'extra_scanners',
                           scanner => 'scanners',
                           relationship => 'type' } }

has extra_scanners => (
  is  => 'ro',
  isa => 'ArrayRef[Str]',
  default => sub { [] },
);

has scanners => (
  is  => 'ro',
  isa => 'ArrayRef[Str]',
  predicate => 'has_scanners',
);


has _scanner => (
  is => 'ro',
  lazy => 1,
  default => sub {
    my $self = shift;

    require Perl::PrereqScanner;
    Perl::PrereqScanner->VERSION('1.016'); # don't skip "lib"

    return Perl::PrereqScanner->new(
      ($self->has_scanners ? (scanners => $self->scanners) : ()),
      extra_scanners => $self->extra_scanners,
    )
  },
  init_arg => undef,
);

has type => (
  is => 'ro',
  isa => enum([qw(requires recommends suggests)]),
  default => 'requires',
);

sub scan_file_reqs {
  my ($self, $file) = @_;
  return $self->_scanner->scan_ppi_document($self->ppi_document_for_file($file))
}

sub register_prereqs {
  my $self  = shift;

  my $type = $self->type;

  my $reqs_by_phase = $self->scan_prereqs;
  while (my ($phase, $reqs) = each %$reqs_by_phase) {
    $self->zilla->register_prereqs({ phase => $phase, type => $type }, %$reqs);
  }
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::AutoPrereqs - automatically extract prereqs from your modules

=head1 VERSION

version 6.032

=head1 SYNOPSIS

In your F<dist.ini>:

  [AutoPrereqs]
  skip = ^Foo|Bar$
  skip = ^Other::Dist

=head1 DESCRIPTION

This plugin will extract loosely your distribution prerequisites from
your files using L<Perl::PrereqScanner>.

If some prereqs are not found, you can still add them manually with the
L<Prereqs|Dist::Zilla::Plugin::Prereqs> plugin.

This plugin will skip the modules shipped within your dist.

B<Note>, if you have any non-Perl files in your C<t/> directory or other
directories being scanned, be sure to mark those files' encoding as C<bytes>
with the L<Encoding|Dist::Zilla::Plugin::Encoding> plugin so they won't be
scanned:

    [Encoding]
    encoding = bytes
    match    = ^t/data/

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

=head2 finder

This is the name of a L<FileFinder|Dist::Zilla::Role::FileFinder>
whose files will be scanned to determine runtime prerequisites.  It
may be specified multiple times.  The default value is
C<:InstallModules> and C<:ExecFiles>.

=head2 test_finder

Just like C<finder>, but for test-phase prerequisites.  The default
value is C<:TestFiles>.

=head2 configure_finder

Just like C<finder>, but for configure-phase prerequisites.  There is
no default value; AutoPrereqs will not determine configure-phase
prerequisites unless you set configure_finder.

=head2 develop_finder

Just like C<finder>, but for develop-phase prerequisites.  The default value
is C<:ExtraTestFiles>.

=head2 skips

This is an arrayref of regular expressions, derived from all the 'skip' lines
in the configuration.  Any module names matching any of these regexes will not
be registered as prerequisites.

=head2 relationship

The relationship used for the registered prerequisites. The default value is
'requires'; other options are 'recommends' and 'suggests'.

=head2 extra_scanners

This is an arrayref of scanner names (as expected by L<Perl::PrereqScanner>).
It will be passed as the C<extra_scanners> parameter to L<Perl::PrereqScanner>.

=head2 scanners

This is an arrayref of scanner names (as expected by L<Perl::PrereqScanner>).
If present, it will be passed as the C<scanners> parameter to
L<Perl::PrereqScanner>, which means that it will replace the default list
of scanners.

=head1 SEE ALSO

L<Prereqs|Dist::Zilla::Plugin::Prereqs>, L<Perl::PrereqScanner>.

=head1 CREDITS

This plugin was originally contributed by Jerome Quelin.

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
