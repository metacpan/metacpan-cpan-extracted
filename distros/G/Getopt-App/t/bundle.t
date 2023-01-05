use Test2::V0;
use File::Spec::Functions qw(catdir catfile rel2abs);
use Getopt::App           ();

my $script = rel2abs(catfile qw(example bin bundle));
plan skip_all => "$script" unless -x $script;

my $first_line = join '.*', 'package Getopt::App', 'use feature', 'use strict', 'use warnings', 'use utf8', 'use Carp',
  'use Getopt::Long', 'use List::Util', '\$OPT_COMMENT_RE', '\$OPTIONS', '\$SUBCOMMANDS', '\%APPS', '\$call_maybe';

my @expect_bundled = (
  qr/^\#!/,
  qr/$first_line/,
  qr/sub capture \{.*\}/,
  qr/sub extract_usage \{.*\}/,
  qr/sub import \{.*\}/,
  qr/sub new \{.*\}/,
  qr/sub run \{.*\}/,
  qr/sub _getopt_complete_reply \{.*\}/,
  qr/sub _getopt_configure \{.*\}/,
  qr/sub _getopt_load_subcommand \{.*\}/,
  qr/sub _getopt_post_process_argv \{.*\}/,
  qr/sub _getopt_unknown_subcommand \{.*\}/,
  qr/sub _exit \{.*\}/,
  qr/sub _subcommand_run \{.*\}/,
  qr/sub _subcommand_run_maybe \{.*\}/,
  qr/sub _usage_for_options \{.*\}/,
  qr/sub _usage_for_subcommands \{.*\}/,
  qr/BEGIN\{\$INC\{'Getopt\/App\.pm'\}='BUNDLED'\}/,
  qr/package Test::Cool;/,
);

subtest bundle => sub {
  open my $OUT, '>', \my $bundled;
  Getopt::App->bundle($script, $OUT);
  ok !Test::Cool->can('new'), 'Test::Cool not loaded';

  my @bundled = split /\n/, $bundled;
  my $i       = 0;
  while ($i < @expect_bundled) {
    like $bundled[$i], $expect_bundled[$i], "match $expect_bundled[$i]";
    $i++;
  }

  my @warnings;
  local $SIG{__WARN__} = sub { $_[0] =~ m!Subroutine! || push @warnings, $_[0] };
  my $app = eval $bundled or diag $@;
  ok Test::Cool->can('new'), 'Test::Cool loaded';

  my @ok;
  push @ok, is ref $app,   'CODE', 'compiled';
  push @ok, is \@warnings, [],     'no warnings';

  unless (@ok == grep $_, @ok) {
    my $i = 0;
    diag sprintf "[%02s] %s", ++$i, $_ for @_;
    diag "Got warning: $_" for @warnings;
  }
};

done_testing;
