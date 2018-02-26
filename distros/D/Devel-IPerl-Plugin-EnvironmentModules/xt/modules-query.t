package main;

use strict;
use warnings;
use Test::More;
use Devel::IPerl;
use IPerl;
use lib 'xt/lib';
use FindBin;
use File::Spec::Functions qw{catfile};

$ENV{PERL_MODULECMD} = catfile $FindBin::Bin, qw{bin modulecmd};

my $iperl = new_ok('IPerl');

is $iperl->load_plugin('EnvironmentModules'), 1, 'loaded';

can_ok $iperl,
  qw{module_avail module_load module_list_array module_list module_search
     module_show module_unload};

for my $name(qw{avail list}){
  my $cb = $iperl->can("module_$name");
  is $iperl->$cb(), "$name\n", 'returns stderr';
}

my $cb = $iperl->can("module_show");
is $iperl->$cb(), -1, 'empty args == -1';
is $iperl->$cb('modulename'), "show\n", 'returns stderr';

$cb = $iperl->can("module_search");
is $iperl->$cb(), -1, 'empty args == -1';
is $iperl->$cb(qr{^gcc/}), 'no match', 'no match';
is $iperl->$cb(qr{avail}), 'avail', 'match';

{
  no strict 'refs';
  no warnings 'redefine';
  # *{"${class}::$_"} = $NAME->("${class}::$_", $patch{$_}) for keys %patch;
  local *{'Devel::IPerl::Plugin::EnvironmentModules::avail'} = sub {
    return join "\n", qw{alpha beta gamma}, 'delta   theta    Epsilon/1';
  };

  $cb = $iperl->can("module_search");
  is $iperl->$cb(qr{^alpha$}), 'alpha', 'match';
  is $iperl->$cb(qr{^beta$}), 'beta', 'match';
  is $iperl->$cb(qr{^delta$}), 'delta', 'match';
  is $iperl->$cb(qr{^(alpha|theta)$}), join("\n", qw{alpha theta}), 'match';
  is $iperl->$cb(qr{^(theta|epsilon/1|beta)$}i),
    join("\n", qw{beta Epsilon/1 theta}), 'matches sorted';
}

{
  no strict 'refs';
  no warnings 'redefine';
  local *{'Devel::IPerl::Plugin::EnvironmentModules::list'} = sub {
    return <<'EOM';
Currently Loaded Modulefiles:
  1) use.own            3) texlive/20151117   5) samtools/1.2
  2) system/0.3         4) pandoc/1.19.2
EOM
  };

  $cb = $iperl->can("module_list_array");
  is_deeply $iperl->$cb(),
    ['use.own', 'texlive/20151117', 'samtools/1.2', 'system/0.3', 'pandoc/1.19.2'],
    'sorted list of loaded modules';
}

done_testing
