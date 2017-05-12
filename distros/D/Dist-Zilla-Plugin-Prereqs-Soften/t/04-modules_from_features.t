
use strict;
use warnings;

use Test::More;

# FILENAME: 01-basic.t
# CREATED: 03/23/14 19:41:51 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Basic interface test

use Test::Requires {
  'Dist::Zilla::Plugin::OptionalFeature' => 0,
  'Dist::Zilla'                          => 5.020,    # EUMM Ver = 0
};

use Test::DZil qw(simple_ini Builder);
use Path::Tiny qw( path );
use Test::Differences qw( eq_or_diff );

my $of_config = [ 'OptionalFeature' => 'Example', { '-description' => 'An example feature', 'Foo' => 2, } ];
my $expected_yaml = {
  configure => { requires   => { 'ExtUtils::MakeMaker' => '0', }, },
  runtime   => { recommends => { 'Foo'                 => '1' } },
  develop   => { requires   => { 'Foo'                 => '2' } },
};

local $@;

if ( eval { Dist::Zilla::Plugin::OptionalFeature->VERSION('0.022'); 1 } ) {
  $of_config->[2]->{'-always_suggest'} = 0;
  $expected_yaml->{configure}->{requires} = {
    %{ $expected_yaml->{configure}->{requires} },
    'CPAN::Meta::Requirements' => '2.120620',
    'Module::Metadata'         => 0,
  };
}

my $tzil = Builder->from_config(
  { dist_root => 'invalid' },
  {
    add_files => {
      path( 'source', 'dist.ini' ) => simple_ini(

        [ 'Prereqs', { 'Foo' => 1 } ],    #
        ['MakeMaker'],                    #
        $of_config,                       #
        [ 'Prereqs::Soften', { 'modules_from_features' => 1 } ],    #
        ['GatherDir'],                                              #
      ),
      path( 'source', 'lib', 'E.pm' ) => <<'EO_EPM',
use strict;
use warnings;

package E;

# ABSTRACT: Fake dist stub

use Moose;
with 'Dist::Zilla::Role::Plugin';

1;

EO_EPM

    }
  }
);

$tzil->chrome->logger->set_debug(1);

$tzil->build;

eq_or_diff( $tzil->prereqs->as_string_hash, $expected_yaml );

done_testing;

