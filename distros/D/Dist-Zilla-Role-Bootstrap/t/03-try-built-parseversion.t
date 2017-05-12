
use strict;
use warnings;

use Test::More;

{

  package Example;
  use Moose;
  with 'Dist::Zilla::Role::Bootstrap';

  sub bootstrap {
    1;
  }

  __PACKAGE__->meta->make_immutable;
  1;
}

pass("Role Composition Check Ok");
ok( Example->bootstrap, 'invoke basic method on composed class' );

require Dist::Zilla::Chrome::Test;
require Dist::Zilla::MVP::Section;
require Dist::Zilla::Dist::Builder;
require Dist::Zilla::MVP::Assembler::Zilla;

my $chrome  = Dist::Zilla::Chrome::Test->new();
my $section = Dist::Zilla::MVP::Assembler::Zilla->new(
  chrome        => $chrome,
  zilla_class   => 'Dist::Zilla::Dist::Builder',
  section_class => 'Dist::Zilla::MVP::Section',
);
use FindBin;
use Path::Tiny qw( path );

my $cwd    = path('./')->absolute;
my $source = path("$FindBin::Bin")->parent->child('corpus')->child('fake_dist_01');

my $scratch = Path::Tiny->tempdir;
use File::Copy::Recursive qw(rcopy);

rcopy "$source", "$scratch";

$scratch->child("Example-0.01")->child('lib')->mkpath;
$scratch->child("Example-0.10")->child('lib')->mkpath;
$scratch->child("Example-0.05")->child('lib')->mkpath;

chdir $scratch->stringify;

$section->current_section->payload->{chrome} = $chrome;
$section->current_section->payload->{root}   = $scratch->stringify;
$section->current_section->payload->{name}   = 'Example';
$section->finalize;

my $instance = Example->plugin_from_config(
  'testing',
  {
    try_built        => 1,
    try_built_method => 'parseversion'
  },
  $section
);
$instance->distname;
$instance->fallback;
$instance->try_built;
$instance->try_built_method;

is_deeply(
  $instance->dump_config,
  {
    'Dist::Zilla::Role::Bootstrap' => {
      distname                                 => 'Example',
      fallback                                 => 1,
      try_built                                => 1,
      try_built_method                         => 'parseversion',
      '$Dist::Zilla::Role::Bootstrap::VERSION' => $Dist::Zilla::Role::Bootstrap::VERSION,
    }
  },
  'dump_config is expected'
);

is( $instance->distname,         'Example',          'distname is Example' );
is( $instance->_cwd->realpath,   $scratch->realpath, 'cwd is project root/' );
is( $instance->try_built,        1,                  'try_built is on' );
is( $instance->try_built_method, 'parseversion',     'try_built_method is parseversion' );

is( $instance->fallback, 1, 'fallback is on' );
is( $instance->_bootstrap_root->realpath, $scratch->child('Example-0.10')->realpath, '_bootstrap_root == _cwd' );
ok( $instance->can('_add_inc'), '_add_inc method exists' );

chdir $cwd->stringify;
done_testing;
