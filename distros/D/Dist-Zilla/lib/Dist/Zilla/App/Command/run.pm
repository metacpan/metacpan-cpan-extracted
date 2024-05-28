package Dist::Zilla::App::Command::run 6.032;
# ABSTRACT: run stuff in a dir where your dist is built

use Dist::Zilla::Pragmas;

use Dist::Zilla::App -command;

#pod =head1 SYNOPSIS
#pod
#pod   $ dzil run ./bin/myscript
#pod   $ dzil run prove -bv t/mytest.t
#pod   $ dzil run bash
#pod
#pod =head1 DESCRIPTION
#pod
#pod This command will build your dist with Dist::Zilla, then build the
#pod distribution and then run a command in the build directory.  It's something
#pod like doing this:
#pod
#pod   dzil build
#pod   rsync -avp My-Project-version/ .build/
#pod   cd .build
#pod   perl Makefile.PL            # or perl Build.PL
#pod   make                        # or ./Build
#pod   export PERL5LIB=$PWD/blib/lib:$PWD/blib/arch
#pod   <your command as defined by rest of params>
#pod
#pod Except for the fact it's built directly in a subdir of .build (like
#pod F<.build/69105y2>).
#pod
#pod A command returning with an non-zero error code will left the build directory
#pod behind for analysis, and C<dzil> will exit with a non-zero status.  Otherwise,
#pod the build directory will be removed and dzil will exit with status zero.
#pod
#pod If no run command is provided, a new default shell is invoked. This can be
#pod useful for testing your distribution as if it were installed.
#pod
#pod =cut

sub abstract { 'run stuff in a dir where your dist is built' }

sub opt_spec {
  [ 'build!' => 'do the Build actions before running the command; done by default',
                { default => 1 } ],
  [ 'trial'  => 'build a trial release that PAUSE will not index' ],
}

sub description {
  "This will build your dist and run the given 'command' in the build dir.\n" .
  "If no command was specified, your shell will be run there instead."
}

sub usage_desc {
  return '%c run %o [ command [ arg1 arg2 ... ] ]';
}

sub execute {
  my ($self, $opt, $args) = @_;

  unless (@$args) {
    my $envname = $^O eq 'MSWin32' ? 'COMSPEC' : 'SHELL';
    unless ($ENV{$envname}) {
      $self->usage_error("no command supplied to run and no \$$envname set");
    }
    $args = [ $ENV{$envname} ];
    $self->log("no command supplied to run so using \$$envname: $args->[0]");
  }

  $self->zilla->run_in_build($args, { build => $opt->build, trial => $opt->trial });
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::App::Command::run - run stuff in a dir where your dist is built

=head1 VERSION

version 6.032

=head1 SYNOPSIS

  $ dzil run ./bin/myscript
  $ dzil run prove -bv t/mytest.t
  $ dzil run bash

=head1 DESCRIPTION

This command will build your dist with Dist::Zilla, then build the
distribution and then run a command in the build directory.  It's something
like doing this:

  dzil build
  rsync -avp My-Project-version/ .build/
  cd .build
  perl Makefile.PL            # or perl Build.PL
  make                        # or ./Build
  export PERL5LIB=$PWD/blib/lib:$PWD/blib/arch
  <your command as defined by rest of params>

Except for the fact it's built directly in a subdir of .build (like
F<.build/69105y2>).

A command returning with an non-zero error code will left the build directory
behind for analysis, and C<dzil> will exit with a non-zero status.  Otherwise,
the build directory will be removed and dzil will exit with status zero.

If no run command is provided, a new default shell is invoked. This can be
useful for testing your distribution as if it were installed.

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

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
