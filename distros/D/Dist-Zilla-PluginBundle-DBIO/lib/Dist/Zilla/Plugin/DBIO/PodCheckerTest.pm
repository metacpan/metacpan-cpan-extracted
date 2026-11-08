package Dist::Zilla::Plugin::DBIO::PodCheckerTest;
# ABSTRACT: Generate xt/author/pod-checker.t, a Pod::Checker gate on the built POD
our $VERSION = '0.900004';
use Moose;
use Dist::Zilla::File::InMemory;
with 'Dist::Zilla::Role::FileGatherer';


sub gather_files {
  my ($self) = @_;
  $self->add_file(Dist::Zilla::File::InMemory->new(
    name    => 'xt/author/pod-checker.t',
    content => $self->_template,
  ));
  $self->log_debug('gathered xt/author/pod-checker.t');
}

sub _template {
  return <<'PERL';
use strict;
use warnings;
use File::Find ();
use Pod::Checker ();
use Test::More;

# Pod::Checker over the built distribution: modules under lib/, scripts under
# bin/. This is the woven POD -- what gets installed -- so it catches what no
# source file shows, above all an L</name> whose heading the woven document
# does not have ("unresolved internal link").
#
# Paths are relative to the distribution root, which is where `make test` and
# `prove` run from.
my @files;
for my $dir (grep { -d } qw(lib bin)) {
  File::Find::find({
    no_chdir => 1,
    wanted   => sub {
      push @files, $_ if -f && ($dir eq 'bin' || /\.(?:pm|pod)\z/);
    },
  }, $dir);
}

# Started from the wrong directory this would otherwise pass on nothing.
ok scalar(@files), 'found files to check under lib/ and bin/'
  or diag 'nothing found -- run this test from the distribution root';

for my $file (sort @files) {
  my $report = '';
  open my $out, '>:encoding(UTF-8)', \$report
    or die "cannot open in-memory handle: $!";

  # Errors only: warnings are not reported, so a green run stays quiet.
  my $checker = Pod::Checker->new(-warnings => 0);
  $checker->parse_from_file($file, $out);
  close $out;

  # num_errors is -1 for a file without any POD -- nothing to check, no fault.
  ok $checker->num_errors <= 0, "POD of $file"
    or diag $report;
}

done_testing;
PERL
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::DBIO::PodCheckerTest - Generate xt/author/pod-checker.t, a Pod::Checker gate on the built POD

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

Gathers an F<xt/author/pod-checker.t> test that runs L<Pod::Checker> over
every module under F<lib/> and every script under F<bin/> of the B<built>
distribution -- the POD as L<Pod::Weaver> left it, which is what gets
installed and what a reader sees. Any Pod::Checker error fails the test; the
checker's own messages (file, line, text) are printed as diagnostics.

It exists because a woven module can be broken without any source file looking
wrong: a C<LE<lt>/nameE<gt>> link whose heading the woven document does not
have is an C<unresolved internal link> to Pod::Checker, and nothing else in the
build notices it. L<Test::Pod> does not either -- it checks POD syntax, not
link targets -- which is why this is a Pod::Checker test and not
L<Dist::Zilla::Plugin::PodSyntaxTests>.

Only errors fail the test. Pod::Checker warnings are not reported at all, so a
green run stays quiet. A file without any POD is not an error. A run that finds
no file to check fails rather than passing on nothing.

F<[ExtraTests]> promotes the file to F<t/author-pod-checker.t>, guarded by
C<AUTHOR_TESTING>: it runs under C<dzil test> and C<dzil release>, and is
skipped when the distribution is merely installed. It needs nothing beyond
core Perl.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
