use strict;
use warnings;
package Dist::Zilla::App::Command::authordeps 6.012;
# ABSTRACT: List your distribution's author dependencies

use Dist::Zilla::App -command;

#pod =head1 SYNOPSIS
#pod
#pod   $ dzil authordeps
#pod
#pod This will scan the F<dist.ini> file and print a list of plugin modules that
#pod probably need to be installed for the dist to be buildable.  This is a very
#pod naive scan, but tends to be pretty accurate.  Modules can be added to its
#pod results by using special comments in the form:
#pod
#pod   ; authordep Some::Package
#pod
#pod =cut

sub abstract { "list your distribution's author dependencies" }

sub opt_spec {
  return (
    [ 'root=s' => 'the root of the dist; defaults to .' ],
    [ 'missing' => 'list only the missing dependencies' ],
    [ 'versions' => 'include required version numbers in listing' ],
  );
}

sub execute {
  my ($self, $opt, $arg) = @_;

  require Dist::Zilla::Path;
  require Dist::Zilla::Util::AuthorDeps;

  my $deps = Dist::Zilla::Util::AuthorDeps::format_author_deps(
    Dist::Zilla::Util::AuthorDeps::extract_author_deps(
      Dist::Zilla::Path::path($opt->root // '.'),
      $opt->missing,
    ), $opt->versions
  );

  $self->log($deps) if $deps;

  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::App::Command::authordeps - List your distribution's author dependencies

=head1 VERSION

version 6.012

=head1 SYNOPSIS

  $ dzil authordeps

This will scan the F<dist.ini> file and print a list of plugin modules that
probably need to be installed for the dist to be buildable.  This is a very
naive scan, but tends to be pretty accurate.  Modules can be added to its
results by using special comments in the form:

  ; authordep Some::Package

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
