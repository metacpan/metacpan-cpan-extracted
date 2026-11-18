#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Dist::Zilla::Tester;
use Dist::Zilla::Chrome::Term;
use Path::Tiny;
use File::Temp qw(tempdir);

my $CHECK = 'Dist::Zilla::Plugin::Author::GETTY::InstallCheck';

sub make_tzil {
  my ($config, $tempdir) = @_;
  my $dist_dir = path($tempdir, 'dist');
  $dist_dir->mkpath;
  $dist_dir->child('dist.ini')->spew($config);
  $dist_dir->child('lib')->mkpath;
  $dist_dir->child('lib', 'Foo.pm')->spew("package Foo;\n# ABSTRACT: foo\n1;\n");
  return Dist::Zilla::Tester->from_config(
    { dist_root => "$dist_dir" },
    { tempdir_root => $tempdir, chrome => Dist::Zilla::Chrome::Term->new },
  );
}

my $HEAD = <<'CONF';
name = Test-Dist
version = 0.001
author = Test <test@test.de>
license = Perl_5
copyright_holder = Test

CONF

# Order of the release-time plugins in the bundle -----------------------------

sub order {
  my ($extra) = @_;
  my $tzil = make_tzil($HEAD . "[\@Author::GETTY]\n$extra", tempdir(CLEANUP => 1));
  return [ map { ref $_ } @{ $tzil->plugins } ];
}

sub idx {
  my ($list, $class) = @_;
  my @i = grep { $list->[$_] eq $class } 0 .. $#$list;
  return @i;
}

{
  my $p = order('');
  my @check   = idx($p, $CHECK);
  my @confirm = idx($p, 'Dist::Zilla::Plugin::ConfirmRelease');
  my @test    = idx($p, 'Dist::Zilla::Plugin::TestRelease');
  is scalar(@check),   1, 'default: one InstallCheck';
  is scalar(@confirm), 1, 'default: ConfirmRelease exactly once';
  is scalar(@test),    1, 'default: one TestRelease';
  ok $test[0] < $check[0], 'TestRelease before InstallCheck';
  ok $check[0] < $confirm[0], 'InstallCheck before ConfirmRelease';
  is $confirm[0], $check[0] + 1, 'ConfirmRelease directly after InstallCheck';
  my @ir = idx($p, 'Dist::Zilla::Plugin::InstallRelease');
  is scalar(@ir), 1, 'InstallRelease stays';
}

{
  my $p = order("no_installrelease = 1\n");
  is scalar(idx($p, $CHECK)), 0, 'no_installrelease: no InstallCheck';
  is scalar(idx($p, 'Dist::Zilla::Plugin::ConfirmRelease')), 1,
    'no_installrelease: ConfirmRelease exactly once';
}

{
  my $p = order("alien_name = foo\nalien_repo = http://example.invalid/\n");
  is scalar(idx($p, $CHECK)), 0, 'alien: no InstallCheck';
  is scalar(idx($p, 'Dist::Zilla::Plugin::ConfirmRelease')), 1,
    'alien: ConfirmRelease exactly once';
}

# Default command ---------------------------------------------------------------

{
  my $tzil = make_tzil($HEAD . "[GatherDir]\n[Author::GETTY::InstallCheck]\n", tempdir(CLEANUP => 1));
  my ($plugin) = grep { ref $_ eq $CHECK } @{ $tzil->plugins };
  is_deeply $plugin->command, [ 'cpanm', '--test-only' ],
    'the default command is cpanm --test-only';
}

# Behaviour of the plugin -------------------------------------------------------
# The `command` attribute points at a small perl script (run with $^X, so this
# works the same on Windows): the plugin runs the command in list form without
# a shell, and the script reports what it was given and its environment.

sub release_conf {
  my ($stub) = @_;
  return $HEAD . <<"CONF";
[GatherDir]
[FakeRelease]
[Author::GETTY::InstallCheck]
command = $^X
command = $stub
CONF
}

sub write_stub {
  my ($file, $exit) = @_;
  $file->spew(<<"PL");
open my \$fh, '>', \$ENV{STUB_OUT} or die "open: \$!";
print \$fh "ARGS:\@ARGV\\n";
print \$fh "RELEASE_TESTING:", (exists \$ENV{RELEASE_TESTING} ? \$ENV{RELEASE_TESTING} : 'unset'), "\\n";
print \$fh "AUTHOR_TESTING:", (exists \$ENV{AUTHOR_TESTING} ? \$ENV{AUTHOR_TESTING} : 'unset'), "\\n";
print \$fh "KEEP:", (exists \$ENV{INSTALLCHECK_KEEP} ? \$ENV{INSTALLCHECK_KEEP} : 'unset'), "\\n";
close \$fh;
exit $exit;
PL
}

for my $case ([ok => 0], [fail => 3]) {
  my ($label, $exit) = @$case;
  my $tmp  = path(tempdir(CLEANUP => 1));
  my $stub = $tmp->child('stub.pl');
  write_stub($stub, $exit);
  my $out = $tmp->child('stub.out');

  local $ENV{STUB_OUT} = "$out";
  local $ENV{RELEASE_TESTING} = 1;
  local $ENV{AUTHOR_TESTING} = 1;
  local $ENV{INSTALLCHECK_KEEP} = 'yes';

  $tmp->child('t')->mkpath;
  my $tzil = make_tzil(release_conf($stub), $tmp->child('t')->stringify);
  my $died = !eval { $tzil->release; 1 };
  my $err  = $@;
  my $fake = grep { /fake/i } @{ $tzil->log_messages };

  my %seen = map { /^(\w+):(.*)$/ ? ($1 => $2) : () } split /\r?\n/, ($out->exists ? $out->slurp : '');

  if ($exit == 0) {
    ok !$died, 'passing command: release goes on' or diag $err;
    ok $fake, 'passing command: the Releaser ran';
  } else {
    ok $died, 'failing command: release aborts';
    like $err, qr/nothing was uploaded/i, 'failing command: message says nothing was uploaded';
    like $err, qr/Test-Dist-0\.001\.tar\.gz/, 'failing command: message names the tarball';
    ok !$fake, 'failing command: the Releaser did not run';
  }
  like $seen{ARGS}, qr/^(?:[A-Za-z]:)?[\\\/]\S*Test-Dist-0\.001\.tar\.gz$/,
    "$label: command gets the absolute tarball path";
  is $seen{RELEASE_TESTING}, 'unset', "$label: RELEASE_TESTING not set for the command";
  is $seen{AUTHOR_TESTING},  'unset', "$label: AUTHOR_TESTING not set for the command";
  is $seen{KEEP}, 'yes', "$label: the rest of the environment passes through";
  is $ENV{RELEASE_TESTING}, 1, "$label: caller's RELEASE_TESTING restored";
}

done_testing;
