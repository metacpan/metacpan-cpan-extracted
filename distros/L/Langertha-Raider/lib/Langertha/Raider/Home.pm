package Langertha::Raider::Home;
# ABSTRACT: Internal resolver of the home and project .raider directories
our $VERSION = '0.503';
use strict;
use warnings;
use Path::Tiny;


sub home_dir { $ENV{HOME} // (getpwuid($<))[7] }

sub dir_name { '.raider' }

sub home_base {
  my ( $self, $home ) = @_;
  $home //= $self->home_dir;
  return unless defined $home;
  return $self->_base($home);
}

sub project_base {
  my ( $self, $root ) = @_;
  return $self->_base($root);
}

sub _base { path($_[1])->absolute->child($_[0]->dir_name) }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Langertha::Raider::Home - Internal resolver of the home and project .raider directories

=head1 VERSION

version 0.503

=head1 SYNOPSIS

    # Internal to Langertha-Raider -- no API promise.
    my $home = Langertha::Raider::Home->home_dir;                 # $ENV{HOME}, else getpwuid
    my $user = Langertha::Raider::Home->home_base;                # ~/.raider
    my $proj = Langertha::Raider::Home->project_base($root);      # <root>/.raider

=head1 DESCRIPTION

B<Internal module.> Its interface may change without notice.

The one place that knows where the F<.raider> directories of a user and of a
project live (ADR 0011). Class methods only; every path is returned as an
absolute L<Path::Tiny>.

=head2 home_dir

The user's home: C<$ENV{HOME}>, else the home from the password database.
May be C<undef> when neither knows one.

=head2 dir_name

The name of the directory inside a home or project, C<.raider>.

=head2 home_base

    my $base = Langertha::Raider::Home->home_base;          # ~/.raider
    my $base = Langertha::Raider::Home->home_base($home);   # <home>/.raider

F<.raider> under the given home, by default under L</home_dir>. Returns
nothing when there is no home at all.

=head2 project_base

F<.raider> under the given project root.

=head1 SUPPORT

=head2 Issues

Please report bugs and feature requests on GitHub at
L<https://github.com/Getty/langertha-raider/issues>.

=head2 IRC

Join C<#langertha> on C<irc.perl.org> or message Getty directly.

=head1 CONTRIBUTING

Contributions are welcome! Please fork the repository and submit a pull request.

=head1 AUTHOR

Torsten Raudssus <torsten@raudssus.de> L<https://raudssus.de/>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2026 by Torsten Raudssus.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
