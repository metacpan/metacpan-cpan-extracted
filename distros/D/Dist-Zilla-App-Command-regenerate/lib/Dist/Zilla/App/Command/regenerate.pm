use 5.006;    # our
use strict;
use warnings;

package Dist::Zilla::App::Command::regenerate;

our $VERSION = '0.001002';

# ABSTRACT: Write content into your source tree from your release staging

our $AUTHORITY = 'cpan:DBOOK'; # AUTHORITY

use Dist::Zilla::App '-command';
use Carp qw( croak );
use namespace::clean;

## no critic (ProhibitAmbiguousNames)
sub abstract { 'write release staging contents into source tree' }

sub opt_spec { }

sub execute {
  my ( $self, ) = @_;

  # TODO: Maybe add room for additional early steps
  # in the build cycle?
  my ( $target, ) = $self->zilla->ensure_built_in_tmpdir;
  croak('No -Regenerator plugins to regenerate with')
    unless my @regens = @{ $self->zilla->plugins_with('-Regenerator') };

  # TODO: Pass through args? Maybe regenerate specific files?
  for my $regen (@regens) {
    $regen->regenerate(
      {
        build_root => "$target",
        root       => $self->zilla->root . q{},
      },
    );
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::App::Command::regenerate - Write content into your source tree from your release staging

=head1 VERSION

version 0.001002

=head1 SYNOPSIS

  # Have approprite dist.ini
  dzil regenerate  # Source tree updated!

=head1 DESCRIPTION

C<Dist::Zilla::App::Command::regenerate> provides a C<regenerate> command to C<Dist::Zilla>
that allows some simple tooling to update your source tree when you choose to.

This works by producing a new synthetic target like the C<release> target, which happens
after the C<build> stage, but does not produce a release.

In conjunction with appropriate C<plugins> performing
L<< C<-Regenerator>|Dist::Zilla::Role::Regenerator >>, This means that:

=over 4

=item * You won't be frustrated with C<dzil build> constantly tweaking your source tree

=item * You won't be forced to ship a release just to update the state of some files that are generated
by plugins

=item * You won't even have to update your source tree B<ever> if you don't want to.

=back

When calling C<dzil regenerate>, a full copy of the distribution is built in a temporary directory
like it does when you call C<dzil test>.

Then after C<dzil regenerate> has written your built distribution out to the temporary directory,
any C<plugin>'s that perform the C<-Regenerator> role are called and told where your source tree is,
and where the build tree is, and they are expected to do the required work.

In effect, C<dzil regenerate> is a lot like:

  dzil build --not && \
    DO_STUFF_WITH .build/latest/  && \
    MAYBECOPY .build/latest/stuff ./stuff

Where those last 2 lines are done with C<plugins>.

=head1 SEE ALSO

=over 4

=item * L<< C<dzil update>|Dist::Zilla::App::Command::update >>

This command invokes only the C<dzil build> parts of the equation and rely C<dzil build>
itself doing your source tree modification.

A goal of C<dzil regenerate> is to avoid C<dzil build> doing source tree modification.

=back

=head1 AUTHOR

Kent Fredric <kentnl@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016-2017 by Kent Fredric <kentfredric@gmail.com>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
