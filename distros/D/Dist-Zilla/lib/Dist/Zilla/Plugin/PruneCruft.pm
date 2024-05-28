package Dist::Zilla::Plugin::PruneCruft 6.032;
# ABSTRACT: prune stuff that you probably don't mean to include

use Moose;
use Moose::Util::TypeConstraints;
with 'Dist::Zilla::Role::FilePruner';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

#pod =head1 SYNOPSIS
#pod
#pod This plugin tries to compensate for the stupid crap that turns up in your
#pod working copy, removing it before it gets into your dist and screws everything
#pod up.
#pod
#pod In your F<dist.ini>:
#pod
#pod   [PruneCruft]
#pod
#pod If you would like to exclude certain exclusions, use the C<except> option (it
#pod can be specified multiple times):
#pod
#pod   [PruneCruft]
#pod   except = \.gitignore
#pod   except = t/.*/\.keep$
#pod
#pod This plugin is included in the L<@Basic|Dist::Zilla::PluginBundle::Basic>
#pod bundle.
#pod
#pod =head1 SEE ALSO
#pod
#pod Dist::Zilla plugins:
#pod L<@Basic|Dist::Zilla::PluginBundle::Basic>,
#pod L<PruneFiles|Dist::Zilla::Plugin::PruneFiles>,
#pod L<ManifestSkip|Dist::Zilla::Plugin::ManifestSkip>.
#pod
#pod =cut

{
  my $type = subtype as 'ArrayRef[RegexpRef]';
  coerce $type, from 'ArrayRef[Str]', via { [map { qr/$_/ } @$_] };
  has except => (
    is      => 'ro',
    isa     => $type,
    coerce  => 1,
    default => sub { [] },
  );
  sub mvp_multivalue_args { qw(except) }
}

sub _dont_exclude_file {
  my ($self, $file) = @_;
  for my $exception (@{ $self->except }) {
    return 1 if $file->name =~ $exception;
  }
  return;
}

sub exclude_file {
  my ($self, $file) = @_;

  return 0 if $self->_dont_exclude_file($file);
  return 1 if index($file->name, $self->zilla->name . '-') == 0;
  return 1 if $file->name =~ /\A\./;
  return 1 if $file->name =~ /\A(?:Build|Makefile)\z/;
  return 1 if $file->name eq 'Makefile.old';
  return 1 if $file->name =~ /\Ablib/;
  return 1 if $file->name =~ /\.(?:o|bs)$/;
  return 1 if $file->name =~ /\A_Inline/;
  return 1 if $file->name eq 'MYMETA.yml';
  return 1 if $file->name eq 'MYMETA.json';
  return 1 if $file->name eq 'pm_to_blib';
  return 1 if substr($file->name, 0, 6) eq '_eumm/';
  # Avoid bundling fatlib/ dir created by App::FatPacker
  # https://github.com/andk/pause/pull/65
  return 1 if substr($file->name, 0, 7) eq 'fatlib/';
  return 1 if substr($file->name, 0, 4) eq 'tmp/';

  if (my $file = $file->name =~ s/\.c$//r) {
    for my $other (@{ $self->zilla->files }) {
      return 1 if $other->name eq "${file}.xs";
    }
  }

  return;
}

sub prune_files {
  my ($self) = @_;

  # Copy list (break reference) so we can mutate.
  for my $file ((), @{ $self->zilla->files }) {
    next unless $self->exclude_file($file);

    $self->log_debug([ 'pruning %s', $file->name ]);

    $self->zilla->prune_file($file);
  }

  return;
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::PruneCruft - prune stuff that you probably don't mean to include

=head1 VERSION

version 6.032

=head1 SYNOPSIS

This plugin tries to compensate for the stupid crap that turns up in your
working copy, removing it before it gets into your dist and screws everything
up.

In your F<dist.ini>:

  [PruneCruft]

If you would like to exclude certain exclusions, use the C<except> option (it
can be specified multiple times):

  [PruneCruft]
  except = \.gitignore
  except = t/.*/\.keep$

This plugin is included in the L<@Basic|Dist::Zilla::PluginBundle::Basic>
bundle.

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

Dist::Zilla plugins:
L<@Basic|Dist::Zilla::PluginBundle::Basic>,
L<PruneFiles|Dist::Zilla::Plugin::PruneFiles>,
L<ManifestSkip|Dist::Zilla::Plugin::ManifestSkip>.

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
