package Dist::Zilla::App::Command::clean 6.032;
# ABSTRACT: clean up after build, test, or install

use Dist::Zilla::Pragmas;

use Dist::Zilla::App -command;

#pod =head1 SYNOPSIS
#pod
#pod   dzil clean [ --dry-run|-n ]
#pod
#pod This command removes some files that are created during build, test, and
#pod install.  It's a very thin layer over the C<L<clean|Dist::Zilla/clean>> method
#pod on the Dist::Zilla object.  The documentation for that method gives more
#pod information about the files that will be removed.
#pod
#pod =cut

sub opt_spec {
  [ 'dry-run|n'   => 'don\'t actually remove anything, just show what would be done' ],
}

#pod =head1 OPTIONS
#pod
#pod =head2 -n, --dry-run
#pod
#pod Nothing is removed; instead, everything that would be removed will be listed.
#pod
#pod =cut

sub abstract { 'clean up after build, test, or install' }

sub execute {
  my ($self, $opt, $arg) = @_;

  $self->zilla->clean($opt->dry_run);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::App::Command::clean - clean up after build, test, or install

=head1 VERSION

version 6.032

=head1 SYNOPSIS

  dzil clean [ --dry-run|-n ]

This command removes some files that are created during build, test, and
install.  It's a very thin layer over the C<L<clean|Dist::Zilla/clean>> method
on the Dist::Zilla object.  The documentation for that method gives more
information about the files that will be removed.

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

=head1 OPTIONS

=head2 -n, --dry-run

Nothing is removed; instead, everything that would be removed will be listed.

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
