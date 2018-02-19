use strict;
use warnings;
package Dist::Zilla::App::Command::release 6.011;
# ABSTRACT: release your dist to the CPAN

use Dist::Zilla::App -command;

#pod =head1 SYNOPSIS
#pod
#pod   dzil release
#pod
#pod   dzil release --trial
#pod
#pod This command is a very, very thin wrapper around the
#pod C<L<release|Dist::Zilla/release>> method on the Dist::Zilla object.  It will
#pod build, archive, and release your distribution using your Releaser plugins.  The
#pod only option, C<--trial>, will cause it to build a trial build.
#pod
#pod =cut

sub abstract { 'release your dist' }

sub opt_spec {
  [ 'trial' => 'build a trial release that PAUSE will not index' ],
}

sub execute {
  my ($self, $opt, $arg) = @_;

  my $zilla;
  {
    # isolate changes to RELEASE_STATUS to zilla construction
    local $ENV{RELEASE_STATUS} = $ENV{RELEASE_STATUS};
    $ENV{RELEASE_STATUS} = 'testing' if $opt->trial;
    $zilla = $self->zilla;
  }

  $self->zilla->release;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::App::Command::release - release your dist to the CPAN

=head1 VERSION

version 6.011

=head1 SYNOPSIS

  dzil release

  dzil release --trial

This command is a very, very thin wrapper around the
C<L<release|Dist::Zilla/release>> method on the Dist::Zilla object.  It will
build, archive, and release your distribution using your Releaser plugins.  The
only option, C<--trial>, will cause it to build a trial build.

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
