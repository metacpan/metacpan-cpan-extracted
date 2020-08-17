package Dist::Zilla::Plugin::PERLANCAR::CheckPendingRelease;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-08-14'; # DATE
our $DIST = 'Dist-Zilla-Plugin-PERLANCAR-CheckPendingRelease'; # DIST
our $VERSION = '0.001'; # VERSION

use Moose;
with qw(Dist::Zilla::Role::BeforeRelease);

use namespace::autoclean;
use File::Which qw(which);
use IPC::System::Options qw(system);

sub before_release {
  my $self = shift;

  my $prog = "my-pending-perl-release";
  unless (which $prog) {
      $self->log_debug("Program $prog is not in PATH, skipping check of pending releases");
      return;
  }

  my $dist = $self->zilla->name;
  my $output;
  system(
      {log=>1, die=>1, capture_stdout=>\$output},
      $prog, "dist", $dist,
  );
  if ($output =~ /\S/) {
      $self->log_fatal("There is a pending release of $dist, aborting build");
  } else {
      $self->log_debug("There is no pending release of $dist, continuing build");
  }
}

__PACKAGE__->meta->make_immutable;
1;
# ABSTRACT: Check for pending release before releasing

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::PERLANCAR::CheckPendingRelease - Check for pending release before releasing

=head1 VERSION

This document describes version 0.001 of Dist::Zilla::Plugin::PERLANCAR::CheckPendingRelease (from Perl distribution Dist-Zilla-Plugin-PERLANCAR-CheckPendingRelease), released on 2020-08-14.

=head1 SYNOPSIS

In your F<dist.ini>:

 [PERLANCAR::CheckPendingRelease]

=head1 DESCRIPTION

In the BeforeRelease phase, this plugin checks whether the program
L<my-pending-perl-release> is found in PATH. If the program is found, this
plugin uses the program to check whether a previous release of the distro being
built is pending release. And when that is the case, the plugin aborts the build
to avoid releasing a newer version of the distro while another, older version
has been built but not yet released.

This plugin is most probably only useful to me, as I often build but not
immediately release my distros using L<Dist::Zilla>. I release this plugin
because this plugin is included in my standard bundle. When the
C<my-pending-perl-release> program is not found in PATH, this plugin will do
nothing.

=for Pod::Coverage .+

=head1 CONFIGURATION

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Dist-Zilla-Plugin-PERLANCAR-CheckPendingRelease>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Dist-Zilla-Plugin-PERLANCAR-CheckPendingRelease>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Dist-Zilla-Plugin-PERLANCAR-CheckPendingRelease>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
