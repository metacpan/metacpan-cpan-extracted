use strict;
use warnings;
use Test::More 0.88;
use Test::DZil;

plan tests => 7;

my $tzil = Builder->from_config(
  { dist_root => 'corpus/DZT' },
  {
    add_files => {
      'source/dist.ini' => simple_ini(
        { version => '4.7' },
        # [GatherDir]
        'GatherDir',
        # [Template::Tiny]
        [
          'Template::Tiny' => {
            var => [ 'foo = 10', 'bar = hello world'],
          }
        ],
      )
    }
  }
);

$tzil->build;

pass('built');

my $foo_pm = eval { $tzil->slurp_file('build/lib/Foo.pm') };
diag $@ if $@;
ok $foo_pm, "created lib/Foo.pm";

eval $foo_pm;
is $@, '', 'resulting code compiled ok';

is $Foo::VARS{'dzil_version'}, '4.7',         'dzil_version = 4.7';
is $Foo::VARS{'dzil_name'   }, 'DZT-Sample',  'dzil_name    = DZT-Sample';
is $Foo::VARS{'foo'         }, 10,            'foo          = 10';
is $Foo::VARS{'bar'         }, 'hello world', 'bar          = hello world';
