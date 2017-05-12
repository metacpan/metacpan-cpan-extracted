use strict;
use warnings;
BEGIN {
  $ENV{DEVEL_CONFESS_OPTIONS} = '';
}
use Test::More tests => 3;
use lib 't/lib';
use Capture
  capture_with_debugger => ['-d', '-MDevel::Confess=evalsource,nowarnings'],
;
use Cwd qw(cwd);

my $code = <<'END_CODE';
#line 1 test-block.pl
sub Foo::foo {
  die "error";
}

sub Bar::bar {
  eval 'Foo::foo()';
  die $@ if $@;
}

eval 'sub Baz::baz { Bar::bar() } 1;' or die $@;

Baz::baz();
END_CODE

{
  local %ENV = %ENV;
  delete $ENV{$_} for grep /^PERL5?DB/, keys %ENV;
  delete $ENV{LOGDIR};
  $ENV{HOME} = cwd;
  $ENV{PERLDB_OPTS} = 'NonStop noTTY dieLevel=1';
  my $out = capture_with_debugger $code;

  for my $eval ('Foo::foo()', 'sub Baz::baz { Bar::bar() } 1;') {
    local $TODO = 'eval source not preserved after run in 5.10.0'
      if "$]" == 5.010_000 && $eval =~ /sub/;
    like $out, qr/context for \(eval \d+\).* line 1:\n\s*1 :.*\Q$eval\E/,
      'trace includes eval text';
  }

  my @file_context = grep !/\(eval/, $out =~ /context for (.*?) line/g;
  is join(', ', @file_context), '',
    'trace only includes eval frames';
}
