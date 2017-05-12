# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use Test::MockObject 1.09;
use Test::MockObject::Extends 1.09;

my $version = '1.002003';
my $expversion = $version;

my $zilla = Test::MockObject->new();
$zilla->set_bound(version => \$expversion);
$zilla->set_isa('Dist::Zilla');

my $gdv_mod = 'Git::DescribeVersion';
my $gdv = Test::MockObject->new();
$gdv->fake_module($gdv_mod, new => sub { @$gdv{keys %{$_[1]}} = values %{$_[1]}; $gdv });
$gdv->set_bound(version => \$expversion);

%Git::DescribeVersion::Defaults = ('cookie' => 'tasty', no => 'change');

my $mod = 'Dist::Zilla::Plugin::Git::DescribeVersion';
eval "require $mod" or die $@;
my $plug = $mod->new({plugin_name => $mod, zilla => $zilla});
isa_ok($plug, $mod);

my ($log, $fatal);
my $eval_error = "boo\n";
$plug = Test::MockObject::Extends->new($plug);
$plug->mock(log_fatal => sub { $fatal = "fatal: $_[1]"; die($eval_error); });
$plug->mock(log       => sub { $log   =   "log: $_[1]"; });
$plug->mock(zilla     => sub { $zilla });

# test basic functionality
is($plug->provide_version(), $version, 'expected version');
like($log, qr/described version as \Q$version\E/, 'version logged expectedly');

{
  # test %ENV override
  local $ENV{V} = 'reindeer';
  is($plug->provide_version(), $ENV{V}, '$ENV{V} overrides');
  delete $ENV{V};
  is($plug->provide_version(), $version, '$ENV{V} unset, returns version');
}

# test no version received from Git::DescribeVersion
$expversion = undef;
is(eval { $plug->provide_version(); }, undef, 'eval returned undef on expected death');
is($@, $eval_error, 'died with correct warning');
like($fatal, qr/could not determine version/i, 'expected warning logged');

# test argument passing to Git::DescribeVersion
$expversion = $version;
foreach my $opt ( $Git::DescribeVersion::Defaults{cookie}, qw(bark woof) ){
  $plug->mock(cookie => sub { $opt });
  $plug->provide_version();
  is($gdv->{cookie}, $opt, 'argument passed to gdv');
  is($gdv->{no}, 'change', 'attribute at default');
}

# it's better than nothing
done_testing;
