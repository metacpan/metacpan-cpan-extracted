use Test2::V0;
use lib 't/lib';
use TestRepo;
use Git::Native;
use Path::Tiny;

# Regression test for the TestRepo config isolation (karr-9, karr-13).
#
# The suite used to isolate itself with GIT_CONFIG_GLOBAL=/dev/null and
# GIT_CONFIG_SYSTEM=/dev/null. That works for the git CLI and does exactly
# nothing for libgit2, which knows neither variable (nor GIT_CONFIG_NOSYSTEM):
# it resolves the non-repository config levels through its own sysdir search
# path - guessed from HOME / XDG_CONFIG_HOME during git_libgit2_init for the
# global and XDG levels, and compiled in as /etc/gitconfig for the system
# level. So every assertion about a real config key was answered from the
# developer's ~/.gitconfig or from /etc/gitconfig, and every test commit was
# signed with the developer's identity.
#
# TestRepo now closes both. Git::Native->set_config_search_path points every
# non-repository level at a throwaway directory (karr-13; needs the
# git_libgit2_opts binding from Git::Libgit2 0.006), and the HOME redirect
# stays for the non-config things a home directory carries - ~/.ssh above all.
# This file pins that down from both levels and from both sides:
#
#   * an isolated repository sees no global identity and no system settings,
#   * a probe config placed in each redirected directory *is* read, so the
#     assertions above measure a live channel and not an empty universe,
#   * a subprocess without TestRepo reads the fixture's ~/.gitconfig and the
#     real /etc/gitconfig - the leak channels are real, and TestRepo closes
#     them without touching the repository level, which stays visible on
#     purpose (t/67-signature.t depends on it).

my $PROBE_EMAIL  = 'global-probe@example.invalid';
my $LEAK_EMAIL   = 'leak-probe@example.invalid';
my $SYSTEM_PROBE = 'system-probe-value';

# First simple key/value out of the real /etc/gitconfig, or the empty list.
# Lets the system-level assertions use a genuine setting without hardcoding
# anything about this machine. core.* is skipped because git_repository_init
# writes core.* into the repository config, so a core key would be answered by
# the repository level and prove nothing; so are values with quoting, comment
# characters or continuations, which would need a real config parser to
# compare against.
sub first_system_setting {
  my $file = path('/etc/gitconfig');
  return () unless $file->is_file;
  my @lines = eval { $file->lines_utf8( { chomp => 1 } ) } or return ();
  my ( $section, $subsection );
  for my $line (@lines) {
    next if $line =~ /^\s*[#;]/;
    if ( $line =~ /^\s*\[\s*([\w.-]+)\s*(?:"([^"]*)")?\s*\]/ ) {
      ( $section, $subsection ) = ( lc $1, $2 );
      next;
    }
    next unless defined $section && $section ne 'core';
    next unless $line =~ /^\s*([\w-]+)\s*=\s*(.+?)\s*$/;
    my ( $name, $value ) = ( lc $1, $2 );
    next unless $value =~ m{^[\w .:%/\@+-]+$};
    return ( join( '.', grep { defined && length } $section, $subsection, $name ),
      $value );
  }
  return ();
}

subtest 'every non-repository level is redirected, CLI variables still set' => sub {
  # All three mechanisms have to be in place: the env vars cover a git CLI a
  # fixture might shell out to, the search path covers libgit2 itself, and the
  # HOME redirect covers ~/.ssh.
  is $ENV{GIT_CONFIG_GLOBAL}, '/dev/null', 'GIT_CONFIG_GLOBAL still pinned';
  is $ENV{GIT_CONFIG_SYSTEM}, '/dev/null', 'GIT_CONFIG_SYSTEM still pinned';

  is $ENV{HOME}, "$TestRepo::HOME", 'HOME points at the throwaway directory';
  ok -d $ENV{HOME}, 'the throwaway HOME exists';
  isnt $ENV{HOME}, $TestRepo::REAL_HOME, 'HOME is not the real one';
  is $ENV{XDG_CONFIG_HOME}, "$TestRepo::HOME/.config",
    'XDG_CONFIG_HOME is inside the throwaway HOME too';

  ok -d $TestRepo::SYSTEM_CONFIG_DIR, 'the stand-in for /etc exists';
  isnt "$TestRepo::SYSTEM_CONFIG_DIR", '/etc',
    'and it is emphatically not /etc';
};

subtest 'a TestRepo repository has no global identity' => sub {
  my ( $repo, $tmp ) = TestRepo::new_repo();

  is $repo->config_string('user.email'), undef, 'user.email is unset';
  is $repo->config_string('user.name'),  undef, 'user.name is unset';

  # The visible consequence, and the one that used to be machine-dependent:
  # commit_create / tag_create fall back to signature_default, which now takes
  # the documented placeholder instead of whoever is sitting at the keyboard.
  my $sig = $repo->signature_default;
  is $sig->email, 'unconfigured@example.invalid',
    'signature_default falls back to the placeholder identity';
  is $sig->name, 'Git::Native', 'and to the placeholder name';
};

subtest 'the real ~/.gitconfig on this machine is invisible' => sub {
  # The literal statement of the bug: whatever identity the developer has
  # configured must not answer a config_string on a test repository.
  my $real = defined $TestRepo::REAL_HOME
    ? path( $TestRepo::REAL_HOME, '.gitconfig' ) : undef;

  skip_all 'no ~/.gitconfig on this machine - nothing to leak'
    unless $real && $real->is_file;

  my $raw = eval { $real->slurp_utf8 } // '';
  my ($email) = $raw =~ /^\s*email\s*=\s*(\S+)/m;

  skip_all "~/.gitconfig has no user.email to probe with ($real)"
    unless defined $email;

  my ( $repo, $tmp ) = TestRepo::new_repo();
  isnt $repo->config_string('user.email'), $email,
    'the identity from the real ~/.gitconfig does not reach a test repository';
  isnt $repo->signature_default->email, $email,
    'and does not end up signing test commits';
};

subtest 'counter-probe: a config in the redirected HOME IS read' => sub {
  # Without this, the subtests above would pass just as well if libgit2 had
  # stopped reading the global level for some unrelated reason. Dropping a
  # config into the redirected HOME is the same channel the developer's
  # ~/.gitconfig used to come through - it has to still work, only now it
  # points somewhere harmless.
  my $probe = path( "$TestRepo::HOME", '.gitconfig' );
  $probe->spew_utf8("[user]\n\temail = $PROBE_EMAIL\n\tname = Global Probe\n");

  my ( $repo, $tmp ) = TestRepo::new_repo();
  is $repo->config_string('user.email'), $PROBE_EMAIL,
    'the global level is read from the redirected HOME';
  is $repo->signature_default->email, $PROBE_EMAIL,
    'and it does reach signature_default - so the isolation is what silences it';

  $probe->remove;
  my ( $after, $after_tmp ) = TestRepo::new_repo();
  is $after->config_string('user.email'), undef,
    'and it is gone again once the probe config is removed';
};

subtest 'the system level reads the redirected directory, not /etc' => sub {
  # Same shape as the global counter-probe above, one level down. /etc cannot
  # be written to from a test, so the proof runs the other way round: point
  # the system search path at a throwaway directory (TestRepo already did),
  # then show that a config dropped in there answers as the system level -
  # which is only possible if the redirect took, since the level would
  # otherwise still be reading /etc/gitconfig.
  my $probe = path( "$TestRepo::SYSTEM_CONFIG_DIR", 'gitconfig' );
  $probe->spew_utf8("[probe]\n\tsystem = $SYSTEM_PROBE\n");

  my ( $repo, $tmp ) = TestRepo::new_repo();
  is $repo->config_string('probe.system'), $SYSTEM_PROBE,
    'the system level is read from the redirected directory';

  $probe->remove;
  my ( $after, $after_tmp ) = TestRepo::new_repo();
  is $after->config_string('probe.system'), undef,
    'and it is gone again once the probe config is removed';

  # ... and the real /etc/gitconfig is not being read alongside it. On this
  # machine that is filter.lfs.*, which used to reach every test repository.
  my ( $key, $value ) = first_system_setting();
  if ( defined $key ) {
    is $after->config_string($key), undef,
      "a real /etc/gitconfig setting ($key) is invisible in a test repository";
  }
  else {
    note '/etc/gitconfig has no simple setting to probe with - '
      . 'the redirect is still proven by the probe config above';
    ok 1, 'nothing to probe against on this machine';
  }
};

subtest 'repository-local config is deliberately NOT isolated' => sub {
  # Tests are expected to configure the repository they just created (that is
  # how t/67-signature.t gets a deterministic identity). Isolating the local
  # level too would break that, so pin the layering: local wins over global,
  # and it survives with no global config at all.
  my ( $repo, $tmp ) = TestRepo::new_repo();
  $repo->config->set_string( 'user.email', 'local@example.invalid' );
  $repo->config->set_string( 'user.name',  'Local Tester' );

  is $repo->config_string('user.email'), 'local@example.invalid',
    'a repo-local value is readable';
  is $repo->signature_default->email, 'local@example.invalid',
    'and signature_default uses it';

  my $probe = path( "$TestRepo::HOME", '.gitconfig' );
  $probe->spew_utf8("[user]\n\temail = $PROBE_EMAIL\n");
  is $repo->config_string('user.email'), 'local@example.invalid',
    'the repo-local level still outranks the global one';
  $probe->remove;
};

subtest 'set_config_search_path argument guards' => sub {
  # The isolation above is only as good as the call that sets it up, so a
  # typo'd level name has to be loud rather than silently isolating nothing.
  like dies { Git::Native->set_config_search_path() },
    qr/at least one level/, 'a call with no levels croaks';
  like dies { Git::Native->set_config_search_path( sytem => '/nope' ) },
    qr/unknown config level 'sytem'/, 'a misspelled level croaks';
  like dies { Git::Native->set_config_search_path( sytem => '/nope' ) },
    qr/global, programdata, system, xdg/, 'and lists the ones that exist';

  # Names are case-insensitive, and setting a level to where it already
  # points is a no-op that still reports success.
  ok( Git::Native->set_config_search_path( SYSTEM => "$TestRepo::SYSTEM_CONFIG_DIR" ),
    'a level name is case-insensitive and returns true' );
};

subtest 'a process without TestRepo really does read $HOME/.gitconfig' => sub {
  # This one needs a subprocess: libgit2 resolves its search path once, at
  # init, so the difference between "isolated" and "not isolated" cannot be
  # produced inside an already-initialised process. The fixture HOME plays the
  # part of the developer's home directory.
  my $fixture = Path::Tiny->tempdir;
  $fixture->child('.gitconfig')
    ->spew_utf8("[user]\n\temail = $LEAK_EMAIL\n\tname = Leak Probe\n");

  my $script = Path::Tiny->tempfile( SUFFIX => '.pl' );
  $script->spew_utf8( <<'PROBE' );
use strict;
use warnings;
use lib 't/lib';
BEGIN { require TestRepo if $ENV{PROBE_WITH_TESTREPO} }
use Path::Tiny;
use Git::Native;
my $tmp  = Path::Tiny->tempdir;
my $repo = Git::Native->init( "$tmp", initial_branch => 'main' );
print "HOME=$ENV{HOME}\n";
print "EMAIL=", $repo->config_string('user.email') // '(unset)', "\n";
PROBE

  my $run = sub {
    my ($with_testrepo) = @_;
    local $ENV{HOME}                 = "$fixture";
    local $ENV{XDG_CONFIG_HOME}      = "$fixture/.config";
    local $ENV{GIT_CONFIG_GLOBAL}    = '/dev/null';
    local $ENV{GIT_CONFIG_SYSTEM}    = '/dev/null';
    local $ENV{PROBE_WITH_TESTREPO}  = $with_testrepo ? 1 : 0;
    my $out = qx{$^X -Ilib "$script" 2>&1};
    die "probe process failed (rc=$?): $out" if $?;
    my %got = $out =~ /^(\w+)=(.*)$/mg;
    return \%got;
  };

  my $without = $run->(0);
  my $with    = $run->(1);

  is $without->{EMAIL}, $LEAK_EMAIL,
    'without TestRepo, libgit2 reads $HOME/.gitconfig despite GIT_CONFIG_GLOBAL=/dev/null';
  is $without->{HOME}, "$fixture", 'that process kept the HOME it was given';

  is $with->{EMAIL}, '(unset)', 'with TestRepo loaded first, that config is invisible';
  isnt $with->{EMAIL}, $without->{EMAIL},
    'the two runs disagree - the isolation is doing the work, not the environment';

  isnt $with->{HOME}, "$fixture", 'TestRepo redirected HOME away from the fixture';
  ok !-e $with->{HOME},
    'and the throwaway HOME was cleaned up when the process exited';
};

subtest 'a process without TestRepo really does read /etc/gitconfig' => sub {
  # The system-level twin of the subtest above, and the one that needs a
  # subprocess most: /etc/gitconfig is the level no environment variable can
  # move, so the only way to see the un-isolated state is a process that never
  # called set_config_search_path. Three runs, so the last one also pins the
  # documented "undef puts the compiled-in default back" behaviour without
  # un-isolating this process.
  my ( $key, $value ) = first_system_setting();
  skip_all 'no simple setting in /etc/gitconfig to probe with'
    unless defined $key;

  my $script = Path::Tiny->tempfile( SUFFIX => '.pl' );
  $script->spew_utf8( <<'PROBE' );
use strict;
use warnings;
use lib 't/lib';
BEGIN { require TestRepo if $ENV{PROBE_WITH_TESTREPO} }
use Path::Tiny;
use Git::Native;
Git::Native->set_config_search_path( system => undef ) if $ENV{PROBE_RESET};
my $tmp  = Path::Tiny->tempdir;
my $repo = Git::Native->init( "$tmp", initial_branch => 'main' );
print "VALUE=", $repo->config_string( $ENV{PROBE_KEY} ) // '(unset)', "\n";
PROBE

  my $run = sub {
    my (%opt) = @_;
    local $ENV{GIT_CONFIG_GLOBAL}   = '/dev/null';
    local $ENV{GIT_CONFIG_SYSTEM}   = '/dev/null';
    local $ENV{PROBE_KEY}           = $key;
    local $ENV{PROBE_WITH_TESTREPO} = $opt{testrepo} ? 1 : 0;
    local $ENV{PROBE_RESET}         = $opt{reset}    ? 1 : 0;
    my $out = qx{$^X -Ilib "$script" 2>&1};
    die "probe process failed (rc=$?): $out" if $?;
    my ($v) = $out =~ /^VALUE=(.*)$/m;
    return $v;
  };

  is $run->( testrepo => 0 ), $value,
    "without TestRepo, libgit2 reads $key from /etc/gitconfig "
    . 'despite GIT_CONFIG_SYSTEM=/dev/null';
  is $run->( testrepo => 1 ), '(unset)',
    'with TestRepo loaded first, the system level is invisible';
  is $run->( testrepo => 1, reset => 1 ), $value,
    'and set_config_search_path(system => undef) hands /etc/gitconfig back';
};

done_testing;
