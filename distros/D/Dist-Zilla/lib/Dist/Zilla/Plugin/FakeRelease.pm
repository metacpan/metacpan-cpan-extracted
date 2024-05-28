package Dist::Zilla::Plugin::FakeRelease 6.032;
# ABSTRACT: fake plugin to test release

use Moose;
with 'Dist::Zilla::Role::Releaser';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

has user => (
  is   => 'ro',
  isa  => 'Str',
  required => 1,
  default  => 'AUTHORID',
);

sub cpanid { shift->user }

sub release {
  my $self = shift;

  for my $env (
    'DIST_ZILLA_FAKERELEASE_FAIL', # old
    'DZIL_FAKERELEASE_FAIL',       # new
  ) {
    $self->log_fatal("$env set, aborting") if $ENV{$env};
  }

  $self->log('Fake release happening (nothing was really done)');
}

__PACKAGE__->meta->make_immutable;
1;

#pod =head1 SYNOPSIS
#pod
#pod     [FakeRelease]
#pod     user = CPANAUTHORID ; # optional.
#pod
#pod =head1 DESCRIPTION
#pod
#pod This plugin is a L<Releaser|Dist::Zilla::Role::Releaser> that does nothing. It
#pod is directed to plugin authors, who may need a dumb release plugin to test their
#pod shiny plugin implementing L<BeforeRelease|Dist::Zilla::Role::BeforeRelease>
#pod and L<AfterRelease|Dist::Zilla::Role::AfterRelease>.
#pod
#pod When this plugin does the release, it will just log a message and finish.
#pod
#pod If you set the environment variable C<DZIL_FAKERELEASE_FAIL> to a true value,
#pod the plugin will die instead of doing nothing. This can be useful for
#pod authors wanting to test reliably that release failed.
#pod
#pod You can optionally provide the 'user' parameter, which defaults to 'AUTHORID',
#pod which will allow things that depend on this metadata
#pod ( Sometimes provided by L<UploadToCPAN|Dist::Zilla::Plugin::UploadToCPAN> ) to still work.
#pod ( For example: L<Dist::Zilla::Plugin::Twitter> )
#pod
#pod =head1 SEE ALSO
#pod
#pod Core Dist::Zilla plugins:
#pod L<ConfirmRelease|Dist::Zilla::Plugin::ConfirmRelease>,
#pod L<UploadToCPAN|Dist::Zilla::Plugin::UploadToCPAN>.
#pod

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::FakeRelease - fake plugin to test release

=head1 VERSION

version 6.032

=head1 SYNOPSIS

    [FakeRelease]
    user = CPANAUTHORID ; # optional.

=head1 DESCRIPTION

This plugin is a L<Releaser|Dist::Zilla::Role::Releaser> that does nothing. It
is directed to plugin authors, who may need a dumb release plugin to test their
shiny plugin implementing L<BeforeRelease|Dist::Zilla::Role::BeforeRelease>
and L<AfterRelease|Dist::Zilla::Role::AfterRelease>.

When this plugin does the release, it will just log a message and finish.

If you set the environment variable C<DZIL_FAKERELEASE_FAIL> to a true value,
the plugin will die instead of doing nothing. This can be useful for
authors wanting to test reliably that release failed.

You can optionally provide the 'user' parameter, which defaults to 'AUTHORID',
which will allow things that depend on this metadata
( Sometimes provided by L<UploadToCPAN|Dist::Zilla::Plugin::UploadToCPAN> ) to still work.
( For example: L<Dist::Zilla::Plugin::Twitter> )

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

=head1 SEE ALSO

Core Dist::Zilla plugins:
L<ConfirmRelease|Dist::Zilla::Plugin::ConfirmRelease>,
L<UploadToCPAN|Dist::Zilla::Plugin::UploadToCPAN>.

=head1 AUTHOR

Ricardo SIGNES 😏 <cpan@semiotic.systems>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024 by Ricardo SIGNES.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
