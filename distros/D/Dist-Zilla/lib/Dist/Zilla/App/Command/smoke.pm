use strict;
use warnings;
package Dist::Zilla::App::Command::smoke 6.015;
# ABSTRACT: smoke your dist

use Dist::Zilla::App -command;

#pod =head1 SYNOPSIS
#pod
#pod   dzil smoke [ --release ] [ --author ] [ --no-automated ]
#pod
#pod =head1 DESCRIPTION
#pod
#pod This command builds and tests the distribution in "smoke testing mode."
#pod
#pod This command is a thin wrapper around the L<test|Dist::Zilla::Dist::Builder/test> method in
#pod Dist::Zilla.  It builds your dist and runs the tests with the AUTOMATED_TESTING
#pod environment variable turned on, so it's like doing this:
#pod
#pod   export AUTOMATED_TESTING=1
#pod   dzil build --no-tgz
#pod   cd $BUILD_DIRECTORY
#pod   perl Makefile.PL
#pod   make
#pod   make test
#pod
#pod A build that fails tests will be left behind for analysis, and F<dzil> will
#pod exit a non-zero value.  If the tests are successful, the build directory will
#pod be removed and F<dzil> will exit with status 0.
#pod
#pod =cut

sub opt_spec {
  [ 'release'   => 'enables the RELEASE_TESTING env variable', { default => 0 } ],
  [ 'automated!' => 'enables the AUTOMATED_TESTING env variable (default behavior)', { default => 1 } ],
  [ 'author' => 'enables the AUTHOR_TESTING env variable', { default => 0 } ]
}

#pod =head1 OPTIONS
#pod
#pod =head2 --release
#pod
#pod This will run the test suite with RELEASE_TESTING=1
#pod
#pod =head2 --no-automated
#pod
#pod This will run the test suite without setting AUTOMATED_TESTING
#pod
#pod =head2 --author
#pod
#pod This will run the test suite with AUTHOR_TESTING=1
#pod
#pod =cut

sub abstract { 'smoke your dist' }

sub execute {
  my ($self, $opt, $arg) = @_;

  local $ENV{RELEASE_TESTING} = 1 if $opt->release;
  local $ENV{AUTHOR_TESTING} = 1 if $opt->author;
  local $ENV{AUTOMATED_TESTING} = 1 if $opt->automated;

  $self->zilla->test;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::App::Command::smoke - smoke your dist

=head1 VERSION

version 6.015

=head1 SYNOPSIS

  dzil smoke [ --release ] [ --author ] [ --no-automated ]

=head1 DESCRIPTION

This command builds and tests the distribution in "smoke testing mode."

This command is a thin wrapper around the L<test|Dist::Zilla::Dist::Builder/test> method in
Dist::Zilla.  It builds your dist and runs the tests with the AUTOMATED_TESTING
environment variable turned on, so it's like doing this:

  export AUTOMATED_TESTING=1
  dzil build --no-tgz
  cd $BUILD_DIRECTORY
  perl Makefile.PL
  make
  make test

A build that fails tests will be left behind for analysis, and F<dzil> will
exit a non-zero value.  If the tests are successful, the build directory will
be removed and F<dzil> will exit with status 0.

=head1 OPTIONS

=head2 --release

This will run the test suite with RELEASE_TESTING=1

=head2 --no-automated

This will run the test suite without setting AUTOMATED_TESTING

=head2 --author

This will run the test suite with AUTHOR_TESTING=1

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
