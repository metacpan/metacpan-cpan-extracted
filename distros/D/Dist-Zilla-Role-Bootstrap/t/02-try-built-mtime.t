
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
use Path::Tiny qw( path );
use FindBin;
my $cwd    = path('./')->absolute;
my $source = path("$FindBin::Bin")->parent->child('corpus')->child('fake_dist_01');

my $scratch = Path::Tiny->tempdir;
use File::Copy::Recursive qw(rcopy);

rcopy "$source", "$scratch";

my (@scratches) = map { $scratch->child( 'Example-' . $_ ) } qw( 0.01 0.10 0.05 );

for my $scratch_id ( 0 .. $#scratches ) {
  my $scratch = $scratches[$scratch_id];
  if ( $scratch_id == 0 ) {
    $scratch->child('lib')->mkpath;
    next;
  }
  my $tries      = 0;
  my $sleep_step = 0.3;    # Start intentionally slow to hopefully hit a subsecond transition.
  my $elapsed    = 0.0;

  while ( not -e $scratch or $scratch->stat->mtime <= $scratches[ $scratch_id - 1 ]->stat->mtime ) {
    $tries++;
    if ( $elapsed > 5 ) {
      diag "Your system has a broken clock/filesystem and mtime based tests cant work";
    SKIP: {
        skip "Broken MTime", 8;
      }
      done_testing;
      exit 0;
    }
    if ( $elapsed > 2 ) {
      diag "mtime looks a bit wonky :/, this test will seem slow";
    }

    select( undef, undef, undef, $sleep_step );
    $elapsed += $sleep_step;
    note "Attempt " . ($tries) . " at creating " . $scratch . " @" . (gmtime) . "( elapsed: $elapsed )";
    $scratch->remove_tree() if -e $scratch;
    $scratch->child('lib')->mkpath;
    $sleep_step = $sleep_step * 2;    # Exponentially larger steps to find clock slew as fast as possible
  }
  note "Succcess @" . (gmtime) . "( elapsed: $elapsed )";
}
chdir $scratch->stringify;

$section->current_section->payload->{chrome} = $chrome;
$section->current_section->payload->{root}   = $scratch->stringify;
$section->current_section->payload->{name}   = 'Example';
$section->finalize;

my $instance = Example->plugin_from_config(
  'testing',
  {
    try_built        => 1,
    try_built_method => 'mtime'
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
      try_built_method                         => 'mtime',
      '$Dist::Zilla::Role::Bootstrap::VERSION' => $Dist::Zilla::Role::Bootstrap::VERSION,
    }
  },
  'dump_config is expected'
);

is( $instance->distname,                  'Example',                                 'distname is Example' );
is( $instance->_cwd->realpath,            $scratch->realpath,                        'cwd is project root/' );
is( $instance->try_built,                 1,                                         'try_built is on' );
is( $instance->try_built_method,          'mtime',                                   'try_built_method is mtime' );
is( $instance->fallback,                  1,                                         'fallback is on' );
is( $instance->_bootstrap_root->realpath, $scratch->child('Example-0.05')->realpath, '_bootstrap_root == _cwd' )
  or diag explain [
  map {
    { $_->stringify => $_->stat->mtime }
  } @scratches
  ];
ok( $instance->can('_add_inc'), '_add_inc method exists' );

chdir $cwd->stringify;
done_testing;
