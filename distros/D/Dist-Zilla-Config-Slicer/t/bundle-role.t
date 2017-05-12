# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use lib 't/lib';

foreach my $name ( map { "Test::Bundle$_" } '', '::Easy' ) {
  my $BNAME = '@CLTB';
  my $mod = "Dist::Zilla::Config::Slicer::$name";
  eval "require $mod" or die $@;

  my @expected = (
    ["$BNAME/Test::Compile"  => e('Test::Compile') => {fake_home => 1}],
    ["$BNAME/MetaNoIndex"    => e('MetaNoIndex')   => { file => ['.secret'], directory => [qw(t xt inc)] }],
    ["$BNAME/Scan4Prereqs"   => e('AutoPrereqs')   => { }],
    ["$BNAME/GoodbyeGarbage" => e('PruneCruft')    => { }],
    ["$BNAME/DontNeedThese"  => e('PruneCruft')    => { }],
  );

  my $bundled = sub { $mod->bundle_config({ name => $BNAME, payload => shift }) };
  my $i = 0;

  is_deeply
    [ $bundled->({}) ],
    [ @expected ],
    "default plugins bundled for $name";

  is_deeply
    [ $bundled->({'Test::Compile.fake_home' => 0}) ],
    [ overwrite(\@expected, $i++, { fake_home => 0 }) ],
    "overwrote simple scalar for $name";

  is_deeply
    [ $bundled->({'MetaNoIndex.directory'  => 'goober'}) ],
    [ overwrite(\@expected, $i++, { file => ['.secret'], directory => [qw(t xt inc goober)] })],
    "append to directory for $name";

  is_deeply
    [ $bundled->({'Scan4Prereqs.skip' => 'Goober'}) ],
    [ overwrite(\@expected, $i++, { skip => 'Goober' })],
    "overwrote by name/alias for $name";

  is_deeply
    [ $bundled->({'PruneCruft.except[]' => '\.gitignore'}) ],
    [ overwrite(\@expected, map { ($i + $_, { except => ['\.gitignore'] }) } 0, 1)],
    "insert as directory by package for $name (into multiple plugins)";
  $i += 2;
}

done_testing;

sub e { Dist::Zilla::Util->expand_config_package_name($_[0]); }

sub overwrite {
  my $a = shift;
  my @e = map { [ @$_ ] } @$a; # copy
  while(@_){
    my ($i, $p) = splice(@_, 0, 2);
    $e[ $i ]->[2] = $p;
  }
  return @e;
}
