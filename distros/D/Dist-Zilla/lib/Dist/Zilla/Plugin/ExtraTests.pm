package Dist::Zilla::Plugin::ExtraTests 6.032;
# ABSTRACT: rewrite ./xt tests to ./t tests with skips

use Moose;
with 'Dist::Zilla::Role::FileMunger';

use Dist::Zilla::Pragmas;

use namespace::autoclean;

#pod =head1 DESCRIPTION
#pod
#pod This plugin rewrites tests found in the following directories:
#pod
#pod   ./xt/author  - tests for author testing (env AUTHOR_TESTING is true)
#pod   ./xt/release - tests for pre-release testers (env RELEASE_TESTING is true)
#pod   ./xt/smoke   - tests for automated testers (env AUTOMATED_TESTING is true)
#pod
#pod The tests are renamed and moved to F<./t>, and they are rewritten to include
#pod some simple Perl code to skip all included tests if the correct env vars are
#pod not set.
#pod
#pod =cut

sub munge_file {
  my ($self, $file) = @_;

  return unless $file->name =~ m{\Axt/(smoke|author|release)/.+\.t\z};
  my $method = "_rewrite_$1\_test";

  $self->log("rewriting $1 test " . $file->name);

  $self->$method($file);
}

sub _rewrite_smoke_test {
  my ($self, $file) = @_;
  $self->_rewrite($file, 'AUTOMATED_TESTING', '"smoke bot" testing');
}

sub _rewrite_author_test {
  my ($self, $file) = @_;
  $self->_rewrite($file, 'AUTHOR_TESTING', 'testing by the author');
}

sub _rewrite_release_test {
  my ($self, $file) = @_;
  $self->_rewrite($file, 'RELEASE_TESTING', 'release candidate testing');
}

sub _rewrite {
  my ($self, $file, $env, $msg) = @_;

  my $name = $file->name =~ s{^xt/([^/]+)/}{t/$1-}r;

  $file->name($name);

  my @lines = split /\n/, $file->content;
  my $after = $lines[0] =~ /\A#!/ ? 1 : 0;
  splice @lines, $after, 0, qq|
BEGIN {
  unless (\$ENV{$env}) {
    print qq{1..0 # SKIP these tests are for $msg\\n};
    exit
  }
}
|;

  $file->content(join "\n", @lines, '');
}

__PACKAGE__->meta->make_immutable;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::ExtraTests - rewrite ./xt tests to ./t tests with skips

=head1 VERSION

version 6.032

=head1 DESCRIPTION

This plugin rewrites tests found in the following directories:

  ./xt/author  - tests for author testing (env AUTHOR_TESTING is true)
  ./xt/release - tests for pre-release testers (env RELEASE_TESTING is true)
  ./xt/smoke   - tests for automated testers (env AUTOMATED_TESTING is true)

The tests are renamed and moved to F<./t>, and they are rewritten to include
some simple Perl code to skip all included tests if the correct env vars are
not set.

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
