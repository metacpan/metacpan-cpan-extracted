# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use lib 't/lib';

use Dist::Zilla::Util;
sub e { Dist::Zilla::Util->expand_config_package_name($_[0]); }

sub test_bundle {
  my ($name, $rem_attr, $desc) = @_;

  my $BNAME = '@'.$name;
  my $mod = "Dist::Zilla::PluginBundle::$name";
  eval "require $mod" or die $@;

  my $prefix = "$BNAME/Thingy/Dooer";
  my @notprune = (
    ["$prefix/Scan4Prereqs"   => e('AutoPrereqs')   => { }],
  );
  my @expected = (
    @notprune,
    ["$prefix/GoodbyeGarbage" => e('PruneCruft')    => { }],
  );

  my $bundled = sub {
    $mod->bundle_config({
      name => $BNAME,
      payload => {
        prefixes => [qw(Thingy Dooer)],
        %{ $_[0] },
      },
    })
  };

  is_deeply
    [ $bundled->({}) ],
    [ @expected ],
    "default plugins bundled for $name";

  is_deeply
    [ $bundled->({$rem_attr => ['PruneCruft']}) ],
    [ @notprune ],
    "minus plugins specified by $desc";
}

test_bundle TestRemover   => '-remove'  => '-remove';
test_bundle EasyRemover   => '-remove'  => '-remove';
test_bundle CustomRemover => scurvy_cur => 'alternate attribute';

done_testing;
