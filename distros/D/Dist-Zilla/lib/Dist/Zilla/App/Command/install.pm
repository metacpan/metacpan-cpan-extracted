use strict;
use warnings;
package Dist::Zilla::App::Command::install 6.009;
# ABSTRACT: install your dist

use Dist::Zilla::App -command;

#pod =head1 SYNOPSIS
#pod
#pod Installs your distribution using a specified command.
#pod
#pod     dzil install [--install-command="cmd"]
#pod
#pod =cut
sub abstract { 'install your dist' }

#pod =head1 EXAMPLE
#pod
#pod     $ dzil install
#pod     $ dzil install --install-command="cpan ."
#pod
#pod =cut

sub opt_spec {
  [ 'install-command=s', 'command to run to install (e.g. "cpan .")' ],
  [ 'keep-build-dir|keep' => 'keep the build directory even after a success' ],
}

#pod =head1 OPTIONS
#pod
#pod =head2 --install-command
#pod
#pod This defines what command to run after building the dist in the dist dir.
#pod
#pod Any value that works with L<C<system>|perlfunc/system> is accepted.
#pod
#pod If not specified, calls (roughly):
#pod
#pod     cpanm .
#pod
#pod For more information, look at the L<install|Dist::Zilla::Dist::Builder/install> method in
#pod Dist::Zilla.
#pod
#pod =cut

sub execute {
  my ($self, $opt, $arg) = @_;

  $self->zilla->install({
    $opt->install_command
      ? (install_command => [ $opt->install_command ])
      : (),
    $opt->keep_build_dir
      ? (keep_build_dir => 1)
      : (),
  });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::App::Command::install - install your dist

=head1 VERSION

version 6.009

=head1 SYNOPSIS

Installs your distribution using a specified command.

    dzil install [--install-command="cmd"]

=head1 EXAMPLE

    $ dzil install
    $ dzil install --install-command="cpan ."

=head1 OPTIONS

=head2 --install-command

This defines what command to run after building the dist in the dist dir.

Any value that works with L<C<system>|perlfunc/system> is accepted.

If not specified, calls (roughly):

    cpanm .

For more information, look at the L<install|Dist::Zilla::Dist::Builder/install> method in
Dist::Zilla.

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2017 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
