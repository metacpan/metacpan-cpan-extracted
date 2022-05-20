use strict;
use warnings;
use File::Spec::Functions qw(catdir catfile rel2abs);
use Test::More;
use Getopt::App ();

my $script = rel2abs(catfile qw(example bin bundle));
plan skip_all => "$script" unless -x $script;

my @expect_bundled = (
  qr/^\#!/,
  qr/package Getopt::App;use feature/,
  qr/sub capture \{.*\}/,
  qr/sub extract_usage \{.*\}/,
  qr/sub import \{.*\}/,
  qr/sub new \{.*\}/,
  qr/sub run \{.*\}/,
  qr/sub _call \{.*\}/,
  qr/sub _getopt_configure \{.*\}/,
  qr/sub _getopt_post_process_argv \{.*\}/,
  qr/sub _subcommand \{.*\}/,
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
  push @ok, is ref $app,          'CODE', 'compiled';
  push @ok, is_deeply \@warnings, [],     'no warnings';

  unless (@ok == grep $_, @ok) {
    my $i = 0;
    diag sprintf "[%02s] %s", ++$i, $_ for @_;
    diag "Got warning: $_" for @warnings;
  }
};

done_testing;
