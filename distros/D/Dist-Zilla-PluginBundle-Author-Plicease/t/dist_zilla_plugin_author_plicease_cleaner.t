use 5.022;
use Test2::V0 -no_srand => 1;
use Test::DZil;
use Path::Tiny qw( path );

my @files = qw(
  .tmp/foo.txt
  _alien/foo.txt
  sub/_alien/foo.txt
  ffi/target/foo.txt
  ffi/foo.o
  ffi/foo.so
  ffi/foo.c
  t/ffi/zig-cache/foo.txt
  t/ffi/foo.ppu
  foo.o
  sub/dir/foo.o
  sub/dir/foo.c
  roger/foo.txt
  sub/roger/foo.txt
  corpus/roger/foo.txt
  keep/foo.o
  lib/Foo.pm
);

sub tzil
{
  my(%config) = @_;

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          {},
          # [GatherDir]
          'GatherDir',
          [ 'Author::Plicease::Cleaner' => \%config ],
        ),
        map { ("source/$_" => '') } @files,
      }
    }
  );

  return $tzil;
}

sub clean
{
  my($tzil, $dry) = @_;
  my $orig = Path::Tiny->cwd;
  chdir $tzil->root;
  my $ok = eval { $tzil->clean($dry); 1 };
  my $error = $@;
  chdir $orig;
  die $error unless $ok;
}

sub remaining
{
  my($tzil) = @_;
  my $root = path($tzil->root);
  [ sort grep { -e $root->child($_) } @files ];
}

subtest 'defaults' => sub {

  my $tzil = tzil();

  is $tzil->plugin_named('Author::Plicease::Cleaner')->clean, [], 'no extra clean rules';

  clean($tzil);

  note $_->{message} for $tzil->chrome->logger->events->@*;

  is
    remaining($tzil),
    [ sort qw(
      ffi/foo.c
      foo.o
      sub/dir/foo.o
      sub/dir/foo.c
      roger/foo.txt
      sub/roger/foo.txt
      corpus/roger/foo.txt
      keep/foo.o
      lib/Foo.pm
    ) ],
    'removed default rules (.tmp, _alien, ffi/*)',
  ;

};

subtest 'extra clean rules' => sub {

  my $tzil = tzil(
    clean => [ '*.o', '/roger', 'corpus/roger' ],
  );

  clean($tzil);

  note $_->{message} for $tzil->chrome->logger->events->@*;

  is
    remaining($tzil),
    [ sort qw(
      ffi/foo.c
      sub/dir/foo.c
      sub/roger/foo.txt
      lib/Foo.pm
    ) ],
    'removed extra rules: recursive glob and root-anchored paths',
  ;

};

subtest 'clean_keep' => sub {

  my $tzil = tzil(
    clean      => [ '*.o' ],
    clean_keep => [ '^keep/', 'sub/dir' ],
  );

  clean($tzil);

  is
    remaining($tzil),
    [ sort qw(
      ffi/foo.c
      sub/dir/foo.o
      sub/dir/foo.c
      roger/foo.txt
      sub/roger/foo.txt
      corpus/roger/foo.txt
      keep/foo.o
      lib/Foo.pm
    ) ],
    'kept files matching clean_keep',
  ;

};

subtest 'dry run' => sub {

  my $tzil = tzil( clean => [ '*.o' ] );

  clean($tzil, 1);

  my $log = [ map { $_->{message} } $tzil->chrome->logger->events->@* ];
  note $_ for @$log;

  is remaining($tzil), [ sort @files ], 'nothing removed';
  ok( (grep /clean: would remove \.tmp$/,   @$log), 'would remove .tmp' );
  ok( (grep /clean: would remove foo\.o$/,  @$log), 'would remove foo.o' );
  ok( (grep /clean: would remove ffi\/foo\.so$/, @$log), 'would remove ffi/foo.so' );
  ok( !(grep /clean: removing/, @$log), 'did not remove anything' );

};

subtest 'only cleans its own zilla' => sub {

  my $tzil1 = tzil( clean => [ '*.o' ] );
  my $tzil2 = tzil();

  clean($tzil2);

  ok -e path($tzil2->root)->child('ffi/foo.c'), 'sanity';
  ok -e path($tzil2->root)->child('foo.o'), "other instance's rules not applied";

};

done_testing;
