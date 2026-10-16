use 5.022;
use Test2::V0 -no_srand => 1;
use Test::DZil;
use Perl::PrereqScanner;
use experimental qw( signatures );

sub scanned_prereqs ($content)
{
  Perl::PrereqScanner->new->scan_string($content)->as_string_hash;
}

sub build ($tests_config = {}, @extra)
{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          {},
          # [GatherDir]
          'GatherDir',
          [ 'Author::Plicease::Tests' => $tests_config ],
          @extra,
        )
      }
    }
  );

  $tzil->build;

  my %files = map { $_->name => $_ } @{ $tzil->files };

  return ($tzil, \%files);
}

subtest 'basic' => sub {

  my($tzil, $files) = build(
    {},
    [ 'Prereqs' => {
      'Foo::Bar' => 0,
      'perl'     => '5.008',
      'strict'   => 0,
      'warnings' => 0,
      'base'     => 0,
    } ],
    [ 'Prereqs' => 'TestPrereqs' => {
      -phase     => 'test',
      'Baz::Test' => 0,
    } ],
    [ 'Prereqs' => 'DevelopPrereqs' => {
      -phase     => 'develop',
      'Develop::Only' => 0,
    } ],
  );

  ok $files->{$_}, "has $_" for qw(
    xt/author/strict.t
    xt/author/eol.t
    xt/author/pod.t
    xt/author/no_tabs.t
    xt/author/pod_coverage.t
    xt/author/pod_spelling_common.t
    xt/author/pod_spelling_system.t
    xt/author/version.t
    xt/release/changes.t
    xt/release/fixme.t
    t/00_diag.t
  );

  my $diag = $files->{'t/00_diag.t'}->content;
  note $diag;

  like   $diag, qr/^use Test::More tests => 1;$/m, 'uses Test::More by default';
  unlike $diag, qr/## (GENERATE|PREAMBLE) ##/,     'placeholders replaced';
  like   $diag, qr/^  Foo::Bar$/m,                 'runtime prereq';
  like   $diag, qr/^  Baz::Test$/m,                'test prereq';
  unlike $diag, qr/^  Develop::Only$/m,            'no develop prereq';
  unlike $diag, qr/^  (perl|strict|warnings|base)$/m, 'no perl/strict/warnings/base';
  unlike $diag, qr/EV\.pm/,                        'no EV';
  unlike $diag, qr/Test\/Tester/,                  'no Test::Tester';

  is(
    $tzil->root->child('t/00_diag.t')->slurp_raw,
    $diag,
    'also written to the source root',
  );

};

subtest 'test2_v0' => sub {

  my($tzil, $files) = build({ test2_v0 => 1 });

  my $diag = $files->{'t/00_diag.t'}->content;
  note $diag;

  like   $diag, qr/^use Test2::V0 -no_srand => 1;$/m, 'uses Test2::V0';
  unlike $diag, qr/^use Test::More tests/m,          'does not use Test::More';

};

subtest 'diag overrides' => sub {

  my($tzil, $files) = build(
    { diag => [ '+Extra::Module', '-Foo::Bar', '+EV' ] },
    [ 'Prereqs' => {
      'Foo::Bar'     => 0,
      'Other::Thing' => 0,
    } ],
  );

  my $diag = $files->{'t/00_diag.t'}->content;
  note $diag;

  like   $diag, qr/^  Extra::Module$/m,  'added module';
  unlike $diag, qr/^  Foo::Bar$/m,       'removed module';
  like   $diag, qr/^  Other::Thing$/m,   'kept module';
  like   $diag, qr/^BEGIN \{ eval \{ require 'EV\.pm'; \} \}$/m, 'EV loaded early';
  ok !exists scanned_prereqs($diag)->{EV}, 'EV not detected as a prereq';

};

subtest 'bad diag override' => sub {

  like(
    dies { build({ diag => [ 'Foo::Bar' ] }) },
    qr/diagnostic override must be prefixed with \+ or -/,
    'dies without + or -',
  );

};

subtest 'JSON::MaybeXS' => sub {

  my($tzil, $files) = build(
    {},
    [ 'Prereqs' => { 'JSON::MaybeXS' => 0 } ],
  );

  my $diag = $files->{'t/00_diag.t'}->content;

  like $diag, qr/^  JSON::MaybeXS$/m, 'JSON::MaybeXS';
  like $diag, qr/^  JSON::PP$/m,      'JSON::PP';
  like $diag, qr/^  JSON::XS$/m,      'JSON::XS';

};

subtest 'Test::Builder + Test::Tester' => sub {

  my($tzil, $files) = build(
    {},
    [ 'Prereqs' => { 'Test::Builder' => 0, 'Test::Tester' => 0 } ],
  );

  like $files->{'t/00_diag.t'}->content, qr/^eval \{ require 'Test\/Tester\.pm'; \};/m, 'requires Test::Tester';
  ok !exists scanned_prereqs($files->{'t/00_diag.t'}->content)->{'Test::Tester'}, 'Test::Tester not detected as a prereq';

};

subtest 'diag_preamble' => sub {

  my($tzil, $files) = build(
    { diag_preamble => [ '| $post_diag = sub {', '|   diag "hello";', '| };' ] },
  );

  my $diag = $files->{'t/00_diag.t'}->content;
  note $diag;

  like $diag, qr/^\$post_diag = sub \{\n  diag "hello";\n\};$/m, 'preamble inserted with | stripped';

};

subtest 'existing t/00_diag.t is replaced' => sub {

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/t/00_diag.t' => "old content\n",
        'source/dist.ini' => simple_ini(
          {},
          'GatherDir',
          [ 'Author::Plicease::Tests' => {} ],
        )
      }
    }
  );

  $tzil->build;

  my @diag = grep { $_->name eq 't/00_diag.t' } @{ $tzil->files };

  is scalar(@diag), 1, 'only one t/00_diag.t';
  unlike $diag[0]->content, qr/old content/, 'content replaced';
  like   $diag[0]->content, qr/^use Test::More/m, 'with generated content';

};

subtest 'test skipped on CI' => sub {

  my($tzil) = build();
  my($plugin) = grep { $_->isa('Dist::Zilla::Plugin::Author::Plicease::Tests') } @{ $tzil->plugins };

  local $ENV{CI} = 'true';
  ok lives { $plugin->test('.') }, 'test is a no-op on CI';

};

done_testing;
