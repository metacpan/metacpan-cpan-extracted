package Dist::Zilla::Plugin::DBIO::VersionLockstepTest;
# ABSTRACT: Generate xt/author/version-lockstep.t, a gate that every module carries the main module's version
our $VERSION = '0.900007';
use Moose;
use Dist::Zilla::File::InMemory;
with 'Dist::Zilla::Role::FileGatherer';


sub gather_files {
  my ($self) = @_;
  my $main = $self->zilla->main_module->name;
  $self->add_file(Dist::Zilla::File::InMemory->new(
    name    => 'xt/author/version-lockstep.t',
    content => $self->_template($main),
  ));
  $self->log_debug('gathered xt/author/version-lockstep.t');
}

sub _template {
  my ($self, $main) = @_;
  (my $quoted = $main) =~ s/([\\'])/\\$1/g;
  my $tpl = <<'PERL';
use strict;
use warnings;
use File::Find ();
use Test::More;

# Every module under lib/ carries the version of the main module. The
# release rewrites all of them; this checks the result. Paths are relative to
# the distribution root.
my $main = '@@MAIN@@';

# The literal $VERSION assignment of a file, or undef when it has none.
sub version_of {
  my ($file) = @_;
  open my $fh, '<:encoding(UTF-8)', $file or die "cannot read $file: $!";
  while (my $line = <$fh>) {
    return $1 if $line =~ /^\s*(?:our\s+)?\$VERSION\s*=\s*['"]?([0-9][0-9._]*)['"]?\s*;/;
  }
  return undef;
}

my $want = -f $main ? version_of($main) : undef;
ok defined $want, "main module $main carries a literal \$VERSION"
  or BAIL_OUT 'no main module version to compare against -- run this test from the distribution root';

my @files;
File::Find::find({
  no_chdir => 1,
  wanted   => sub { push @files, $_ if -f && /\.pm\z/ },
}, 'lib');
ok scalar(@files), 'found modules under lib/';

for my $file (sort @files) {
  my $have = version_of($file);
  ok defined $have && $have eq $want,
    "$file carries version $want"
    or diag defined $have
      ? "$file has \$VERSION $have, the main module has $want"
      : "$file has no literal \$VERSION, the main module has $want";
}

done_testing;
PERL
  $tpl =~ s/\@\@MAIN\@\@/$quoted/;
  return $tpl;
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Dist::Zilla::Plugin::DBIO::VersionLockstepTest - Generate xt/author/version-lockstep.t, a gate that every module carries the main module's version

=head1 VERSION

version 0.900007

=head1 DESCRIPTION

Gathers an F<xt/author/version-lockstep.t> test that reads the literal
C<$VERSION> of the main module and of every F<.pm> under F<lib/> of the
B<built> distribution, and fails when a module has none or a different one.
Each deviating module is named with the version it carries.

It exists for the core distribution (C<core = 1> in the bundle). Core and
drivers alike version through L<Dist::Zilla::PluginBundle::Git::VersionManager>:
C<RewriteVersion::Transitional> rewrites the C<$VERSION> of every module at the
release. This test checks the result in the built distribution, so a module
whose C<$VERSION> comes out of step, whatever the way, turns the test red
instead of installing with a stale version.

The main module is the one L<Dist::Zilla> reports for the distribution at
build time; its path is written into the generated test. A run that finds no
module to check fails rather than passing on nothing.

F<[ExtraTests]> promotes the file to F<t/author-version-lockstep.t>, guarded
by C<AUTHOR_TESTING>: it runs under C<dzil test> and C<dzil release>, and is
skipped when the distribution is merely installed. It needs nothing beyond
core Perl.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
