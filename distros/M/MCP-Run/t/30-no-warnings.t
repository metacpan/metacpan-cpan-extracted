use strict;
use warnings;
use Test::More;

# Regression tests: any warning produced inside our code fails the test.
# These pin down the bugs found while auditing Compress.pm:
#   - a transform returning undef used to slip into join()
#   - undef inputs used to propagate through the filter pipeline
use lib 'lib';
use MCP::Run::Compress ();

sub with_fatal_warnings {
  my ($code) = @_;
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_; die "WARNED: @_" };
  my $ok = eval { $code->(); 1 };
  my $err = $@;
  return ($ok, $err, \@warnings);
}

subtest 'compress: transform returning undef does not warn' => sub {
  my $c = MCP::Run::Compress->new;

  # git diff --stat's built-in transform returns undef for the summary line
  my $out = " file1.txt | 5 +++ --- 2 deletions(-)\n 2 files changed, 8 insertions(+), 3 deletions(-)\n";
  my ($stdout, $stderr) = $c->compress('git diff --stat', $out, '');

  unlike($stdout, qr/files? changed/, 'summary line dropped by transform');
  like($stdout, qr/file1\.txt/, 'per-file line kept');
};

subtest 'compress: undef inputs do not warn under FATAL warnings' => sub {
  my ($ok, $err, $warnings) = with_fatal_warnings(sub {
    my $c = MCP::Run::Compress->new;
    my ($stdout, $stderr) = $c->compress('ls', undef, undef);
    is($stdout, '', 'undef stdout becomes empty string');
    is($stderr, '', 'undef stderr becomes empty string');
  });
  ok($ok, "no warnings emitted: $err");
};

subtest 'compress: bare git (no subcommand) does not warn' => sub {
  my ($ok, $err) = with_fatal_warnings(sub {
    my $c = MCP::Run::Compress->new;
    $c->compress('git', 'whatever', '');
  });
  ok($ok, "no warnings: $err");
};

subtest 'compress: empty command does not warn' => sub {
  my ($ok, $err) = with_fatal_warnings(sub {
    my $c = MCP::Run::Compress->new;
    $c->compress('', "no command\n", '');
  });
  ok($ok, "no warnings: $err");
};

subtest 'process: does not warn under FATAL warnings for matched filter' => sub {
  my ($ok, $err) = with_fatal_warnings(sub {
    my $c = MCP::Run::Compress->new;
    my $out = " file1.txt | 5 +++ --- 2 deletions(-)\n 2 files changed, 8 insertions(+), 3 deletions(-)\n";
    my $r = $c->process('git diff --stat', $out, '');
    # A filter will match — regardless of which one wins the hash iteration,
    # both paths drop the summary line via either transform (returns undef)
    # or strip_lines_matching.
    unlike($r->{stdout}, qr/\d+\s+files?\s+changed/, 'summary line dropped');
    like($r->{stdout}, qr/file1\.txt/, 'per-file line kept');
  });
  ok($ok, "no warnings emitted: $err");
};

subtest 'process: undef inputs do not warn under FATAL warnings' => sub {
  my ($ok, $err) = with_fatal_warnings(sub {
    my $c = MCP::Run::Compress->new;
    my $r = $c->process('ls', undef, '');
    is($r->{stdout}, '', 'undef stdout becomes empty string');
  });
  ok($ok, "no warnings: $err");
};

subtest 'transform_command: short git args do not warn' => sub {
  my ($ok, $err) = with_fatal_warnings(sub {
    local $ENV{ANTHROPIC_MODEL} = 'MiniMax-M2.7';
    my $c = MCP::Run::Compress->new;
    $c->transform_command('git');
    $c->transform_command('ls -la');
  });
  ok($ok, "no warnings: $err");
};

done_testing;
