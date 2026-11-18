#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw(tempdir);
use IPC::Cmd qw(can_run);
use Path::Tiny;
use JSON::PP ();

# A real build of a small dist with [@Author::GETTY] in a git repository
# (fabricated .git/config, never a network), once without any remote and once
# with a github origin:
#  - no remote: no empty =head1 SUPPORT in the built files, podchecker clean,
#    and no `git svn info` probe by [Repository] on STDERR;
#  - github origin: the SUPPORT section with its Issues line, and the
#    repository resources GithubMeta reports;
#  - only a gitlab remote named upstream: [Repository] is pointed at it, so the
#    dist gets its repository resource and no `git svn info` noise.
# Without a remote the built META carries no empty resources hashes (the
# SUPPORT template reads distmeta->{resources}{...}{web}, which used to
# autovivify bugtracker and repository in the dist's own metadata).

plan skip_all => "Dist::Zilla::Tester not available"
  unless eval { require Dist::Zilla::Tester; require Pod::Checker; 1 };
plan skip_all => "git binary not available" unless can_run('git');

$ENV{DZIL_BINARY_SKIP}     = 1;
$ENV{DZIL_DOCKER_API_SKIP} = 1;

my $POD = <<'POD';
package Some::Dist;
# ABSTRACT: a small dist
our $VERSION = '0.001';
1;

__END__

=head1 SYNOPSIS

  use Some::Dist;

=head1 DESCRIPTION

Does nothing.

=cut
POD

# Builds the dist; returns ($tzil, $stderr, the built root).
sub build {
  my ($origin, $remote_name) = @_;
  $remote_name //= 'origin';
  my $tempdir = tempdir(CLEANUP => 1);
  my $root    = path($tempdir, 'dist');
  $root->child('lib')->mkpath;
  $root->child('dist.ini')->spew(<<'INI');
name = Some-Dist
author = Test <test@test.de>
license = Perl_5
copyright_holder = Test

[@Author::GETTY]
generate_license = 1
INI
  $root->child('lib', 'Some', 'Dist.pm')->parent->mkpath;
  $root->child('lib', 'Some', 'Dist.pm')->spew($POD);
  $root->child('Changes')->spew("Revision history\n\n{{\$NEXT}}\n\n  - first\n");

  my @git = (
    [qw(init -q)],
    [qw(add -A)],
    ['-c', 'user.email=test@test.de', '-c', 'user.name=Test', 'commit', '-q', '-m', 'init'],
    ($origin ? ['remote', 'add', $remote_name, $origin] : ()),
  );
  system('git', '-C', "$root", @$_) == 0 or die "git @$_ failed in $root: $?" for @git;

  # fd 2 itself is redirected so that child processes (git) are captured too
  my $errfile = path($tempdir, 'stderr');
  open my $olderr, '>&', \*STDERR or die "dup: $!";
  open STDERR, '>', "$errfile" or die "redirect: $!";
  my $tzil = eval {
    my $t = Dist::Zilla::Tester->from_config({ dist_root => "$root" }, { tempdir_root => "$tempdir" });
    $t->build;
    $t;
  };
  my $died = $@;
  open STDERR, '>&', $olderr or die "restore: $!";
  die $died unless $tzil;

  return ($tzil, scalar $errfile->slurp, $tzil->built_in);
}


sub built_pms {
  my ($built) = @_;
  my @pm;
  $built->child('lib')->visit(sub { push @pm, $_ if /\.pm\z/ }, { recurse => 1 });
  return @pm;
}

subtest 'build without a remote' => sub {
  my ($tzil, $stderr, $built) = build();
  my @pm = built_pms($built);
  ok(scalar @pm, 'sanity: the build produced a .pm');

  for my $pm (@pm) {
    my $text = $pm->slurp;
    unlike($text, qr/^=head1 SUPPORT/m, "no =head1 SUPPORT in " . $pm->basename);
    like($text, qr/^=head1 DESCRIPTION/m, "sanity: the weaver ran (DESCRIPTION present) in " . $pm->basename);

    my ($out, $log) = ('', '');
    open my $ofh, '>', \$out; open my $lfh, '<', \$text;
    my $checker = Pod::Checker->new(-warnings => 2);
    $checker->parse_from_file($lfh, $ofh);
    close $ofh;
    is($checker->num_errors, 0, "podchecker: no errors in " . $pm->basename) or diag $out;
    unlike($out, qr/empty section/i, "podchecker: no empty-section warning in " . $pm->basename);
  }

  unlike($stderr, qr/svn/, 'no `git svn info` probe on STDERR');
  my $meta = $tzil->distmeta;
  for my $key (qw(bugtracker repository)) {
    ok(!exists $meta->{resources} || !exists $meta->{resources}{$key} || keys %{ $meta->{resources}{$key} },
      "distmeta: no empty resources.$key hash");
  }
  ok(!exists $meta->{resources}, 'distmeta: no resources key at all without a remote');
  my $json = JSON::PP->new->decode($built->child('META.json')->slurp_raw);
  ok(!exists $json->{resources}, 'META.json: no resources key at all without a remote');
  is_deeply($meta->{resources}{repository} // {}, {}, 'no repository resource values (there is nothing to report)');
};

subtest 'build with a github origin' => sub {
  my ($tzil, $stderr, $built) = build('https://github.com/getty/p5-some-dist.git');
  my @pm = built_pms($built);

  for my $pm (@pm) {
    my $text = $pm->slurp;
    like($text, qr/^=head1 SUPPORT/m, "=head1 SUPPORT in " . $pm->basename);
    like($text, qr/=head2 Issues\s+Please report bugs and feature requests at\s+L<https:\/\/github\.com\/getty\/p5-some-dist\/issues>/,
      "the Issues line links the bugtracker in " . $pm->basename);
  }

  my $res = $tzil->distmeta->{resources};
  is($res->{bugtracker}{web}, 'https://github.com/getty/p5-some-dist/issues', 'bugtracker web');
  is_deeply($res->{repository}, {
    type => 'git',
    url  => 'https://github.com/getty/p5-some-dist.git',
    web  => 'https://github.com/getty/p5-some-dist',
  }, 'repository resource as GithubMeta reports it');
  unlike($stderr, qr/svn/, 'no svn noise either');
};

subtest 'build with only a gitlab remote named upstream' => sub {
  my ($tzil, $stderr, $built) = build('https://gitlab.com/getty/p5-some-dist.git', 'upstream');
  unlike($stderr, qr/svn/, 'no `git svn info` probe on STDERR');
  my ($repo) = grep { ref $_ && $_->isa('Dist::Zilla::Plugin::Repository') } @{ $tzil->plugins };
  ok($repo, 'sanity: the build used [Repository]');
  is($repo && $repo->git_remote, 'upstream', '[Repository] reads the upstream remote');
  my $res = $tzil->distmeta->{resources};
  is($res->{repository}{type}, 'git', 'resources.repository.type');
  is($res->{repository}{url}, 'https://gitlab.com/getty/p5-some-dist.git', 'resources.repository.url');
  ok(length($res->{repository}{web} // ''), 'resources.repository.web is set') or diag explain $res;
  my $json = JSON::PP->new->decode($built->child('META.json')->slurp_raw);
  is($json->{resources}{repository}{url}, 'https://gitlab.com/getty/p5-some-dist.git', 'META.json carries the repository url');
};

for my $case (
  [ github   => 'https://github.com/x/y.git',   'https://github.com/x/y' ],
  [ codeberg => 'https://codeberg.org/x/y.git', 'https://codeberg.org/x/y' ],
) {
  my ($label, $url, $web) = @$case;
  subtest "build with only a $label remote named upstream" => sub {
    my ($tzil, $stderr, $built) = build($url, 'upstream');
    unlike($stderr, qr/svn/, 'no `git svn info` probe on STDERR');
    my $res = $tzil->distmeta->{resources};
    is($res->{repository}{url}, $url, 'resources.repository.url');
    is($res->{repository}{web}, $web, 'resources.repository.web');
    is($res->{bugtracker}{web}, "$web/issues", 'resources.bugtracker.web');
  };
}

done_testing;
