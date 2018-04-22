package Dist::Zilla::Plugin::ConfirmRelease 6.012;
# ABSTRACT: prompt for confirmation before releasing

use Moose;
with 'Dist::Zilla::Role::BeforeRelease';

use namespace::autoclean;

sub before_release {
  my ($self, $tgz) = @_;

  my $releasers = join q{, },
                  map {; $_->plugin_name }
                  @{ $self->zilla->plugins_with(-Releaser) };

  $self->log("*** Preparing to release $tgz with $releasers ***");
  my $prompt = "Do you want to continue the release process?";

  my $default = exists $ENV{DZIL_CONFIRMRELEASE_DEFAULT}
              ? $ENV{DZIL_CONFIRMRELEASE_DEFAULT}
              : 0;

  my $confirmed = $self->zilla->chrome->prompt_yn(
    $prompt,
    { default => $default }
  );

  $self->log_fatal("Aborting release") unless $confirmed;
}

__PACKAGE__->meta->make_immutable;
1;

#pod =head1 DESCRIPTION
#pod
#pod This plugin prompts the author whether or not to continue before releasing
#pod the distribution to CPAN.  It gives authors a chance to abort before
#pod they upload.
#pod
#pod The default is "no", but you can set the environment variable
#pod C<DZIL_CONFIRMRELEASE_DEFAULT> to "yes" if you just want to hit enter to
#pod release.

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::ConfirmRelease - prompt for confirmation before releasing

=head1 VERSION

version 6.012

=head1 DESCRIPTION

This plugin prompts the author whether or not to continue before releasing
the distribution to CPAN.  It gives authors a chance to abort before
they upload.

The default is "no", but you can set the environment variable
C<DZIL_CONFIRMRELEASE_DEFAULT> to "yes" if you just want to hit enter to
release.

=head1 AUTHOR

Ricardo SIGNES 😏 <rjbs@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
