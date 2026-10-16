use 5.022;
use Test2::V0 -no_srand => 1;
use Test::DZil;
use List::Util qw( first );
use Dist::Zilla::Plugin::Author::Plicease;
use experimental qw( signatures );

sub build ($config = {}, $files = {})
{
  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        %$files,
        'source/dist.ini' => simple_ini(
          {},
          'GatherDir',
          'MakeMaker',
          [ 'Prereqs' => {
            'perl'                    => '5.008',
            'Moo'                     => 0,
            'Path::Tiny'              => '0.200',
            'JSON'                    => 0,
            'JSON::MaybeXS'           => 0,
            'PerlX::Maybe'            => 0,
            'Mojo::UserAgent'         => 0,
            'Foo::Bar'                => 0,
            'Foo::Baz'                => 0,
          } ],
          [ 'Prereqs' => 'TestPrereqs' => {
            '-phase'                  => 'test',
            'Test2::V0'               => 0,
            'Test2::API'              => 0,
            'Test::More'              => 0,
          } ],
          [ 'Author::Plicease::SpecialPrereqs' => $config ],
        ),
      },
    },
  );

  $tzil->build;

  return $tzil;
}

subtest 'prereqs' => sub {

  my $tzil = build({ upgrade => [ 'Foo::Bar = 0.02' ] });

  my $prereqs = $tzil->prereqs->as_string_hash;

  is(
    $prereqs,
    hash {
      field runtime => hash {
        field requires => hash {
          field 'perl'            => '5.008';
          field 'Moo'             => '2.0';
          field 'Path::Tiny'      => '0.200';
          field 'PerlX::Maybe'    => '0.003';
          field 'Foo::Bar'        => '0.02';
          field 'Foo::Baz'        => '0';
          field 'JSON'            => '0';
          field 'JSON::MaybeXS'   => '0';
          field 'Mojo::UserAgent' => '0';
          end;
        };
        field recommends => hash {
          field 'JSON::XS'         => '0';
          field 'PerlX::Maybe::XS' => '0';
          field 'Cpanel::JSON::XS' => '0';
          field 'EV'               => '0';
          end;
        };
        etc;
      };
      field test => hash {
        field requires => hash {
          field 'Test2::V0'  => '0.000121';
          field 'Test2::API' => '1.302015';
          field 'Test::More' => '0.98';
          end;
        };
        etc;
      };
      etc;
    },
    'upgrades and recommends',
  );

};

subtest 'bad upgrade' => sub {

  like
    dies { build({ upgrade => [ 'Foo::Bar' ] }) },
    qr/upgrade failed: Foo::Bar/,
    'malformed upgrade is fatal';

};

subtest 'perlcriticrc' => sub {

  my $tzil = build({}, {
    'source/perlcriticrc' => join("\n",
      'severity = 1',
      '[TestingAndDebugging::RequireUseStrict]',
      '[-ValuesAndExpressions::ProhibitMagicNumbers]',
      '[Freenode::Each]',
      '',
    ),
  });

  my $recommends = $tzil->prereqs->as_string_hash->{develop}->{recommends};

  is(
    $recommends,
    hash {
      field 'Perl::Critic::Policy::TestingAndDebugging::RequireUseStrict' => '0';
      field 'Perl::Critic::Policy::Freenode::Each'                        => '0';
      field 'Perl::Critic::Policy::-ValuesAndExpressions::ProhibitMagicNumbers' => DNE();
      field 'Perl::Critic::Policy::_' => DNE();
      etc;
    },
    'recommends policies from perlcriticrc',
  );

};

subtest 'installer preamble' => sub {

  my $tzil = build({ preamble => [ '| $ENV{FOO} = 1;', '| $ENV{BAR} = 2;' ] });

  my $file = first { $_->name eq 'Makefile.PL' } $tzil->files->@*;
  ok $file, 'has Makefile.PL';

  my $content = $file->content;
  note $content;

  like $content, qr/\ABEGIN \{\n  use strict; use warnings;\n  \$ENV\{FOO\} = 1;\n  \$ENV\{BAR\} = 2;\n  unless\(eval q\{ use 5\.008; 1\}\) \{\n    print "Perl 5\.008 or better required\\n";\n    exit;\n  \}\n\}\n/, 'preamble';

};

subtest 'installer preamble without perl prereq' => sub {

  my $tzil = Builder->from_config(
    { dist_root => 'corpus/DZT' },
    {
      add_files => {
        'source/dist.ini' => simple_ini(
          {},
          'GatherDir',
          'MakeMaker',
          [ 'Author::Plicease::SpecialPrereqs' => {} ],
        ),
      },
    },
  );

  ok no_warnings { $tzil->build }, 'no warnings';

  my $file = first { $_->name eq 'Makefile.PL' } $tzil->files->@*;
  ok $file, 'has Makefile.PL';

  my $content = $file->content;
  note $content;

  like $content, qr/^  unless\(eval q\{ use 5\.006; 1\}\) \{\n    print "Perl 5\.006 or better required\\n";/m, 'defaults to 5.006';

};

subtest 'before_release' => sub {

  my $tzil = build();
  my $plugin = $tzil->plugin_named('Author::Plicease::SpecialPrereqs');

  is $plugin->win32, 0, 'win32 defaults to false';

  {
    local $^O = 'MSWin32';
    like dies { $plugin->before_release }, qr/This dist is not releasable on MSWin32/, 'not releasable on MSWin32';
  }

  {
    local $^O = 'linux';
    my $git = Dist::Zilla::Plugin::Author::Plicease->git;
    if($git)
    {
      ok lives { $plugin->before_release }, 'releasable on linux';
    }
    else
    {
      like dies { $plugin->before_release }, qr/release requires git/, 'requires git';
    }
  }

  my $tzil2 = build({ win32 => 1 });
  my $plugin2 = $tzil2->plugin_named('Author::Plicease::SpecialPrereqs');

  {
    local $^O = 'linux';
    like dies { $plugin2->before_release }, qr/This dist must be released on MSWin32/, 'must be released on MSWin32';
  }

};

done_testing;
